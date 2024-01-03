/*
    Description: 
        This module implements the core logic of the BaptswapV2. 
        It allows users to create token pairs, add liquidity, remove liquidity, swap tokens, and stake tokens. 
        It also allows token owners to set individual token fees and withdraw team fee.
        There are two fee types:
        - DEX fees: liquidity fee + treasury fee
        - Individual token fees: liquidity fee + rewards fee + team fee

    Note from the original code devs: 
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        Please use swap_utils_v2::sort_token_type<X,Y>()
        before using any function
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    TODO: 
        
*/

module baptswap_v2::swap_v2 {

    use std::signer;
    use std::option::{Self, Option};
    use std::string;

    // use aptos_std::debug;
    use aptos_std::type_info;

    use aptos_framework::aptos_account;
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::event;
    use aptos_framework::timestamp;
    use aptos_framework::account;

    use baptswap::math;
    use baptswap::u256;

    use baptswap_v2::admin;
    use baptswap_v2::constants;
    use baptswap_v2::errors;
    use baptswap_v2::fee_on_transfer::{Self, FeeOnTransferInfo};
    use baptswap_v2::stake;
    use baptswap_v2::swap_utils_v2;
    use baptswap_v2::utils;

    use bapt_framework::deployer;

    friend baptswap_v2::router_v2;

    // -------
    // Structs
    // -------

    // The LP Token type
    struct LPToken<phantom X, phantom Y> has key {}

    // Stores the metadata required for the token pairs
    struct TokenPairMetadata<phantom X, phantom Y> has key {
        // The first provider of the token pair
        creator: address,
        // The Token owner of token X; if off, rewards/team = 0; if on, it changes
        fee_on_transfer_x: Option<FeeOnTransferInfo<X>>,
        // The Token owner of token Y; if off, rewards/team = 0; if on, it changes
        fee_on_transfer_y: Option<FeeOnTransferInfo<Y>>,
        // It's reserve_x * reserve_y, as of immediately after the most recent liquidity event
        k_last: u128,
        // The liquidity fee = dex_liquidity fee + liquidity fee X + liquidity fee Y
        liquidity_fee: u128,
        // The rewards fee = rewards fee X + rewards fee Y 
        rewards_fee: u128,
        // The team fee = team fee X + team fee Y
        team_fee: u128,       
        // The BaptSwap treasury fee
        treasury_fee: u128,
        // T0 token balance
        balance_x: Coin<X>,
        // T1 token balance
        balance_y: Coin<Y>,
        // Mint capacity of LP Token
        mint_cap: coin::MintCapability<LPToken<X, Y>>,
        // Burn capacity of LP Token
        burn_cap: coin::BurnCapability<LPToken<X, Y>>,
        // Freeze capacity of LP Token
        freeze_cap: coin::FreezeCapability<LPToken<X, Y>>,
    }
    // Stores the reservation info required for the token pairs
    struct TokenPairReserve<phantom X, phantom Y> has key {
        reserve_x: u64,
        reserve_y: u64,
        block_timestamp_last: u64
    }

    // ------
    // Events
    // ------

    #[event]
    struct PairCreatedEvent has drop, store {
        user: address,
        token_x: string::String,
        token_y: string::String
    }

    #[event]
    struct PairEventHolder<phantom X, phantom Y> has key {
        add_liquidity: event::EventHandle<AddLiquidityEvent<X, Y>>,
        remove_liquidity: event::EventHandle<RemoveLiquidityEvent<X, Y>>,
        swap: event::EventHandle<SwapEvent<X, Y>>
    }

    #[event]
    struct AddLiquidityEvent<phantom X, phantom Y> has drop, store {
        user: address,
        amount_x: u64,
        amount_y: u64,
        liquidity: u64
    }

    #[event]
    struct RemoveLiquidityEvent<phantom X, phantom Y> has drop, store {
        user: address,
        liquidity: u64,
        amount_x: u64,
        amount_y: u64
    }

    #[event]
    struct SwapEvent<phantom X, phantom Y> has drop, store {
        user: address,
        amount_x_in: u64,
        amount_y_in: u64,
        amount_x_out: u64,
        amount_y_out: u64
    }

    #[event]
    struct FeeOnTransferRegistered<phantom X, phantom Y> has drop, store {
        user: address,
        token_x: string::String,
        token_y: string::String
    }

    public(friend) fun add_swap_event<X, Y>(
        sender: &signer,
        amount_x_in: u64,
        amount_y_in: u64,
        amount_x_out: u64,
        amount_y_out: u64
    ) acquires PairEventHolder {
        let sender_addr = signer::address_of(sender);
        let pair_event_holder = borrow_global_mut<PairEventHolder<X, Y>>(constants::get_resource_account_address());
        event::emit_event<SwapEvent<X, Y>>(
            &mut pair_event_holder.swap,
            SwapEvent<X, Y> {
                user: sender_addr,
                amount_x_in,
                amount_y_in,
                amount_x_out,
                amount_y_out
            }
        );
    }

    public(friend) fun add_swap_event_with_address<X, Y>(
        sender_addr: address,
        amount_x_in: u64,
        amount_y_in: u64,
        amount_x_out: u64,
        amount_y_out: u64
    ) acquires PairEventHolder {
        let pair_event_holder = borrow_global_mut<PairEventHolder<X, Y>>(constants::get_resource_account_address());
        event::emit_event<SwapEvent<X, Y>>(
            &mut pair_event_holder.swap,
            SwapEvent<X, Y> {
                user: sender_addr,
                amount_x_in,
                amount_y_in,
                amount_x_out,
                amount_y_out
            }
        );
    }

    public fun emit_pair_created_event(user: address, token_x: string::String, token_y: string::String) { 
        event::emit<PairCreatedEvent>(PairCreatedEvent { user, token_x, token_y }); 
    }

    // ---------------
    // Entry functions
    // ---------------

    // toggle all individual token fees in a token pair; given CoinType, and a Token Pair
    public entry fun toggle_all_fees<CoinType, X, Y>(
        sender: &signer,
        activate: bool,
    ) acquires TokenPairMetadata {
        // update new fees based on "activate" variable
        toggle_liquidity_fee<CoinType, X, Y>(sender, activate);
        toggle_team_fee<CoinType, X, Y>(sender, activate);
        toggle_rewards_fee<CoinType, X, Y>(sender, activate);
    }

