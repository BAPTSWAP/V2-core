/*

    TODO: 
    - refactor: treasury_fee_modifier -> treasury_fee
    - come up with a better name for the module
*/

module baptswap_v2::admin {

    use aptos_framework::event;

    use std::signer;

    // use aptos_std::debug;
    use aptos_std::smart_table::{Self, SmartTable};
    
    use aptos_framework::account;
    use aptos_framework::resource_account;

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

    // ------
    // Events
    // ------

    #[event]
    struct OwnershipTransferRequestEvent has drop, store { memo: u64, new_owner: address }
    #[event]
    struct OwnershipTransferCanceledEvent has drop, store { memo: u64, new_owner: address }
    #[event]
    struct TreasuryAddressUpdatedEvent has drop, store { old_treasury_address: address,  new_treasury_address: address }
    #[event]
    struct AdminUpdatedEvent has drop, store { old_admin: address, new_admin: address }
    #[event]
    struct DexLiquidityFeeUpdatedEvent has drop, store { old_liquidity_fee: u128, new_liquidity_fee: u128 }
    #[event]
    struct DexTreasuryFeeUpdatedEvent has drop, store { old_treasury_fee: u128, new_treasury_fee: u128 }
    #[event]
    struct OwnershipTransferRejectedEvent has drop, store { memo: u64 }

    fun emit_ownership_transfer_request_event(memo: u64, new_owner: address) {
        event::emit<OwnershipTransferRequestEvent>(
            OwnershipTransferRequestEvent { memo, new_owner }
        );
    }

    fun emit_ownership_transfer_canceled_event(memo: u64, new_owner: address) {
        event::emit<OwnershipTransferCanceledEvent>(
            OwnershipTransferCanceledEvent { memo, new_owner }
        );
    }

    fun emit_treasury_address_updated_event(old_treasury_address: address, new_treasury_address: address) {
        event::emit<TreasuryAddressUpdatedEvent>(
            TreasuryAddressUpdatedEvent { old_treasury_address, new_treasury_address }
        );
    }

    fun emit_admin_updated_event(old_admin: address, new_admin: address) {
        event::emit<AdminUpdatedEvent>(
            AdminUpdatedEvent { old_admin, new_admin }
        );
    }

    fun emit_dex_liquidity_fee_updated_event(old_liquidity_fee: u128, new_liquidity_fee: u128) {
        event::emit<DexLiquidityFeeUpdatedEvent>(
            DexLiquidityFeeUpdatedEvent { old_liquidity_fee, new_liquidity_fee }
        );
    }

    fun emit_dex_treasury_fee_updated_event(old_treasury_fee: u128, new_treasury_fee: u128) {
        event::emit<DexTreasuryFeeUpdatedEvent>(
            DexTreasuryFeeUpdatedEvent { old_treasury_fee, new_treasury_fee }
        );
    }

    fun emit_ownership_transfer_rejected_event(memo: u64) {
        event::emit<OwnershipTransferRejectedEvent>(
            OwnershipTransferRejectedEvent { memo }
        );
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
    public entry fun offer_admin_previliges(signer_ref: &signer, receiver_addr: address, memo: u64) acquires AdminInfo, Pending {
        // assert no request is pending
        assert!(smart_table::length(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table) == 0, errors::pending_request());
        // assert signer is the admin
        assert!(signer::address_of(signer_ref) == get_admin(), errors::not_admin());
        // assert receiver_addr is not the admin
        assert!(receiver_addr != get_admin(), errors::same_address());
        // create a new table entry
        smart_table::add<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, memo, receiver_addr);
        // emit event
        emit_ownership_transfer_request_event(memo, receiver_addr);
    }

