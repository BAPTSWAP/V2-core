module baptswap_v2::router_v2 {

    use aptos_framework::aptos_coin::{AptosCoin as APT};
    use aptos_framework::coin;

    use aptos_std::type_info;

    use baptswap::swap_utils;

    use baptswap_v2::fee_on_transfer;
    use baptswap_v2::errors;
    use baptswap_v2::stake;
    use baptswap_v2::swap_v2;

    use bapt_framework::deployer;

    use std::signer;

    // Create a Pair from 2 Coins
    // Should revert if the pair is already created
    public entry fun create_pair<X, Y>(
        sender: &signer,
    ) {
        if (swap_utils::sort_token_type<X, Y>()) {
            swap_v2::create_pair<X, Y>(sender);
        } else {
            swap_v2::create_pair<Y, X>(sender);
        }
    }

    // Add fee on transfer to a pair; callable only by owners of X or Y
    public entry fun register_fee_on_transfer_in_a_pair<CoinType, X, Y>(sender: &signer, is_x_staked: bool) {
        swap_v2::add_fee_on_transfer_in_pair<CoinType, X, Y>(sender);
        stake::create_pool<CoinType, X, Y>(sender, is_x_staked);
    }

    public entry fun stake_tokens_in_pool<X, Y>(
        sender: &signer,
        amount: u64
    ) {
        assert_pair_is_created<X, Y>();
        if (swap_utils::sort_token_type<X, Y>()) {
            assert!(stake::is_pool_created<X, Y>(), errors::pool_not_created());
            stake::deposit<X, Y>(sender, amount);
        } else {
            assert!(stake::is_pool_created<Y, X>(), errors::pool_not_created());
            stake::deposit<Y, X>(sender, amount);
        }
    }

    public entry fun unstake_claim_rewards_from_pool<X, Y>(
        sender: &signer,
        amount: u64
    ) {
        assert_pair_is_created<X, Y>();
        assert!(((stake::is_pool_created<X, Y>() || stake::is_pool_created<Y, X>())), errors::pool_not_created());
        if (swap_utils::sort_token_type<X, Y>()) {
            stake::withdraw<X, Y>(sender, amount);
        } else {
            stake::withdraw<Y, X>(sender, amount);
        }
    }

    // claim team fees in a given pair; claimed by the counterpart token callable by token owners.
    // Fails if the accumualted fees are zero
    public entry fun claim_accumulated_team_fee<CoinType, X, Y>(sender: &signer) {
        assert_pair_is_created<X, Y>();
        assert!(type_info::type_of<CoinType>() == type_info::type_of<X>() || type_info::type_of<CoinType>() == type_info::type_of<Y>(), errors::coin_type_does_not_match_x_or_y());
        // based on type
        if (type_info::type_of<CoinType>() == type_info::type_of<X>()) {
            // assert the signer is the token owner
            assert!(deployer::is_coin_owner<X>(sender), errors::not_owner());
            let (team_balance_x, team_balance_y) = swap_v2::get_accumulated_team_fee<X, X, Y>();
            // if team balance x > 0, withdraw it and send it to the signer address
            if (team_balance_x > 0) {
                // assert accumulated fees are not zero 
                assert!(team_balance_x > 0, errors::insufficient_amount());
                // withdraw accumulated fees, and send it to the signer address
                let team_fee_x_coins = swap_v2::extract_team_fee_x<X, X, Y>(team_balance_x);
                coin::deposit<X>(fee_on_transfer::get_owner<X>(), team_fee_x_coins);
            };
            // if team balance y > 0, withdraw it and send it to the signer address
            if (team_balance_y > 0) {
                // assert accumulated fees are not zero 
                assert!(team_balance_y > 0, errors::insufficient_amount());
                // withdraw accumulated fees, and send it to the signer address
                let team_fee_y_coins = swap_v2::extract_team_fee_y<X, X, Y>(team_balance_y);
                coin::deposit<Y>(fee_on_transfer::get_owner<Y>(), team_fee_y_coins);
            };
        } else {
            // assert the signer is the token owner
            assert!(deployer::is_coin_owner<Y>(sender), errors::not_owner());
            let (team_balance_x, team_balance_y) = swap_v2::get_accumulated_team_fee<Y, X, Y>();
            // if team balance x > 0, withdraw it and send it to the signer address
            if (team_balance_x > 0) {
                // assert accumulated fees are not zero 
                assert!(team_balance_x > 0, errors::insufficient_amount());
                // withdraw accumulated fees, and send it to the signer address
                let team_fee_x_coins = swap_v2::extract_team_fee_x<Y, X, Y>(team_balance_x);
                coin::deposit<X>(fee_on_transfer::get_owner<X>(), team_fee_x_coins);
            };
            // if team balance y > 0, withdraw it and send it to the signer address
            if (team_balance_y > 0) {
                // assert accumulated fees are not zero 
                assert!(team_balance_y > 0, errors::insufficient_amount());
                // withdraw accumulated fees, and send it to the signer address
                let team_fee_y_coins = swap_v2::extract_team_fee_y<Y, X, Y>(team_balance_y);
                coin::deposit<Y>(fee_on_transfer::get_owner<Y>(), team_fee_y_coins);
            };
        }
    }

    // Add Liquidity, create pair if it's needed
    public entry fun add_liquidity<X, Y>(
        sender: &signer,
        amount_x_desired: u64,
        amount_y_desired: u64,
        amount_x_min: u64,
        amount_y_min: u64,
    ) {
        if (!(swap_v2::is_pair_created<X, Y>() || swap_v2::is_pair_created<Y, X>())) {
            create_pair<X, Y>(sender);
        };

        let amount_x;
        let amount_y;
        let _lp_amount;
        if (swap_utils::sort_token_type<X, Y>()) {
            (amount_x, amount_y, _lp_amount) = swap_v2::add_liquidity<X, Y>(sender, amount_x_desired, amount_y_desired);
            assert!(amount_x >= amount_x_min, errors::insufficient_x_amount());
            assert!(amount_y >= amount_y_min, errors::insufficient_y_amount());
        } else {
            (amount_y, amount_x, _lp_amount) = swap_v2::add_liquidity<Y, X>(sender, amount_y_desired, amount_x_desired);
            assert!(amount_x >= amount_x_min, errors::insufficient_x_amount());
            assert!(amount_y >= amount_y_min, errors::insufficient_y_amount());
        };
    }

    inline fun assert_pair_is_created<X, Y>(){
        assert!(swap_v2::is_pair_created<X, Y>() || swap_v2::is_pair_created<Y, X>(), errors::pair_not_created());
    }

    // TODO: if a pair not created, find route; should be used in swap 

    // Remove Liquidity
    public entry fun remove_liquidity<X, Y>(
        sender: &signer,
        liquidity: u64,
        amount_x_min: u64,
        amount_y_min: u64
    ) {
        let amount_x;
        let amount_y;
        if (swap_utils::sort_token_type<X, Y>()) {
            assert_pair_is_created<X, Y>();
            (amount_x, amount_y) = swap_v2::remove_liquidity<X, Y>(sender, liquidity);
            assert!(amount_x >= amount_x_min, errors::insufficient_x_amount());
            assert!(amount_y >= amount_y_min, errors::insufficient_y_amount());
        } else {
            assert_pair_is_created<Y, X>();
            (amount_y, amount_x) = swap_v2::remove_liquidity<Y, X>(sender, liquidity);
            assert!(amount_x >= amount_x_min, errors::insufficient_x_amount());
            assert!(amount_y >= amount_y_min, errors::insufficient_y_amount());
        }
    }

    fun add_swap_event_with_address_internal<X, Y>(
        sender_addr: address,
        amount_x_in: u64,
        amount_y_in: u64,
        amount_x_out: u64,
        amount_y_out: u64
    ) {
        if (swap_utils::sort_token_type<X, Y>()){
            swap_v2::add_swap_event_with_address<X, Y>(sender_addr, amount_x_in, amount_y_in, amount_x_out, amount_y_out);
        } else {
            swap_v2::add_swap_event_with_address<Y, X>(sender_addr, amount_y_in, amount_x_in, amount_y_out, amount_x_out);
        }
    }

    fun add_swap_event_internal<X, Y>(
        sender: &signer,
        amount_x_in: u64,
        amount_y_in: u64,
        amount_x_out: u64,
        amount_y_out: u64
    ) {
        let sender_addr = signer::address_of(sender);
        add_swap_event_with_address_internal<X, Y>(sender_addr, amount_x_in, amount_y_in, amount_x_out, amount_y_out);
    }

    // Swap exact input amount of X to maxiumin possible amount of Y
    public entry fun swap_exact_input<X, Y>(
        sender: &signer,
        x_in: u64,
        y_min_out: u64
    ) {
        swap_exact_input_internal<X, Y>(sender, x_in, y_min_out);
    }

    fun swap_exact_input_internal<X, Y>(sender: &signer, x_in: u64, y_min_out: u64): u64 {
        let y_out = if (swap_utils::sort_token_type<X, Y>()) {
            assert_pair_is_created<X, Y>();
            swap_v2::swap_exact_x_to_y<X, Y>(sender, x_in, signer::address_of(sender))
        } else {
            assert_pair_is_created<Y, X>();
            swap_v2::swap_exact_y_to_x<Y, X>(sender, x_in, signer::address_of(sender))
        };
        assert!(y_out >= y_min_out, errors::output_less_than_min());
        add_swap_event_internal<X, Y>(sender, x_in, 0, 0, y_out);

        y_out
    }

    // multi-hop
    // swap X for Y while pair<X, Y> doesn't exist, intermidiate token is Z
    
    public fun multi_hop_exact_input<X, Y, Z>(sender: &signer, x_in: u64, y_min_out: u64) {
        // if <X,Y> pair is created, swap X for Y
        if (swap_v2::is_pair_created<X, Y>()) { swap_exact_input<X, Y>(sender, x_in, y_min_out) }
        else {
            let z_in = swap_exact_input_internal<X, Z>(sender, x_in, 0);    // TODO: should not be 0
            swap_exact_input_internal<Z, Y>(sender, z_in, y_min_out);
        }
    }

    public entry fun swap_exact_input_with_z_as_intermidiate<X, Y, Z>(
        sender: &signer,
        x_in: u64,
        y_min_out: u64
    ) { multi_hop_exact_input<X, Y, Z>(sender, x_in, y_min_out); }

    // Z is APT
    public entry fun swap_exact_input_with_apt_as_intermidiate<X, Y>(
        sender: &signer,
        x_in: u64,
        y_min_out: u64
    ) { swap_exact_input_with_z_as_intermidiate<X, Y, APT>( sender, x_in, y_min_out) }
        
    // TODO: Z is BAPT

    // TODO: Z is USDC

    // Swap miniumn possible amount of X to exact output amount of Y
    public entry fun swap_exact_output<X, Y>(sender: &signer, y_out: u64, x_max_in: u64) {
        swap_exact_output_internal<X, Y>(sender, y_out, x_max_in);
    }

    public fun multi_hop_exact_output<X, Y, Z>(sender: &signer, y_out: u64, x_max_in: u64) {
        // if <X,Y> pair is created, swap X for Y
        if (swap_v2::is_pair_created<X, Y>()) { swap_exact_output<X, Y>(sender, y_out, x_max_in) }
        else {
            let z_out = swap_exact_output_internal<Z, Y>(sender, y_out, 0);    // TODO: should not be 0
            swap_exact_output_internal<X, Z>(sender, z_out, x_max_in); 
        }   
    }

    // TODO: Z is BAPT

    // TODO: Z is USDC

    fun swap_exact_output_internal<X, Y>(sender: &signer, y_out: u64, x_max_in: u64): u64 {
        let x_in = if (swap_utils::sort_token_type<X, Y>()) {
            assert_pair_is_created<X, Y>();
            let (rin, rout, _) = swap_v2::token_reserves<X, Y>();
            let total_fees = swap_v2::token_fees<X, Y>();
            let amount_in = swap_utils::get_amount_in(y_out, rin, rout, total_fees);
            swap_v2::swap_x_to_exact_y<X, Y>(sender, amount_in, y_out, signer::address_of(sender))
        } else {
            assert_pair_is_created<Y, X>();
            let (rout, rin, _) = swap_v2::token_reserves<Y, X>();
            let total_fees = swap_v2::token_fees<Y, X>();
            let amount_in = swap_utils::get_amount_in(y_out, rin, rout, total_fees);
            swap_v2::swap_y_to_exact_x<Y, X>(sender, amount_in, y_out, signer::address_of(sender))
        };
        assert!(x_in <= x_max_in, errors::input_more_than_max());
        add_swap_event_internal<X, Y>(sender, x_in, 0, 0, y_out);

        x_in
    }

    public entry fun swap_exact_output_with_z_as_intermidiate<X, Y, Z>(
        sender: &signer,
        y_out: u64,
        x_max_in: u64
    ) { multi_hop_exact_output<X, Y, Z>(sender, y_out, x_max_in); }

    // Z is APT
    public entry fun swap_exact_output_with_apt_as_intermidiate<X, Y>(
        sender: &signer,
        y_out: u64,
        x_max_in: u64
    ) { swap_exact_output_with_z_as_intermidiate<X, Y, APT>( sender, y_out, x_max_in) }

    // TODO: Z and W are APT and BAPT

    fun get_amount_in_internal<X, Y>(is_x_to_y:bool, y_out_amount: u64): u64 {
        if (is_x_to_y) {
            let (rin, rout, _) = swap_v2::token_reserves<X, Y>();
            let total_fees = swap_v2::token_fees<X, Y>();
            swap_utils::get_amount_in(y_out_amount, rin, rout, total_fees)
        } else {
            let (rout, rin, _) = swap_v2::token_reserves<Y, X>();
            let total_fees = swap_v2::token_fees<Y, X>();
            swap_utils::get_amount_in(y_out_amount, rin, rout, total_fees)
        }
    } 

    public fun get_amount_in<X, Y>(y_out_amount: u64): u64 {
        assert_pair_is_created<X, Y>();
        let is_x_to_y = swap_utils::sort_token_type<X, Y>();
        get_amount_in_internal<X, Y>(is_x_to_y, y_out_amount)
    }

    public entry fun register_lp<X, Y>(sender: &signer) {
        swap_v2::register_lp<X, Y>(sender);
    }

    public entry fun register_token<X>(sender: &signer) {
        coin::register<X>(sender);
    }
}
