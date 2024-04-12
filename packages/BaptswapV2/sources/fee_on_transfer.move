/*

*/

module baptswap_v2::fee_on_transfer {

    use aptos_framework::event;

    // use aptos_std::debug;
    use aptos_std::type_info;

    use bapt_framework::deployer;

    use baptswap_v2::admin;
    use baptswap_v2::constants;
    use baptswap_v2::errors;

    use std::signer;
    use std::string::{String};

    friend baptswap_v2::router_v2;
    friend baptswap_v2::swap_v2;

    // -------
    // Structs
    // -------

    // used to store the token owner and the token fee; needed for Individual token fees
    struct FeeOnTransferInfo<phantom CoinType> has key, copy, drop, store {
        owner: address,
        token_name: String,
        liquidity_fee_modifier: u128,
        rewards_fee_modifier: u128,
        team_fee_modifier: u128,
    }

    // ------
    // Events
    // ------

    #[event]
    struct FeeOnTransferInfoInitializedEvent has drop, store {
        owner: address,
        token_name: String,
        liquidity_fee_modifier: u128,
        rewards_fee_modifier: u128,
        team_fee_modifier: u128,
    }

    #[event]
    struct LiquidityChangeEvent has drop, store { 
        old_liquidity_fee: u128,
        new_liquidity_fee: u128 
    }

    #[event]
    struct RewardsChangeEvent has drop, store { 
        old_rewards_fee: u128,
        new_rewards_fee: u128 
    }

    #[event]
    struct TeamChangeEvent has drop, store {
        old_team_fee: u128,
        new_team_fee: u128
    }

    fun emit_fee_on_transfer_info_initialized_event<CoinType>(
        owner: address,
        liquidity_fee_modifier: u128,
        rewards_fee_modifier: u128,
        team_fee_modifier: u128
    ) {
        let token_name = type_info::type_name<CoinType>();
        event::emit<FeeOnTransferInfoInitializedEvent>(
            FeeOnTransferInfoInitializedEvent {
                owner,
                token_name,
                liquidity_fee_modifier,
                rewards_fee_modifier,
                team_fee_modifier
            }
        )
    }

    fun emit_liquidity_fee_updated_event(old_liquidity_fee: u128, new_liquidity_fee: u128) {
        event::emit<LiquidityChangeEvent>(
            LiquidityChangeEvent { old_liquidity_fee, new_liquidity_fee }  
        )
    }

    fun emit_rewards_fee_updated_event(old_rewards_fee: u128, new_rewards_fee: u128) {
        event::emit<RewardsChangeEvent>(
            RewardsChangeEvent { old_rewards_fee, new_rewards_fee }  
        )
    }

    fun emit_team_fee_updated_event(old_team_fee: u128, new_team_fee: u128) {
        event::emit<TeamChangeEvent>(
            TeamChangeEvent { old_team_fee, new_team_fee }  
        )
    }

    // --------------------
    // initialize functions
    // --------------------
    
