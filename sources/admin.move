/*

    TODO: 
    - refactor: treasury_fee_modifier -> treasury_fee
    - come up with a better name for the module
*/

module baptswap_v2::admin {

    use std::signer;
    use std::option::{Self, Option};
    use std::string;

    // use aptos_std::debug;
    use aptos_std::smart_table::{Self, SmartTable};
    use aptos_std::type_info;

    use aptos_framework::aptos_coin::{AptosCoin as APT};
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::resource_account;

    use baptswap::math;
    use baptswap::swap_utils;
    use baptswap::u256;

    use baptswap_v2::constants;
    use baptswap_v2::errors;

    friend baptswap_v2::fee_on_transfer;
    friend baptswap_v2::stake;
    friend baptswap_v2::swap_v2;

    // -------
    // Structs
    // -------

    // Global storage for swap info
    struct AdminInfo has key {
        signer_cap: account::SignerCapability,
        treasury_address: address,
        admin: address,
        liquidity_fee_modifier: u128,
        treasury_fee_modifier: u128
    }

    // Global storage for pending ownership transfer
    struct Pending has key {
        table: SmartTable<u64, address>  // <id, ownership offer>
    }

    // --------------------
    // Initialize Functions
    // --------------------

    fun init_module(sender: &signer) {
        let signer_cap = resource_account::retrieve_resource_account_cap(sender, @dev_2);
        let resource_signer = account::create_signer_with_capability(&signer_cap);
        // initialize swap info
        move_to(&resource_signer, AdminInfo {
            signer_cap,
            treasury_address: @treasury,
            admin: @admin,
            liquidity_fee_modifier: 30,  // 0.3%
            treasury_fee_modifier: 60,   // 0.6%
        });

        move_to(&resource_signer, Pending { table: smart_table::new<u64, address>() });
    }

