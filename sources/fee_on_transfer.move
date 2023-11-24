/*

*/

module baptswap_v2::fee_on_transfer {

    use aptos_framework::account;
    use aptos_framework::aptos_coin::{AptosCoin as APT};
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;
    use aptos_framework::resource_account;

    // use aptos_std::debug;
    use aptos_std::type_info;

    use baptswap::math;
    use baptswap::swap_utils;
    use baptswap::u256;

    use bapt_framework::deployer;

    use baptswap_v2::admin;
    use baptswap_v2::constants;
    use baptswap_v2::errors;
    use baptswap_v2::utils;

    use std::signer;
    use std::option::{Self, Option};
    use std::string;

    friend baptswap_v2::router_v2;
    friend baptswap_v2::swap_v2;

    // -------
    // Structs
    // -------

    // used to store the token owner and the token fee; needed for Individual token fees
    struct FeeOnTransferInfo<phantom CoinType> has key, copy, drop, store {
        owner: address,
        liquidity_fee_modifier: u128,
        rewards_fee_modifier: u128,
        team_fee_modifier: u128,
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
        // assert that the fees do not exceed the thresholds
        let new_dex_fees = admin::get_dex_fees() + liquidity_fee;
        let fee_on_transfer = liquidity_fee + rewards_fee + team_fee;
        assert!(admin::does_not_exceed_dex_fee_threshold(new_dex_fees), 1);
        assert!(does_not_exceed_fee_on_transfer_threshold(fee_on_transfer) == true, 1);
        // move token info under the resource account
        let resource_signer = &admin::get_resource_signer();
        move_to(
            resource_signer, 
            FeeOnTransferInfo<CoinType> {
                owner: signer::address_of(sender),
                liquidity_fee_modifier: liquidity_fee,
                rewards_fee_modifier: rewards_fee,
                team_fee_modifier: team_fee
            }
        );
    }

    // --------------------
    // Initialize functions
    // --------------------
    
    // toggle all individual token fees in a token pair; given CoinType, and a Token Pair
    public entry fun toggle_all_fee<CoinType, X, Y>(
        sender: &signer,
        activate: bool,
    ) acquires FeeOnTransferInfo {
        // update new fees based on "activate" variable
        toggle_liquidity_fee<CoinType, X, Y>(sender, activate);
        toggle_team_fee<CoinType, X, Y>(sender, activate);
        toggle_rewards_fee<CoinType, X, Y>(sender, activate);

        // TODO: events
    }

    // Toggle liquidity fee
    public entry fun toggle_liquidity_fee<CoinType, X, Y>(
        sender: &signer,  
        activate: bool
    ) acquires FeeOnTransferInfo {
        // assert cointype is either X or Y
        assert!(type_info::type_of<CoinType>() == type_info::type_of<X>() || type_info::type_of<CoinType>() == type_info::type_of<Y>(), 1);
        // assert sender is token owner
        assert!(deployer::is_coin_owner<CoinType>(sender), errors::not_owner());
        // TODO: assert FeeOnTransferInfo<CoinType> is registered in the pair

        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        let fee_on_transfer = borrow_global<FeeOnTransferInfo<CoinType>>(signer::address_of(sender));

        if (activate) {
            metadata.liquidity_fee = metadata.liquidity_fee + fee_on_transfer.liquidity_fee_modifier;
        } else {
            metadata.liquidity_fee = metadata.liquidity_fee - fee_on_transfer.liquidity_fee_modifier;
        }

    }

