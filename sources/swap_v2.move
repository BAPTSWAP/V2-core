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
        Please use swap_utils::sort_token_type<X,Y>()
        before using any function
    !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    TODO: 
        - function to check if the CoinType is registered in a pair <X, Y>
        - function to return token info of a given coinType
        - make token_fees returns a tuple
*/

module baptswap_v2::swap_v2 {

    use std::signer;
    use std::option::{Self, Option};
    use std::string;

    // use aptos_std::debug;
    use aptos_std::type_info;

    use aptos_framework::aptos_coin::{AptosCoin as APT};
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::event;
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::resource_account;

    use baptswap::math;
    use baptswap::swap_utils;
    use baptswap::u256;

    use baptswap_v2::admin;
    use baptswap_v2::constants;
    use baptswap_v2::errors;
    use baptswap_v2::fee_on_transfer::{Self, FeeOnTransferInfo};
    use baptswap_v2::stake;
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
        // T0 team balance
        team_balance_x: Coin<X>,    // this should go to team y
        // T1 team balance
        team_balance_y: Coin<Y>,    // this should go to team x
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

    struct SwapInfo has key {
        pair_created: event::EventHandle<PairCreatedEvent>
    }

    struct PairCreatedEvent has drop, store {
        user: address,
        token_x: string::String,
        token_y: string::String
    }

    struct PairEventHolder<phantom X, phantom Y> has key {
        add_liquidity: event::EventHandle<AddLiquidityEvent<X, Y>>,
        remove_liquidity: event::EventHandle<RemoveLiquidityEvent<X, Y>>,
        swap: event::EventHandle<SwapEvent<X, Y>>,
        change_fee: event::EventHandle<FeeChangeEvent<X, Y>>
    }

    struct AddLiquidityEvent<phantom X, phantom Y> has drop, store {
        user: address,
        amount_x: u64,
        amount_y: u64,
        liquidity: u64,

    }

    struct RemoveLiquidityEvent<phantom X, phantom Y> has drop, store {
        user: address,
        liquidity: u64,
        amount_x: u64,
        amount_y: u64,

    }

    struct SwapEvent<phantom X, phantom Y> has drop, store {
        user: address,
        amount_x_in: u64,
        amount_y_in: u64,
        amount_x_out: u64,
        amount_y_out: u64
    }

    // TODO: related to fee_on_transfer?
    struct FeeChangeEvent<phantom X, phantom Y> has drop, store {
        user: address,
        liquidity_fee: u128,
        team_fee: u128,
        rewards_fee: u128
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

    // --------------------
    // Initialize Functions
    // --------------------

    fun init_module(sender: &signer) {
        let signer_cap = resource_account::retrieve_resource_account_cap(sender, @dev_2);
        let resource_signer = account::create_signer_with_capability(&signer_cap);
        move_to(&resource_signer, SwapInfo { pair_created: account::new_event_handle<PairCreatedEvent>(&resource_signer) });
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
    ) acquires SwapInfo {
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
                team_balance_x: coin::zero<X>(),
                team_balance_y: coin::zero<Y>(),
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
                swap: account::new_event_handle<SwapEvent<X, Y>>(&resource_signer),
                change_fee: account::new_event_handle<FeeChangeEvent<X,Y>>(&resource_signer)
            }
        );

        // pair created event
        let token_x = type_info::type_name<X>();
        let token_y = type_info::type_name<Y>();

        let swap_info = borrow_global_mut<SwapInfo>(constants::get_resource_account_address());
        event::emit_event<PairCreatedEvent>(
            &mut swap_info.pair_created,
            PairCreatedEvent {
                user: sender_addr,
                token_x,
                token_y
            }
        );