    // temporarily toggle all individual token fees in a token pair; used when updating fee tier
    inline fun temp_toggle_fee_on_transfer_fees<CoinType, X, Y>(activate: bool) acquires TokenPairMetadata {
        // assert cointype is either X or Y
        assert!(type_info::type_of<CoinType>() == type_info::type_of<X>() || type_info::type_of<CoinType>() == type_info::type_of<Y>(), errors::coin_type_does_not_match_x_or_y());
        // assert fee on transfer is registered
        assert!(is_fee_on_transfer_registered<CoinType, X, Y>(), errors::fee_on_transfer_not_registered());

        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());

        if (activate) {
            metadata.liquidity_fee = metadata.liquidity_fee + fee_on_transfer::get_liquidity_fee<CoinType>();
            metadata.team_fee = metadata.team_fee + fee_on_transfer::get_team_fee<CoinType>();
            metadata.rewards_fee = metadata.rewards_fee + fee_on_transfer::get_rewards_fee<CoinType>();
        } else {
            metadata.liquidity_fee = metadata.liquidity_fee - fee_on_transfer::get_liquidity_fee<CoinType>();
            metadata.team_fee = metadata.team_fee - fee_on_transfer::get_team_fee<CoinType>();
            metadata.rewards_fee = metadata.rewards_fee - fee_on_transfer::get_rewards_fee<CoinType>();
        }
    }

    // Toggle liquidity fee
    public entry fun toggle_liquidity_fee<CoinType, X, Y>(
        sender: &signer,  
        activate: bool
    ) acquires TokenPairMetadata {
        // assert cointype is either X or Y
        assert!(type_info::type_of<CoinType>() == type_info::type_of<X>() || type_info::type_of<CoinType>() == type_info::type_of<Y>(), errors::coin_type_does_not_match_x_or_y());
        // assert sender is token owner
        assert!(deployer::is_coin_owner<CoinType>(sender), errors::not_owner());
        // assert fee on transfer is registered
        assert!(is_fee_on_transfer_registered<CoinType, X, Y>(), errors::fee_on_transfer_not_registered());

        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());

        if (activate) {
            metadata.liquidity_fee = metadata.liquidity_fee + fee_on_transfer::get_liquidity_fee<CoinType>();
        } else {
            metadata.liquidity_fee = metadata.liquidity_fee - fee_on_transfer::get_liquidity_fee<CoinType>();
        }

    }

    // toggle team fee
    public entry fun toggle_team_fee<CoinType, X, Y>(
        sender: &signer, 
        activate: bool,
    ) acquires TokenPairMetadata {
        // assert sender is token owner
        assert!(deployer::is_coin_owner<CoinType>(sender), errors::not_owner());
        // assert fee on transfer is registered
        assert!(is_fee_on_transfer_registered<CoinType, X, Y>(), errors::fee_on_transfer_not_registered());
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        // if cointype = x
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            // if activate = true
            if (activate) {
                metadata.team_fee = metadata.team_fee + fee_on_transfer::get_team_fee<CoinType>();
            // if activate = false
            } else {
                metadata.team_fee = metadata.team_fee - fee_on_transfer::get_team_fee<CoinType>();
            }
        // if cointype = y
        } else if (type_info::type_of<CoinType>() == type_info::type_of<Y>()) {
            // if activate = true
            if (activate) {
                metadata.team_fee = metadata.team_fee + fee_on_transfer::get_team_fee<CoinType>();
            // if activate = false
            } else {
                metadata.team_fee = metadata.team_fee - fee_on_transfer::get_team_fee<CoinType>();
            }
        } else { assert!(false, errors::coin_type_does_not_match_x_or_y()); }
    }

    // toggle rewards fee for a token in a token pair
    public entry fun toggle_rewards_fee<CoinType, X, Y>(
        sender: &signer,
        activate: bool,
    ) acquires TokenPairMetadata {
        // assert CoinType is either X or Y
        assert!(
            type_info::type_of<CoinType>() == type_info::type_of<X>()
            || type_info::type_of<CoinType>() == type_info::type_of<Y>(),
            errors::coin_type_does_not_match_x_or_y()
        );
        // assert sender is token owner
        assert!(deployer::is_coin_owner<CoinType>(sender), errors::not_owner());
        // assert fee on transfer is registered
        assert!(is_fee_on_transfer_registered<CoinType, X, Y>(), errors::fee_on_transfer_not_registered());

        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        // if cointype = x
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            // if activate = true
            if (activate) {
                metadata.rewards_fee = metadata.rewards_fee + fee_on_transfer::get_rewards_fee<CoinType>();
            // if activate = false
            } else {
                metadata.rewards_fee = metadata.rewards_fee - fee_on_transfer::get_rewards_fee<CoinType>();
            }
        // if cointype = y
        } else if (type_info::type_of<CoinType>() == type_info::type_of<Y>()) {
            // if activate = true
            if (activate) {
                metadata.rewards_fee = metadata.rewards_fee + fee_on_transfer::get_rewards_fee<CoinType>();
            // if activate = false
            } else {
                metadata.rewards_fee = metadata.rewards_fee - fee_on_transfer::get_rewards_fee<CoinType>();
            }
        } else { assert!(false, errors::coin_type_does_not_match_x_or_y()); }
    }

    // ------------------
    // Internal Functions
    // ------------------

    // Add more liquidity to token types. This method explicitly assumes the
    // min of both tokens are 0.
    public(friend) fun add_liquidity<X, Y>(
        sender: &signer,
        amount_x: u64,
        amount_y: u64
    ): (u64, u64, u64) acquires TokenPairReserve, TokenPairMetadata, PairEventHolder {
        let (a_x, a_y, coin_lp, coin_left_x, coin_left_y) = add_liquidity_direct(coin::withdraw<X>(sender, amount_x), coin::withdraw<Y>(sender, amount_y));
        let sender_addr = signer::address_of(sender);
        let lp_amount = coin::value(&coin_lp);
        assert!(lp_amount > 0, errors::insufficient_liquidity());
        utils::check_or_register_coin_store<LPToken<X, Y>>(sender);
        coin::deposit(sender_addr, coin_lp);
        coin::deposit(sender_addr, coin_left_x);
        coin::deposit(sender_addr, coin_left_y);

        let pair_event_holder = borrow_global_mut<PairEventHolder<X, Y>>(constants::get_resource_account_address());
        event::emit_event<AddLiquidityEvent<X, Y>>(
            &mut pair_event_holder.add_liquidity,
            AddLiquidityEvent<X, Y> {
                user: sender_addr,
                amount_x: a_x,
                amount_y: a_y,
                liquidity: lp_amount,
            }
        );

        (a_x, a_y, lp_amount)
    }

    // Remove liquidity to token types.
    public(friend) fun remove_liquidity<X, Y>(
        sender: &signer,
        liquidity: u64,
    ): (u64, u64) acquires TokenPairMetadata, TokenPairReserve, PairEventHolder {
        let coins = coin::withdraw<LPToken<X, Y>>(sender, liquidity);
        let (coins_x, coins_y) = remove_liquidity_direct<X, Y>(coins);
        let amount_x = coin::value(&coins_x);
        let amount_y = coin::value(&coins_y);
        utils::check_or_register_coin_store<X>(sender);
        utils::check_or_register_coin_store<Y>(sender);
        let sender_addr = signer::address_of(sender);
        coin::deposit<X>(sender_addr, coins_x);
        coin::deposit<Y>(sender_addr, coins_y);

        // event
        let pair_event_holder = borrow_global_mut<PairEventHolder<X, Y>>(constants::get_resource_account_address());
        event::emit_event<RemoveLiquidityEvent<X, Y>>(
            &mut pair_event_holder.remove_liquidity,
            RemoveLiquidityEvent<X, Y> {
                user: sender_addr,
                amount_x,
                amount_y,
                liquidity,
            }
        );
        (amount_x, amount_y)
    }

    // Create the specified coin pair; all fees are toggled off
    public(friend) fun create_pair<X, Y>(
        sender: &signer,
    ) {
        assert!(!is_pair_created<X, Y>(), errors::already_initialized());

        let sender_addr = signer::address_of(sender);
        let resource_signer = admin::get_resource_signer();

        let lp_name: string::String = string::utf8(b"BaptswapV2-");
        let name_x = coin::symbol<X>();
        let name_y = coin::symbol<Y>();
        string::append(&mut lp_name, name_x);
        string::append_utf8(&mut lp_name, b"/");
        string::append(&mut lp_name, name_y);
        string::append_utf8(&mut lp_name, b"-LP");
        if (string::length(&lp_name) > errors::max_coin_name_length()) {
            lp_name = string::utf8(b"BaptSwap LPs");
        };

        // now we init the LP token
        let (burn_cap, freeze_cap, mint_cap) = coin::initialize<LPToken<X, Y>>(
            &resource_signer,
            lp_name,
            string::utf8(b"BAPT-LP"),
            8,
            true
        );

        move_to<TokenPairReserve<X, Y>>(
            &resource_signer,
            TokenPairReserve {
                reserve_x: 0,
                reserve_y: 0,
                block_timestamp_last: 0
            }
        );

        move_to<TokenPairMetadata<X, Y>>(
            &resource_signer,
            TokenPairMetadata {
                creator: sender_addr,
                k_last: 0,
                fee_on_transfer_x: option::none<FeeOnTransferInfo<X>>(),
                fee_on_transfer_y: option::none<FeeOnTransferInfo<Y>>(),
                liquidity_fee: 0,
                treasury_fee: 0,
                team_fee: 0,
                rewards_fee: 0,
                balance_x: coin::zero<X>(),
                balance_y: coin::zero<Y>(),
                burn_cap,
                freeze_cap,
                mint_cap
            }
        );

        move_to<PairEventHolder<X, Y>>(
            &resource_signer,
            PairEventHolder {
                add_liquidity: account::new_event_handle<AddLiquidityEvent<X, Y>>(&resource_signer),
                remove_liquidity: account::new_event_handle<RemoveLiquidityEvent<X, Y>>(&resource_signer),
                swap: account::new_event_handle<SwapEvent<X, Y>>(&resource_signer)
            }
        );

        // pair created event
        let token_x = type_info::type_name<X>();
        let token_y = type_info::type_name<Y>();

        emit_pair_created_event(sender_addr, token_x, token_y);

        // create LP CoinStore , which is needed as a lock for minimum_liquidity
        register_lp<X, Y>(&resource_signer);
    }

    // Register a pair; callable only by token owners; a one time operation in a pair
    public(friend) fun add_fee_on_transfer_in_pair<CoinType, X, Y>(
        sender: &signer
    ) acquires TokenPairMetadata {
        // assert sender is the token owner of CoinType
        assert!(deployer::is_coin_owner<CoinType>(sender), errors::not_owner());
        // assert CoinType is either X or Y
        assert!(
            type_info::type_of<CoinType>() == type_info::type_of<X>()
            || type_info::type_of<CoinType>() == type_info::type_of<Y>(),
            errors::coin_type_does_not_match_x_or_y()
        );
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        
        // if Cointype = X, add fee_on_transfer to pair_metadata.fee_on_transfer_x
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            let fee_on_transfer = fee_on_transfer::get_info<X>();
            option::fill<FeeOnTransferInfo<X>>(&mut metadata.fee_on_transfer_x, fee_on_transfer);
            toggle_all_fees<X, X, Y>(sender, true);
            // register Y; needed to receive team fees
            utils::check_or_register_coin_store<Y>(sender);
        // if Cointype = Y, add fee_on_transfer to pair_metadata.fee_on_transfer_y
        } else {
            let fee_on_transfer = fee_on_transfer::get_info<Y>();
            option::fill<FeeOnTransferInfo<Y>>(&mut metadata.fee_on_transfer_y, fee_on_transfer);
            toggle_all_fees<Y, X, Y>(sender, true);
            // register X; needed to receive team fees
            utils::check_or_register_coin_store<X>(sender);
        }
    }

    /// Swap X to Y, X is in and Y is out. This method assumes amount_out_min is 0
    public(friend) fun swap_exact_x_to_y<X, Y>(
        sender: &signer,
        amount_in: u64,
        to: address
    ): u64 acquires TokenPairReserve, TokenPairMetadata {
        let coins = coin::withdraw<X>(sender, amount_in);
        let (coins_x_out, coins_y_out) = swap_exact_x_to_y_direct<X, Y>(coins);
        let amount_out = coin::value(&coins_y_out);
        utils::check_or_register_coin_store<Y>(sender);
        coin::destroy_zero(coins_x_out); // or others ways to drop `coins_x_out`
        coin::deposit(to, coins_y_out);
        // distribute fees 
        distribute_dex_fees<Y, X, Y>(sender, amount_out);
        // based on whether Y fee_on_transfer is registered
        distribute_fee_on_transfer_fees<Y, X, Y>(sender, amount_out);
        amount_out
    }

    /// Swap X to Y, X is in and Y is out. This method assumes amount_out_min is 0
    fun swap_exact_x_to_y_direct<X, Y>(
        coins_in: coin::Coin<X>
    ): (coin::Coin<X>, coin::Coin<Y>) acquires TokenPairReserve, TokenPairMetadata {
        let amount_in = coin::value<X>(&coins_in);
        deposit_x<X, Y>(coins_in);
        let (rin, rout, _) = token_reserves<X, Y>();
        let amount_out = swap_utils_v2::get_amount_out(amount_in, rin, rout, liquidity_fee<X, Y>());
        let (coins_x_out, coins_y_out) = swap<X, Y>(0, amount_out);
        assert!(coin::value<X>(&coins_x_out) == 0, errors::insufficient_output_amount());
        (coins_x_out, coins_y_out)
    }

    public(friend) fun swap_x_to_exact_y<X, Y>(
        sender: &signer,
        amount_in: u64,
        amount_out: u64,
        to: address
    ): u64 acquires TokenPairReserve, TokenPairMetadata {
        let coins_in = coin::withdraw<X>(sender, amount_in);
        let (coins_x_out, coins_y_out) = swap_x_to_exact_y_direct<X, Y>(coins_in, amount_out);
        utils::check_or_register_coin_store<Y>(sender);
        coin::destroy_zero(coins_x_out); // or others ways to drop `coins_x_out`
        coin::deposit(to, coins_y_out);
        // distribute fees 
        distribute_dex_fees<Y, X, Y>(sender, amount_out);
        // based on whether Y fee_on_transfer is registered
        distribute_fee_on_transfer_fees<Y, X, Y>(sender, amount_out);
        amount_in
    }

    public(friend) fun swap_x_to_exact_y_direct<X, Y>(
        coins_in: coin::Coin<X>, amount_out: u64
    ): (coin::Coin<X>, coin::Coin<Y>) acquires TokenPairReserve, TokenPairMetadata {
        deposit_x<X, Y>(coins_in);
        let (coins_x_out, coins_y_out) = swap<X, Y>(0, amount_out);
        assert!(coin::value<X>(&coins_x_out) == 0, errors::insufficient_output_amount());
        (coins_x_out, coins_y_out)
    }

    /// Swap Y to X, Y is in and X is out. This method assumes amount_out_min is 0
    public(friend) fun swap_exact_y_to_x<X, Y>(
        sender: &signer,
        amount_in: u64,
        to: address
    ): u64 acquires TokenPairReserve, TokenPairMetadata {
        let coins = coin::withdraw<Y>(sender, amount_in);
        let (coins_x_out, coins_y_out) = swap_exact_y_to_x_direct<X, Y>(coins);
        let amount_out = coin::value<X>(&coins_x_out);
        utils::check_or_register_coin_store<X>(sender);
        coin::deposit(to, coins_x_out);
        // distribute fees 
        distribute_dex_fees<X, X, Y>(sender, amount_out);
        // based on whether X fee_on_transfer is registered
        distribute_fee_on_transfer_fees<X, X, Y>(sender, amount_out);
        coin::destroy_zero(coins_y_out); // or others ways to drop `coins_y_out`
        amount_out
    }

    public(friend) fun swap_y_to_exact_x<X, Y>(
        sender: &signer,
        amount_in: u64,
        amount_out: u64,
        to: address
    ): u64 acquires TokenPairReserve, TokenPairMetadata {
        let coins_in = coin::withdraw<Y>(sender, amount_in);
        let (coins_x_out, coins_y_out) = swap_y_to_exact_x_direct<X, Y>(coins_in, amount_out);
        utils::check_or_register_coin_store<X>(sender);
        coin::deposit(to, coins_x_out);
        coin::destroy_zero(coins_y_out); // or others ways to drop `coins_y_out`
        // distribute fees 
        distribute_dex_fees<X, X, Y>(sender, amount_out);
        // based on whether Y fee_on_transfer is registered
        distribute_fee_on_transfer_fees<X, X, Y>(sender, amount_out);
        amount_in
    }

    public(friend) fun swap_y_to_exact_x_direct<X, Y>(
        coins_in: coin::Coin<Y>, amount_out: u64
    ): (coin::Coin<X>, coin::Coin<Y>) acquires TokenPairReserve, TokenPairMetadata {
        deposit_y<X, Y>(coins_in);
        let (coins_x_out, coins_y_out) = swap<X, Y>(amount_out, 0);
        assert!(coin::value<Y>(&coins_y_out) == 0, errors::insufficient_output_amount());
        (coins_x_out, coins_y_out)
    }

    /// Swap Y to X, Y is in and X is out. This method assumes amount_out_min is 0
    fun swap_exact_y_to_x_direct<X, Y>(
        coins_in: coin::Coin<Y>
    ): (coin::Coin<X>, coin::Coin<Y>) acquires TokenPairReserve, TokenPairMetadata {
        let amount_in = coin::value<Y>(&coins_in);
        deposit_y<X, Y>(coins_in);
        let (rout, rin, _) = token_reserves<X, Y>();
        // calulate total liquidity fee
        let metadata = borrow_global<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        let liquidity_fee = metadata.liquidity_fee;
        let amount_out = swap_utils_v2::get_amount_out(amount_in, rin, rout, liquidity_fee);  
        let (coins_x_out, coins_y_out) = swap<X, Y>(amount_out, 0);
        assert!(coin::value<Y>(&coins_y_out) == 0, errors::insufficient_output_amount());
        (coins_x_out, coins_y_out)
    }

    // --------------
    // View Functions
    // --------------

    #[view]
    public fun is_pair_created<X, Y>(): bool {
        exists<TokenPairReserve<X, Y>>(constants::get_resource_account_address())
    }

    #[view]
    // Get the total supply of LP Tokens
    public fun total_lp_supply<X, Y>(): u128 {
        option::get_with_default(
            &coin::supply<LPToken<X, Y>>(),
            0u128
        )
    }

    #[view]
    // Get the current liquidity fee for a token pair
    public fun liquidity_fee<X, Y>(): u128 acquires TokenPairMetadata {
        let metadata = borrow_global<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        metadata.liquidity_fee
    }

    #[view]
    // Get the current fees for a token pair
    public fun token_fees<X, Y>(): (u128) acquires TokenPairMetadata {
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        (
            metadata.liquidity_fee + metadata.treasury_fee + metadata.team_fee + metadata.rewards_fee
        )
    }

    #[view]
    // Get the current reserves of T0 and T1 with the latest updated timestamp
    public fun token_reserves<X, Y>(): (u64, u64, u64) acquires TokenPairReserve {
        let reserve = borrow_global<TokenPairReserve<X, Y>>(constants::get_resource_account_address());
        (reserve.reserve_x, reserve.reserve_y, reserve.block_timestamp_last)
    }

    #[view]
    // The amount of balance currently in pools of the liquidity pair
    public fun token_balances<X, Y>(): (u64, u64) acquires TokenPairMetadata {
        let meta =
            borrow_global<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        (
            coin::value(&meta.balance_x),
            coin::value(&meta.balance_y)
        )
    }

    // Obtain the LP token balance of `addr`.
    // This method can only be used to check other users' balance.
    public fun lp_balance<X, Y>(addr: address): u64 {
        coin::balance<LPToken<X, Y>>(addr)
    }

    #[view]
    // return pair reserve if it's created
    public fun get_reserve<X, Y>(): TokenPairReserve<X, Y> acquires TokenPairReserve {
        // assert pair is created
        assert!(is_pair_created<X, Y>(), errors::pair_not_created());
        let reserve = borrow_global<TokenPairReserve<X, Y>>(constants::get_resource_account_address());
        TokenPairReserve<X, Y> {
            reserve_x: reserve.reserve_x,
            reserve_y: reserve.reserve_y,
            block_timestamp_last: reserve.block_timestamp_last
        }
    }

    #[view]
    // return true if fee_on_transfer is registered in a pair
    public fun is_fee_on_transfer_registered<CoinType, X, Y>(): bool acquires TokenPairMetadata {
        // assert CoinType is either X or Y
        assert!(
            type_info::type_of<CoinType>() == type_info::type_of<X>()
            || type_info::type_of<CoinType>() == type_info::type_of<Y>(),
            errors::coin_type_does_not_match_x_or_y()
        );
        if (swap_utils_v2::sort_token_type<X, Y>()) {
            // assert pair is created
            assert!(is_pair_created<X, Y>(), errors::pair_not_created());
            let metadata = borrow_global<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
            // if CoinType = X
            if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
                option::is_some(&metadata.fee_on_transfer_x)
            // if CoinType = Y
            } else {
                option::is_some(&metadata.fee_on_transfer_y)
            }
        } else {
            // assert pair is created
            assert!(is_pair_created<Y, X>(), errors::pair_not_created());
            let metadata = borrow_global<TokenPairMetadata<Y, X>>(constants::get_resource_account_address());
            // if CoinType = Y
            if (type_info::type_of<CoinType>() == type_info::type_of<Y>()) {
                option::is_some(&metadata.fee_on_transfer_x)
            // if CoinType = X
            } else {
                option::is_some(&metadata.fee_on_transfer_y)
            }
        }
    }

    #[view]
    // returns dex fees in a given pair; this is useful when pairs have different tiers
    public fun get_dex_fees_in_a_pair<X, Y>(): (u128, u128) acquires TokenPairMetadata {
        if (swap_utils_v2::sort_token_type<X, Y>()) {
            assert!(is_pair_created<X, Y>(), errors::pair_not_created());
            let metadata = borrow_global<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
            let dex_liquidity_fee = metadata.liquidity_fee;
            let dex_treasury_fee = metadata.treasury_fee;
            // if X has fee on transfer registered, deduct fee on transfer liquidity fee from dex liquidity fee
            if (is_fee_on_transfer_registered<X, X, Y>()) {
                let fee_on_transfer_liquidity_fee = fee_on_transfer::get_liquidity_fee<X>();
                dex_liquidity_fee = dex_liquidity_fee - fee_on_transfer_liquidity_fee;
            };
            // if Y has fee on transfer registered, deduct fee on transfer liquidity fee from dex liquidity fee
            if (is_fee_on_transfer_registered<Y, X, Y>()) {
                let fee_on_transfer_liquidity_fee = fee_on_transfer::get_liquidity_fee<Y>();
                dex_liquidity_fee = dex_liquidity_fee - fee_on_transfer_liquidity_fee;
            };

            (dex_liquidity_fee, dex_treasury_fee)
        } else {
            assert!(is_pair_created<Y, X>(), errors::pair_not_created());
            let metadata = borrow_global<TokenPairMetadata<Y, X>>(constants::get_resource_account_address());
            let dex_liquidity_fee = metadata.liquidity_fee;
            let dex_treasury_fee = metadata.treasury_fee;
            // if X has fee on transfer registered, deduct fee on transfer liquidity fee from dex liquidity fee
            if (is_fee_on_transfer_registered<X, Y, X>()) {
                let fee_on_transfer_liquidity_fee = fee_on_transfer::get_liquidity_fee<X>();
                dex_liquidity_fee = dex_treasury_fee - fee_on_transfer_liquidity_fee;
            };
            // if Y has fee on transfer registered, deduct fee on transfer liquidity fee from dex liquidity fee
            if (is_fee_on_transfer_registered<Y, Y, X>()) {
                let fee_on_transfer_liquidity_fee = fee_on_transfer::get_liquidity_fee<Y>();
                dex_liquidity_fee = dex_treasury_fee - fee_on_transfer_liquidity_fee;
            };

            (dex_liquidity_fee, dex_treasury_fee)
        }
    }

    // -----------------
    // Utility Functions
    // -----------------

    // calculate individual token fees amounts given token info; 
    // depends on whether it's x or y, the amount is either amount_in or amount_out
    inline fun calculate_fee_on_transfer_amounts<CoinType>(amount: u64): (u128, u128, u128) {
        // calculate fee amounts
        (
            utils::calculate_amount(fee_on_transfer::get_liquidity_fee<CoinType>(), amount),
            utils::calculate_amount(fee_on_transfer::get_rewards_fee<CoinType>(), amount),
            utils::calculate_amount(fee_on_transfer::get_team_fee<CoinType>(), amount)
        )
    }

    // calculate dex fees amounts given swap info
    inline fun calculate_dex_fees_amounts<CoinType>(amount_in: u64): (u128, u128) {
        // calculate fee amounts
        (
            utils::calculate_amount(admin::get_liquidity_fee_modifier(), amount_in),
            utils::calculate_amount(admin::get_treasury_fee_modifier(), amount_in)
        )
    }

    public fun register_lp<X, Y>(sender: &signer) {
        coin::register<LPToken<X, Y>>(sender);
    }

    // Add more liquidity to token types. This method explicitly assumes the
    // min of both tokens are 0.
    fun add_liquidity_direct<X, Y>(
        x: Coin<X>,
        y: Coin<Y>,
    ): (u64, u64, Coin<LPToken<X, Y>>, Coin<X>, Coin<Y>) acquires TokenPairReserve, TokenPairMetadata {
        let amount_x = coin::value(&x);
        let amount_y = coin::value(&y);
        let (reserve_x, reserve_y, _) = token_reserves<X, Y>();
        let (a_x, a_y) = if (reserve_x == 0 && reserve_y == 0) {
            (amount_x, amount_y)
        } else {
            let amount_y_optimal = swap_utils_v2::quote(amount_x, reserve_x, reserve_y);
            if (amount_y_optimal <= amount_y) {
                (amount_x, amount_y_optimal)
            } else {
                let amount_x_optimal = swap_utils_v2::quote(amount_y, reserve_y, reserve_x);
                assert!(amount_x_optimal <= amount_x, errors::invalid_amount());
                (amount_x_optimal, amount_y)
            }
        };

        assert!(a_x <= amount_x, errors::insufficient_amount());
        assert!(a_y <= amount_y, errors::insufficient_amount());

        let left_x = coin::extract(&mut x, amount_x - a_x);
        let left_y = coin::extract(&mut y, amount_y - a_y);
        deposit_x<X, Y>(x);
        deposit_y<X, Y>(y);
        let (lp) = mint<X, Y>();
        (a_x, a_y, lp, left_x, left_y)
    }

    // Remove liquidity to token types.
    fun remove_liquidity_direct<X, Y>(
        liquidity: Coin<LPToken<X, Y>>,
    ): (Coin<X>, Coin<Y>) acquires TokenPairMetadata, TokenPairReserve {
        burn<X, Y>(liquidity)
    }

    // used in swap functions to distribute DEX fees
    fun distribute_dex_fees<CoinType, X, Y>(signer_ref: &signer, amount: u64) {
        // based on cointype
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            // distribute DEX fees to dex owner;
            let (_, amount_to_treasury) = calculate_dex_fees_amounts<X>(amount);
            // let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
            // liquidity
            // let liquidity_fee_coins = coin::withdraw<X>(signer_ref, (amount_to_liquidity as u64));
            // coin::merge(&mut metadata.balance_x, liquidity_fee_coins);
            // treasury 
            let treasury_fee_coins = coin::withdraw<X>(signer_ref, (amount_to_treasury as u64));
            aptos_account::deposit_coins<X>(admin::get_treasury_address(), treasury_fee_coins);
        } else if (type_info::type_of<CoinType>() == type_info::type_of<Y>()) {
            // distribute DEX fees to dex owner;
            let (_, amount_to_treasury) = calculate_dex_fees_amounts<Y>(amount);
            // let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
            // liquidity
            // let liquidity_fee_coins = coin::withdraw<Y>(signer_ref, (amount_to_liquidity as u64));
            // coin::merge(&mut metadata.balance_y, liquidity_fee_coins);
            // treasury 
            let treasury_fee_coins = coin::withdraw<Y>(signer_ref, (amount_to_treasury as u64));
            aptos_account::deposit_coins<Y>(admin::get_treasury_address(), treasury_fee_coins);
        } else { assert!(false, errors::coin_type_does_not_match_x_or_y()); }
    }

    // used in swap functions to distribute fee_on_transfer fees
    // if x, fees are taken from amount_in. If y, fees are taken from amount_out
    fun distribute_fee_on_transfer_fees<CoinType, X, Y>(signer_ref: &signer, amount: u64) acquires TokenPairMetadata {
        /*
            if cointype is x: 
            - liquidity: liquidity amount fee will not be extracted from x
            - rewards:
                - amount of x (rate of x * amount to rewards x) goes to <X, Y>Rewards pool 
                - amount of x (rate of y * amount to rewards x) goes to <Y, X>Rewards pool
            - team: 
                - amount of x (rate of x * amount to team fee) goes to team fee x
                - amount of x (rate of y * amount to team fee) goes to team fee y
        */ 
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            // calculate the fees 
            let (_, x_rewards_amount_from_x_ratio, x_team_amount_from_x_ratio) = if (is_fee_on_transfer_registered<X, X, Y>()) {
                calculate_fee_on_transfer_amounts<X>(amount)
            } else { (0u128, 0u128, 0u128) };
            let (_, x_rewards_amount_from_y_ratio, x_team_amount_from_y_ratio) = if (is_fee_on_transfer_registered<Y, X, Y>()) {
                calculate_fee_on_transfer_amounts<Y>(amount)
            } else { (0u128, 0u128, 0u128) };

            // extract fees
            // let liquidity_x_fee_coins = coin::withdraw<X>(signer_ref, ((liquidity_amount_x + liquidity_amount_y) as u64));

            // distribute fees
            // liquidity
            // coin::merge(&mut metadata.balance_x, liquidity_x_fee_coins);
            // rewards
            if (stake::is_pool_created<X, Y>()) {
                let rewards_coins_to_xy_pool = coin::withdraw<X>(signer_ref, (x_rewards_amount_from_x_ratio as u64));
                stake::distribute_rewards<X, Y>(rewards_coins_to_xy_pool, coin::zero<Y>());
            };
            if (stake::is_pool_created<Y, X>()) {
                let rewards_coins_to_yx_pool = coin::withdraw<X>(signer_ref, (x_rewards_amount_from_y_ratio as u64));
                stake::distribute_rewards<Y, X>(coin::zero<Y>(), rewards_coins_to_yx_pool);
            };
            // team
            if (is_fee_on_transfer_registered<X, X, Y>()) {
                let x_team_x_coins = coin::withdraw<X>(signer_ref, (x_team_amount_from_x_ratio as u64));
                aptos_account::deposit_coins<X>(fee_on_transfer::get_owner<X>(), x_team_x_coins);
            };
            if (is_fee_on_transfer_registered<Y, X, Y>()) {
                let y_team_x_coins = coin::withdraw<X>(signer_ref, (x_team_amount_from_y_ratio as u64));
                aptos_account::deposit_coins<X>(fee_on_transfer::get_owner<Y>(), y_team_x_coins);
            };
        }
        /*
            if cointype is y and is registered: 
            - liquidity: liquidity amount fee will not be extracted from y
            - rewards:
                - amount of y (rate of x * amount to rewards y) goes to <X, Y>Rewards pool 
                - amount of y (rate of y * amount to rewards y) goes to <Y, X>Rewards pool
            - team: 
                - amount of y (rate of x * amount to team fee) goes to team fee x
                - amount of y (rate of y * amount to team fee) goes to team fee y
        */ 
        else if (type_info::type_of<CoinType>() == type_info::type_of<Y>()) {
            // calculate the fees
            let (_, y_rewards_amount_from_x_ratio, y_team_amount_from_x_ratio) = if (is_fee_on_transfer_registered<X, X, Y>()) {
                calculate_fee_on_transfer_amounts<X>(amount)
            } else { (0u128, 0u128, 0u128) };
            let (_, y_rewards_amount_from_y_ratio, y_team_amount_from_y_ratio) = if (is_fee_on_transfer_registered<Y, X, Y>()) {
                calculate_fee_on_transfer_amounts<Y>(amount)
            } else { (0u128, 0u128, 0u128) };

            // extract fees
            // let liquidity_y_fee_coins = coin::withdraw<Y>(signer_ref, ((liquidity_amount_x + liquidity_amount_y) as u64));

            // distribute fees
            // liquidity
            // coin::merge(&mut metadata.balance_y, liquidity_y_fee_coins);
            // rewards
            if (stake::is_pool_created<X, Y>()) {
                let rewards_coins_to_xy_pool = coin::withdraw<Y>(signer_ref, (y_rewards_amount_from_x_ratio as u64));
                stake::distribute_rewards<X, Y>(coin::zero<X>(), rewards_coins_to_xy_pool);
            };
            if (stake::is_pool_created<Y, X>()) {
                let rewards_coins_to_yx_pool = coin::withdraw<Y>(signer_ref, (y_rewards_amount_from_y_ratio as u64));
                stake::distribute_rewards<Y, X>(rewards_coins_to_yx_pool, coin::zero<X>());
            };
            // team
            if (is_fee_on_transfer_registered<X, X, Y>()) {
                let x_team_y_coins = coin::withdraw<Y>(signer_ref, (y_team_amount_from_x_ratio as u64));
                aptos_account::deposit_coins<Y>(fee_on_transfer::get_owner<X>(), x_team_y_coins);
            };
            if (is_fee_on_transfer_registered<Y, X, Y>()) {
                let y_team_y_coins = coin::withdraw<Y>(signer_ref, (y_team_amount_from_y_ratio as u64));
                aptos_account::deposit_coins<Y>(fee_on_transfer::get_owner<Y>(), y_team_y_coins);
            };
        }
    }

    // Update fee tier in a pair
    public(friend) fun update_fee_tier<Tier, X, Y>(signer_ref: &signer) acquires TokenPairMetadata {
        // assert signer is admin
        assert!(signer::address_of(signer_ref) == admin::get_admin(), errors::not_admin());
        // assert tier is valid
        assert!(admin::is_valid_tier<Tier>(), errors::invalid_tier());
        // update fees
        // toggle off fee on transfer fees
        if (is_fee_on_transfer_registered<X, X, Y>()) {
            temp_toggle_fee_on_transfer_fees<X, X, Y>(false);
        };
        if (is_fee_on_transfer_registered<Y, X, Y>()) {
            temp_toggle_fee_on_transfer_fees<Y, X, Y>(false);
        };
        // add new dex fees based on the tier
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        if (type_info::type_of<Tier>() == type_info::type_of<admin::Universal>()) {
            // get the fees
            let (liquidity_fee, treasury_fee) = admin::get_universal_tier_fees();
            // update pair fees 
            metadata.liquidity_fee = liquidity_fee;
            metadata.treasury_fee = treasury_fee;
        } else if (type_info::type_of<Tier>() == type_info::type_of<admin::PopularTraded>()) {
            // get the fees
            let (liquidity_fee, treasury_fee) = admin::get_popular_traded_tier_fees();
            // update pair fees 
            metadata.liquidity_fee = liquidity_fee;
            metadata.treasury_fee = treasury_fee;
        } else if (type_info::type_of<Tier>() == type_info::type_of<admin::Stable>()) {
            // get the fees
            let (liquidity_fee, treasury_fee) = admin::get_stable_tier_fees();
            // update pair fees 
            metadata.liquidity_fee = liquidity_fee;
            metadata.treasury_fee = treasury_fee;
        } else {
            // get the fees
            let (liquidity_fee, treasury_fee) = admin::get_very_stable_tier_fees();
            // update pair fees 
            metadata.liquidity_fee = liquidity_fee;
            metadata.treasury_fee = treasury_fee;
        };
        // Toggle on fee on transfer fees
        if (is_fee_on_transfer_registered<X, X, Y>()) {
            temp_toggle_fee_on_transfer_fees<X, X, Y>(true);
        };
        if (is_fee_on_transfer_registered<Y, X, Y>()) {
            temp_toggle_fee_on_transfer_fees<Y, X, Y>(true);
        };
    }

    // Swap
    fun swap<X, Y>(
        amount_x_out: u64,
        amount_y_out: u64
    ): (Coin<X>, Coin<Y>) acquires TokenPairReserve, TokenPairMetadata {
        assert!(amount_x_out > 0 || amount_y_out > 0, errors::insufficient_output_amount());

        let reserves = borrow_global_mut<TokenPairReserve<X, Y>>(constants::get_resource_account_address());
        assert!(amount_x_out < reserves.reserve_x && amount_y_out < reserves.reserve_y, errors::insufficient_liquidity());

        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());

        let liquidity_fee = metadata.liquidity_fee;

        let fee_denominator = liquidity_fee;

        let coins_x_out = coin::zero<X>();
        let coins_y_out = coin::zero<Y>();
        if (amount_x_out > 0) coin::merge(&mut coins_x_out, extract_x(amount_x_out, metadata));
        if (amount_y_out > 0) coin::merge(&mut coins_y_out, extract_y(amount_y_out, metadata));
        let (balance_x, balance_y) = token_balances<X, Y>();

        let amount_x_in = if (balance_x > reserves.reserve_x - amount_x_out) {
            balance_x - (reserves.reserve_x - amount_x_out)
        } else { 0 };
        let amount_y_in = if (balance_y > reserves.reserve_y - amount_y_out) {
            balance_y - (reserves.reserve_y - amount_y_out)
        } else { 0 };

        assert!(amount_x_in > 0 || amount_y_in > 0, errors::insufficient_input_amount());

        let prec = (constants::get_precision() as u128);
        let balance_x_adjusted = (balance_x as u128) * prec - (amount_x_in as u128) * fee_denominator;
        let balance_y_adjusted = (balance_y as u128) * prec - (amount_y_in as u128) * fee_denominator;
        let reserve_x_adjusted = (reserves.reserve_x as u128) * prec;
        let reserve_y_adjusted = (reserves.reserve_y as u128) * prec;

        // No need to use u256 when balance_x_adjusted * balance_y_adjusted and reserve_x_adjusted * reserve_y_adjusted are less than constants::get_max_u128().
        let compare_result = if(balance_x_adjusted > 0 && reserve_x_adjusted > 0 && constants::get_max_u128() / balance_x_adjusted > balance_y_adjusted && constants::get_max_u128() / reserve_x_adjusted > reserve_y_adjusted){
            balance_x_adjusted * balance_y_adjusted >= reserve_x_adjusted * reserve_y_adjusted
        }else{
            let p = u256::mul_u128(balance_x_adjusted, balance_y_adjusted);
            let k = u256::mul_u128(reserve_x_adjusted, reserve_y_adjusted);
            u256::ge(&p, &k)
        };
        assert!(compare_result, errors::k());

        update(balance_x, balance_y, reserves);

        (coins_x_out, coins_y_out)
    }

    // Mint LP Token.
    // This low-level function should be called from a contract which performs important safety checks
    fun mint<X, Y>(): (Coin<LPToken<X, Y>>) acquires TokenPairReserve, TokenPairMetadata {
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        let (balance_x, balance_y) = (coin::value(&metadata.balance_x), coin::value(&metadata.balance_y));
        let reserves = borrow_global_mut<TokenPairReserve<X, Y>>(constants::get_resource_account_address());
        let amount_x = (balance_x as u128) - (reserves.reserve_x as u128);
        let amount_y = (balance_y as u128) - (reserves.reserve_y as u128);

        //let fee_amount = mint_fee<X, Y>(reserves.reserve_x, reserves.reserve_y, metadata);

        //Need to add fee amount which have not been mint.
        let total_supply = total_lp_supply<X, Y>();
        let liquidity = if (total_supply == 0u128) {
            let sqrt = math::sqrt(amount_x * amount_y);
            assert!(sqrt > constants::get_minimum_liquidity(), errors::insufficient_liquidity_minted());
            let l = sqrt - constants::get_minimum_liquidity();
            // permanently lock the first minimum liquidity tokens
            mint_lp_to<X, Y>(constants::get_resource_account_address(), (constants::get_minimum_liquidity() as u64), &metadata.mint_cap);
            l
        } else {
            let liquidity = math::min(amount_x * total_supply / (reserves.reserve_x as u128), amount_y * total_supply / (reserves.reserve_y as u128));
            assert!(liquidity > 0u128, errors::insufficient_liquidity_minted());
            liquidity
        };

        let lp = mint_lp<X, Y>((liquidity as u64), &metadata.mint_cap);
        update<X, Y>(balance_x, balance_y, reserves);
        metadata.k_last = (reserves.reserve_x as u128) * (reserves.reserve_y as u128);

        (lp)
    }

    fun burn<X, Y>(lp_tokens: Coin<LPToken<X, Y>>): (Coin<X>, Coin<Y>) acquires TokenPairMetadata, TokenPairReserve {
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        let (balance_x, balance_y) = (coin::value(&metadata.balance_x), coin::value(&metadata.balance_y));
        let reserves = borrow_global_mut<TokenPairReserve<X, Y>>(constants::get_resource_account_address());
        let liquidity = coin::value(&lp_tokens);

        //let fee_amount = mint_fee<X, Y>(reserves.reserve_x, reserves.reserve_y, metadata);

        //Need to add fee amount which have not been mint.
        let total_lp_supply = total_lp_supply<X, Y>();
        let amount_x = ((balance_x as u128) * (liquidity as u128) / (total_lp_supply as u128) as u64);
        let amount_y = ((balance_y as u128) * (liquidity as u128) / (total_lp_supply as u128) as u64);
        assert!(amount_x > 0 && amount_y > 0, errors::insufficient_liquidity_burned());

        coin::burn<LPToken<X, Y>>(lp_tokens, &metadata.burn_cap);

        let w_x = extract_x((amount_x as u64), metadata);
        let w_y = extract_y((amount_y as u64), metadata);

        update(coin::value(&metadata.balance_x), coin::value(&metadata.balance_y), reserves);

        metadata.k_last = (reserves.reserve_x as u128) * (reserves.reserve_y as u128);

        (w_x, w_y)
    }

    fun update<X, Y>(balance_x: u64, balance_y: u64, reserve: &mut TokenPairReserve<X, Y>) {
        let block_timestamp = timestamp::now_seconds();

        reserve.reserve_x = balance_x;
        reserve.reserve_y = balance_y;
        reserve.block_timestamp_last = block_timestamp;
    }

    // Mint LP Tokens to account
    fun mint_lp_to<X, Y>(
        to: address,
        amount: u64,
        mint_cap: &coin::MintCapability<LPToken<X, Y>>
    ) {
        let coins = coin::mint<LPToken<X, Y>>(amount, mint_cap);
        coin::deposit(to, coins);
    }

    // Mint LP Tokens to account
    fun mint_lp<X, Y>(amount: u64, mint_cap: &coin::MintCapability<LPToken<X, Y>>): Coin<LPToken<X, Y>> {
        coin::mint<LPToken<X, Y>>(amount, mint_cap)
    }

    fun deposit_x<X, Y>(amount: Coin<X>) acquires TokenPairMetadata {
        let metadata =
            borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        
        coin::merge(&mut metadata.balance_x, amount);
    }

    fun deposit_y<X, Y>(amount: Coin<Y>) acquires TokenPairMetadata {
        let metadata =
            borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());

        coin::merge(&mut metadata.balance_y, amount);
    }

    // Extract `amount` from this contract
    fun extract_x<X, Y>(amount: u64, metadata: &mut TokenPairMetadata<X, Y>): Coin<X> {
        assert!(coin::value<X>(&metadata.balance_x) > amount, errors::insufficient_amount());
        coin::extract(&mut metadata.balance_x, amount)
    }

    // Extract `amount` from this contract
    fun extract_y<X, Y>(amount: u64, metadata: &mut TokenPairMetadata<X, Y>): Coin<Y> {
        assert!(coin::value<Y>(&metadata.balance_y) > amount, errors::insufficient_amount());
        coin::extract(&mut metadata.balance_y, amount)
    }
}