    // toggle team fee
    public entry fun toggle_team_fee<CoinType, X, Y>(
        sender: &signer, 
        activate: bool,
    ) acquires FeeOnTransferInfo {
        // assert sender is token owner
        assert!(deployer::is_coin_owner<CoinType>(sender), errors::not_owner());
        // TODO: assert FeeOnTransferInfo<CoinType> is registered in the pair

        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        let fee_on_transfer = borrow_global<FeeOnTransferInfo<CoinType>>(signer::address_of(sender));
        // if cointype = x
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            // if activate = true
            if (activate == true) {
                metadata.team_fee = metadata.team_fee + fee_on_transfer.team_fee_modifier;
            // if activate = false
            } else {
                metadata.team_fee = metadata.team_fee - fee_on_transfer.team_fee_modifier;
            }
        // if cointype = y
        } else if (type_info::type_of<CoinType>() == type_info::type_of<Y>()) {
            // if activate = true
            if (activate == true) {
                metadata.team_fee = metadata.team_fee + fee_on_transfer.team_fee_modifier;
            // if activate = false
            } else {
                metadata.team_fee = metadata.team_fee - fee_on_transfer.team_fee_modifier;
            }
        } else { assert!(false, 1); }
    }

    // toggle rewards fee for a token in a token pair
    public entry fun toggle_rewards_fee<CoinType, X, Y>(
        sender: &signer,
        activate: bool,
    ) acquires FeeOnTransferInfo {
        // assert sender is token owner
        assert!(deployer::is_coin_owner<CoinType>(sender), errors::not_owner());
        // TODO: assert FeeOnTransferInfo<CoinType> is registered in the pair

        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        let fee_on_transfer = borrow_global<FeeOnTransferInfo<CoinType>>(signer::address_of(sender));
        // if cointype = x
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            // if activate = true
            if (activate == true) {
                metadata.rewards_fee = metadata.rewards_fee + fee_on_transfer.rewards_fee_modifier;
            // if activate = false
            } else {
                metadata.rewards_fee = metadata.rewards_fee - fee_on_transfer.rewards_fee_modifier;
            }
        // if cointype = y
        } else if (type_info::type_of<CoinType>() == type_info::type_of<Y>()) {
            // if activate = true
            if (activate == true) {
                metadata.rewards_fee = metadata.rewards_fee + fee_on_transfer.rewards_fee_modifier;
            // if activate = false
            } else {
                metadata.rewards_fee = metadata.rewards_fee - fee_on_transfer.rewards_fee_modifier;
            }
        } else { assert!(false, 1); }
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
        assert!(new_fee != fee_on_transfer_liquidity_fee, 1);
        // assert the newer total fee is less than the threshold
        assert!(
            does_not_exceed_fee_on_transfer_threshold(new_fee + fee_on_transfer.rewards_fee_modifier + fee_on_transfer.team_fee_modifier), 
            1
        );
        // update the fee
        fee_on_transfer.liquidity_fee_modifier = new_fee;
    }

    // update fee_on_transfer rewards fee
    public entry fun set_rewards_fee<CoinType>(sender: &signer, new_fee: u128) {
        let fee_on_transfer = borrow_global_mut<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address());
        let fee_on_transfer_rewards_fee = fee_on_transfer.rewards_fee_modifier;
        // assert sender is token owner of CoinType
        assert!(deployer::is_coin_owner<CoinType>(sender), errors::not_owner());
        // assert new fee is not equal to the existing fee
        assert!(new_fee != fee_on_transfer_rewards_fee, 1);
        // assert the newer total fee is less than the threshold
        assert!(
            does_not_exceed_fee_on_transfer_threshold(new_fee + fee_on_transfer.liquidity_fee_modifier + fee_on_transfer.team_fee_modifier), 
            1
        );
        // update the fee
        fee_on_transfer.rewards_fee_modifier = new_fee;
    }

    // update fee_on_transfer team fee
    public entry fun set_team_fee<CoinType>(sender: &signer, new_fee: u128) {
        let fee_on_transfer = borrow_global_mut<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address());
        let fee_on_transfer_team_fee = fee_on_transfer.team_fee_modifier;
        // assert sender is token owner of CoinType
        assert!(deployer::is_coin_owner<CoinType>(sender), errors::not_owner());
        // assert new fee is not equal to the existing fee
        assert!(new_fee != fee_on_transfer_team_fee, 1);
        // assert the newer total fee is less than the threshold
        assert!(
            does_not_exceed_fee_on_transfer_threshold(new_fee + fee_on_transfer.liquidity_fee_modifier + fee_on_transfer.rewards_fee_modifier), 
            1
        );
        // update the fee
        fee_on_transfer.team_fee_modifier = new_fee;
    }

    // ---------
    // Accessors
    // ---------

    // returns true if given rate is less than the individual token threshold
    public(friend) inline fun does_not_exceed_fee_on_transfer_threshold(total_fees_numerator: u128): bool {
        if (total_fees_numerator <= constants::get_fee_on_transfer_threshold_numerator()) true else false
    }

    // returns a FeeOnTransferInfo<CoinType>
    public(friend) inline fun get_fee_on_transfer_info<CoinType>(): FeeOnTransferInfo<CoinType> {
        let fee_on_transfer_token_info =  borrow_global<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address());
        
        FeeOnTransferInfo<CoinType> {
            owner: fee_on_transfer_token_info.owner,
            liquidity_fee_modifier: fee_on_transfer_token_info.liquidity_fee_modifier,
            rewards_fee_modifier: fee_on_transfer_token_info.rewards_fee_modifier,
            team_fee_modifier: fee_on_transfer_token_info.team_fee_modifier,
        }    
    }

    // --------------
    // View functions
    // --------------

    #[view]
    public fun get_liquidity_fee<CoinType>(): u128 {
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
    // Returns the total fee on transfer for a given token
    public fun get_total_fee_on_transfer<CoinType>(): u128 acquires FeeOnTransferInfo {
        let fee_on_transfer = borrow_global<FeeOnTransferInfo<CoinType>>(constants::get_resource_account_address());
        fee_on_transfer.liquidity_fee_modifier + fee_on_transfer.rewards_fee_modifier + fee_on_transfer.team_fee_modifier
    }
    
    #[view]
    // Checks if the fee on transfer is created
    public fun is_created<CoinType>(signer_ref: &signer): bool {
        exists<FeeOnTransferInfo<CoinType>>(signer::address_of(signer_ref))
    }
}