    public entry fun offer_treasury_previliges(signer_ref: &signer, receiver_addr: address, memo: u64) acquires AdminInfo, Pending {
        // assert no request is pending
        assert!(smart_table::length(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table) == 0, errors::pending_request());
        // assert signer is the admin
        assert!(signer::address_of(signer_ref) == get_admin(), errors::not_admin());
        // assert receiver_addr is not the admin
        assert!(receiver_addr != get_treasury_address(), errors::same_address());
        // create a new table entry
        smart_table::add<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, memo, receiver_addr);
        // emit event
        emit_ownership_transfer_request_event(memo, receiver_addr);
    }

    public entry fun cancel_admin_previliges(signer_ref: &signer, memo: u64) acquires AdminInfo, Pending {
        // assert signer is the admin
        assert!(signer::address_of(signer_ref) == get_admin(), errors::not_admin());
        // destruct the pending resource
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, memo);
        // emit event
        emit_ownership_transfer_canceled_event(memo, get_admin());
    }

    public entry fun cancel_treasury_previliges(signer_ref: &signer, memo: u64) acquires AdminInfo, Pending {
        // assert signer is the treausry
        assert!(signer::address_of(signer_ref) == get_treasury_address(), errors::not_admin());
        // destruct the pending resource
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, memo);
        // emit event
        emit_ownership_transfer_canceled_event(memo, get_treasury_address());
    }

    // from the perspective of the receiver
    public entry fun claim_admin_previliges(signer_ref: &signer, memo: u64) acquires AdminInfo, Pending {
        // assert signer is the one recieving the previliges
        let signer_addr = signer::address_of(signer_ref);
        assert!(
            smart_table::borrow<u64, address>(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, memo)
            == &signer_addr, 
            errors::not_owner()
        );
        // update admin info 
        set_admin(*smart_table::borrow(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, memo));
        // remove the entry
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, memo);
        // emit event
        emit_admin_updated_event(signer_addr, get_admin());
    }

    public entry fun claim_treasury_previliges(signer_ref: &signer, memo: u64) acquires AdminInfo, Pending {
        // assert signer is the one recieving the previliges
        let signer_addr = signer::address_of(signer_ref);
        assert!(
            smart_table::borrow<u64, address>(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, memo)
            == &signer_addr, 
            errors::not_owner()
        );
        // update treasury address
        set_treasury_address(*smart_table::borrow(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, memo));
        // remove the entry
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, memo);
        // emit event
        emit_treasury_address_updated_event(signer_addr, get_treasury_address());
    }

    public entry fun reject_admin_previliges(signer_ref: &signer, memo: u64) acquires Pending {
        // assert signer is the one recieving the previliges
        let signer_addr = signer::address_of(signer_ref);
        assert!(
            smart_table::borrow<u64, address>(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, memo)
            == &signer_addr, 
            errors::not_owner()
        );
        // remove the entry
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, memo);
        // emit event
        emit_ownership_transfer_rejected_event(memo);
    }

    public entry fun reject_treasury_previliges(signer_ref: &signer, memo: u64) acquires Pending {
        // assert signer is the one recieving the previliges
        let signer_addr = signer::address_of(signer_ref);
        assert!(
            smart_table::borrow<u64, address>(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, memo)
            == &signer_addr, 
            errors::not_owner()
        );
        // remove the entry
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, memo);
        // emit event
        emit_ownership_transfer_rejected_event(memo);
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
        assert!(signer::address_of(sender) == swap_info.admin, errors::not_admin());
        // assert new fee is not equal to the existing fee
        assert!(new_fee != swap_info.liquidity_fee_modifier, errors::already_initialized());
        // assert the newer total fee is less than the threshold
        assert!(does_not_exceed_dex_fee_threshold(new_fee + swap_info.treasury_fee_modifier), errors::excessive_fee());
        // update the fee
        swap_info.liquidity_fee_modifier = new_fee;
        // emit event
        emit_dex_liquidity_fee_updated_event(swap_info.liquidity_fee_modifier, new_fee);
    }

    // Set dex treasury fee
    public entry fun set_dex_treasury_fee(sender: &signer, new_fee: u128) acquires AdminInfo {
        let swap_info = borrow_global_mut<AdminInfo>(@baptswap_v2);
        // assert sender is admin
        assert!(signer::address_of(sender) == swap_info.admin, errors::already_initialized());
        // assert new fee is not equal to the existing fee
        assert!(new_fee != swap_info.treasury_fee_modifier, errors::already_initialized());
        // assert the newer total fee is less than the threshold
        assert!(does_not_exceed_dex_fee_threshold(new_fee + swap_info.liquidity_fee_modifier), errors::excessive_fee());
        // update the fee
        swap_info.treasury_fee_modifier = new_fee;
        // emit event
        emit_dex_treasury_fee_updated_event(swap_info.treasury_fee_modifier, new_fee);
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