    // from the perspective of the sender
    public entry fun offer_admin_previliges(signer_ref: &signer, receiver_addr: address, id: u64) acquires AdminInfo, Pending {
        // assert signer is the admin
        assert!(signer::address_of(signer_ref) == get_admin(), errors::not_admin());
        // assert receiver_addr is not the admin
        assert!(receiver_addr != get_admin(), errors::same_address());
        // create a new table entry
        smart_table::add<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id, receiver_addr)
    }

    public entry fun offer_treasury_previliges(signer_ref: &signer, receiver_addr: address, id: u64) acquires AdminInfo, Pending {
        // assert signer is the admin
        assert!(signer::address_of(signer_ref) == get_admin(), errors::not_admin());
        // assert receiver_addr is not the admin
        assert!(receiver_addr != get_treasury_address(), errors::same_address());
        // create a new table entry
        smart_table::add<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id, receiver_addr)
    }

    public entry fun cancel_admin_previliges(signer_ref: &signer, id: u64) acquires Pending {
        // destruct the pending resource
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id);
    }

    public entry fun cancel_treasury_previliges(signer_ref: &signer, id: u64) acquires Pending {
        // destruct the pending resource
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id);
    }

    // from the perspective of the receiver
    public entry fun claim_admin_previliges(signer_ref: &signer, id: u64) acquires AdminInfo, Pending {
        // assert id exists and the signer is the receiver
        assert!(smart_table::contains<u64, address>(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        assert!(signer::address_of(signer_ref) == *smart_table::borrow(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        // update admin info 
        set_admin(*smart_table::borrow(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id));
        // remove the entry
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id);
    }

    public entry fun claim_treasury_previliges(signer_ref: &signer, id: u64) acquires AdminInfo, Pending {
        // assert id exists and the signer is the receiver
        assert!(smart_table::contains<u64, address>(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        assert!(signer::address_of(signer_ref) == *smart_table::borrow(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        // update admin info 
        set_treasury_address(*smart_table::borrow(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id));
        // remove the entry
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id);
    }

    public entry fun reject_admin_previliges(signer_ref: &signer, id: u64) acquires Pending {
        // assert signer is the receiver
        assert!(smart_table::contains<u64, address>(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        assert!(signer::address_of(signer_ref) == *smart_table::borrow(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        // remove the entry
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id);
    }

    public entry fun reject_treasury_previliges(signer_ref: &signer, id: u64) acquires Pending {
        // assert signer is the receiver
        assert!(smart_table::contains<u64, address>(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        assert!(signer::address_of(signer_ref) == *smart_table::borrow(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        // remove the entry
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id);
    }

    // --------
    // Mutators
    // --------

    // Set treasury_address; follow the two step ownership transfer pattern
    fun set_treasury_address(new_treasury_address: address) acquires AdminInfo {
        let swap_info = borrow_global_mut<AdminInfo>(@baptswap_v2);
        // update the treasury address
        swap_info.treasury_address = new_treasury_address;
    }

    // Set admin; follow the two step ownership transfer pattern
    fun set_admin(new_admin: address) acquires AdminInfo {
        let swap_info = borrow_global_mut<AdminInfo>(@baptswap_v2);
        // update the admin
        swap_info.admin = new_admin;
    }

    // Set dex liquidity fee
    public entry fun set_dex_liquidity_fee(sender: &signer, new_fee: u128) acquires AdminInfo {
        let swap_info = borrow_global_mut<AdminInfo>(@baptswap_v2);
        // assert sender is admin
        assert!(signer::address_of(sender) == swap_info.admin, 1);
        // assert new fee is not equal to the existing fee
        assert!(new_fee != swap_info.liquidity_fee_modifier, 1);
        // assert the newer total fee is less than the threshold
        assert!(does_not_exceed_dex_fee_threshold(new_fee + swap_info.treasury_fee_modifier) == true, 1);
        // update the fee
        swap_info.liquidity_fee_modifier = new_fee;
    }

    // Set dex treasury fee
    public entry fun set_dex_treasury_fee(sender: &signer, new_fee: u128) acquires AdminInfo {
        let swap_info = borrow_global_mut<AdminInfo>(@baptswap_v2);
        // assert sender is admin
        assert!(signer::address_of(sender) == swap_info.admin, 1);
        // assert new fee is not equal to the existing fee
        assert!(new_fee != swap_info.treasury_fee_modifier, 1);
        // assert the newer total fee is less than the threshold
        assert!(does_not_exceed_dex_fee_threshold(new_fee + swap_info.liquidity_fee_modifier) == true, 1);
        // update the fee
        swap_info.treasury_fee_modifier = new_fee;
    }

    // --------------
    // View Functions
    // --------------

    public(friend) fun get_resource_signer(): signer acquires AdminInfo {
        let signer_cap = &borrow_global<AdminInfo>(@baptswap_v2).signer_cap;
        account::create_signer_with_capability(signer_cap)
    }

    #[view]
    public fun get_treasury_address(): address acquires AdminInfo {
        let admin_info = borrow_global<AdminInfo>(@baptswap_v2);
        admin_info.treasury_address
    }

    #[view]
    public fun get_admin(): address acquires AdminInfo {
        let admin_info = borrow_global<AdminInfo>(@baptswap_v2);
        admin_info.admin
    }

    #[view]
    public fun get_liquidity_fee_modifier(): u128 acquires AdminInfo {
        let admin_info = borrow_global<AdminInfo>(@baptswap_v2);
        admin_info.liquidity_fee_modifier
    }

    #[view]
    public fun get_treasury_fee_modifier(): u128 acquires AdminInfo {
        let admin_info = borrow_global<AdminInfo>(@baptswap_v2);
        admin_info.treasury_fee_modifier
    }

    #[view]
    // Returns dex fees: liquidity_fee_modifier + treasury_fee_modifier
    public fun get_dex_fees(): u128 acquires AdminInfo {
        let admin_info = borrow_global<AdminInfo>(@baptswap_v2);
        admin_info.liquidity_fee_modifier + admin_info.treasury_fee_modifier
    }

    // returns true if given rate is less than dex fee threshold
    public inline fun does_not_exceed_dex_fee_threshold(total_fees_numerator: u128): bool {
        if (total_fees_numerator <= constants::get_fee_threshold_numerator()) true else false
    }

    #[test_only]
    friend baptswap_v2::swap_v2_test;

    #[test_only]
    public fun init_test(sender: &signer) {
        init_module(sender)
    }
}