    // token owners will to specify the cointype and input the fees.
    public entry fun initialize_fee_on_transfer<CoinType>(
        sender: &signer,
        liquidity_fee: u128,
        rewards_fee: u128,
        team_fee: u128
    ) {
        // assert that the token info is not initialized yet
        assert!(!exists<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address()), errors::already_initialized());
        assert!(deployer::is_coin_owner<CoinType>(sender), errors::not_owner());
        // assert that the fees do not exceed the threshold
        let fee_on_transfer = liquidity_fee + rewards_fee + team_fee;
        assert!(does_not_exceed_fee_on_transfer_threshold(fee_on_transfer), errors::excessive_fee());
        // move token info under the resource account
        let resource_signer = &admin::get_resource_signer();
        move_to(
            resource_signer, 
            FeeOnTransferInfo<CoinType> {
                owner: signer::address_of(sender),
                token_name: type_info::type_name<CoinType>(),
                liquidity_fee_modifier: liquidity_fee,
                rewards_fee_modifier: rewards_fee,
                team_fee_modifier: team_fee
            }
        );
        // emit event
        emit_fee_on_transfer_info_initialized_event<CoinType>(
            signer::address_of(sender),
            liquidity_fee,
            rewards_fee,
            team_fee
        );
    }

    // ------------------
    // Internal functions
    // ------------------

    // --------
    // Mutators
    // --------

    // update fee_on_transfer liquidity fee
    public entry fun set_liquidity_fee<CoinType>(sender: &signer, new_fee: u128) acquires FeeOnTransferInfo {
        let fee_on_transfer = borrow_global_mut<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address());
        let fee_on_transfer_liquidity_fee = fee_on_transfer.liquidity_fee_modifier;
        // assert sender is token owner of CoinType
        assert!(deployer::is_coin_owner<CoinType>(sender), errors::not_owner());
        // assert new fee is not equal to the existing fee
        assert!(new_fee != fee_on_transfer_liquidity_fee, errors::already_initialized());
        // assert the newer total fee is less than the threshold
        assert!(
            does_not_exceed_fee_on_transfer_threshold(new_fee + fee_on_transfer.rewards_fee_modifier + fee_on_transfer.team_fee_modifier), 
            errors::excessive_fee()
        );
        // update the fee
        fee_on_transfer.liquidity_fee_modifier = new_fee;
        // emit event
        emit_liquidity_fee_updated_event(fee_on_transfer_liquidity_fee, new_fee);
    }

    // update fee_on_transfer rewards fee
    public entry fun set_rewards_fee<CoinType>(sender: &signer, new_fee: u128) acquires FeeOnTransferInfo {
        let fee_on_transfer = borrow_global_mut<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address());
        let fee_on_transfer_rewards_fee = fee_on_transfer.rewards_fee_modifier;
        // assert sender is token owner of CoinType
        assert!(deployer::is_coin_owner<CoinType>(sender), errors::not_owner());
        // assert new fee is not equal to the existing fee
        assert!(new_fee != fee_on_transfer_rewards_fee, errors::already_initialized());
        // assert the newer total fee is less than the threshold
        assert!(
            does_not_exceed_fee_on_transfer_threshold(new_fee + fee_on_transfer.liquidity_fee_modifier + fee_on_transfer.team_fee_modifier), 
            errors::excessive_fee()
        );
        // update the fee
        fee_on_transfer.rewards_fee_modifier = new_fee;
        // emit event
        emit_rewards_fee_updated_event(fee_on_transfer_rewards_fee, new_fee);
    }

    // update fee_on_transfer team fee
    public entry fun set_team_fee<CoinType>(sender: &signer, new_fee: u128) acquires FeeOnTransferInfo {
        let fee_on_transfer = borrow_global_mut<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address());
        let fee_on_transfer_team_fee = fee_on_transfer.team_fee_modifier;
        // assert sender is token owner of CoinType
        assert!(deployer::is_coin_owner<CoinType>(sender), errors::not_owner());
        // assert new fee is not equal to the existing fee
        assert!(new_fee != fee_on_transfer_team_fee, errors::already_initialized());
        // assert the newer total fee is less than the threshold
        assert!(
            does_not_exceed_fee_on_transfer_threshold(new_fee + fee_on_transfer.liquidity_fee_modifier + fee_on_transfer.rewards_fee_modifier), 
            errors::excessive_fee()
        );
        // update the fee
        fee_on_transfer.team_fee_modifier = new_fee;
        // emit event
        emit_team_fee_updated_event(fee_on_transfer_team_fee, new_fee);
    }

    // ---------
    // Accessors
    // ---------

    // returns true if given rate is less than the individual token threshold
    public(friend) inline fun does_not_exceed_fee_on_transfer_threshold(total_fees_numerator: u128): bool {
        if (total_fees_numerator <= constants::get_fee_on_transfer_threshold_numerator()) true else false
    }

    // --------------
    // View functions
    // --------------

    #[view]
    // Returns the token fee on transfer info
    public fun get_info<CoinType>(): FeeOnTransferInfo<CoinType> acquires FeeOnTransferInfo {
        let fee_on_transfer = borrow_global<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address());
        FeeOnTransferInfo<CoinType> {
            owner: fee_on_transfer.owner,
            token_name: fee_on_transfer.token_name,
            liquidity_fee_modifier: fee_on_transfer.liquidity_fee_modifier,
            rewards_fee_modifier: fee_on_transfer.rewards_fee_modifier,
            team_fee_modifier: fee_on_transfer.team_fee_modifier,
        }
    }

    #[view]
    public fun get_owner<CoinType>(): address acquires FeeOnTransferInfo {
        let fee_on_transfer = borrow_global<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address());
        fee_on_transfer.owner
    }

    #[view]
    public fun get_liquidity_fee<CoinType>(): u128  acquires FeeOnTransferInfo {
        let fee_on_transfer = borrow_global<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address());
        fee_on_transfer.liquidity_fee_modifier
    }

    #[view]
    public fun get_team_fee<CoinType>(): u128 acquires FeeOnTransferInfo {
        let fee_on_transfer = borrow_global<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address());
        fee_on_transfer.team_fee_modifier
    }

    #[view]
    public fun get_rewards_fee<CoinType>(): u128 acquires FeeOnTransferInfo {
        let fee_on_transfer = borrow_global<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address());
        fee_on_transfer.rewards_fee_modifier
    }

    #[view]
    // Returns the total fee on transfer fees for a given token
    public fun get_all_fee_on_transfer<CoinType>(): u128 acquires FeeOnTransferInfo {
        let fee_on_transfer = borrow_global<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address());
        fee_on_transfer.liquidity_fee_modifier + fee_on_transfer.rewards_fee_modifier + fee_on_transfer.team_fee_modifier
    }
    
    #[view]
    // Checks if the fee on transfer is created
    public fun is_created<CoinType>(): bool {
        exists<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address())
    }

    // ----
    // Test
    // ----

    #[test_only]
    public entry fun initialize_fee_on_transfer_for_test<CoinType>(
        sender: &signer,
        liquidity_fee: u128,
        rewards_fee: u128,
        team_fee: u128
    ) {
        // assert that the token info is not initialized yet
        assert!(!exists<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address()), errors::already_initialized());
        assert!(deployer::is_coin_owner<CoinType>(sender), errors::not_owner());
        // assert that the fees do not exceed the threshold
        let fee_on_transfer = liquidity_fee + rewards_fee + team_fee;
        assert!(does_not_exceed_fee_on_transfer_threshold(fee_on_transfer), errors::excessive_fee());
        // move token info under the resource account
        let resource_signer = &admin::get_resource_signer();
        move_to(
            resource_signer, 
            FeeOnTransferInfo<CoinType> {
                owner: signer::address_of(sender),
                token_name: type_info::type_name<CoinType>(),
                liquidity_fee_modifier: liquidity_fee,
                rewards_fee_modifier: rewards_fee,
                team_fee_modifier: team_fee
            }
        );
    }
}