/*

*/

module baptswap_v2::stake {

    use std::signer;

    // use aptos_std::debug;
    use aptos_std::type_info;

    use aptos_framework::coin;

    use baptswap::math;
    use baptswap::u256;

    use bapt_framework::deployer;

    use baptswap_v2::admin;
    use baptswap_v2::constants;
    use baptswap_v2::errors;
    use baptswap_v2::fee_on_transfer;
    use baptswap_v2::utils;

    friend baptswap_v2::router_v2;
    friend baptswap_v2::swap_v2;

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

    // Initialize rewards pool in a token pair
    public(friend) fun create_pool<CoinType, X, Y>(
        sender: &signer,
        is_x_staked: bool
    ) {
        let resource_signer = admin::get_resource_signer();
        let precision_factor = math::pow(10u128, 12u8);
        // based on CoinType
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            assert!(!exists<TokenPairRewardsPool<X, Y>>(constants::get_resource_account_address()), errors::already_initialized());
            // Assert initializer is the owner of either X or Y
            assert!(deployer::is_coin_owner<X>(sender), errors::not_owner());
            // Assert either of the fee_on_transfer is intialized 
            assert!(fee_on_transfer::is_created<X>(), errors::fee_on_transfer_not_initialized());
            // Create the pool resource
            let resource_signer = admin::get_resource_signer();
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
        } else {
            assert!(!exists<TokenPairRewardsPool<Y, X>>(constants::get_resource_account_address()), errors::already_initialized());
            // Assert initializer is the owner of either X or Y
            assert!(deployer::is_coin_owner<Y>(sender), errors::not_owner());
            // Assert either of the fee_on_transfer is intialized
            assert!(fee_on_transfer::is_created<Y>(), errors::fee_on_transfer_not_initialized());
            // Create the pool resource
            move_to<TokenPairRewardsPool<Y, X>>(
                &resource_signer,
                TokenPairRewardsPool {
                    staked_tokens: 0,
                    balance_x: coin::zero<Y>(),
                    balance_y: coin::zero<X>(),
                    magnified_dividends_per_share_x: 0,
                    magnified_dividends_per_share_y: 0,
                    precision_factor,
                    is_x_staked
                }
            );
        }
        
    }

    // stake tokens in a token pair given an amount and a token pair
    public(friend) fun deposit<X, Y>(
        sender: &signer,
        amount: u64
    ) acquires TokenPairRewardsPool, RewardsPoolUserInfo {
        let account_address = signer::address_of(sender);

        assert!(exists<TokenPairRewardsPool<X, Y>>(constants::get_resource_account_address()), errors::pool_not_created());
        let pool_info = borrow_global_mut<TokenPairRewardsPool<X, Y>>(constants::get_resource_account_address());

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
                    utils::check_or_register_coin_store<X>(sender);
                    let x_out = coin::extract<X>(&mut pool_info.balance_x, pending_reward_x);
                    coin::deposit(signer::address_of(sender), x_out);
                };

                if (pending_reward_y > 0) {
                    // Check/register y and extract from pool
                    utils::check_or_register_coin_store<Y>(sender);
                    let y_out = coin::extract<Y>(&mut pool_info.balance_y, pending_reward_y);
                    coin::deposit(signer::address_of(sender), y_out);
                };
            };

            if (amount > 0) {
                utils::transfer_in<X>(&mut user_info.staked_tokens, sender, amount);
                pool_info.staked_tokens = pool_info.staked_tokens + amount;
            };

            // Calculate and update user corrections
            calculate_and_update_user_corrections<X, Y, X>(sender, amount, pool_info);

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
                    utils::check_or_register_coin_store<X>(sender);
                    let x_out = coin::extract<X>(&mut pool_info.balance_x, pending_reward_x);
                    coin::deposit(signer::address_of(sender), x_out);
                };

                if (pending_reward_y > 0) {
                    // Check/register y and extract from pool
                    utils::check_or_register_coin_store<Y>(sender);
                    let y_out = coin::extract<Y>(&mut pool_info.balance_y, pending_reward_y);
                    coin::deposit(signer::address_of(sender), y_out);
                };
            };

            if (amount > 0) {
                utils::transfer_in<Y>(&mut user_info.staked_tokens, sender, amount);
                pool_info.staked_tokens = pool_info.staked_tokens + amount;
            };

            // Calculate and update user corrections
            calculate_and_update_user_corrections<X, Y, Y>(sender, amount, pool_info);
        };
    }

    // unstake tokens pair
    public(friend) entry fun withdraw<X, Y>(
        sender: &signer,
        amount: u64
    ) acquires TokenPairRewardsPool, RewardsPoolUserInfo {
        let account_address = signer::address_of(sender);
        assert!(exists<TokenPairRewardsPool<X, Y>>(constants::get_resource_account_address()), errors::pool_not_created());
        let pool_info = borrow_global_mut<TokenPairRewardsPool<X, Y>>(constants::get_resource_account_address());

        if (pool_info.is_x_staked) {
            calculate_pending_rewards<X, Y, X>(sender, amount, pool_info);
            // Transfer staked tokens out
            if (amount > 0) {
                let user_info = borrow_global_mut<RewardsPoolUserInfo<X, Y, X>>(account_address);
                utils::transfer_out<X>(&mut user_info.staked_tokens, sender, amount);
                pool_info.staked_tokens = pool_info.staked_tokens - amount;
                // if staked tokens is 0, initialize magnified_dividends_per_shares to 0
                if (pool_info.staked_tokens == 0) {
                    reset_magnified_dividends_per_share<X, Y>(pool_info);
                };
            };
            // Calculate and update user corrections
            calculate_and_update_user_corrections<X, Y, X>(sender, amount, pool_info);
        } else {
            calculate_pending_rewards<X, Y, Y>(sender, amount, pool_info);
            // Transfer staked tokens out
            if (amount > 0) {
                let user_info = borrow_global_mut<RewardsPoolUserInfo<X, Y, Y>>(account_address);
                utils::transfer_out<Y>(&mut user_info.staked_tokens, sender, amount);
                pool_info.staked_tokens = pool_info.staked_tokens - amount;
                // if staked tokens is 0, initialize magnified_dividends_per_shares to 0
                if (pool_info.staked_tokens == 0) {
                    reset_magnified_dividends_per_share<X, Y>(pool_info);
                };
            };
            // Calculate and update user corrections
            calculate_and_update_user_corrections<X, Y, Y>(sender, amount, pool_info);
        }
    }  

    inline fun reset_magnified_dividends_per_share<X, Y>(pool_info: &mut TokenPairRewardsPool<X, Y>) {
        pool_info.magnified_dividends_per_share_x = 0;
        pool_info.magnified_dividends_per_share_y = 0;
    }

    // claim rewards
    public(friend) entry fun claim_rewards<X, Y>(sender: &signer) acquires TokenPairRewardsPool, RewardsPoolUserInfo {
        assert!(exists<TokenPairRewardsPool<X, Y>>(constants::get_resource_account_address()), errors::pool_not_created());
        let pool_info = borrow_global_mut<TokenPairRewardsPool<X, Y>>(constants::get_resource_account_address());

        if (pool_info.is_x_staked) {
            calculate_pending_rewards<X, Y, X>(sender, 0, pool_info);
            // Calculate and update user corrections
            calculate_and_update_user_corrections<X, Y, X>(sender, 0, pool_info);
        } else {
            calculate_pending_rewards<X, Y, Y>(sender, 0, pool_info);
            // Calculate and update user corrections
            calculate_and_update_user_corrections<X, Y, Y>(sender, 0, pool_info);
        };
    }

    inline fun calculate_pending_rewards<X, Y, CoinType>(
        sender: &signer,
        amount: u64,
        pool_info: &mut TokenPairRewardsPool<X, Y>
    ) acquires TokenPairRewardsPool, RewardsPoolUserInfo {
        let account_address = signer::address_of(sender);
        // based on CoinType
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            let user_info = borrow_global_mut<RewardsPoolUserInfo<X, Y, X>>(account_address);
            assert!(coin::value<X>(&mut user_info.staked_tokens) >= amount, errors::insufficient_balance());

            // Calculate pending rewards
            let pending_reward_x = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_x, pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
            let pending_reward_y = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_y, pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);
            
            if (pending_reward_x > 0) {
                // Check/register x and extract from pool
                utils::check_or_register_coin_store<X>(sender);
                let x_out = coin::extract<X>(&mut pool_info.balance_x, pending_reward_x);
                coin::deposit(account_address, x_out);
            };

            if (pending_reward_y > 0) {
                // Check/register y and extract from pool
                utils::check_or_register_coin_store<Y>(sender);
                let y_out = coin::extract<Y>(&mut pool_info.balance_y, pending_reward_y);
                coin::deposit(account_address, y_out);
            };
        } else {
            let user_info = borrow_global_mut<RewardsPoolUserInfo<X, Y, Y>>(account_address);
            assert!(coin::value<Y>(&mut user_info.staked_tokens) >= amount, errors::insufficient_balance());

            // Calculate pending rewards
            let pending_reward_x = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_x, pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
            let pending_reward_y = cal_pending_reward(coin::value(&user_info.staked_tokens), user_info.reward_debt_y, pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);
            
            if (pending_reward_x > 0) {
                // Check/register x and extract from pool
                utils::check_or_register_coin_store<X>(sender);
                let x_out = coin::extract<X>(&mut pool_info.balance_x, pending_reward_x);
                coin::deposit(account_address, x_out);
            };

            if (pending_reward_y > 0) {
                // Check/register y and extract from pool
                utils::check_or_register_coin_store<Y>(sender);
                let y_out = coin::extract<Y>(&mut pool_info.balance_y, pending_reward_y);
                coin::deposit(account_address, y_out);
            };
        }
    }

    // Calculate and update user corrections
    inline fun calculate_and_update_user_corrections<X, Y, CoinType>(
        sender: &signer,
        amount: u64,
        pool_info: &mut TokenPairRewardsPool<X, Y>
    ) acquires TokenPairRewardsPool, RewardsPoolUserInfo {
        let account_address = signer::address_of(sender);
        // based on CoinType
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            assert!(exists<RewardsPoolUserInfo<X, Y, X>>(account_address), errors::no_stake());
            let user_info = borrow_global_mut<RewardsPoolUserInfo<X, Y, X>>(account_address);
            assert!(coin::value<X>(&mut user_info.staked_tokens) >= amount, errors::insufficient_balance());
            update_user_reward_debt<X, Y, X>(account_address, coin::value(&user_info.staked_tokens), pool_info);
        } else {
            assert!(exists<RewardsPoolUserInfo<X, Y, Y>>(account_address), errors::no_stake()); 
            let user_info = borrow_global_mut<RewardsPoolUserInfo<X, Y, Y>>(account_address);
            assert!(coin::value<Y>(&mut user_info.staked_tokens) >= amount, errors::insufficient_balance());
            update_user_reward_debt<X, Y, Y>(account_address, coin::value(&user_info.staked_tokens), pool_info);
        }
    }

    // update user reward debt
    inline fun update_user_reward_debt<X, Y, CoinType>(
        account_address: address,
        debt_amount: u64,
        pool_info: &mut TokenPairRewardsPool<X, Y>
    ) acquires TokenPairRewardsPool, RewardsPoolUserInfo {
        // based on CoinType
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            let user_info = borrow_global_mut<RewardsPoolUserInfo<X, Y, X>>(account_address);
            user_info.reward_debt_x = reward_debt(debt_amount, pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
            user_info.reward_debt_y = reward_debt(debt_amount, pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);
        } else {
            let user_info = borrow_global_mut<RewardsPoolUserInfo<X, Y, Y>>(account_address);
            user_info.reward_debt_x = reward_debt(debt_amount, pool_info.magnified_dividends_per_share_x, pool_info.precision_factor);
            user_info.reward_debt_y = reward_debt(debt_amount, pool_info.magnified_dividends_per_share_y, pool_info.precision_factor);
        }
    }

    // Calculate and adjust the maginified dividends per share
    public(friend) fun update_pool<X, Y>(reward_x: u64, reward_y: u64) acquires TokenPairRewardsPool {
        let pool_info = borrow_global_mut<TokenPairRewardsPool<X, Y>>(constants::get_resource_account_address());

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

    // ---------
    // Accessors
    // ---------  

    #[view]
    public fun is_pool_created<X, Y>(): bool {
        exists<TokenPairRewardsPool<X, Y>>(constants::get_resource_account_address())
    }

    #[view]
    public fun token_rewards_pool_info<X, Y>(): (u64, u64, u64, u128, u128, u128, bool) acquires TokenPairRewardsPool {
        assert!(is_pool_created<X, Y>(), errors::pool_not_created());

        let pool = borrow_global_mut<TokenPairRewardsPool<X, Y>>(constants::get_resource_account_address());

        (
            pool.staked_tokens, coin::value(&pool.balance_x), coin::value(&pool.balance_y),
            pool.magnified_dividends_per_share_x, pool.magnified_dividends_per_share_y,
            pool.precision_factor, pool.is_x_staked
        )
    }

    #[view]
    // Get current accumulated fees for a token pair
    public fun get_rewards_fees_accumulated<X, Y>(): (u64, u64) acquires TokenPairRewardsPool {
        assert!(is_pool_created<X, Y>(), errors::pool_not_created());
        let pool = borrow_global_mut<TokenPairRewardsPool<X, Y>>(constants::get_resource_account_address());

        (coin::value<X>(&pool.balance_x), coin::value<Y>(&pool.balance_y))
    }

    public(friend) fun distribute_rewards<X, Y>(
        rewards_x: coin::Coin<X>, 
        rewards_y: coin::Coin<Y>
    ) acquires TokenPairRewardsPool {
        // Update pool
        update_pool<X, Y>(coin::value<X>(&rewards_x), coin::value<Y>(&rewards_y));

        let rewards_pool = borrow_global_mut<TokenPairRewardsPool<X, Y>>(constants::get_resource_account_address());
        coin::merge(&mut rewards_pool.balance_x, rewards_x);
        coin::merge(&mut rewards_pool.balance_y, rewards_y);
    }
}