        // create LP CoinStore , which is needed as a lock for minimum_liquidity
        register_lp<X, Y>(&resource_signer);
    }

    // Register a pair; callable only by token owners
    public(friend) fun add_fee_on_transfer_in_pair<CoinType, X, Y>(
        sender: &signer
    ) acquires TokenPairMetadata {
        let sender_addr = signer::address_of(sender);
        // assert sender is the token owner of CoinType
        assert!(deployer::is_coin_owner<CoinType>(sender), errors::not_owner());
        
        // assert CoinType is either X or Y
        assert!(
            type_info::type_of<CoinType>() == type_info::type_of<X>()
            || type_info::type_of<CoinType>() == type_info::type_of<Y>(),
            1
        );
        // TODO: assert the token owner didn't register that pair already
        // assert!(!is_token_registered_in_pair<CoinType, X, Y>(sender, pair), 1);
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        
        // if Cointype = X, add fee_on_transfer to pair_metadata.fee_on_transfer_x
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            let fee_on_transfer = fee_on_transfer::get_fee_on_transfer_info<X>();
            option::fill<FeeOnTransferInfo<X>>(&mut metadata.fee_on_transfer_x, fee_on_transfer);
            fee_on_transfer::toggle_all_fee<CoinType, X, Y>(sender, true);
            // register Y; needed to receive team fees
            utils::check_or_register_coin_store<Y>(sender);
        // if Cointype = Y, add fee_on_transfer to pair_metadata.fee_on_transfer_y
        } else {
            let fee_on_transfer = fee_on_transfer::get_fee_on_transfer_info<Y>();
            option::fill<FeeOnTransferInfo<Y>>(&mut metadata.fee_on_transfer_y, fee_on_transfer);
            fee_on_transfer::toggle_all_fee<CoinType, X, Y>(sender, true);
            // register X; needed to receive team fees
            utils::check_or_register_coin_store<X>(sender);
        }
    }

    // Swap X to Y, X is in and Y is out. This method assumes amount_out_min is 0
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
        amount_out
    }

    // Swap X to Y, X is in and Y is out. This method assumes amount_out_min is 0
    public(friend) fun swap_exact_x_to_y_direct<X, Y>(
        coins_in: Coin<X>
    ): (Coin<X>, Coin<Y>) acquires TokenPairReserve, TokenPairMetadata {
        // Grab token pair metadata
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address()); 
        // get the value of coins in u64
        let amount_in = coin::value<X>(&coins_in);

        // deposit amount_in x into balance x
        coin::merge(&mut metadata.balance_x, coins_in);

        // get amount_out y given amount_in x, reserves of x and y, and total_fees from x
        let (rin, rout, _) = token_reserves<X, Y>();
        let total_fees = token_fees<X, Y>();

        // Get amount after deducting fees and swap it to y
        let amount_out = swap_utils::get_amount_out(amount_in, rin, rout, total_fees);
        let (coins_x_out, coins_y_out) = swap<X, Y>(0, amount_out);

        // distribute DEX fees and update reserves
        distribute_dex_fees<X, Y>(amount_in);
        // distrubute fees and update reserves
        distribute_fee_on_transfer<X, Y>(amount_in);

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
        amount_in
    }

    public(friend) fun swap_x_to_exact_y_direct<X, Y>(
        coins_in: Coin<X>,
        amount_out: u64
    ): (Coin<X>, Coin<Y>) acquires TokenPairReserve, TokenPairMetadata {
        // Grab token pair metadata
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address()); 
        // get the value of coins in in u64
        let amount_in = coin::value<X>(&coins_in);

        // deposit amount_in x into balance x
        coin::merge(&mut metadata.balance_x, coins_in);

        // get amount_out y given amount_in x, reserves of x and y, and total_fees from x
        let (rin, rout, _) = token_reserves<X, Y>();
        let total_fees = token_fees<X, Y>();

        // Get amount after deducting fees and swap it to y
        let amount_out = swap_utils::get_amount_out(amount_in, rin, rout, total_fees);
        let (coins_x_out, coins_y_out) = swap<X, Y>(0, amount_out);

        // distribute DEX fees and update reserves
        distribute_dex_fees<X, Y>(amount_in);
        // distrubute fees and update reserves
        distribute_fee_on_transfer<X, Y>(amount_in);

        assert!(coin::value<X>(&coins_x_out) == amount_out, errors::insufficient_output_amount());
        (coins_x_out, coins_y_out)
    }

    // Swap Y to X, Y is in and X is out. This method assumes amount_out_min is 0
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
        amount_in
    }

    public(friend) fun swap_y_to_exact_x_direct<X, Y>(
        coins_in: Coin<Y>,
        amount_out: u64
    ): (Coin<X>, Coin<Y>) acquires TokenPairReserve, TokenPairMetadata {
        // Grab token pair metadata
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address()); 
        // get the value of coins in in u64
        let amount_in = coin::value<Y>(&coins_in);

        // deposit amount_in y into balance y
        coin::merge(&mut metadata.balance_y, coins_in);

        // get amount_out x given amount_in y, reserves of x and y, and total_fees from y
        let (rin, rout, _) = token_reserves<X, Y>();
        let total_fees = token_fees<X, Y>();

        // Get amount after deducting fees and swap it to x
        let amount_out = swap_utils::get_amount_out(amount_in, rin, rout, total_fees);
        let (coins_x_out, coins_y_out) = swap<X, Y>(amount_out, 0);

        // distribute DEX fees and update reserves
        distribute_dex_fees<X, Y>(amount_in);
        // distrubute fees and update reserves
        distribute_fee_on_transfer<X, Y>(amount_in);

        assert!(coin::value<Y>(&coins_y_out) == amount_out, errors::insufficient_output_amount());
        (coins_x_out, coins_y_out)
    }

    // Swap Y to X, Y is in and X is out. This method assumes amount_out_min is 0
    public(friend) fun swap_exact_y_to_x_direct<X, Y>(
        coins_in: Coin<Y>
    ): (Coin<X>, Coin<Y>) acquires TokenPairReserve, TokenPairMetadata {
        // Grab token pair metadata
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address()); 
        // get the value of coins in in u64
        let amount_in = coin::value<Y>(&coins_in);

        // deposit amount_in y into balance y
        coin::merge(&mut metadata.balance_y, coins_in);

        // get amount_out x given amount_in y, reserves of x and y, and total_fees from y
        let (rin, rout, _) = token_reserves<X, Y>();
        let total_fees = token_fees<X, Y>();

        // Get amount after deducting fees and swap it to x
        let amount_out = swap_utils::get_amount_out(amount_in, rin, rout, total_fees);
        let (coins_x_out, coins_y_out) = swap<X, Y>(amount_out, 0);

        // distribute DEX fees and update reserves
        distribute_dex_fees<X, Y>(amount_in);
        // distrubute fees and update reserves
        distribute_fee_on_transfer<X, Y>(amount_in);

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
        (
            reserve.reserve_x,
            reserve.reserve_y,
            reserve.block_timestamp_last
        )
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

    // ---------
    // Accessors
    // ---------

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

    // -----------------
    // Utility Functions
    // -----------------

    // calculate individual token fees amounts given token info
    inline fun calculate_fee_on_transfer_amounts<CoinType>(amount_in: u64): (u128, u128, u128) {
        let token_liquidity_fee_numerator = fee_on_transfer::get_liquidity_fee<CoinType>();
        let token_rewards_fee_numerator = fee_on_transfer::get_rewards_fee<CoinType>();
        let token_team_fee_numerator = fee_on_transfer::get_team_fee<CoinType>();
        // calculate fee amounts
        (
            utils::calculate_amount(token_liquidity_fee_numerator, amount_in),
            utils::calculate_amount(token_rewards_fee_numerator, amount_in),
            utils::calculate_amount(token_team_fee_numerator, amount_in),
        )
    }

    // calculate dex fees amounts given swap info
    inline fun calculate_dex_fees_amounts<CoinType>(amount_in: u64): (u128, u128) {
        // calculate fee amounts
        (
            utils::calculate_amount(admin::get_treasury_fee_modifier(), amount_in),
            utils::calculate_amount(admin::get_liquidity_fee_modifier(), amount_in)
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
            let amount_y_optimal = swap_utils::quote(amount_x, reserve_x, reserve_y);
            if (amount_y_optimal <= amount_y) {
                (amount_x, amount_y_optimal)
            } else {
                let amount_x_optimal = swap_utils::quote(amount_y, reserve_y, reserve_x);
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

    // used in swap functions to distribute DEX fees and update reserves correspondingly
    fun distribute_dex_fees<X, Y>(amount_in: u64) acquires TokenPairReserve, TokenPairMetadata {
        // distribute DEX fees to dex owner;
        let (amount_to_liquidity, amount_to_treasury) = calculate_dex_fees_amounts<Y>(amount_in);
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        // liquidity
        let liquidity_fee_coins = coin::extract<Y>(&mut metadata.balance_y, (amount_to_liquidity as u64));
        coin::merge(&mut metadata.balance_y, liquidity_fee_coins);
        // treasury 
        let treasury_fee_coins = coin::extract<Y>(&mut metadata.balance_y, (amount_to_treasury as u64));
        coin::deposit<Y>(admin::get_treasury_address(), treasury_fee_coins);
        // update reserves
        update_reserves<X, Y>();
    }

    fun update_reserves<X, Y>() acquires TokenPairReserve, TokenPairMetadata {
        let reserves = borrow_global_mut<TokenPairReserve<X, Y>>(constants::get_resource_account_address());
        let (balance_x, balance_y) = token_balances<X, Y>();
        update(balance_x, balance_y, reserves);
    }

    // used in swap functions to distribute fees and update reserves correspondingly
    // TODO: when extracting fees, we need to check if the token if fee is not zero (follow the same logic as in rewards_fees)
    // TODO: code duplication spotted, can be improved
    fun distribute_fee_on_transfer<X, Y>(
        amount_in: u64
    ) acquires TokenPairReserve, TokenPairMetadata {
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());
        let fee_on_transfer_x = metadata.fee_on_transfer_x;
        let fee_on_transfer_y = metadata.fee_on_transfer_y;
        // if token info x is registered & token info y is not, calculate only token info x fees
        if (!option::is_none<FeeOnTransferInfo<X>>(&fee_on_transfer_x) && option::is_none<FeeOnTransferInfo<Y>>(&fee_on_transfer_y)) {
            // calculate the fees 
            let (amount_to_liquidity, amount_to_rewards, amount_to_team) = calculate_fee_on_transfer_amounts<X>(amount_in);
            // extract fees
            let liquidity_coins = coin::extract<X>(&mut metadata.balance_x, (amount_to_liquidity as u64));
            // let rewards_coins = coin::extract<X>(&mut metadata.balance_x, (amount_to_rewards as u64));
            let team_coins = coin::extract<X>(&mut metadata.balance_x, (amount_to_team as u64));
            
            // distribute fees
            coin::merge(&mut metadata.balance_x, liquidity_coins);
            // rewards fees must go to rewards pool
            if (metadata.rewards_fee > 0) {
                // TODO: distribute_rewards should get Coin<X> and Coin<Y> instead of u128
                stake::distribute_rewards<X, Y>(amount_to_rewards, 0);
            };
            coin::merge(&mut metadata.team_balance_x, team_coins);
            // update reserves
            update_reserves<X, Y>();
        }
        // if token info y is registered & token info x not, calculate only token info y fees
        else if (option::is_none<FeeOnTransferInfo<X>>(&fee_on_transfer_x) && !option::is_none<FeeOnTransferInfo<Y>>(&fee_on_transfer_y)) {
            // calculate the fees 
            let (amount_to_liquidity, amount_to_rewards, amount_to_team) = calculate_fee_on_transfer_amounts<Y>(amount_in);
            
            // extract fees
            let liquidity_coins = coin::extract<Y>(&mut metadata.balance_y, (amount_to_liquidity as u64));
            // let rewards_coins = coin::extract<Y>(&mut metadata.balance_y, (amount_to_rewards as u64));
            let team_coins = coin::extract<Y>(&mut metadata.balance_y, (amount_to_team as u64));
            
            // distribute fees
            coin::merge(&mut metadata.balance_y, liquidity_coins);
            // rewards fees must go to rewards pool
            if (metadata.rewards_fee > 0) {
                stake::distribute_rewards<X, Y>(0, amount_to_rewards);
            };
            coin::merge(&mut metadata.team_balance_y, team_coins);
            // update reserves
            update_reserves<X, Y>();
        }
        // if token info x and token info y are both registered
        else if (!option::is_none<FeeOnTransferInfo<X>>(&fee_on_transfer_x) && !option::is_none<FeeOnTransferInfo<Y>>(&fee_on_transfer_y)) {
            // calculate the fees
            let (amount_to_liquidity_x, amount_to_rewards_x, amount_to_team_x) = calculate_fee_on_transfer_amounts<X>(amount_in);
            let (amount_to_liquidity_y, amount_to_rewards_y, amount_to_team_y) = calculate_fee_on_transfer_amounts<Y>(amount_in);

            // extract fees
            let liquidity_coins_x = coin::extract<X>(&mut metadata.balance_x, (amount_to_liquidity_x as u64));
            let team_coins_x = coin::extract<X>(&mut metadata.balance_x, (amount_to_team_x as u64));
            let liquidity_coins_y = coin::extract<Y>(&mut metadata.balance_y, (amount_to_liquidity_y as u64));
            let team_coins_y = coin::extract<Y>(&mut metadata.balance_y, (amount_to_team_y as u64));

            // distribute fees
            coin::merge(&mut metadata.balance_x, liquidity_coins_x);
            coin::merge(&mut metadata.balance_y, liquidity_coins_y);
            // rewards fees must go to rewards pool
            if (metadata.rewards_fee > 0) {
                stake::distribute_rewards<X, Y>(amount_to_rewards_x, amount_to_rewards_y);
            };
            coin::merge(&mut metadata.team_balance_x, team_coins_x);
            coin::merge(&mut metadata.team_balance_y, team_coins_y);
            // update reserves
            update_reserves<X, Y>();
        } 
    }

    // Swap
    fun swap<X, Y>(
        amount_x_out: u64,
        amount_y_out: u64
    ): (Coin<X>, Coin<Y>) acquires TokenPairReserve, TokenPairMetadata {
        assert!(amount_x_out > 0 || amount_y_out > 0, errors::insufficient_output_amount());

        let reserves = borrow_global_mut<TokenPairReserve<X, Y>>(constants::get_resource_account_address());
        assert!(amount_x_out < reserves.reserve_x && amount_y_out < reserves.reserve_y, errors::insufficient_liquidity());

        let total_fees = token_fees<X, Y>();

        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(constants::get_resource_account_address());

        // Calculate total fees here
        let fee_denominator = total_fees + 20u128;

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
        let compare_result = if(
            balance_x_adjusted > 0 
            && reserve_x_adjusted > 0 
            && constants::get_max_u128() / balance_x_adjusted > balance_y_adjusted 
            && constants::get_max_u128() / reserve_x_adjusted > reserve_y_adjusted
        ) { balance_x_adjusted * balance_y_adjusted >= reserve_x_adjusted * reserve_y_adjusted } else {
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

    // -----
    // Tests
    // -----

    #[test_only]
    public fun initialize(sender: &signer) {
        init_module(sender);
    }
}