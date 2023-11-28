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

    friend baptswap_v2::fee_on_transfer;
    friend baptswap_v2::ownership_transfers;
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

    // --------------------
    // Initialize Functions
    // --------------------

    fun init_module(sender: &signer) {
        let signer_cap = resource_account::retrieve_resource_account_cap(sender, @dev_2);
        let resource_signer = account::create_signer_with_capability(&signer_cap);
        // initialize swap info
        move_to(&resource_signer, AdminInfo {
            signer_cap,
            treasury_address: @baptswap_v2, // TODO: tbs
            admin: @baptswap_v2, // TODO: tbs
            liquidity_fee_modifier: 30,  // 0.3%
            treasury_fee_modifier: 60,   // 0.6%
        });
    }

    // --------
    // Mutators
    // --------

    // Set treasury_address; follow the two step ownership transfer pattern
    public(friend) fun set_treasury_address(new_treasury_address: address) acquires AdminInfo {
        let swap_info = borrow_global_mut<AdminInfo>(@baptswap_v2);
        // update the treasury address
        swap_info.treasury_address = new_treasury_address;
    }

    // Set admin; follow the two step ownership transfer pattern
    public(friend) fun set_admin(new_admin: address) acquires AdminInfo {
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

}