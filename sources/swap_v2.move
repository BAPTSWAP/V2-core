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
    use aptos_std::event;

    use aptos_framework::aptos_coin::{AptosCoin as APT};
    use aptos_framework::coin::{Self, Coin};
    use aptos_framework::timestamp;
    use aptos_framework::account;
    use aptos_framework::resource_account;

    use baptswap::math;
    use baptswap::swap_utils;
    use baptswap::u256;

    use bapt_framework::deployer;

    friend baptswap_v2::router_v2;

    // ------
    // Errors
    // ------

    const ERROR_ONLY_ADMIN: u64 = 0;
    const ERROR_ALREADY_INITIALIZED: u64 = 1;
    const ERROR_NOT_CREATOR: u64 = 2;
    const ERROR_INSUFFICIENT_LIQUIDITY_MINTED: u64 = 4;
    const ERROR_INSUFFICIENT_AMOUNT: u64 = 6;
    const ERROR_INSUFFICIENT_LIQUIDITY: u64 = 7;
    const ERROR_INVALID_AMOUNT: u64 = 8;
    const ERROR_TOKENS_NOT_SORTED: u64 = 9;
    const ERROR_INSUFFICIENT_LIQUIDITY_BURNED: u64 = 10;
    const ERROR_INSUFFICIENT_OUTPUT_AMOUNT: u64 = 13;
    const ERROR_INSUFFICIENT_INPUT_AMOUNT: u64 = 14;
    const ERROR_K: u64 = 15;
    const ERROR_X_NOT_REGISTERED: u64 = 16;
    const ERROR_Y_NOT_REGISTERED: u64 = 16;
    const ERROR_NOT_ADMIN: u64 = 17;
    const ERROR_NOT_FEE_TO: u64 = 18;
    const ERROR_NOT_EQUAL_EXACT_AMOUNT: u64 = 19;
    const ERROR_NOT_RESOURCE_ACCOUNT: u64 = 20;
    const ERROR_NO_FEE_WITHDRAW: u64 = 21;
    const ERROR_EXCESSIVE_FEE: u64 = 22;
    const ERROR_PAIR_NOT_CREATED: u64 = 23;
    const ERROR_MUST_BE_INFERIOR_TO_TWENTY: u64 = 24;
    const ERROR_POOL_NOT_CREATED: u64 = 25;
    const ERROR_NO_STAKE: u64 = 26;
    const ERROR_INSUFFICIENT_BALANCE: u64 = 27;
    const ERROR_NO_REWARDS: u64 = 28;
    const ERROR_NOT_OWNER: u64 = 29;
    const ERROR_FEE_ON_TRANSFER_NOT_INITIALIZED: u64 = 30;

    // ---------
    // Constants
    // ---------

    // addresses
    const TREASURY_ACCOUNT: address = @bapt_framework;  // TODO: to be set
    const DEFAULT_ADMIN: address = @default_admin;
    const RESOURCE_ACCOUNT: address = @baptswap_v2;
    const DEV: address = @dev_2;

    const MINIMUM_LIQUIDITY: u128 = 1000;
    const MAX_COIN_NAME_LENGTH: u64 = 32;
    const PRECISION: u64 = 10000;
    const MAX_U128: u128 = 340282366920938463463374607431768211455;
    // Max DEX fee: 0.9%; (90 / (100*100))
    const DEX_FEE_THRESHOLD_NUMERATOR: u128 = 90;
    // Max individual token fee: 15%; (1500 / (100*100))
    const FEE_ON_TRANSFER_THRESHOLD_NUMERATOR: u128 = 1500;

    // -------
    // Structs
    // -------

    // used to store the token owner and the token fee; needed for Individual token fees
    struct TokenInfo<phantom CoinType> has key, copy, drop, store {
        owner: address,
        liquidity_fee_modifier: u128,
        rewards_fee_modifier: u128,
        team_fee_modifier: u128,
    }

    // The LP Token type
    struct LPToken<phantom X, phantom Y> has key {}

    // Stores the metadata required for the token pairs
    struct TokenPairMetadata<phantom X, phantom Y> has key {
        // The first provider of the token pair
        creator: address,
        // The Token owner of token X; if off, rewards/team = 0; if on, it changes
        token_info_x: Option<TokenInfo<X>>,
        // The Token owner of token Y; if off, rewards/team = 0; if on, it changes
        token_info_y: Option<TokenInfo<Y>>,
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

    // Stores the rewards pool info for token pairs
    struct TokenPairRewardsPool<phantom X, phantom Y> has key {
        staked_tokens: u64,
        balance_x: coin::Coin<X>,
        balance_y: coin::Coin<Y>,
        magnified_dividends_per_share_x: u128,
        magnified_dividends_per_share_y: u128,
        precision_factor: u128,
        is_x_staked: bool,
    }

    struct RewardsPoolUserInfo<phantom X, phantom Y, phantom StakeToken> has key, store {
        staked_tokens: coin::Coin<StakeToken>,
        reward_debt_x: u128,
        reward_debt_y: u128,
        withdrawn_x: u64,
        withdrawn_y: u64,
    }

    // Global storage for swap info
    struct SwapInfo has key {
        signer_cap: account::SignerCapability,
        fee_to: address,
        admin: address,
        liquidity_fee_modifier: u128,
        treasury_fee_modifier: u128,
        pair_created: event::EventHandle<PairCreatedEvent>
    }

    // ------
    // Events
    // ------

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

    struct FeeChangeEvent<phantom X, phantom Y> has drop, store {
        user: address,
        liquidity_fee: u128,
        team_fee: u128,
        rewards_fee: u128
    }

    // --------------------
    // Initialize Functions
    // --------------------

    fun init_module(sender: &signer) {
        let signer_cap = resource_account::retrieve_resource_account_cap(sender, DEV);
        let resource_signer = account::create_signer_with_capability(&signer_cap);
        move_to(&resource_signer, SwapInfo {
            signer_cap,
            fee_to: TREASURY_ACCOUNT,  
            admin: DEFAULT_ADMIN,
            liquidity_fee_modifier: 30,  // 0.3%
            treasury_fee_modifier: 60,   // 0.6%
            pair_created: account::new_event_handle<PairCreatedEvent>(&resource_signer),
        });
    }

    // Initialize individual token fees;
    // token owners will to specify the cointype and input the fees.
    public(friend) fun init_fee_on_transfer<CoinType>(
        sender: &signer,
        liquidity_fee: u128,
        rewards_fee: u128,
        team_fee: u128
    ) acquires SwapInfo {
        // assert that the token info is not initialized yet
        assert!(!exists<TokenInfo<CoinType>>(RESOURCE_ACCOUNT), ERROR_ALREADY_INITIALIZED);
        // assert sender is the owner of the token
        let sender_addr = signer::address_of(sender);
        assert!(is_token_owner<CoinType>(sender), ERROR_NOT_OWNER);
        // assert that the fees do not exceed the thresholds
        let swap_info = borrow_global<SwapInfo>(RESOURCE_ACCOUNT);
        let dex_fees = swap_info.liquidity_fee_modifier + swap_info.treasury_fee_modifier + liquidity_fee;
        let fee_on_transfer = liquidity_fee + rewards_fee + team_fee;
        assert!(does_not_exceed_dex_fee_threshold(dex_fees) == true, 1);
        assert!(does_not_exceed_fee_on_transfer_threshold(fee_on_transfer) == true, 1);
        // move token info under the signer address
        move_to(
            sender, 
            TokenInfo<CoinType> {
                owner: sender_addr,
                liquidity_fee_modifier: liquidity_fee,
                rewards_fee_modifier: rewards_fee,
                team_fee_modifier: team_fee
            }
        );
    }

    // Initialize rewards pool in a token pair
    public(friend) fun init_rewards_pool<X, Y>(
        sender: &signer,
        is_x_staked: bool
    ) acquires SwapInfo {
        assert!(is_pair_created<X, Y>(), ERROR_PAIR_NOT_CREATED);
        assert!(!exists<TokenPairRewardsPool<X, Y>>(RESOURCE_ACCOUNT), ERROR_ALREADY_INITIALIZED);

        let sender_addr = signer::address_of(sender);

        // Assert initializer is the owner of either X or Y
        assert!(is_token_owner<X>(sender) || is_token_owner<Y>(sender), ERROR_NOT_OWNER);

        // Assert either of the fee_on_transfer is intialized 
        // TODO: and != 0?
        assert!(
            is_fee_on_transfer_created<X>(sender)
            || is_fee_on_transfer_created<Y>(sender), 
            ERROR_FEE_ON_TRANSFER_NOT_INITIALIZED
        );
        
        // Create the pool resource
        let swap_info = borrow_global_mut<SwapInfo>(RESOURCE_ACCOUNT);
        let resource_signer = account::create_signer_with_capability(&swap_info.signer_cap);

        let precision_factor = math::pow(10u128, 12u8);

        move_to<TokenPairRewardsPool<X, Y>>(
            &resource_signer,
            TokenPairRewardsPool {
                staked_tokens: 0,
                balance_x: coin::zero<X>(),
                balance_y: coin::zero<Y>(),
                magnified_dividends_per_share_x: 0,
                magnified_dividends_per_share_y: 0,
                precision_factor,
                is_x_staked
            }
        );
    }

    // ---------------
    // Entry Functions
    // ---------------

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
        assert!(lp_amount > 0, ERROR_INSUFFICIENT_LIQUIDITY);
        check_or_register_coin_store<LPToken<X, Y>>(sender);
        coin::deposit(sender_addr, coin_lp);
        coin::deposit(sender_addr, coin_left_x);
        coin::deposit(sender_addr, coin_left_y);

        let pair_event_holder = borrow_global_mut<PairEventHolder<X, Y>>(RESOURCE_ACCOUNT);
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
        check_or_register_coin_store<X>(sender);
        check_or_register_coin_store<Y>(sender);
        let sender_addr = signer::address_of(sender);
        coin::deposit<X>(sender_addr, coins_x);
        coin::deposit<Y>(sender_addr, coins_y);
        // event
        let pair_event_holder = borrow_global_mut<PairEventHolder<X, Y>>(RESOURCE_ACCOUNT);
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

    public(friend) fun add_swap_event<X, Y>(
        sender: &signer,
        amount_x_in: u64,
        amount_y_in: u64,
        amount_x_out: u64,
        amount_y_out: u64
    ) acquires PairEventHolder {
        let sender_addr = signer::address_of(sender);
        let pair_event_holder = borrow_global_mut<PairEventHolder<X, Y>>(RESOURCE_ACCOUNT);
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
        let pair_event_holder = borrow_global_mut<PairEventHolder<X, Y>>(RESOURCE_ACCOUNT);
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

    // stake tokens in a token pair given an amount and a token pair
    public(friend) fun stake_tokens<X, Y>(
        sender: &signer,
        amount: u64
    ) acquires TokenPairRewardsPool, RewardsPoolUserInfo {
        let account_address = signer::address_of(sender);

        assert!(exists<TokenPairRewardsPool<X, Y>>(RESOURCE_ACCOUNT), ERROR_POOL_NOT_CREATED);
        let pool_info = borrow_global_mut<TokenPairRewardsPool<X, Y>>(RESOURCE_ACCOUNT);

        if (pool_info.is_x_staked) {
            if (!exists<RewardsPoolUserInfo<X, Y, X>>(account_address)) {
                move_to(sender, RewardsPoolUserInfo<X, Y, X> {
                    staked_tokens: coin::zero<X>(),
                    reward_debt_x: 0,
                    reward_debt_y: 0,
                    withdrawn_x: 0,
                    withdrawn_y: 0,
                })
            };

            let user_info = borrow_global_mut<RewardsPoolUserInfo<X, Y, X>>(account_address);

            if (coin::value(&mut user_info.staked_tokens) > 0) {
                // Calculate pending rewards
                let pending_reward_x = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_x, pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
                let pending_reward_y = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_y, pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);
                
                if (pending_reward_x > 0) {
                    // Check/register x and extract from pool
                    check_or_register_coin_store<X>(sender);
                    let x_out = coin::extract<X>(&mut pool_info.balance_x, pending_reward_x);
                    coin::deposit(signer::address_of(sender), x_out);
                };

                if (pending_reward_y > 0) {
                    // Check/register y and extract from pool
                    check_or_register_coin_store<Y>(sender);
                    let y_out = coin::extract<Y>(&mut pool_info.balance_y, pending_reward_y);
                    coin::deposit(signer::address_of(sender), y_out);
                };
            };

            if (amount > 0) {
                transfer_in<X>(&mut user_info.staked_tokens, sender, amount);
                pool_info.staked_tokens = pool_info.staked_tokens + amount;
            };

            //Calculate and update user corrections
            user_info.reward_debt_x = reward_debt(coin::value(&user_info.staked_tokens), pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
            user_info.reward_debt_y = reward_debt(coin::value(&user_info.staked_tokens), pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);

        } else {
            if (!exists<RewardsPoolUserInfo<X, Y, Y>>(account_address)) {
                move_to(sender, RewardsPoolUserInfo<X, Y, Y> {
                    staked_tokens: coin::zero<Y>(),
                    reward_debt_x: 0,
                    reward_debt_y: 0,
                    withdrawn_x: 0,
                    withdrawn_y: 0,
                })
            };

            let user_info = borrow_global_mut<RewardsPoolUserInfo<X, Y, Y>>(account_address);

            if (coin::value(&mut user_info.staked_tokens) > 0) {
                // Calculate pending rewards
                let pending_reward_x = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_x, pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
                let pending_reward_y = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_y, pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);
                
                if (pending_reward_x > 0) {
                    // Check/register x and extract from pool
                    check_or_register_coin_store<X>(sender);
                    let x_out = coin::extract<X>(&mut pool_info.balance_x, pending_reward_x);
                    coin::deposit(signer::address_of(sender), x_out);
                };

                if (pending_reward_y > 0) {
                    // Check/register y and extract from pool
                    check_or_register_coin_store<Y>(sender);
                    let y_out = coin::extract<Y>(&mut pool_info.balance_y, pending_reward_y);
                    coin::deposit(signer::address_of(sender), y_out);
                };
            };

            if (amount > 0) {
                transfer_in<Y>(&mut user_info.staked_tokens, sender, amount);
                pool_info.staked_tokens = pool_info.staked_tokens + amount;
            };

            // Calculate and update user corrections
            user_info.reward_debt_x = reward_debt(coin::value(&user_info.staked_tokens), pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
            user_info.reward_debt_y = reward_debt(coin::value(&user_info.staked_tokens), pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);

        };
    }

    // unstake tokens pair
    public entry fun unstake_tokens<X, Y>(
        sender: &signer,
        amount: u64
    ) acquires TokenPairRewardsPool, RewardsPoolUserInfo {
        let account_address = signer::address_of(sender);

        assert!(exists<TokenPairRewardsPool<X, Y>>(RESOURCE_ACCOUNT), ERROR_POOL_NOT_CREATED);
        let pool_info = borrow_global_mut<TokenPairRewardsPool<X, Y>>(RESOURCE_ACCOUNT);

        if (pool_info.is_x_staked) {
            assert!(exists<RewardsPoolUserInfo<X, Y, X>>(account_address), ERROR_NO_STAKE);
            let user_info = borrow_global_mut<RewardsPoolUserInfo<X, Y, X>>(account_address);
            assert!(coin::value<X>(&mut user_info.staked_tokens) >= amount, ERROR_INSUFFICIENT_BALANCE);

            // Calculate pending rewards
            let pending_reward_x = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_x, pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
            let pending_reward_y = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_y, pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);
            
            if (pending_reward_x > 0) {
                // Check/register x and extract from pool
                check_or_register_coin_store<X>(sender);
                let x_out = coin::extract<X>(&mut pool_info.balance_x, pending_reward_x);
                coin::deposit(signer::address_of(sender), x_out);
            };

            if (pending_reward_y > 0) {
                // Check/register y and extract from pool
                check_or_register_coin_store<Y>(sender);
                let y_out = coin::extract<Y>(&mut pool_info.balance_y, pending_reward_y);
                coin::deposit(signer::address_of(sender), y_out);
            };

            // Tranfer staked tokens out
            if (amount > 0) {
                transfer_out<X>(&mut user_info.staked_tokens, sender, amount);
                pool_info.staked_tokens = pool_info.staked_tokens - amount;
            };

            //Calculate and update user corrections
            user_info.reward_debt_x = reward_debt(coin::value(&user_info.staked_tokens), pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
            user_info.reward_debt_y = reward_debt(coin::value(&user_info.staked_tokens), pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);


        } else {
            assert!(exists<RewardsPoolUserInfo<X, Y, Y>>(account_address), ERROR_NO_STAKE);
            let user_info = borrow_global_mut<RewardsPoolUserInfo<X, Y, Y>>(account_address);
            assert!(coin::value<Y>(&mut user_info.staked_tokens) >= amount, ERROR_INSUFFICIENT_BALANCE);

            // Calculate pending rewards
            let pending_reward_x = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_x, pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
            let pending_reward_y = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_y, pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);
            
            if (pending_reward_x > 0) {
                // Check/register x and extract from pool
                check_or_register_coin_store<X>(sender);
                let x_out = coin::extract<X>(&mut pool_info.balance_x, pending_reward_x);
                coin::deposit(signer::address_of(sender), x_out);
            };

            if (pending_reward_y > 0) {
                // Check/register y and extract from pool
                check_or_register_coin_store<Y>(sender);
                let y_out = coin::extract<Y>(&mut pool_info.balance_y, pending_reward_y);
                coin::deposit(signer::address_of(sender), y_out);
            };

            // Tranfer staked tokens out
            if (amount > 0) {
                transfer_out<Y>(&mut user_info.staked_tokens, sender, amount);
                pool_info.staked_tokens = pool_info.staked_tokens - amount;
            };

            //Calculate and update user corrections
            user_info.reward_debt_x = reward_debt(coin::value(&user_info.staked_tokens), pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
            user_info.reward_debt_y = reward_debt(coin::value(&user_info.staked_tokens), pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);
        }
    }    

    // claim rewards
    public entry fun claim_rewards<X, Y>(
        sender: &signer
    ) acquires TokenPairRewardsPool, RewardsPoolUserInfo {
        let account_address = signer::address_of(sender);

        assert!(exists<TokenPairRewardsPool<X, Y>>(RESOURCE_ACCOUNT), ERROR_POOL_NOT_CREATED);
        let pool_info = borrow_global_mut<TokenPairRewardsPool<X, Y>>(RESOURCE_ACCOUNT);

        if (pool_info.is_x_staked) {
            assert!(exists<RewardsPoolUserInfo<X, Y, X>>(account_address), ERROR_NO_STAKE);
            let user_info = borrow_global_mut<RewardsPoolUserInfo<X, Y, X>>(account_address);

            // Calculate pending rewards
            let pending_reward_x = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_x, pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
            let pending_reward_y = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_y, pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);
            
            if (pending_reward_x > 0) {
                // Check/register x and extract from pool
                check_or_register_coin_store<X>(sender);
                let x_out = coin::extract<X>(&mut pool_info.balance_x, pending_reward_x);
                coin::deposit(signer::address_of(sender), x_out);
            };

            if (pending_reward_y > 0) {
                // Check/register y and extract from pool
                check_or_register_coin_store<Y>(sender);
                let y_out = coin::extract<Y>(&mut pool_info.balance_y, pending_reward_y);
                coin::deposit(signer::address_of(sender), y_out);
            };

            //Calculate and update user corrections
            user_info.reward_debt_x = reward_debt(coin::value(&user_info.staked_tokens), pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
            user_info.reward_debt_y = reward_debt(coin::value(&user_info.staked_tokens), pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);
 
        } else {
            assert!(exists<RewardsPoolUserInfo<X, Y, Y>>(account_address), ERROR_NO_STAKE);
            let user_info = borrow_global_mut<RewardsPoolUserInfo<X, Y, Y>>(account_address);

            // Calculate pending rewards
            let pending_reward_x = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_x, pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
            let pending_reward_y = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_y, pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);
            
            if (pending_reward_x > 0) {
                // Check/register x and extract from pool
                check_or_register_coin_store<X>(sender);
                let x_out = coin::extract<X>(&mut pool_info.balance_x, pending_reward_x);
                coin::deposit(signer::address_of(sender), x_out);
            };

            if (pending_reward_y > 0) {
                // Check/register y and extract from pool
                check_or_register_coin_store<Y>(sender);
                let y_out = coin::extract<Y>(&mut pool_info.balance_y, pending_reward_y);
                coin::deposit(signer::address_of(sender), y_out);
            };

            //Calculate and update user corrections
            user_info.reward_debt_x = reward_debt(coin::value(&user_info.staked_tokens), pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
            user_info.reward_debt_y = reward_debt(coin::value(&user_info.staked_tokens), pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);
 
        };

   }

    public entry fun set_admin(sender: &signer, new_admin: address) acquires SwapInfo {
        let sender_addr = signer::address_of(sender);
        let swap_info = borrow_global_mut<SwapInfo>(RESOURCE_ACCOUNT);
        assert!(sender_addr == swap_info.admin, ERROR_NOT_ADMIN);
        swap_info.admin = new_admin;
    }

    public entry fun set_fee_to(sender: &signer, new_fee_to: address) acquires SwapInfo {
        let sender_addr = signer::address_of(sender);
        let swap_info = borrow_global_mut<SwapInfo>(RESOURCE_ACCOUNT);
        assert!(sender_addr == swap_info.admin, ERROR_NOT_ADMIN);
        swap_info.fee_to = new_fee_to;
    }

    // ------------------
    // Internal Functions
    // ------------------

    // Register a pair; callable only by token owners
    public(friend) fun add_fee_on_transfer_in_pair<CoinType, X, Y>(
        sender: &signer
    ) acquires TokenInfo, TokenPairMetadata {
        let sender_addr = signer::address_of(sender);
        // assert sender is the token owner of CoinType
        assert!(is_token_owner<CoinType>(sender), ERROR_NOT_OWNER);
        // assert pair exists
        assert!(is_pair_created<X, Y>(), ERROR_PAIR_NOT_CREATED);
        // assert CoinType is either X or Y
        assert!(
            type_info::type_of<CoinType>() == type_info::type_of<X>()
            || type_info::type_of<CoinType>() == type_info::type_of<Y>(),
            1
        );
        // TODO: assert the token owner didn't register that pair already
        // assert!(!is_token_registered_in_pair<CoinType, X, Y>(sender, pair), 1);
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT);
        
        // if Cointype = X, add token_info to pair_metadata.token_info_x
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            let token_info = borrow_global<TokenInfo<X>>(sender_addr);
            option::fill<TokenInfo<X>>(&mut metadata.token_info_x, *token_info);
            toggle_all_fee_on_transfer<CoinType, X, Y>(sender, true);
            // register Y; needed to receive team fees
            check_or_register_coin_store<Y>(sender);
        // if Cointype = Y, add token_info to pair_metadata.token_info_y
        } else {
            let token_info = borrow_global<TokenInfo<Y>>(sender_addr);
            option::fill<TokenInfo<Y>>(&mut metadata.token_info_y, *token_info);
            toggle_all_fee_on_transfer<CoinType, X, Y>(sender, true);
            // register X; needed to receive team fees
            check_or_register_coin_store<X>(sender);
        }
    }

    // Toggle fees 

    // toggle all individual token fees in a token pair; given CoinType, and a Token Pair
    public entry fun toggle_all_fee_on_transfer<CoinType, X, Y>(
        sender: &signer,
        activate: bool,
    ) acquires TokenInfo, TokenPairMetadata {
        // update new fees based on "activate" variable
        toggle_fee_on_transfer_liquidity_fee<CoinType, X, Y>(sender, activate);
        toggle_fee_on_transfer_team_fee<CoinType, X, Y>(sender, activate);
        toggle_fee_on_transfer_rewards_fee<CoinType, X, Y>(sender, activate);

        // TODO: events
    }

    // Toggle liquidity fee
    public entry fun toggle_fee_on_transfer_liquidity_fee<CoinType, X, Y>(
        sender: &signer,  
        activate: bool
    ) acquires TokenInfo, TokenPairMetadata {
        // assert sender is token owner
        assert!(is_token_owner<CoinType>(sender), ERROR_NOT_OWNER);
        // TODO: assert TokenInfo<CoinType> is registered in the pair

        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT);
        let token_info = borrow_global<TokenInfo<CoinType>>(signer::address_of(sender));
        // if cointype = x
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            // if activate = true
            if (activate == true) {
                metadata.liquidity_fee = metadata.liquidity_fee + token_info.liquidity_fee_modifier;
            // if activate = false
            } else {
                metadata.liquidity_fee = metadata.liquidity_fee - token_info.liquidity_fee_modifier;
            }
        // if cointype = y
        } else if (type_info::type_of<CoinType>() == type_info::type_of<Y>()) {
            // if activate = true
            if (activate == true) {
                metadata.liquidity_fee = metadata.liquidity_fee + token_info.liquidity_fee_modifier;
            // if activate = false
            } else {
                metadata.liquidity_fee = metadata.liquidity_fee - token_info.liquidity_fee_modifier;
            }
        } else { assert!(false, 1); }
    }

    // toggle team fee
    public entry fun toggle_fee_on_transfer_team_fee<CoinType, X, Y>(
        sender: &signer, 
        activate: bool,
    ) acquires TokenInfo, TokenPairMetadata {
        // assert sender is token owner
        assert!(is_token_owner<CoinType>(sender), ERROR_NOT_OWNER);
        // TODO: assert TokenInfo<CoinType> is registered in the pair

        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT);
        let token_info = borrow_global<TokenInfo<CoinType>>(signer::address_of(sender));
        // if cointype = x
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            // if activate = true
            if (activate == true) {
                metadata.team_fee = metadata.team_fee + token_info.team_fee_modifier;
            // if activate = false
            } else {
                metadata.team_fee = metadata.team_fee - token_info.team_fee_modifier;
            }
        // if cointype = y
        } else if (type_info::type_of<CoinType>() == type_info::type_of<Y>()) {
            // if activate = true
            if (activate == true) {
                metadata.team_fee = metadata.team_fee + token_info.team_fee_modifier;
            // if activate = false
            } else {
                metadata.team_fee = metadata.team_fee - token_info.team_fee_modifier;
            }
        } else { assert!(false, 1); }
    }

    // toggle liquidity fee
    public entry fun toggle_fee_on_transfer_rewards_fee<CoinType, X, Y>(
        sender: &signer,
        activate: bool,
    ) acquires TokenInfo, TokenPairMetadata {
        // assert sender is token owner
        assert!(is_token_owner<CoinType>(sender), ERROR_NOT_OWNER);
        // TODO: assert TokenInfo<CoinType> is registered in the pair

        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT);
        let token_info = borrow_global<TokenInfo<CoinType>>(signer::address_of(sender));
        // if cointype = x
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            // if activate = true
            if (activate == true) {
                metadata.rewards_fee = metadata.rewards_fee + token_info.rewards_fee_modifier;
            // if activate = false
            } else {
                metadata.rewards_fee = metadata.rewards_fee - token_info.rewards_fee_modifier;
            }
        // if cointype = y
        } else if (type_info::type_of<CoinType>() == type_info::type_of<Y>()) {
            // if activate = true
            if (activate == true) {
                metadata.rewards_fee = metadata.rewards_fee + token_info.rewards_fee_modifier;
            // if activate = false
            } else {
                metadata.rewards_fee = metadata.rewards_fee - token_info.rewards_fee_modifier;
            }
        } else { assert!(false, 1); }
    }

    // Create the specified coin pair; all fees are toggled off
    public(friend) fun create_pair<X, Y>(
        sender: &signer,
    ) acquires SwapInfo {
        assert!(!is_pair_created<X, Y>(), ERROR_ALREADY_INITIALIZED);

        let sender_addr = signer::address_of(sender);
        let swap_info = borrow_global_mut<SwapInfo>(RESOURCE_ACCOUNT);
        let resource_signer = account::create_signer_with_capability(&swap_info.signer_cap);

        let lp_name: string::String = string::utf8(b"BaptswapV2-");
        let name_x = coin::symbol<X>();
        let name_y = coin::symbol<Y>();
        string::append(&mut lp_name, name_x);
        string::append_utf8(&mut lp_name, b"/");
        string::append(&mut lp_name, name_y);
        string::append_utf8(&mut lp_name, b"-LP");
        if (string::length(&lp_name) > MAX_COIN_NAME_LENGTH) {
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
                token_info_x: option::none<TokenInfo<X>>(),
                token_info_y: option::none<TokenInfo<Y>>(),
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

    // Swap X to Y, X is in and Y is out. This method assumes amount_out_min is 0
    public(friend) fun swap_exact_x_to_y<X, Y>(
        sender: &signer,
        amount_in: u64,
        to: address
    ): u64 acquires SwapInfo, TokenPairReserve, TokenPairMetadata, TokenPairRewardsPool {
        let coins = coin::withdraw<X>(sender, amount_in);
        let (coins_x_out, coins_y_out) = swap_exact_x_to_y_direct<X, Y>(coins);
        let amount_out = coin::value(&coins_y_out);
        check_or_register_coin_store<Y>(sender);
        coin::destroy_zero(coins_x_out); // or others ways to drop `coins_x_out`
        coin::deposit(to, coins_y_out);
        amount_out
    }

    // Swap X to Y, X is in and Y is out. This method assumes amount_out_min is 0
    public(friend) fun swap_exact_x_to_y_direct<X, Y>(
        coins_in: Coin<X>
    ): (Coin<X>, Coin<Y>) acquires SwapInfo, TokenPairReserve, TokenPairMetadata, TokenPairRewardsPool {
        // Grab token pair metadata
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT); 
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

        assert!(coin::value<X>(&coins_x_out) == 0, ERROR_INSUFFICIENT_OUTPUT_AMOUNT);
        (coins_x_out, coins_y_out)
    }

    public(friend) fun swap_x_to_exact_y<X, Y>(
        sender: &signer,
        amount_in: u64,
        amount_out: u64,
        to: address
    ): u64 acquires SwapInfo, TokenPairReserve, TokenPairMetadata, TokenPairRewardsPool {
        let coins_in = coin::withdraw<X>(sender, amount_in);
        let (coins_x_out, coins_y_out) = swap_x_to_exact_y_direct<X, Y>(coins_in, amount_out);
        check_or_register_coin_store<Y>(sender);
        coin::destroy_zero(coins_x_out); // or others ways to drop `coins_x_out`
        coin::deposit(to, coins_y_out);
        amount_in
    }

    public(friend) fun swap_x_to_exact_y_direct<X, Y>(
        coins_in: Coin<X>,
        amount_out: u64
    ): (Coin<X>, Coin<Y>) acquires SwapInfo, TokenPairReserve, TokenPairMetadata, TokenPairRewardsPool {
        // Grab token pair metadata
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT); 
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

        assert!(coin::value<X>(&coins_x_out) == amount_out, ERROR_INSUFFICIENT_OUTPUT_AMOUNT);
        (coins_x_out, coins_y_out)
    }

    // Swap Y to X, Y is in and X is out. This method assumes amount_out_min is 0
    public(friend) fun swap_exact_y_to_x<X, Y>(
        sender: &signer,
        amount_in: u64,
        to: address
    ): u64 acquires SwapInfo, TokenPairReserve, TokenPairMetadata, TokenPairRewardsPool {
        let coins = coin::withdraw<Y>(sender, amount_in);
        let (coins_x_out, coins_y_out) = swap_exact_y_to_x_direct<X, Y>(coins);
        let amount_out = coin::value<X>(&coins_x_out);
        check_or_register_coin_store<X>(sender);
        coin::deposit(to, coins_x_out);
        coin::destroy_zero(coins_y_out); // or others ways to drop `coins_y_out`
        amount_out
    }

    public(friend) fun swap_y_to_exact_x<X, Y>(
        sender: &signer,
        amount_in: u64,
        amount_out: u64,
        to: address
    ): u64 acquires SwapInfo, TokenPairReserve, TokenPairMetadata, TokenPairRewardsPool {
        let coins_in = coin::withdraw<Y>(sender, amount_in);
        let (coins_x_out, coins_y_out) = swap_y_to_exact_x_direct<X, Y>(coins_in, amount_out);
        check_or_register_coin_store<X>(sender);
        coin::deposit(to, coins_x_out);
        coin::destroy_zero(coins_y_out); // or others ways to drop `coins_y_out`
        amount_in
    }

    public(friend) fun swap_y_to_exact_x_direct<X, Y>(
        coins_in: Coin<Y>,
        amount_out: u64
    ): (Coin<X>, Coin<Y>) acquires SwapInfo, TokenPairReserve, TokenPairMetadata, TokenPairRewardsPool {
        // Grab token pair metadata
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT); 
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

        assert!(coin::value<Y>(&coins_y_out) == amount_out, ERROR_INSUFFICIENT_OUTPUT_AMOUNT);
        (coins_x_out, coins_y_out)
    }

    // Swap Y to X, Y is in and X is out. This method assumes amount_out_min is 0
    public(friend) fun swap_exact_y_to_x_direct<X, Y>(
        coins_in: Coin<Y>
    ): (Coin<X>, Coin<Y>) acquires SwapInfo, TokenPairReserve, TokenPairMetadata, TokenPairRewardsPool {
        // Grab token pair metadata
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT); 
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

        assert!(coin::value<Y>(&coins_y_out) == 0, ERROR_INSUFFICIENT_OUTPUT_AMOUNT);
        (coins_x_out, coins_y_out)
    }

    // --------------
    // View Functions
    // --------------

    // Callable only by DEX Owner
    
    #[view]
    public fun get_dex_liquidity_fee(): u128 acquires SwapInfo {
        let swap_info = borrow_global<SwapInfo>(RESOURCE_ACCOUNT);
        swap_info.liquidity_fee_modifier
    }

    #[view]
    public fun get_dex_treasury_fee(): u128 acquires SwapInfo {
        let swap_info = borrow_global<SwapInfo>(RESOURCE_ACCOUNT);
        swap_info.treasury_fee_modifier
    }

    // Callable only by token owners

    #[view]
    public fun get_fee_on_transfer_liquidity_fee<CoinType>(
        sender: &signer
    ): u128 acquires TokenInfo {
        let sender_addr = signer::address_of(sender);
        // assert sender is token owner
        assert!(is_token_owner<CoinType>(sender), ERROR_NOT_OWNER);
        let token_info = borrow_global<TokenInfo<CoinType>>(sender_addr);
        token_info.liquidity_fee_modifier
    }

    #[view]
    public fun get_fee_on_transfer_team_fee<CoinType>(
        sender: &signer
    ): u128 acquires TokenInfo {
        let sender_addr = signer::address_of(sender);
        // assert sender is token owner
        assert!(is_token_owner<CoinType>(sender), ERROR_NOT_OWNER);
        let token_info = borrow_global<TokenInfo<CoinType>>(sender_addr);
        token_info.team_fee_modifier
    }

    #[view]
    public fun get_fee_on_transfer_rewards_fee<CoinType>(
        sender: &signer
    ): u128 acquires TokenInfo {
        let sender_addr = signer::address_of(sender);
        // assert sender is token owner
        assert!(is_token_owner<CoinType>(sender), ERROR_NOT_OWNER);
        let token_info = borrow_global<TokenInfo<CoinType>>(sender_addr);
        token_info.rewards_fee_modifier
    }

    #[view]
    public fun is_pair_created<X, Y>(): bool {
        exists<TokenPairReserve<X, Y>>(RESOURCE_ACCOUNT)
    }

    #[view]
    public fun is_pool_created<X, Y>(): bool {
        exists<TokenPairRewardsPool<X, Y>>(RESOURCE_ACCOUNT)
    }

    #[view]
    public fun is_fee_on_transfer_created<CoinType>(signer_ref: &signer): bool {
        exists<TokenInfo<CoinType>>(signer::address_of(signer_ref))
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
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT);
        (
            metadata.liquidity_fee + metadata.treasury_fee + metadata.team_fee + metadata.rewards_fee
        )
    }

    #[view]
    public fun token_rewards_pool_info<X, Y>(): (u64, u64, u64, u128, u128, u128, bool) acquires TokenPairRewardsPool {
        assert!(is_pool_created<X, Y>(), ERROR_POOL_NOT_CREATED);

        let pool = borrow_global_mut<TokenPairRewardsPool<X, Y>>(RESOURCE_ACCOUNT);

        (
            pool.staked_tokens, coin::value(&pool.balance_x), coin::value(&pool.balance_y),
            pool.magnified_dividends_per_share_x, pool.magnified_dividends_per_share_y,
            pool.precision_factor, pool.is_x_staked
        )
    }

    #[view]
    // Get the current reserves of T0 and T1 with the latest updated timestamp
    public fun token_reserves<X, Y>(): (u64, u64, u64) acquires TokenPairReserve {
        let reserve = borrow_global<TokenPairReserve<X, Y>>(RESOURCE_ACCOUNT);
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
            borrow_global<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT);
        (
            coin::value(&meta.balance_x),
            coin::value(&meta.balance_y)
        )
    }

    #[view]
    public fun admin(): address acquires SwapInfo {
        let swap_info = borrow_global_mut<SwapInfo>(RESOURCE_ACCOUNT);
        swap_info.admin
    }

    #[view]
    public fun fee_to(): address acquires SwapInfo {
        let swap_info = borrow_global_mut<SwapInfo>(RESOURCE_ACCOUNT);
        swap_info.fee_to
    }

    // ---------
    // Accessors
    // ---------

    // returns true if given rate is less than dex fee threshold
    inline fun does_not_exceed_dex_fee_threshold(total_fees_numerator: u128): bool {
        if (total_fees_numerator <= DEX_FEE_THRESHOLD_NUMERATOR) true else false
    }

    // returns true if given rate is less than the individual token threshold
    inline fun does_not_exceed_fee_on_transfer_threshold(total_fees_numerator: u128): bool {
        if (total_fees_numerator <= FEE_ON_TRANSFER_THRESHOLD_NUMERATOR) true else false
    }

    // returns true if sender is the owner of token X
    fun is_token_owner<X>(sender: &signer): bool {
        let sender_addr = signer::address_of(sender);
        let token_addr = deployer::coin_address<X>();
        deployer::is_coin_owner(token_addr, sender_addr)
    }

    // Obtain the LP token balance of `addr`.
    // This method can only be used to check other users' balance.
    public fun lp_balance<X, Y>(addr: address): u64 {
        coin::balance<LPToken<X, Y>>(addr)
    }

    public fun check_or_register_coin_store<X>(sender: &signer) {
        if (!coin::is_account_registered<X>(signer::address_of(sender))) {
            coin::register<X>(sender);
        };
    }

    // --------
    // Mutators
    // --------

    // Callable only by DEX Owner

    // set dex liquidity fee
    public entry fun set_dex_liquidity_fee(
        sender: &signer,
        new_fee: u128
    ) acquires SwapInfo {
        let swap_info = borrow_global_mut<SwapInfo>(RESOURCE_ACCOUNT);
        // assert sender is admin
        assert!(signer::address_of(sender) == swap_info.admin, ERROR_NOT_ADMIN);
        // assert new fee is not equal to the existing fee
        assert!(new_fee != swap_info.liquidity_fee_modifier, 1);
        // assert the newer total fee is less than the threshold
        assert!(does_not_exceed_dex_fee_threshold(new_fee + swap_info.treasury_fee_modifier) == true, 1);
        // update the fee
        swap_info.liquidity_fee_modifier = new_fee;
    }

    // set dex treasury fee
    public entry fun set_dex_treasury_fee(
        sender: &signer,
        new_fee: u128
    ) acquires SwapInfo {
        let swap_info = borrow_global_mut<SwapInfo>(RESOURCE_ACCOUNT);
        // assert sender is admin
        assert!(signer::address_of(sender) == swap_info.admin, ERROR_NOT_ADMIN);
        // assert new fee is not equal to the existing fee
        assert!(new_fee != swap_info.treasury_fee_modifier, 1);
        // assert the newer total fee is less than the threshold
        assert!(does_not_exceed_dex_fee_threshold(new_fee + swap_info.liquidity_fee_modifier) == true, 1);
        // update the fee
        swap_info.treasury_fee_modifier = new_fee;
    }

    // Callable only by token owners

    // update individual token liquidity fee
    public entry fun set_fee_on_transfer_liquidity_fee<CoinType>(
        sender: &signer,
        new_fee: u128
    ) acquires TokenInfo {
        let sender_addr = signer::address_of(sender);
        let token_info = borrow_global_mut<TokenInfo<CoinType>>(sender_addr);
        // assert sender is token owner of CoinType
        assert!(is_token_owner<CoinType>(sender), ERROR_NOT_OWNER);
        // assert new fee is not equal to the existing fee
        assert!(new_fee != token_info.liquidity_fee_modifier, 1);
        // assert the newer total fee is less than the threshold
        assert!(does_not_exceed_fee_on_transfer_threshold(new_fee + token_info.rewards_fee_modifier + token_info.team_fee_modifier) == true, 1);
        // update the fee
        token_info.liquidity_fee_modifier = new_fee;
    }

    // set individual token team fee
    public entry fun set_fee_on_transfer_team_fee<CoinType>(
        sender: &signer,
        new_fee: u128
    ) acquires TokenInfo {
        let sender_addr = signer::address_of(sender);
        let token_info = borrow_global_mut<TokenInfo<CoinType>>(sender_addr);
        // assert sender is token owner of CoinType
        assert!(is_token_owner<CoinType>(sender), ERROR_NOT_OWNER);
        // assert new fee is not equal to the existing fee
        assert!(new_fee != token_info.team_fee_modifier, 1);
        // assert the newer total fee is less than the threshold
        assert!(does_not_exceed_fee_on_transfer_threshold(new_fee + token_info.rewards_fee_modifier + token_info.liquidity_fee_modifier) == true, 1);
        // update the fee
        token_info.team_fee_modifier = new_fee;
    }

    // set individual token rewards fee
    public(friend) fun set_fee_on_transfer_rewards_fee<CoinType>(
        sender: &signer,
        new_fee: u128
    ) acquires TokenInfo {
        let sender_addr = signer::address_of(sender);
        let token_info = borrow_global_mut<TokenInfo<CoinType>>(sender_addr);
        // assert sender is token owner of CoinType
        assert!(is_token_owner<CoinType>(sender), ERROR_NOT_OWNER);
        // assert new fee is not equal to the existing fee
        assert!(new_fee != token_info.rewards_fee_modifier, 1);
        // assert the newer total fee is less than the threshold
        assert!(does_not_exceed_fee_on_transfer_threshold(new_fee + token_info.liquidity_fee_modifier + token_info.team_fee_modifier) == true, 1);
        // update the fee
        token_info.rewards_fee_modifier = new_fee;
    }

    // Calculate and adjust the maginified dividends per share
    fun update_pool<X, Y>(pool_info: &mut TokenPairRewardsPool<X, Y>, reward_x: u64, reward_y: u64) {
        if (pool_info.staked_tokens == 0) {
            return
        };

        let (new_x_magnified_dividends_per_share, new_y_magnified_dividends_per_share) = cal_acc_token_per_share(
            pool_info.magnified_dividends_per_share_x,
            pool_info.magnified_dividends_per_share_y,
            pool_info.staked_tokens,
            pool_info.precision_factor,
            reward_x,
            reward_y
        );

        // Update magnitude values
        pool_info.magnified_dividends_per_share_x = new_x_magnified_dividends_per_share;
        pool_info.magnified_dividends_per_share_y = new_y_magnified_dividends_per_share;
    }

    #[view]
    // return pair reserve if it's created
    public fun get_reserve<X, Y>(): TokenPairReserve<X, Y> acquires TokenPairReserve {
        // assert pair is created
        assert!(is_pair_created<X, Y>(), ERROR_PAIR_NOT_CREATED);
        let reserve = borrow_global<TokenPairReserve<X, Y>>(RESOURCE_ACCOUNT);
        TokenPairReserve<X, Y> {
            reserve_x: reserve.reserve_x,
            reserve_y: reserve.reserve_y,
            block_timestamp_last: reserve.block_timestamp_last
        }
    }

    #[view]
    // Get current accumulated fees for a token pair
    public fun get_rewards_fees_accumulated<X, Y>(): (u64, u64) acquires TokenPairRewardsPool {
        let pool_balance_x = 0;
        let pool_balance_y = 0;

        if (is_pool_created<X, Y>()) {
            let pool = borrow_global_mut<TokenPairRewardsPool<X, Y>>(RESOURCE_ACCOUNT);

            pool_balance_x = coin::value<X>(&pool.balance_x);
            pool_balance_y = coin::value<Y>(&pool.balance_y);
        };

        (pool_balance_x, pool_balance_y)
    }

    // -----------------
    // Utility Functions
    // -----------------

    // calculate individual token fees amounts given token info
    fun calculate_fee_on_transfer_amounts<CoinType>(
        token_info: TokenInfo<CoinType>, 
        amount_in: u64
    ): (u128, u128, u128) {
        let token_liquidity_fee_numerator = token_info.liquidity_fee_modifier;
        let token_rewards_fee_numerator = token_info.rewards_fee_modifier;
        let token_team_fee_numerator = token_info.team_fee_modifier;
        // calculate fee amounts
        (
            calculate_amount(token_liquidity_fee_numerator, amount_in),
            calculate_amount(token_rewards_fee_numerator, amount_in),
            calculate_amount(token_team_fee_numerator, amount_in),
        )
    }

    // calculate dex fees amounts given swap info
    fun calculate_dex_fees_amounts<CoinType>(amount_in: u64): (u128, u128) acquires SwapInfo {
        let swap_info = borrow_global<SwapInfo>(RESOURCE_ACCOUNT);
        let dex_liquidity_fee_numerator = swap_info.liquidity_fee_modifier;
        let dex_rewards_fee_numerator = swap_info.treasury_fee_modifier;
        // calculate fee amounts
        (
            calculate_amount(dex_liquidity_fee_numerator, amount_in),
            calculate_amount(dex_rewards_fee_numerator, amount_in)
        )
    }

    // calculates an amount given a numerator; amount = amount in * numerator / (100*100)
    inline fun calculate_amount(numerator: u128, amount_in: u64): u128 {
        (amount_in as u128) * numerator / 10000u128
    }

    fun cal_acc_token_per_share(
        last_magnified_dividends_per_share_x: u128,
        last_magnified_dividends_per_share_y: u128,
        total_staked_token: u64, 
        precision_factor: u128, 
        reward_x: u64, 
        reward_y: u64
    ): (u128, u128) {
        if (reward_x == 0 && reward_y == 0) return (last_magnified_dividends_per_share_x, last_magnified_dividends_per_share_y);

        let x_token_per_share_u256 = u256::from_u64(0u64);
        let y_token_per_share_u256 = u256::from_u64(0u64);

        if (reward_x > 0) {
            // acc_token_per_share = acc_token_per_share + (reward * precision_factor) / total_stake;
            x_token_per_share_u256 = u256::add(
                u256::from_u128(last_magnified_dividends_per_share_x),
                u256::div(
                    u256::mul(u256::from_u64(reward_x), u256::from_u128(precision_factor)),
                    u256::from_u64(total_staked_token)
                )
            );
        } else {
            x_token_per_share_u256 = u256::from_u128(last_magnified_dividends_per_share_x);
        };

        if (reward_y > 0) {
            // acc_token_per_share = acc_token_per_share + (reward * precision_factor) / total_stake;
            y_token_per_share_u256 = u256::add(
                u256::from_u128(last_magnified_dividends_per_share_y),
                u256::div(
                    u256::mul(u256::from_u64(reward_y), u256::from_u128(precision_factor)),
                    u256::from_u64(total_staked_token)
                )
            );
        } else {
            y_token_per_share_u256 = u256::from_u128(last_magnified_dividends_per_share_y);
        };

        (u256::as_u128(x_token_per_share_u256), u256::as_u128(y_token_per_share_u256))
    }

    fun reward_debt(amount: u64, acc_token_per_share: u128, precision_factor: u128): u128 {
        // user.reward_debt = (user_info.amount * pool_info.acc_token_per_share) / pool_info.precision_factor;
        u256::as_u128(
            u256::div(
                u256::mul(
                    u256::from_u64(amount),
                    u256::from_u128(acc_token_per_share)
                ),
                u256::from_u128(precision_factor)
            )
        )
    }

    fun cal_pending_reward(amount: u64, reward_debt: u128, acc_token_per_share: u128, precision_factor: u128): u64 {
        // pending = (user_info::amount * pool_info.acc_token_per_share) / pool_info.precision_factor - user_info.reward_debt
        u256::as_u64(
            u256::sub(
                u256::div(
                    u256::mul(
                        u256::from_u64(amount),
                        u256::from_u128(acc_token_per_share)
                    ), u256::from_u128(precision_factor)
                ), u256::from_u128(reward_debt))
        )
    }

    fun transfer_in<CoinType>(own_coin: &mut Coin<CoinType>, account: &signer, amount: u64) {
        let coin = coin::withdraw<CoinType>(account, amount);
        coin::merge(own_coin, coin);
    }

    fun transfer_out<CoinType>(own_coin: &mut Coin<CoinType>, receiver: &signer, amount: u64) {
        check_or_register_coin_store<CoinType>(receiver);
        let extract_coin = coin::extract<CoinType>(own_coin, amount);
        coin::deposit<CoinType>(signer::address_of(receiver), extract_coin);
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
                assert!(amount_x_optimal <= amount_x, ERROR_INVALID_AMOUNT);
                (amount_x_optimal, amount_y)
            }
        };

        assert!(a_x <= amount_x, ERROR_INSUFFICIENT_AMOUNT);
        assert!(a_y <= amount_y, ERROR_INSUFFICIENT_AMOUNT);

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
    fun distribute_dex_fees<X, Y>(amount_in: u64) acquires SwapInfo, TokenPairReserve, TokenPairMetadata {
        // distribute DEX fees to dex owner;
        let (amount_to_liquidity, amount_to_treasury) = calculate_dex_fees_amounts<Y>(amount_in);
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT);
        // liquidity
        let liquidity_fee_coins = coin::extract<Y>(&mut metadata.balance_y, (amount_to_liquidity as u64));
        coin::merge(&mut metadata.balance_y, liquidity_fee_coins);
        // treasury 
        let treasury_fee_coins = coin::extract<Y>(&mut metadata.balance_y, (amount_to_treasury as u64));
        coin::deposit<Y>(fee_to(), treasury_fee_coins);
        // update reserves
        update_reserves<X, Y>();
    }

    fun update_reserves<X, Y>() acquires TokenPairReserve, TokenPairMetadata {
        let reserves = borrow_global_mut<TokenPairReserve<X, Y>>(RESOURCE_ACCOUNT);
        let (balance_x, balance_y) = token_balances<X, Y>();
        update(balance_x, balance_y, reserves);
    }

    // used in swap functions to distribute fees and update reserves correspondingly
    // TODO: when extracting fees, we need to check if the token if fee is not zero (follow the same logic as in rewards_fees)
    // TODO: a lot of code duplication, can be improved
    fun distribute_fee_on_transfer<X, Y>(
        amount_in: u64
    ) acquires TokenPairReserve, TokenPairMetadata, TokenPairRewardsPool {
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT);
        let token_info_x = metadata.token_info_x;
        let token_info_y = metadata.token_info_y;
        // if token info x is registered & token info y is not, calculate only token info x fees
        if (!option::is_none<TokenInfo<X>>(&token_info_x) && option::is_none<TokenInfo<Y>>(&token_info_y)) {
            let extracted_token_info_x = option::extract(&mut token_info_x);
            // calculate the fees 
            let (amount_to_liquidity, amount_to_rewards, amount_to_team) = calculate_fee_on_transfer_amounts<X>(extracted_token_info_x, amount_in);
            
            // extract fees
            let liquidity_coins = coin::extract<X>(&mut metadata.balance_x, (amount_to_liquidity as u64));
            // let rewards_coins = coin::extract<X>(&mut metadata.balance_x, (amount_to_rewards as u64));
            let team_coins = coin::extract<X>(&mut metadata.balance_x, (amount_to_team as u64));
            
            // distribute fees
            coin::merge(&mut metadata.balance_x, liquidity_coins);
            // rewards fees must go to rewards pool
            if (metadata.rewards_fee > 0) {
                let rewards_pool = borrow_global_mut<TokenPairRewardsPool<X, Y>>(RESOURCE_ACCOUNT);
                let rewards_coins = coin::extract(&mut metadata.balance_x, (amount_to_rewards as u64));

                update_pool<X,Y>(rewards_pool, coin::value(&rewards_coins), 0);
                coin::merge(&mut rewards_pool.balance_x, rewards_coins);
            };
            coin::merge(&mut metadata.team_balance_x, team_coins);
            // update reserves
            update_reserves<X, Y>();
        }
        // if token info y is registered & token info x not, calculate only token info y fees
        else if (option::is_none<TokenInfo<X>>(&token_info_x) && !option::is_none<TokenInfo<Y>>(&token_info_y)) {
            let extracted_token_info_y = option::extract(&mut token_info_y);
            // calculate the fees 
            let (amount_to_liquidity, amount_to_rewards, amount_to_team) = calculate_fee_on_transfer_amounts<Y>(extracted_token_info_y, amount_in);
            
            // extract fees
            let liquidity_coins = coin::extract<Y>(&mut metadata.balance_y, (amount_to_liquidity as u64));
            // let rewards_coins = coin::extract<Y>(&mut metadata.balance_y, (amount_to_rewards as u64));
            let team_coins = coin::extract<Y>(&mut metadata.balance_y, (amount_to_team as u64));
            
            // distribute fees
            coin::merge(&mut metadata.balance_y, liquidity_coins);
            // rewards fees must go to rewards pool
            if (metadata.rewards_fee > 0) {
                let rewards_pool = borrow_global_mut<TokenPairRewardsPool<X, Y>>(RESOURCE_ACCOUNT);
                let rewards_coins = coin::extract(&mut metadata.balance_y, (amount_to_rewards as u64));

                update_pool<X,Y>(rewards_pool, coin::value(&rewards_coins), 0);
                coin::merge(&mut rewards_pool.balance_y, rewards_coins);
            };
            coin::merge(&mut metadata.team_balance_y, team_coins);
            // update reserves
            update_reserves<X, Y>();
        }
        // if token info x and token info y are both registered
        else if (!option::is_none<TokenInfo<X>>(&token_info_x) && !option::is_none<TokenInfo<Y>>(&token_info_y)) {
            let extracted_token_info_x = option::extract(&mut token_info_x);
            let extracted_token_info_y = option::extract(&mut token_info_y);

            // calculate the fees
            let (amount_to_liquidity_x, amount_to_rewards_x, amount_to_team_x) = calculate_fee_on_transfer_amounts<X>(extracted_token_info_x, amount_in);
            let (amount_to_liquidity_y, amount_to_rewards_y, amount_to_team_y) = calculate_fee_on_transfer_amounts<Y>(extracted_token_info_y, amount_in);

            // extract fees
            let liquidity_coins_x = coin::extract<X>(&mut metadata.balance_x, (amount_to_liquidity_x as u64));
            // let rewards_coins_x = coin::extract<X>(&mut metadata.balance_x, (amount_to_rewards_x as u64));
            let team_coins_x = coin::extract<X>(&mut metadata.balance_x, (amount_to_team_x as u64));
            let liquidity_coins_y = coin::extract<Y>(&mut metadata.balance_y, (amount_to_liquidity_y as u64));
            // let rewards_coins_y = coin::extract<Y>(&mut metadata.balance_y, (amount_to_rewards_y as u64));
            let team_coins_y = coin::extract<Y>(&mut metadata.balance_y, (amount_to_team_y as u64));

            // distribute fees
            coin::merge(&mut metadata.balance_x, liquidity_coins_x);
            coin::merge(&mut metadata.balance_y, liquidity_coins_y);
            // rewards fees must go to rewards pool
            if (metadata.rewards_fee > 0) {
                let rewards_pool = borrow_global_mut<TokenPairRewardsPool<X, Y>>(RESOURCE_ACCOUNT);
                let rewards_coins_x = coin::extract(&mut metadata.balance_x, (amount_to_rewards_x as u64));
                let rewards_coins_y = coin::extract(&mut metadata.balance_y, (amount_to_rewards_y as u64));

                update_pool<X,Y>(rewards_pool, coin::value(&rewards_coins_x), coin::value(&rewards_coins_y));
                coin::merge(&mut rewards_pool.balance_x, rewards_coins_x);
                coin::merge(&mut rewards_pool.balance_y, rewards_coins_y);
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
        assert!(amount_x_out > 0 || amount_y_out > 0, ERROR_INSUFFICIENT_OUTPUT_AMOUNT);

        let reserves = borrow_global_mut<TokenPairReserve<X, Y>>(RESOURCE_ACCOUNT);
        assert!(amount_x_out < reserves.reserve_x && amount_y_out < reserves.reserve_y, ERROR_INSUFFICIENT_LIQUIDITY);

        let total_fees = token_fees<X, Y>();

        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT);

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

        assert!(amount_x_in > 0 || amount_y_in > 0, ERROR_INSUFFICIENT_INPUT_AMOUNT);

        let prec = (PRECISION as u128);
        let balance_x_adjusted = (balance_x as u128) * prec - (amount_x_in as u128) * fee_denominator;
        let balance_y_adjusted = (balance_y as u128) * prec - (amount_y_in as u128) * fee_denominator;
        let reserve_x_adjusted = (reserves.reserve_x as u128) * prec;
        let reserve_y_adjusted = (reserves.reserve_y as u128) * prec;

        // No need to use u256 when balance_x_adjusted * balance_y_adjusted and reserve_x_adjusted * reserve_y_adjusted are less than MAX_U128.
        let compare_result = if(
            balance_x_adjusted > 0 
            && reserve_x_adjusted > 0 
            && MAX_U128 / balance_x_adjusted > balance_y_adjusted 
            && MAX_U128 / reserve_x_adjusted > reserve_y_adjusted
        ) { balance_x_adjusted * balance_y_adjusted >= reserve_x_adjusted * reserve_y_adjusted } else {
            let p = u256::mul_u128(balance_x_adjusted, balance_y_adjusted);
            let k = u256::mul_u128(reserve_x_adjusted, reserve_y_adjusted);
            u256::ge(&p, &k)
        };
        assert!(compare_result, ERROR_K);

        update(balance_x, balance_y, reserves);

        (coins_x_out, coins_y_out)
    }

    // Mint LP Token.
    // This low-level function should be called from a contract which performs important safety checks
    fun mint<X, Y>(): (Coin<LPToken<X, Y>>) acquires TokenPairReserve, TokenPairMetadata {
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT);
        let (balance_x, balance_y) = (coin::value(&metadata.balance_x), coin::value(&metadata.balance_y));
        let reserves = borrow_global_mut<TokenPairReserve<X, Y>>(RESOURCE_ACCOUNT);
        let amount_x = (balance_x as u128) - (reserves.reserve_x as u128);
        let amount_y = (balance_y as u128) - (reserves.reserve_y as u128);

        //let fee_amount = mint_fee<X, Y>(reserves.reserve_x, reserves.reserve_y, metadata);

        //Need to add fee amount which have not been mint.
        let total_supply = total_lp_supply<X, Y>();
        let liquidity = if (total_supply == 0u128) {
            let sqrt = math::sqrt(amount_x * amount_y);
            assert!(sqrt > MINIMUM_LIQUIDITY, ERROR_INSUFFICIENT_LIQUIDITY_MINTED);
            let l = sqrt - MINIMUM_LIQUIDITY;
            // permanently lock the first MINIMUM_LIQUIDITY tokens
            mint_lp_to<X, Y>(RESOURCE_ACCOUNT, (MINIMUM_LIQUIDITY as u64), &metadata.mint_cap);
            l
        } else {
            let liquidity = math::min(amount_x * total_supply / (reserves.reserve_x as u128), amount_y * total_supply / (reserves.reserve_y as u128));
            assert!(liquidity > 0u128, ERROR_INSUFFICIENT_LIQUIDITY_MINTED);
            liquidity
        };


        let lp = mint_lp<X, Y>((liquidity as u64), &metadata.mint_cap);

        update<X, Y>(balance_x, balance_y, reserves);

        metadata.k_last = (reserves.reserve_x as u128) * (reserves.reserve_y as u128);

        (lp)
    }

    fun burn<X, Y>(lp_tokens: Coin<LPToken<X, Y>>): (Coin<X>, Coin<Y>) acquires TokenPairMetadata, TokenPairReserve {
        let metadata = borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT);
        let (balance_x, balance_y) = (coin::value(&metadata.balance_x), coin::value(&metadata.balance_y));
        let reserves = borrow_global_mut<TokenPairReserve<X, Y>>(RESOURCE_ACCOUNT);
        let liquidity = coin::value(&lp_tokens);

        //let fee_amount = mint_fee<X, Y>(reserves.reserve_x, reserves.reserve_y, metadata);

        //Need to add fee amount which have not been mint.
        let total_lp_supply = total_lp_supply<X, Y>();
        let amount_x = ((balance_x as u128) * (liquidity as u128) / (total_lp_supply as u128) as u64);
        let amount_y = ((balance_y as u128) * (liquidity as u128) / (total_lp_supply as u128) as u64);
        assert!(amount_x > 0 && amount_y > 0, ERROR_INSUFFICIENT_LIQUIDITY_BURNED);

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
            borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT);
        
        coin::merge(&mut metadata.balance_x, amount);
    }

    fun deposit_y<X, Y>(amount: Coin<Y>) acquires TokenPairMetadata {
        let metadata =
            borrow_global_mut<TokenPairMetadata<X, Y>>(RESOURCE_ACCOUNT);

        coin::merge(&mut metadata.balance_y, amount);
    }

    // Extract `amount` from this contract
    fun extract_x<X, Y>(amount: u64, metadata: &mut TokenPairMetadata<X, Y>): Coin<X> {
        assert!(coin::value<X>(&metadata.balance_x) > amount, ERROR_INSUFFICIENT_AMOUNT);
        coin::extract(&mut metadata.balance_x, amount)
    }

    // Extract `amount` from this contract
    fun extract_y<X, Y>(amount: u64, metadata: &mut TokenPairMetadata<X, Y>): Coin<Y> {
        assert!(coin::value<Y>(&metadata.balance_y) > amount, ERROR_INSUFFICIENT_AMOUNT);
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