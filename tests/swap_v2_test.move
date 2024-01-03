#[test_only]
module baptswap_v2::swap_v2_test {
    use std::signer;
    use std::string;

    use alice::alice_coins::{Self, TestBAPT};
    use bob::bob_coins::{Self, TestMAU};

    use aptos_framework::account;
    use aptos_framework::aptos_coin::{Self, AptosCoin as APT};
    use aptos_framework::coin;
    use aptos_framework::genesis;
    use aptos_framework::managed_coin;

    use aptos_framework::resource_account;

    use aptos_std::debug;
    use aptos_std::math64::pow;
    
    use baptswap::math;
    use baptswap::swap_utils;

    use bapt_framework::deployer;

    use baptswap_v2::admin;
    use baptswap_v2::fee_on_transfer;
    use baptswap_v2::stake;
    use baptswap_v2::swap_v2::{Self, LPToken};
    use baptswap_v2::router_v2;

    use std::features;

    const MAX_U64: u64 = 18446744073709551615;
    const MINIMUM_LIQUIDITY: u128 = 1000;

    public fun setup_test(aptos_framework: signer, bapt_framework: &signer, dev: &signer, admin: &signer, treasury: &signer, resource_account: &signer, alice: &signer, bob: &signer) {
        let (aptos_coin_burn_cap, aptos_coin_mint_cap) = aptos_coin::initialize_for_test_without_aggregator_factory(&aptos_framework);
        features::change_feature_flags(&aptos_framework, vector[26], vector[]);
        account::create_account_for_test(signer::address_of(dev));
        account::create_account_for_test(signer::address_of(admin));
        // account::create_account_for_test(signer::address_of(treasury));
        resource_account::create_resource_account(dev, b"ggbapt_v2", x"");
        admin::init_test(resource_account);
        account::create_account_for_test(signer::address_of(bapt_framework));
        coin::register<APT>(bapt_framework);    // for the deployer
        deployer::init_test(bapt_framework, 1, signer::address_of(bapt_framework));

        // treasury
        // admin::offer_treasury_previliges(resource_account, signer::address_of(treasury), 123);
        // admin::claim_treasury_previliges(treasury, 123);

        account::create_account_for_test(signer::address_of(alice));
        account::create_account_for_test(signer::address_of(bob));
        managed_coin::register<APT>(alice);
        managed_coin::register<APT>(bob);
        coin::register<APT>(treasury);
        
        // mint some APT to be able to pay for the fee of generate_coin
        aptos_coin::mint(&aptos_framework, signer::address_of(alice), 100 * pow(10, 8));
        aptos_coin::mint(&aptos_framework, signer::address_of(bob), 100 * pow(10, 8));
        // destroy APT mint and burn caps
        coin::destroy_mint_cap<APT>(aptos_coin_mint_cap);
        coin::destroy_burn_cap<APT>(aptos_coin_burn_cap);

        coin::register<TestMAU>(alice);
        coin::register<TestBAPT>(bob);

        alice_coins::init_module(alice);
        bob_coins::init_module(bob);
    }

    public fun setup_test_with_genesis(aptos_framework: signer, bapt_framework: &signer, dev: &signer, admin: &signer, treasury: &signer, resource_account: &signer, alice: &signer, bob: &signer) {
        genesis::setup();
        setup_test(aptos_framework, bapt_framework, dev, admin, treasury, resource_account, alice, bob);
    }

    #[test(aptos_framework = @0x1, bapt_framework = @bapt_framework, dev = @dev_2, admin = @admin, treasury = @treasury, resource_account = @baptswap_v2, alice = @0x123, bob = @0x456)]
    fun test_fee_on_transfer(
        aptos_framework: signer,
        bapt_framework: &signer,
        dev: &signer,
        admin: &signer,
        treasury: &signer,
        resource_account: &signer,
        alice: &signer,
        bob: &signer,
    ) {
        setup_test_with_genesis(aptos_framework, bapt_framework, dev, admin, treasury, resource_account, alice, bob);
        // initialize fee on transfer for TestBAPT
        fee_on_transfer::initialize_fee_on_transfer_for_test<TestBAPT>(alice, 100, 100, 100);

        // create pair
        router_v2::create_pair<TestBAPT, APT>(alice);

        let alice_liquidity_x = 10 * pow(10, 8);
        let alice_liquidity_y = 10 * pow(10, 8);

        // alice provider liquidity for BAPT-APT
        router_v2::add_liquidity<APT, TestBAPT>(alice, 100000000, 100000000, 0, 0);

        let fee_on_transfer = fee_on_transfer::get_all_fee_on_transfer<TestBAPT>();
        debug::print<u128>(&fee_on_transfer);
        router_v2::swap_exact_input<APT, TestBAPT>(alice, 2 * pow(10, 6), 0);

        // register fee on transfer in the pairs
        router_v2::register_fee_on_transfer_in_a_pair<TestBAPT, APT, TestBAPT>(alice);
        // assert!(swap_v2::is_fee_on_transfer_registered<TestBAPT, TestBAPT, APT>(), 1);
        assert!(swap_v2::is_fee_on_transfer_registered<TestBAPT, APT, TestBAPT>(), 0);
        assert!(!swap_v2::is_fee_on_transfer_registered<APT, APT, TestBAPT>(), 0);

        // set new liquidity fee on transfer
        fee_on_transfer::set_liquidity_fee<TestBAPT>(alice, 200);
    }

    #[test(aptos_framework = @0x1, bapt_framework = @bapt_framework, dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, alice = @0x123, bob = @0x456)]
    fun test_swap_exact_input(
        aptos_framework: signer,
        bapt_framework: &signer, 
        dev: &signer,
        admin: &signer,
        resource_account: &signer,
        treasury: &signer,
        bob: &signer,
        alice: &signer,
    ) {
        setup_test_with_genesis(aptos_framework, bapt_framework, dev, admin, treasury, resource_account, alice, bob);

        coin::transfer<TestBAPT>(alice, signer::address_of(bob), 10 * pow(10, 8));
        coin::transfer<TestMAU>(bob, signer::address_of(alice), 10 * pow(10, 8));

        coin::register<TestMAU>(alice);
        coin::register<TestBAPT>(bob);
        coin::register<TestBAPT>(treasury);
        coin::register<TestMAU>(treasury);

        // create pair
        router_v2::create_pair<TestBAPT, TestMAU>(alice);
        // these are needed for transferring some of the fees since we want them in APT
        router_v2::create_pair<TestBAPT, APT>(alice);
        router_v2::create_pair<TestMAU, APT>(alice);

        let bob_liquidity_x = 10 * pow(10, 8);
        let bob_liquidity_y = 10 * pow(10, 8);
        let alice_liquidity_x = 2 * pow(10, 8);
        let alice_liquidity_y = 4 * pow(10, 8);

        // bob provider liquidity for BAPT-MAU
        router_v2::add_liquidity<TestBAPT, TestMAU>(bob, bob_liquidity_x, bob_liquidity_y, 0, 0);
        // for the other pairs as well
        router_v2::add_liquidity<TestBAPT, APT>(alice, alice_liquidity_x, alice_liquidity_y, 0, 0);
        router_v2::add_liquidity<TestMAU, APT>(bob, alice_liquidity_x, alice_liquidity_y, 0, 0);

        // TODO: assert liquidity pools equal to inputted ones
        let input_x = 2 * pow(10, 6);
        router_v2::swap_exact_input<TestBAPT, TestMAU>(alice, input_x, 0);
        // debug::print<address>(&swap_v2::fee_to());
    }

    #[test(aptos_framework = @0x1, bapt_framework = @bapt_framework, dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, alice = @0x123, bob = @0x456)]
    fun test_swap_exact_output(
        aptos_framework: signer,
        bapt_framework: &signer, 
        dev: &signer,
        admin: &signer,
        resource_account: &signer,
        treasury: &signer,
        bob: &signer,
        alice: &signer,
    ) {
        setup_test_with_genesis(aptos_framework, bapt_framework, dev, admin, treasury, resource_account, alice, bob);

        coin::transfer<TestBAPT>(alice, signer::address_of(bob), 10 * pow(10, 8));
        coin::transfer<TestMAU>(bob, signer::address_of(alice), 10 * pow(10, 8));

        coin::register<TestMAU>(alice);
        coin::register<TestBAPT>(bob);
        // coin::register<TestBAPT>(treasury);
        // coin::register<TestMAU>(treasury);

        // create pair
        router_v2::create_pair<TestBAPT, TestMAU>(alice);
        // these are needed for transferring some of the fees since we want them in APT
        router_v2::create_pair<TestBAPT, APT>(alice);
        router_v2::create_pair<TestMAU, APT>(alice);

        let bob_liquidity_x = 10 * pow(10, 8);
        let bob_liquidity_y = 10 * pow(10, 8);
        let alice_liquidity_x = 2 * pow(10, 8);
        let alice_liquidity_y = 4 * pow(10, 8);

        // bob provider liquidity for BAPT-MAU
        router_v2::add_liquidity<TestBAPT, TestMAU>(bob, bob_liquidity_x, bob_liquidity_y, 0, 0);
        // for the other pairs as well
        router_v2::add_liquidity<TestBAPT, APT>(alice, alice_liquidity_x, alice_liquidity_y, 0, 0);
        router_v2::add_liquidity<TestMAU, APT>(bob, alice_liquidity_x, alice_liquidity_y, 0, 0);
        
        router_v2::swap_exact_output<TestBAPT, TestMAU>(alice, 2 * pow(10, 6), MAX_U64);
    }

    #[test(aptos_framework = @0x1, bapt_framework = @bapt_framework, dev = @dev_2, admin = @admin, treasury = @treasury, resource_account = @baptswap_v2, alice = @0x123, bob = @0x456)]
    fun test_liquidity_addition_and_removal(
        aptos_framework: signer,
        bapt_framework: &signer,
        dev: &signer,
        admin: &signer,
        treasury: &signer,
        resource_account: &signer,
        alice: &signer,
        bob: &signer,
    ) {
        setup_test_with_genesis(aptos_framework, bapt_framework, dev, admin, treasury, resource_account, alice, bob);

        coin::transfer<TestBAPT>(alice, signer::address_of(bob), 10 * pow(10, 8));
        coin::transfer<TestMAU>(bob, signer::address_of(alice), 10 * pow(10, 8));

        // create pair
        router_v2::create_pair<TestBAPT, TestMAU>(alice);

        let bob_liquidity_x = 10 * pow(10, 8);
        let bob_liquidity_y = 10 * pow(10, 8);
        let alice_liquidity_x = 2 * pow(10, 8);
        let alice_liquidity_y = 4 * pow(10, 8);

        // provide liquidity 
        router_v2::add_liquidity<TestBAPT, TestMAU>(bob, bob_liquidity_x, bob_liquidity_y, 0, 0);
        let (x_reserve, y_reserve, _) = swap_v2::token_reserves<TestBAPT, TestMAU>();
        assert!(x_reserve == bob_liquidity_x, 1);
        assert!(y_reserve == bob_liquidity_y, 2);
        debug::print<u128>(&(swap_v2::total_lp_supply<TestBAPT, TestMAU>()));
        
        router_v2::add_liquidity<TestBAPT, TestMAU>(alice, alice_liquidity_x, alice_liquidity_y, 0, 0);
        let (x_reserve, y_reserve, _) = swap_v2::token_reserves<TestBAPT, TestMAU>();
        
        debug::print<u64>(&(bob_liquidity_y + alice_liquidity_y));
        debug::print<u64>(&y_reserve);

        // remove liquidity
        router_v2::remove_liquidity<TestBAPT, TestMAU>(bob, 1 * pow(10, 6), 0, 0);
        let (x_reserve, y_reserve, _) = swap_v2::token_reserves<TestBAPT, TestMAU>();
        assert!(x_reserve == bob_liquidity_x + alice_liquidity_x - 1 * pow(10, 6), 5);
        
        debug::print<u64>(&(bob_liquidity_y + alice_liquidity_y));
        debug::print<u64>(&y_reserve);

        router_v2::remove_liquidity<TestBAPT, TestMAU>(alice, 1 * pow(10, 6), 0, 0);
        let (x_reserve, y_reserve, _) = swap_v2::token_reserves<TestBAPT, TestMAU>();
        
        debug::print<u64>(&(bob_liquidity_y + alice_liquidity_y));
        debug::print<u64>(&y_reserve);
    }

    #[test(aptos_framework = @0x1, bapt_framework = @bapt_framework, dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, alice = @0x123, bob = @0x456)]
    fun test_stake_with_only_one_fee_transfer(
        aptos_framework: signer,
        bapt_framework: &signer, 
        dev: &signer,
        admin: &signer,
        resource_account: &signer,
        treasury: &signer,
        bob: &signer,
        alice: &signer,
    ) {
        setup_test_with_genesis(aptos_framework, bapt_framework, dev, admin, treasury, resource_account, alice, bob);
        coin::register<TestBAPT>(treasury);

        // create pair
        router_v2::create_pair<TestBAPT, APT>(alice);

        let alice_liquidity_x = 10 * pow(10, 8);
        let alice_liquidity_y = 10 * pow(10, 8);

        // alice provider liquidity for BAPT-APT
        router_v2::add_liquidity<APT, TestBAPT>(alice, alice_liquidity_x, alice_liquidity_y, 0, 0);

        // initialize fee on transfer of both tokens
        fee_on_transfer::initialize_fee_on_transfer_for_test<TestBAPT>(alice, 100, 100, 100);
        let fee_on_transfer = fee_on_transfer::get_all_fee_on_transfer<TestBAPT>();
        debug::print<u128>(&fee_on_transfer);
        coin::register<TestBAPT>(treasury);

        // register fee on transfer in the pairs
        router_v2::register_fee_on_transfer_in_a_pair<TestBAPT, TestBAPT, APT>(alice);
        // assert!(swap_v2::is_fee_on_transfer_registered<TestBAPT, TestBAPT, APT>(), 1);
        assert!(swap_v2::is_fee_on_transfer_registered<TestBAPT, APT, TestBAPT>(), 0);
        assert!(!swap_v2::is_fee_on_transfer_registered<APT, APT, TestBAPT>(), 0);

        // stake
        router_v2::stake_tokens_in_pool<TestBAPT, APT>(alice, 5 * pow(10, 8));

        coin::transfer<TestBAPT>(alice, signer::address_of(bob), 5 * pow(10, 8));

        debug::print<u64>(&coin::balance<APT>(signer::address_of(alice)));
        debug::print<u64>(&coin::balance<TestBAPT>(signer::address_of(alice)));
        // swap
        let input_x = 2 * pow(10, 6);
        router_v2::swap_exact_input<APT, TestBAPT>(bob, input_x, 0);
        // router_v2::swap_exact_output<APT, TestBAPT>(alice, 2 * pow(10, 5), MAX_U64);
        router_v2::swap_exact_input<TestBAPT, APT>(bob, input_x, 0);
        // router_v2::swap_exact_output<TestBAPT, APT>(alice, 2 * pow(10, 5), MAX_U64);
        
        debug::print<u64>(&coin::balance<APT>(signer::address_of(alice)));
        debug::print<u64>(&coin::balance<TestBAPT>(signer::address_of(alice)));
        
        // // Based on sorting of the pairs, the pair is TestBAPT-APT
        // assert!(swap_v2::is_pair_created<TestBAPT, APT>(), 1);
        
        // let (pool_balance_x, pool_balance_y) = stake::get_rewards_fees_accumulated<TestBAPT, APT>();
        
        // debug::print<u64>(&pool_balance_x);
        // debug::print<u64>(&pool_balance_y);
        
        // treasury wallet receives the treasury fee
        // debug::print<u64>(&coin::balance<TestBAPT>(@treasury));

        // router_v2::claim_accumulated_team_fee<TestBAPT, TestBAPT, APT>(alice);
        // assert!(alice_balance_x == 0 && alice_balance_y == 0, 125);
        // debug::print_stack_trace();

        // // get rewards pool info
        // let (staked_tokens, balance_x, balance_y, magnified_dividends_per_share_x, magnified_dividends_per_share_y, precision_factor, is_x_staked) = stake::token_rewards_pool_info<TestBAPT, APT>();
        // debug::print<u64>(&staked_tokens);
        // debug::print<u64>(&balance_x);
        // debug::print<u64>(&balance_y);
        // debug::print<u128>(&magnified_dividends_per_share_x);
        // debug::print<u128>(&magnified_dividends_per_share_y);

        // //// bob stake tokens
        // // coin::transfer<TestBAPT>(alice, signer::address_of(bob), 5 * pow(10, 8));
        // // router_v2::stake_tokens_in_pool<TestBAPT, APT>(bob, 5 * pow(10, 8));
        // // unstake 
        // router_v2::unstake_tokens_from_pool<TestBAPT, APT>(alice, 1 * pow(10, 8));
        // router_v2::unstake_tokens_from_pool<TestBAPT, APT>(alice, 1 * pow(10, 8));
        // router_v2::unstake_tokens_from_pool<TestBAPT, APT>(alice, 1 * pow(10, 8));
        // router_v2::unstake_tokens_from_pool<TestBAPT, APT>(alice, 1 * pow(10, 8));
        // router_v2::unstake_tokens_from_pool<TestBAPT, APT>(alice, 5 * pow(10, 7));
        // router_v2::unstake_tokens_from_pool<TestBAPT, APT>(alice, 1 * pow(10, 7));
        // router_v2::unstake_tokens_from_pool<TestBAPT, APT>(alice, 1 * pow(10, 7));
        // router_v2::unstake_tokens_from_pool<TestBAPT, APT>(alice, 1 * pow(10, 7));
        
        // // router_v2::unstake_tokens_from_pool<TestBAPT, APT>(alice, 1 * pow(10, 8));
        // let (staked_tokens, balance_x, balance_y, magnified_dividends_per_share_x, magnified_dividends_per_share_y, precision_factor, is_x_staked) = stake::token_rewards_pool_info<TestBAPT, APT>();
        // debug::print<u64>(&staked_tokens);
        // debug::print<u64>(&balance_x);
        // debug::print<u64>(&balance_y);
        // debug::print<u128>(&magnified_dividends_per_share_x);
        // debug::print<u128>(&magnified_dividends_per_share_y);
    }   

    #[test(aptos_framework = @0x1, bapt_framework = @bapt_framework, dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, alice = @0x123, bob = @0x456)]
    fun test_create_and_staked_tokens(
        aptos_framework: signer,
        bapt_framework: &signer, 
        dev: &signer,
        admin: &signer,
        resource_account: &signer,
        treasury: &signer,
        bob: &signer,
        alice: &signer,
    ) {
        setup_test_with_genesis(aptos_framework, bapt_framework, dev, admin, treasury, resource_account, alice, bob);
        coin::register<TestBAPT>(treasury);
        coin::register<TestMAU>(treasury);
        coin::transfer<TestBAPT>(alice, signer::address_of(bob), 10 * pow(10, 8));
        coin::transfer<TestMAU>(bob, signer::address_of(alice), 10 * pow(10, 8));

        // create pair
        router_v2::create_pair<TestBAPT, TestMAU>(alice);
        router_v2::create_pair<TestBAPT, APT>(alice);
        router_v2::create_pair<TestMAU, APT>(alice);

        let bob_liquidity_x = 10 * pow(10, 8);
        let bob_liquidity_y = 10 * pow(10, 8);
        let alice_liquidity_x = 15 * pow(10, 8);
        let alice_liquidity_y = 15 * pow(10, 8);

        // bob provider liquidity for BAPT-MAU
        router_v2::add_liquidity<TestBAPT, TestMAU>(bob, bob_liquidity_x, bob_liquidity_y, 0, 0);

        // initialize fee on transfer of both tokens
        fee_on_transfer::initialize_fee_on_transfer_for_test<TestBAPT>(alice, 10, 20, 30);
        fee_on_transfer::initialize_fee_on_transfer_for_test<TestMAU>(bob, 35, 55, 15);

        // register fee on transfer in the pairs
        router_v2::register_fee_on_transfer_in_a_pair<TestBAPT, TestBAPT, TestMAU>(alice);
        router_v2::register_fee_on_transfer_in_a_pair<TestMAU, TestBAPT, TestMAU>(bob);

        // rewards pool
        let response = stake::is_pool_created<TestBAPT, TestMAU>();
        debug::print<bool>(&response); 

        debug::print<u64>(&coin::balance<TestBAPT>(signer::address_of(alice)));
        debug::print<u64>(&coin::balance<TestMAU>(signer::address_of(bob)));

        router_v2::stake_tokens_in_pool<TestMAU, TestBAPT>(alice, 5 * pow(10, 8));
        router_v2::stake_tokens_in_pool<TestBAPT, TestMAU>(alice, 5 * pow(10, 8));

        debug::print<u64>(&coin::balance<TestBAPT>(signer::address_of(alice)));
        debug::print<u64>(&coin::balance<TestMAU>(signer::address_of(bob)));

        let (staked_tokens, balance_x, balance_y, magnified_dividends_per_share_x, magnified_dividends_per_share_y, precision_factor, is_x_staked) = stake::token_rewards_pool_info<TestBAPT, TestMAU>();

        assert!(staked_tokens == 5 * pow(10, 8), 130);

        let (pool_balance_x, pool_balance_y) = stake::get_rewards_fees_accumulated<TestBAPT, TestMAU>();

        assert!(pool_balance_x == 0, 126);
        assert!(pool_balance_y == 0, 126);

        let (pool_balance_x, pool_balance_y) = stake::get_rewards_fees_accumulated<TestBAPT, TestMAU>();

        debug::print<u64>(&pool_balance_x);
        debug::print<u64>(&pool_balance_y);

        // swap
        let input_x = 2 * pow(10, 6);

        let (reserve_x, reserve_y, _) = swap_v2::token_reserves<TestBAPT, TestMAU>();
        let liquidity = (swap_v2::total_lp_supply<TestBAPT, TestMAU>() as u64);

        debug::print<u64>(&liquidity);
        debug::print<u64>(&reserve_x);
        debug::print<u64>(&reserve_y);

        router_v2::swap_exact_input<TestBAPT, TestMAU>(alice, input_x, 0);
        debug::print<u64>(&coin::balance<TestMAU>(@treasury));
        debug::print<u64>(&coin::balance<TestBAPT>(@treasury));
        // assert!(coin::balance<TestMAU>(@treasury) = 2 * pow(10, 6), 111);
        router_v2::swap_exact_input<TestMAU, TestBAPT>(bob, input_x, 0);
        router_v2::swap_exact_input<TestBAPT, TestMAU>(alice, input_x, 0);
        // router_v2::swap_exact_output<TestBAPT, TestMAU>(alice, 1 * pow(10, 4), MAX_U64);
        let (staked_tokens, balance_x, balance_y, magnified_dividends_per_share_x, magnified_dividends_per_share_y, precision_factor, is_x_staked) = stake::token_rewards_pool_info<TestBAPT, TestMAU>();
        let liquidity = (swap_v2::total_lp_supply<TestBAPT, TestMAU>() as u64);
        
        debug::print<u64>(&liquidity);
        debug::print<u64>(&reserve_x);
        debug::print<u64>(&reserve_y);

        let (pool_balance_x, pool_balance_y) = stake::get_rewards_fees_accumulated<TestBAPT, TestMAU>();

        debug::print<u64>(&pool_balance_x);
        debug::print<u64>(&pool_balance_y);

        let (second_pool_balance_x, second_pool_balance_y) = stake::get_rewards_fees_accumulated<TestMAU, TestBAPT>();

        debug::print<u64>(&second_pool_balance_x);
        debug::print<u64>(&second_pool_balance_y);

        // treasury receives the swap fee
        debug::print<u64>(&coin::balance<TestBAPT>(@treasury));
        debug::print<u64>(&coin::balance<TestMAU>(@treasury));

        // add liquidity
        router_v2::add_liquidity<TestBAPT, APT>(alice, 2 * pow(10, 8), 2 * pow(10, 8), 0, 0);
        // register fee on transfer in the pair TestBAPT-APT
        router_v2::register_fee_on_transfer_in_a_pair<TestBAPT, TestBAPT, APT>(alice);
        // set new fee on transfer fees
        fee_on_transfer::set_liquidity_fee<TestBAPT>(alice, 500);
        fee_on_transfer::set_rewards_fee<TestBAPT>(alice, 500);
        fee_on_transfer::set_team_fee<TestBAPT>(alice, 500);
    }

    #[test(aptos_framework = @0x1, bapt_framework = @bapt_framework, dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, alice = @0x123, bob = @0x456)]
    // execute multiple swaps and assert treasury balance
    fun test_treasury_balance(
        aptos_framework: signer,
        bapt_framework: &signer, 
        dev: &signer,
        admin: &signer,
        resource_account: &signer,
        treasury: &signer,
        bob: &signer,
        alice: &signer,
    ) {
        setup_test_with_genesis(aptos_framework, bapt_framework, dev, admin, treasury, resource_account, alice, bob);

        coin::transfer<TestBAPT>(alice, signer::address_of(bob), 10 * pow(10, 8));
        coin::transfer<TestMAU>(bob, signer::address_of(alice), 10 * pow(10, 8));

        coin::register<TestMAU>(alice);
        coin::register<TestBAPT>(bob);

        // create pair
        router_v2::create_pair<TestBAPT, TestMAU>(alice);

        // initialize fee on transfer of both tokens
        fee_on_transfer::initialize_fee_on_transfer_for_test<TestBAPT>(alice, 0, 100, 100);
        fee_on_transfer::initialize_fee_on_transfer_for_test<TestMAU>(bob, 0, 200, 200);

        // register fee on transfer in the pairs
        router_v2::register_fee_on_transfer_in_a_pair<TestBAPT, TestBAPT, TestMAU>(alice);
        router_v2::register_fee_on_transfer_in_a_pair<TestMAU, TestBAPT, TestMAU>(bob);

        let bob_liquidity_x = 10 * pow(10, 8);
        let bob_liquidity_y = 10 * pow(10, 8);
        let alice_liquidity_x = 2 * pow(10, 8);
        let alice_liquidity_y = 4 * pow(10, 8);

        // bob provider liquidity for BAPT-MAU
        router_v2::add_liquidity<TestBAPT, TestMAU>(bob, bob_liquidity_x, bob_liquidity_y, 0, 0);

        let input_x = 2 * pow(10, 6);
        // TestBAPT is X and TestMAU is Y -> Fees are in TestMAU
        router_v2::swap_exact_input<TestBAPT, TestMAU>(alice, input_x, 0);

        // TestMAU is X and TestBAPT is Y -> Fees are in TestBAPT
        router_v2::swap_exact_input<TestMAU, TestBAPT>(bob, input_x, 0);

        // treasury wallet receives the treasury fee
        debug::print<u64>(&coin::balance<TestBAPT>(@treasury));
        debug::print<u64>(&coin::balance<TestMAU>(@treasury));

        // remove some liquidity
        router_v2::remove_liquidity<TestBAPT, TestMAU>(bob, 1 * pow(10, 6), 0, 0);
    }
        
    #[test(aptos_framework = @0x1, bapt_framework = @bapt_framework, dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, alice = @0x123, bob = @0x456)]
    // test ownerships transfer
    fun test_ownership_transfer(
        aptos_framework: signer,
        bapt_framework: &signer, 
        dev: &signer,
        admin: &signer,
        resource_account: &signer,
        treasury: &signer,
        bob: &signer,
        alice: &signer
    ) {
        setup_test_with_genesis(aptos_framework, bapt_framework, dev, admin, treasury, resource_account, alice, bob);

        // transfer admin previliges to bob
        admin::offer_admin_previliges(admin, signer::address_of(bob));
        admin::claim_admin_previliges(bob);
        assert!(admin::get_admin() == signer::address_of(bob), 1);

        // transfer admin previliges back to admin
        admin::offer_admin_previliges(bob, signer::address_of(admin));
        admin::claim_admin_previliges(admin);
        assert!(admin::get_admin() == signer::address_of(admin), 2);

        // transfer admin previliges to alice but alice rejects it
        admin::offer_admin_previliges(admin, signer::address_of(alice));
        admin::reject_admin_previliges(alice);
        assert!(admin::get_admin() == signer::address_of(admin), 3);

        // transfer treasury previliges to alice
        admin::offer_treasury_previliges(admin, signer::address_of(alice));
        admin::claim_treasury_previliges(alice);
        assert!(admin::get_treasury_address() == signer::address_of(alice), 4);

        // transfer treasury previliges to bob but bob rejects it
        admin::offer_treasury_previliges(admin, signer::address_of(bob));
        admin::reject_treasury_previliges(bob);
        assert!(admin::get_treasury_address() == signer::address_of(alice), 6);
    }

    #[test(aptos_framework = @0x1, bapt_framework = @bapt_framework, dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, alice = @0x123, bob = @0x456)]
    // test update tiers
    fun test_update_tiers(
        aptos_framework: signer,
        bapt_framework: &signer, 
        dev: &signer,
        admin: &signer,
        resource_account: &signer,
        treasury: &signer,
        bob: &signer,
        alice: &signer
    ) {
        setup_test_with_genesis(aptos_framework, bapt_framework, dev, admin, treasury, resource_account, alice, bob);

        coin::transfer<TestBAPT>(alice, signer::address_of(bob), 10 * pow(10, 8));
        coin::transfer<TestMAU>(bob, signer::address_of(alice), 10 * pow(10, 8));
        coin::register<TestMAU>(alice);
        coin::register<TestBAPT>(bob);

        // create pair
        router_v2::create_pair<TestBAPT, TestMAU>(alice);
        // add liquidity
        let bob_liquidity_y = 10 * pow(10, 8);
        let alice_liquidity_x = 2 * pow(10, 8);
        router_v2::add_liquidity<TestBAPT, TestMAU>(bob, alice_liquidity_x, bob_liquidity_y, 0, 0);

        // update tiers to popular traded
        router_v2::update_fee_tier<admin::PopularTraded, TestBAPT, TestMAU>(admin);
        admin::is_valid_tier<admin::PopularTraded>();
        let (popular_traded_liquidity_fee, popular_traded_treasury_fee) = admin::get_popular_traded_tier_fees();
        let total_popular_traded_fee = popular_traded_liquidity_fee + popular_traded_treasury_fee;
        assert!(swap_v2::token_fees<TestBAPT, TestMAU>() == (total_popular_traded_fee), 1);

        // update tiers to stable
        router_v2::update_fee_tier<admin::Stable, TestBAPT, TestMAU>(admin);
        admin::is_valid_tier<admin::Stable>();
        let (stable_liquidity_fee, stable_treasury_fee) = admin::get_stable_tier_fees();
        let total_stable_fee = stable_liquidity_fee + stable_treasury_fee;
        assert!(swap_v2::token_fees<TestBAPT, TestMAU>() == (total_stable_fee), 2);

        // update tiers to very stable
        router_v2::update_fee_tier<admin::VeryStable, TestBAPT, TestMAU>(admin);
        admin::is_valid_tier<admin::VeryStable>();
        let (very_stable_liquidity_fee, very_stable_treasury_fee) = admin::get_very_stable_tier_fees();
        let total_very_stable_fee = very_stable_liquidity_fee + very_stable_treasury_fee;
        assert!(swap_v2::token_fees<TestBAPT, TestMAU>() == (total_very_stable_fee), 3);

        // update tiers back to universal
        router_v2::update_fee_tier<admin::Universal, TestBAPT, TestMAU>(admin);
        admin::is_valid_tier<admin::Universal>();
        let (universal_liquidity_fee, universal_treasury_fee) = admin::get_universal_tier_fees();
        let total_universal_fee = universal_liquidity_fee + universal_treasury_fee;
        assert!(swap_v2::token_fees<TestBAPT, TestMAU>() == (total_universal_fee), 4);

        // add fee on transfer
        fee_on_transfer::initialize_fee_on_transfer_for_test<TestBAPT>(alice, 100, 100, 100);
        fee_on_transfer::initialize_fee_on_transfer_for_test<TestMAU>(bob, 100, 100, 100);
        router_v2::register_fee_on_transfer_in_a_pair<TestBAPT, TestBAPT, TestMAU>(alice);
        router_v2::register_fee_on_transfer_in_a_pair<TestMAU, TestBAPT, TestMAU>(bob);

        // calculate fees
        let (dex_liquidity_fee, dex_treasury_fee) = swap_v2::get_dex_fees_in_a_pair<TestBAPT, TestMAU>();
        let dex_fees = dex_liquidity_fee + dex_treasury_fee;
        let bapt_fee_on_transfer = fee_on_transfer::get_all_fee_on_transfer<TestBAPT>();
        let mau_fee_on_transfer = fee_on_transfer::get_all_fee_on_transfer<TestMAU>();
        let expected_fees = dex_fees + bapt_fee_on_transfer + mau_fee_on_transfer;
        // debug::print<u128>(&(expected_fees));
        // debug::print<u128>(&(swap_v2::token_fees<TestBAPT, TestMAU>()));
        assert!(swap_v2::token_fees<TestBAPT, TestMAU>() == (expected_fees), 5);

        // update tiers to popular traded
        router_v2::update_fee_tier<admin::PopularTraded, TestBAPT, TestMAU>(admin);
        let (popular_traded_liquidity_fee, popular_traded_treasury_fee) = admin::get_popular_traded_tier_fees();
        let total_popular_traded_fee = popular_traded_liquidity_fee + popular_traded_treasury_fee;
        let expected_updated_fees = bapt_fee_on_transfer + mau_fee_on_transfer + total_popular_traded_fee;
        assert!(swap_v2::token_fees<TestBAPT, TestMAU>() == (expected_updated_fees), 6);

        // update tiers to stable
        router_v2::update_fee_tier<admin::Stable, TestBAPT, TestMAU>(admin);
        let (stable_liquidity_fee, stable_treasury_fee) = admin::get_stable_tier_fees();
        let total_stable_fee = stable_liquidity_fee + stable_treasury_fee;
        let expected_updated_fees_from_stable = bapt_fee_on_transfer + mau_fee_on_transfer + total_stable_fee;
        assert!(swap_v2::token_fees<TestBAPT, TestMAU>() == (expected_updated_fees_from_stable), 7);

        // update tiers to very stable
        router_v2::update_fee_tier<admin::VeryStable, TestBAPT, TestMAU>(admin);
        let (very_stable_liquidity_fee, very_stable_treasury_fee) = admin::get_very_stable_tier_fees();
        let total_very_stable_fee = very_stable_liquidity_fee + very_stable_treasury_fee;
        let expected_updated_fees_from_very_stable = bapt_fee_on_transfer + mau_fee_on_transfer + total_very_stable_fee;
        assert!(swap_v2::token_fees<TestBAPT, TestMAU>() == (expected_updated_fees_from_very_stable), 8);

        // update tiers back to universal
        router_v2::update_fee_tier<admin::Universal, TestBAPT, TestMAU>(admin);
        let (universal_liquidity_fee, universal_treasury_fee) = admin::get_universal_tier_fees();
        let total_universal_fee = universal_liquidity_fee + universal_treasury_fee;
        let expected_updated_fees_from_universal = bapt_fee_on_transfer + mau_fee_on_transfer + total_universal_fee;
        assert!(swap_v2::token_fees<TestBAPT, TestMAU>() == (expected_updated_fees_from_universal), 9);

        // update dex fees universally and then update tiers to popular traded
        admin::set_dex_liquidity_fee(admin, 0);
        admin::set_dex_treasury_fee(admin, 0);
        assert!(admin::get_dex_fees() == 0, 10);
        router_v2::update_fee_tier<admin::PopularTraded, TestBAPT, TestMAU>(admin);
        let (popular_traded_liquidity_fee, popular_traded_treasury_fee) = admin::get_popular_traded_tier_fees();
        let total_popular_traded_fee = popular_traded_liquidity_fee + popular_traded_treasury_fee;
        let expected_updated_fees_from_popular_traded = bapt_fee_on_transfer + mau_fee_on_transfer + total_popular_traded_fee;
        assert!(swap_v2::token_fees<TestBAPT, TestMAU>() == (expected_updated_fees_from_popular_traded), 10);
    }

    #[test(aptos_framework = @0x1, bapt_framework = @bapt_framework, dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, alice = @0x123, bob = @0x456)]
    // test multi-hop swap functions
    fun test_multi_hop_swaps(
        aptos_framework: signer,
        bapt_framework: &signer, 
        dev: &signer,
        admin: &signer,
        resource_account: &signer,
        treasury: &signer,
        bob: &signer,
        alice: &signer
    ) {
        setup_test_with_genesis(aptos_framework, bapt_framework, dev, admin, treasury, resource_account, alice, bob);

        coin::transfer<TestBAPT>(alice, signer::address_of(bob), 10 * pow(10, 8));
        coin::transfer<TestMAU>(bob, signer::address_of(alice), 10 * pow(10, 8));

        coin::register<TestMAU>(alice);
        coin::register<TestBAPT>(bob);

        // create pair
        // router_v2::create_pair<TestBAPT, TestMAU>(alice);
        router_v2::create_pair<TestBAPT, APT>(alice);
        router_v2::create_pair<TestMAU, APT>(alice);

        let bob_liquidity_x = 2 * pow(10, 8);
        let bob_liquidity_y = 2 * pow(10, 8);
        let alice_liquidity_x = 2 * pow(10, 8);
        let alice_liquidity_y = 2 * pow(10, 8);

        // Add liquidity for BAPT-APT and MAU-APT
        router_v2::add_liquidity<TestBAPT, APT>(bob, bob_liquidity_x, bob_liquidity_y, 0, 0);
        router_v2::add_liquidity<TestMAU, APT>(alice, alice_liquidity_x, alice_liquidity_y, 0, 0);

        // swap without fee on transfer 
        let input_x = 2 * pow(10, 6);
        assert!(!swap_v2::is_pair_created<TestBAPT, TestMAU>() && !swap_v2::is_pair_created<TestMAU, TestBAPT>(), 1);
        router_v2::swap_exact_input<TestBAPT, APT>(alice, 10 * pow(10, 6), 0);
        router_v2::swap_exact_input<TestMAU, APT>(alice, 10 * pow(10, 6), 0);
        router_v2::swap_exact_input_with_one_intermediate_coin<TestBAPT, TestMAU, APT>(alice, 10 * pow(10, 6), 0);
        router_v2::swap_exact_input_with_apt_as_intermidiate<TestMAU, TestBAPT>(alice, input_x, 0);

        // swap with fee on transfer
        fee_on_transfer::initialize_fee_on_transfer_for_test<TestBAPT>(alice, 10, 20, 30);
        fee_on_transfer::initialize_fee_on_transfer_for_test<TestMAU>(bob, 35, 55, 15);

        router_v2::register_fee_on_transfer_in_a_pair<TestBAPT, TestBAPT, APT>(alice);
        router_v2::register_fee_on_transfer_in_a_pair<TestMAU, APT, TestMAU>(bob);

        router_v2::swap_exact_input_with_one_intermediate_coin<TestBAPT, TestMAU, APT>(alice, input_x, 0);
        router_v2::swap_exact_input_with_apt_as_intermidiate<TestMAU, TestBAPT>(alice, input_x, 0);

        // TODO: test swap_exact_input_with_two_intermediate_coins
    }

    // #[test(dev = @dev_2_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // fun test_add_liquidity(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, alice, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, alice, 100 * pow(10, 8));

    //     let bob_liquidity_x = 5 * pow(10, 8);
    //     let bob_liquidity_y = 10 * pow(10, 8);
    //     let alice_liquidity_x = 2 * pow(10, 8);
    //     let alice_liquidity_y = 4 * pow(10, 8);

    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, bob_liquidity_x, bob_liquidity_y, 0, 0);
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(alice, alice_liquidity_x, alice_liquidity_y, 0, 0);

    //     let (balance_y, balance_x) = swap_v2::token_balances<TestBUSD, TestCAKE>();
    //     let (reserve_y, reserve_x, _) = swap_v2::token_reserves<TestBUSD, TestCAKE>();
    //     let resource_account_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(resource_account));
    //     let bob_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(bob));
    //     let alice_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(alice));

    //     let resource_account_suppose_lp_balance = MINIMUM_LIQUIDITY;
    //     let bob_suppose_lp_balance = math::sqrt(((bob_liquidity_x as u128) * (bob_liquidity_y as u128))) - MINIMUM_LIQUIDITY;
    //     let total_supply = bob_suppose_lp_balance + MINIMUM_LIQUIDITY;
    //     let alice_suppose_lp_balance = math::min((alice_liquidity_x as u128) * total_supply / (bob_liquidity_x as u128), (alice_liquidity_y as u128) * total_supply / (bob_liquidity_y as u128));

    //     assert!(balance_x == bob_liquidity_x + alice_liquidity_x, 99);
    //     assert!(reserve_x == bob_liquidity_x + alice_liquidity_x, 98);
    //     assert!(balance_y == bob_liquidity_y + alice_liquidity_y, 97);
    //     assert!(reserve_y == bob_liquidity_y + alice_liquidity_y, 96);

    //     assert!(bob_lp_balance == (bob_suppose_lp_balance as u64), 95);
    //     assert!(alice_lp_balance == (alice_suppose_lp_balance as u64), 94);
    //     assert!(resource_account_lp_balance == (resource_account_suppose_lp_balance as u64), 93);
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // fun test_add_liquidity_with_less_x_ratio(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 200 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 200 * pow(10, 8));

    //     let bob_liquidity_x = 5 * pow(10, 8);
    //     let bob_liquidity_y = 10 * pow(10, 8);

    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, bob_liquidity_x, bob_liquidity_y, 0, 0);

    //     let bob_token_x_before_balance = coin::balance<TestCAKE>(signer::address_of(bob));
    //     let bob_token_y_before_balance = coin::balance<TestBUSD>(signer::address_of(bob));

    //     let bob_add_liquidity_x = 1 * pow(10, 8);
    //     let bob_add_liquidity_y = 5 * pow(10, 8);
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, bob_add_liquidity_x, bob_add_liquidity_y, 0, 0);

    //     let bob_added_liquidity_x = bob_add_liquidity_x;
    //     let bob_added_liquidity_y = (bob_add_liquidity_x as u128) * (bob_liquidity_y as u128) / (bob_liquidity_x as u128);

    //     let bob_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(bob));
    //     let bob_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(bob));
    //     let bob_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(bob));
    //     let resource_account_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(resource_account));

    //     let resource_account_suppose_lp_balance = MINIMUM_LIQUIDITY;
    //     let bob_suppose_lp_balance = math::sqrt(((bob_liquidity_x as u128) * (bob_liquidity_y as u128))) - MINIMUM_LIQUIDITY;
    //     let total_supply = bob_suppose_lp_balance + MINIMUM_LIQUIDITY;
    //     bob_suppose_lp_balance = bob_suppose_lp_balance + math::min((bob_add_liquidity_x as u128) * total_supply / (bob_liquidity_x as u128), (bob_add_liquidity_y as u128) * total_supply / (bob_liquidity_y as u128));

    //     assert!((bob_token_x_before_balance - bob_token_x_after_balance) == (bob_added_liquidity_x as u64), 99);
    //     assert!((bob_token_y_before_balance - bob_token_y_after_balance) == (bob_added_liquidity_y as u64), 98);
    //     assert!(bob_lp_balance == (bob_suppose_lp_balance as u64), 97);
    //     assert!(resource_account_lp_balance == (resource_account_suppose_lp_balance as u64), 96);
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // #[expected_failure(abort_code = 3)]
    // fun test_add_liquidity_with_less_x_ratio_and_less_than_y_min(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 200 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 200 * pow(10, 8));

    //     let initial_reserve_x = 5 * pow(10, 8);
    //     let initial_reserve_y = 10 * pow(10, 8);

    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, initial_reserve_x, initial_reserve_y, 0, 0);

    //     let bob_add_liquidity_x = 1 * pow(10, 8);
    //     let bob_add_liquidity_y = 5 * pow(10, 8);
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, bob_add_liquidity_x, bob_add_liquidity_y, 0, 4 * pow(10, 8));
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // fun test_add_liquidity_with_less_y_ratio(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 200 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 200 * pow(10, 8));

    //     let bob_liquidity_x = 5 * pow(10, 8);
    //     let bob_liquidity_y = 10 * pow(10, 8);

    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, bob_liquidity_x, bob_liquidity_y, 0, 0);

    //     let bob_token_x_before_balance = coin::balance<TestCAKE>(signer::address_of(bob));
    //     let bob_token_y_before_balance = coin::balance<TestBUSD>(signer::address_of(bob));

    //     let bob_add_liquidity_x = 5 * pow(10, 8);
    //     let bob_add_liquidity_y = 4 * pow(10, 8);
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, bob_add_liquidity_x, bob_add_liquidity_y, 0, 0);

    //     let bob_added_liquidity_x = (bob_add_liquidity_y as u128) * (bob_liquidity_x as u128) / (bob_liquidity_y as u128);
    //     let bob_added_liquidity_y = bob_add_liquidity_y;

    //     let bob_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(bob));
    //     let bob_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(bob));
    //     let bob_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(bob));
    //     let resource_account_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(resource_account));

    //     let resource_account_suppose_lp_balance = MINIMUM_LIQUIDITY;
    //     let bob_suppose_lp_balance = math::sqrt(((bob_liquidity_x as u128) * (bob_liquidity_y as u128))) - MINIMUM_LIQUIDITY;
    //     let total_supply = bob_suppose_lp_balance + MINIMUM_LIQUIDITY;
    //     bob_suppose_lp_balance = bob_suppose_lp_balance + math::min((bob_add_liquidity_x as u128) * total_supply / (bob_liquidity_x as u128), (bob_add_liquidity_y as u128) * total_supply / (bob_liquidity_y as u128));


    //     assert!((bob_token_x_before_balance - bob_token_x_after_balance) == (bob_added_liquidity_x as u64), 99);
    //     assert!((bob_token_y_before_balance - bob_token_y_after_balance) == (bob_added_liquidity_y as u64), 98);
    //     assert!(bob_lp_balance == (bob_suppose_lp_balance as u64), 97);
    //     assert!(resource_account_lp_balance == (resource_account_suppose_lp_balance as u64), 96);
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // #[expected_failure(abort_code = 2)]
    // fun test_add_liquidity_with_less_y_ratio_and_less_than_x_min(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 200 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 200 * pow(10, 8));

    //     let initial_reserve_x = 5 * pow(10, 8);
    //     let initial_reserve_y = 10 * pow(10, 8);

    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, initial_reserve_x, initial_reserve_y, 0, 0);

    //     let bob_add_liquidity_x = 5 * pow(10, 8);
    //     let bob_add_liquidity_y = 4 * pow(10, 8);
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, bob_add_liquidity_x, bob_add_liquidity_y, 5 * pow(10, 8), 0);
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12341, alice = @0x12342)]
    // fun test_remove_liquidity(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));
    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, alice, 100 * pow(10, 8));

    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, alice, 100 * pow(10, 8));

    //     let bob_add_liquidity_x = 5 * pow(10, 8);
    //     let bob_add_liquidity_y = 10 * pow(10, 8);

    //     let alice_add_liquidity_x = 2 * pow(10, 8);
    //     let alice_add_liquidity_y = 4 * pow(10, 8);

    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, bob_add_liquidity_x, bob_add_liquidity_y, 0, 0);
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(alice, alice_add_liquidity_x, alice_add_liquidity_y, 0, 0);

    //     let bob_suppose_lp_balance = math::sqrt(((bob_add_liquidity_x as u128) * (bob_add_liquidity_y as u128))) - MINIMUM_LIQUIDITY;
    //     let suppose_total_supply = bob_suppose_lp_balance + MINIMUM_LIQUIDITY;
    //     let alice_suppose_lp_balance = math::min((alice_add_liquidity_x as u128) * suppose_total_supply / (bob_add_liquidity_x as u128), (alice_add_liquidity_y as u128) * suppose_total_supply / (bob_add_liquidity_y as u128));
    //     suppose_total_supply = suppose_total_supply + alice_suppose_lp_balance;
    //     let suppose_reserve_x = bob_add_liquidity_x + alice_add_liquidity_x;
    //     let suppose_reserve_y = bob_add_liquidity_y + alice_add_liquidity_y;

    //     let bob_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(bob));
    //     let alice_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(alice));

    //     assert!((bob_suppose_lp_balance as u64) == bob_lp_balance, 99);
    //     assert!((alice_suppose_lp_balance as u64) == alice_lp_balance, 98);

    //     let alice_token_x_before_balance = coin::balance<TestCAKE>(signer::address_of(alice));
    //     let alice_token_y_before_balance = coin::balance<TestBUSD>(signer::address_of(alice));
    //     let bob_token_x_before_balance = coin::balance<TestCAKE>(signer::address_of(bob));
    //     let bob_token_y_before_balance = coin::balance<TestBUSD>(signer::address_of(bob));

    //     router_v2::remove_liquidity<TestCAKE, TestBUSD>(bob, (bob_suppose_lp_balance as u64), 0, 0);
    //     let bob_remove_liquidity_x = ((suppose_reserve_x) as u128) * bob_suppose_lp_balance / suppose_total_supply;
    //     let bob_remove_liquidity_y = ((suppose_reserve_y) as u128) * bob_suppose_lp_balance / suppose_total_supply;
    //     suppose_total_supply = suppose_total_supply - bob_suppose_lp_balance;
    //     suppose_reserve_x = suppose_reserve_x - (bob_remove_liquidity_x as u64);
    //     suppose_reserve_y = suppose_reserve_y - (bob_remove_liquidity_y as u64);

    //     router_v2::remove_liquidity<TestCAKE, TestBUSD>(alice, (alice_suppose_lp_balance as u64), 0, 0);
    //     let alice_remove_liquidity_x = ((suppose_reserve_x) as u128) * alice_suppose_lp_balance / suppose_total_supply;
    //     let alice_remove_liquidity_y = ((suppose_reserve_y) as u128) * alice_suppose_lp_balance / suppose_total_supply;
    //     suppose_reserve_x = suppose_reserve_x - (alice_remove_liquidity_x as u64);
    //     suppose_reserve_y = suppose_reserve_y - (alice_remove_liquidity_y as u64);

    //     let alice_lp_after_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(alice));
    //     let bob_lp_after_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(bob));
    //     let alice_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(alice));
    //     let alice_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(alice));
    //     let bob_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(bob));
    //     let bob_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(bob));
    //     let (balance_y, balance_x) = swap_v2::token_balances<TestBUSD, TestCAKE>();
    //     let (reserve_y, reserve_x, _) = swap_v2::token_reserves<TestBUSD, TestCAKE>();
    //     let total_supply = std::option::get_with_default(
    //         &coin::supply<LPToken<TestBUSD, TestCAKE>>(),
    //         0u128
    //     );

    //     assert!((alice_token_x_after_balance - alice_token_x_before_balance) == (alice_remove_liquidity_x as u64), 97);
    //     assert!((alice_token_y_after_balance - alice_token_y_before_balance) == (alice_remove_liquidity_y as u64), 96);
    //     assert!((bob_token_x_after_balance - bob_token_x_before_balance) == (bob_remove_liquidity_x as u64), 95);
    //     assert!((bob_token_y_after_balance - bob_token_y_before_balance) == (bob_remove_liquidity_y as u64), 94);
    //     assert!(alice_lp_after_balance == 0, 93);
    //     assert!(bob_lp_after_balance == 0, 92);
    //     assert!(balance_x == suppose_reserve_x, 91);
    //     assert!(balance_y == suppose_reserve_y, 90);
    //     assert!(reserve_x == suppose_reserve_x, 89);
    //     assert!(reserve_y == suppose_reserve_y, 88);
    //     assert!(total_supply == MINIMUM_LIQUIDITY, 87);
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, user1 = @0x12341, user2 = @0x12342, user3 = @0x12343, user4 = @0x12344)]
    // fun test_remove_liquidity_with_more_user(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     user1: &signer,
    //     user2: &signer,
    //     user3: &signer,
    //     user4: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(user1));
    //     account::create_account_for_test(signer::address_of(user2));
    //     account::create_account_for_test(signer::address_of(user3));
    //     account::create_account_for_test(signer::address_of(user4));
    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, user1, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, user2, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, user3, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, user4, 100 * pow(10, 8));

    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, user1, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, user2, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, user3, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, user4, 100 * pow(10, 8));

    //     let user1_add_liquidity_x = 5 * pow(10, 8);
    //     let user1_add_liquidity_y = 10 * pow(10, 8);

    //     let user2_add_liquidity_x = 2 * pow(10, 8);
    //     let user2_add_liquidity_y = 4 * pow(10, 8);

    //     let user3_add_liquidity_x = 25 * pow(10, 8);
    //     let user3_add_liquidity_y = 50 * pow(10, 8);

    //     let user4_add_liquidity_x = 45 * pow(10, 8);
    //     let user4_add_liquidity_y = 90 * pow(10, 8);

    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(user1, user1_add_liquidity_x, user1_add_liquidity_y, 0, 0);
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(user2, user2_add_liquidity_x, user2_add_liquidity_y, 0, 0);
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(user3, user3_add_liquidity_x, user3_add_liquidity_y, 0, 0);
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(user4, user4_add_liquidity_x, user4_add_liquidity_y, 0, 0);

    //     let user1_suppose_lp_balance = math::sqrt(((user1_add_liquidity_x as u128) * (user1_add_liquidity_y as u128))) - MINIMUM_LIQUIDITY;
    //     let suppose_total_supply = user1_suppose_lp_balance + MINIMUM_LIQUIDITY;
    //     let suppose_reserve_x = user1_add_liquidity_x;
    //     let suppose_reserve_y = user1_add_liquidity_y;
    //     let user2_suppose_lp_balance = math::min((user2_add_liquidity_x as u128) * suppose_total_supply / (suppose_reserve_x as u128), (user2_add_liquidity_y as u128) * suppose_total_supply / (suppose_reserve_y as u128));
    //     suppose_total_supply = suppose_total_supply + user2_suppose_lp_balance;
    //     suppose_reserve_x = suppose_reserve_x + user2_add_liquidity_x;
    //     suppose_reserve_y = suppose_reserve_y + user2_add_liquidity_y;
    //     let user3_suppose_lp_balance = math::min((user3_add_liquidity_x as u128) * suppose_total_supply / (suppose_reserve_x as u128), (user3_add_liquidity_y as u128) * suppose_total_supply / (suppose_reserve_y as u128));
    //     suppose_total_supply = suppose_total_supply + user3_suppose_lp_balance;
    //     suppose_reserve_x = suppose_reserve_x + user3_add_liquidity_x;
    //     suppose_reserve_y = suppose_reserve_y + user3_add_liquidity_y;
    //     let user4_suppose_lp_balance = math::min((user4_add_liquidity_x as u128) * suppose_total_supply / (suppose_reserve_x as u128), (user4_add_liquidity_y as u128) * suppose_total_supply / (suppose_reserve_y as u128));
    //     suppose_total_supply = suppose_total_supply + user4_suppose_lp_balance;
    //     suppose_reserve_x = suppose_reserve_x + user4_add_liquidity_x;
    //     suppose_reserve_y = suppose_reserve_y + user4_add_liquidity_y;

    //     let user1_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(user1));
    //     let user2_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(user2));
    //     let user3_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(user3));
    //     let user4_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(user4));

    //     assert!((user1_suppose_lp_balance as u64) == user1_lp_balance, 99);
    //     assert!((user2_suppose_lp_balance as u64) == user2_lp_balance, 98);
    //     assert!((user3_suppose_lp_balance as u64) == user3_lp_balance, 97);
    //     assert!((user4_suppose_lp_balance as u64) == user4_lp_balance, 96);

    //     let user1_token_x_before_balance = coin::balance<TestCAKE>(signer::address_of(user1));
    //     let user1_token_y_before_balance = coin::balance<TestBUSD>(signer::address_of(user1));
    //     let user2_token_x_before_balance = coin::balance<TestCAKE>(signer::address_of(user2));
    //     let user2_token_y_before_balance = coin::balance<TestBUSD>(signer::address_of(user2));
    //     let user3_token_x_before_balance = coin::balance<TestCAKE>(signer::address_of(user3));
    //     let user3_token_y_before_balance = coin::balance<TestBUSD>(signer::address_of(user3));
    //     let user4_token_x_before_balance = coin::balance<TestCAKE>(signer::address_of(user4));
    //     let user4_token_y_before_balance = coin::balance<TestBUSD>(signer::address_of(user4));

    //     router_v2::remove_liquidity<TestCAKE, TestBUSD>(user1, (user1_suppose_lp_balance as u64), 0, 0);
    //     let user1_remove_liquidity_x = ((suppose_reserve_x) as u128) * user1_suppose_lp_balance / suppose_total_supply;
    //     let user1_remove_liquidity_y = ((suppose_reserve_y) as u128) * user1_suppose_lp_balance / suppose_total_supply;
    //     suppose_total_supply = suppose_total_supply - user1_suppose_lp_balance;
    //     suppose_reserve_x = suppose_reserve_x - (user1_remove_liquidity_x as u64);
    //     suppose_reserve_y = suppose_reserve_y - (user1_remove_liquidity_y as u64);

    //     router_v2::remove_liquidity<TestCAKE, TestBUSD>(user2, (user2_suppose_lp_balance as u64), 0, 0);
    //     let user2_remove_liquidity_x = ((suppose_reserve_x) as u128) * user2_suppose_lp_balance / suppose_total_supply;
    //     let user2_remove_liquidity_y = ((suppose_reserve_y) as u128) * user2_suppose_lp_balance / suppose_total_supply;
    //     suppose_total_supply = suppose_total_supply - user2_suppose_lp_balance;
    //     suppose_reserve_x = suppose_reserve_x - (user2_remove_liquidity_x as u64);
    //     suppose_reserve_y = suppose_reserve_y - (user2_remove_liquidity_y as u64);

    //     router_v2::remove_liquidity<TestCAKE, TestBUSD>(user3, (user3_suppose_lp_balance as u64), 0, 0);
    //     let user3_remove_liquidity_x = ((suppose_reserve_x) as u128) * user3_suppose_lp_balance / suppose_total_supply;
    //     let user3_remove_liquidity_y = ((suppose_reserve_y) as u128) * user3_suppose_lp_balance / suppose_total_supply;
    //     suppose_total_supply = suppose_total_supply - user3_suppose_lp_balance;
    //     suppose_reserve_x = suppose_reserve_x - (user3_remove_liquidity_x as u64);
    //     suppose_reserve_y = suppose_reserve_y - (user3_remove_liquidity_y as u64);

    //     router_v2::remove_liquidity<TestCAKE, TestBUSD>(user4, (user4_suppose_lp_balance as u64), 0, 0);
    //     let user4_remove_liquidity_x = ((suppose_reserve_x) as u128) * user4_suppose_lp_balance / suppose_total_supply;
    //     let user4_remove_liquidity_y = ((suppose_reserve_y) as u128) * user4_suppose_lp_balance / suppose_total_supply;
    //     suppose_reserve_x = suppose_reserve_x - (user4_remove_liquidity_x as u64);
    //     suppose_reserve_y = suppose_reserve_y - (user4_remove_liquidity_y as u64);

    //     let user1_lp_after_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(user1));
    //     let user2_lp_after_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(user2));
    //     let user3_lp_after_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(user3));
    //     let user4_lp_after_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(user4));

    //     let user1_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(user1));
    //     let user1_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(user1));
    //     let user2_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(user2));
    //     let user2_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(user2));
    //     let user3_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(user3));
    //     let user3_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(user3));
    //     let user4_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(user4));
    //     let user4_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(user4));

    //     let (balance_y, balance_x) = swap_v2::token_balances<TestBUSD, TestCAKE>();
    //     let (reserve_y, reserve_x, _) = swap_v2::token_reserves<TestBUSD, TestCAKE>();
    //     let total_supply = swap_v2::total_lp_supply<TestBUSD, TestCAKE>();

    //     assert!((user1_token_x_after_balance - user1_token_x_before_balance) == (user1_remove_liquidity_x as u64), 95);
    //     assert!((user1_token_y_after_balance - user1_token_y_before_balance) == (user1_remove_liquidity_y as u64), 94);
    //     assert!((user2_token_x_after_balance - user2_token_x_before_balance) == (user2_remove_liquidity_x as u64), 93);
    //     assert!((user2_token_y_after_balance - user2_token_y_before_balance) == (user2_remove_liquidity_y as u64), 92);
    //     assert!((user3_token_x_after_balance - user3_token_x_before_balance) == (user3_remove_liquidity_x as u64), 91);
    //     assert!((user3_token_y_after_balance - user3_token_y_before_balance) == (user3_remove_liquidity_y as u64), 90);
    //     assert!((user4_token_x_after_balance - user4_token_x_before_balance) == (user4_remove_liquidity_x as u64), 89);
    //     assert!((user4_token_y_after_balance - user4_token_y_before_balance) == (user4_remove_liquidity_y as u64), 88);
    //     assert!(user1_lp_after_balance == 0, 87);
    //     assert!(user2_lp_after_balance == 0, 86);
    //     assert!(user3_lp_after_balance == 0, 85);
    //     assert!(user4_lp_after_balance == 0, 84);
    //     assert!(balance_x == suppose_reserve_x, 83);
    //     assert!(balance_y == suppose_reserve_y, 82);
    //     assert!(reserve_x == suppose_reserve_x, 81);
    //     assert!(reserve_y == suppose_reserve_y, 80);
    //     assert!(total_supply == MINIMUM_LIQUIDITY, 79);
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12341, alice = @0x12342)]
    // #[expected_failure(abort_code = 10)]
    // fun test_remove_liquidity_imbalance(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));
    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, alice, 100 * pow(10, 8));

    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, alice, 100 * pow(10, 8));

    //     let bob_liquidity_x = 5 * pow(10, 8);
    //     let bob_liquidity_y = 10 * pow(10, 8);

    //     let alice_liquidity_x = 1;
    //     let alice_liquidity_y = 2;

    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, bob_liquidity_x, bob_liquidity_y, 0, 0);
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(alice, alice_liquidity_x, alice_liquidity_y, 0, 0);

    //     let bob_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(bob));
    //     let alice_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(alice));

    //     router_v2::remove_liquidity<TestCAKE, TestBUSD>(bob, bob_lp_balance, 0, 0);
    //     // expect the small amount will result one of the amount to be zero and unable to remove liquidity
    //     router_v2::remove_liquidity<TestCAKE, TestBUSD>(alice, alice_lp_balance, 0, 0);
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // fun test_swap_exact_input(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, alice, 100 * pow(10, 8));

    //     let initial_reserve_x = 5 * pow(10, 8);
    //     let initial_reserve_y = 10 * pow(10, 8);
    //     let input_x = 2 * pow(10, 8);
    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, initial_reserve_x, initial_reserve_y, 0, 0);
    //     let bob_suppose_lp_balance = math::sqrt(((initial_reserve_x as u128) * (initial_reserve_y as u128))) - MINIMUM_LIQUIDITY;
    //     let suppose_total_supply = bob_suppose_lp_balance + MINIMUM_LIQUIDITY;

    //     // let bob_lp_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(bob));
    //     let alice_token_x_before_balance = coin::balance<TestCAKE>(signer::address_of(alice));

    //     router_v2::swap_exact_input<TestCAKE, TestBUSD>(alice, input_x, 0);

    //     let (treasury_balance_x, treasury_balance_y, team_balance_x, team_balance_y, pool_balance_x, pool_balance_y) = swap_v2::token_fees_accumulated<TestBUSD, TestCAKE>();

    //     assert!(treasury_balance_y == 2 * pow(10, 5), 125);
    //     // assert!(team_balance_y == 4 * pow(10, 6), 126);
    //     // assert!(pool_balance_y == 8 * pow(10, 6), 127);

    //     let alice_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(alice));
    //     let alice_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(alice));

    //     let total_fees = swap_v2::token_fees<TestBUSD, TestCAKE>();

    //     let amount_x_in_with_fee = input_x - (((input_x as u128) * 10u128 / 10000u128) as u64);

    //     let output_y = calc_output_using_input(input_x, initial_reserve_x, initial_reserve_y, total_fees);
    //     let new_reserve_x = initial_reserve_x + amount_x_in_with_fee;
    //     let new_reserve_y = initial_reserve_y - (output_y as u64);

    //     let (reserve_y, reserve_x, _) = swap_v2::token_reserves<TestBUSD, TestCAKE>();
    //     assert!((alice_token_x_before_balance - alice_token_x_after_balance) == input_x, 99);
    //     assert!(alice_token_y_after_balance == (output_y as u64), 98);
    //     assert!(reserve_x == new_reserve_x, 97);
    //     assert!(reserve_y == new_reserve_y, 96);

    //     let bob_token_x_before_balance = coin::balance<TestCAKE>(signer::address_of(bob));
    //     let bob_token_y_before_balance = coin::balance<TestBUSD>(signer::address_of(bob));

    //     router_v2::remove_liquidity<TestCAKE, TestBUSD>(bob, (bob_suppose_lp_balance as u64), 0, 0);

    //     let bob_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(bob));
    //     let bob_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(bob));

    //     // let suppose_k_last = ((initial_reserve_x * initial_reserve_y) as u128);
    //     // let suppose_k = ((new_reserve_x * new_reserve_y) as u128);
    //     // let suppose_fee_amount = calc_fee_lp(suppose_total_supply, suppose_k, suppose_k_last);
    //     // suppose_total_supply = suppose_total_supply + suppose_fee_amount;

    //     let bob_remove_liquidity_x = ((new_reserve_x) as u128) * bob_suppose_lp_balance / suppose_total_supply;
    //     let bob_remove_liquidity_y = ((new_reserve_y) as u128) * bob_suppose_lp_balance / suppose_total_supply;
    //     new_reserve_x = new_reserve_x - (bob_remove_liquidity_x as u64);
    //     new_reserve_y = new_reserve_y - (bob_remove_liquidity_y as u64);
    //     suppose_total_supply = suppose_total_supply - bob_suppose_lp_balance;

    //     assert!((bob_token_x_after_balance - bob_token_x_before_balance) == (bob_remove_liquidity_x as u64), 95);
    //     assert!((bob_token_y_after_balance - bob_token_y_before_balance) == (bob_remove_liquidity_y as u64), 94);

    //     // swap_v2::withdraw_fee<TestCAKE, TestBUSD>(treasury);
    //     // let treasury_lp_after_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(treasury));
    //     // router_v2::remove_liquidity<TestCAKE, TestBUSD>(treasury, (suppose_fee_amount as u64), 0, 0);
    //     // let treasury_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(treasury));
    //     // let treasury_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(treasury));

    //     // let treasury_remove_liquidity_x = ((new_reserve_x) as u128) * suppose_fee_amount / suppose_total_supply;
    //     // let treasury_remove_liquidity_y = ((new_reserve_y) as u128) * suppose_fee_amount / suppose_total_supply;

    //     // assert!(treasury_lp_after_balance == (suppose_fee_amount as u64), 93);
    //     // assert!(treasury_token_x_after_balance == (treasury_remove_liquidity_x as u64), 92);
    //     // assert!(treasury_token_y_after_balance == (treasury_remove_liquidity_y as u64), 91);
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // fun test_swap_exact_input_overflow(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, MAX_U64);
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, MAX_U64);
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, alice, MAX_U64);

    //     let initial_reserve_x = MAX_U64 / pow(10, 4);
    //     let initial_reserve_y = MAX_U64 / pow(10, 4);
    //     let input_x = pow(10, 9) * pow(10, 8);
    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, initial_reserve_x, initial_reserve_y, 0, 0);

    //     router_v2::swap_exact_input<TestCAKE, TestBUSD>(alice, input_x, 0);
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // #[expected_failure(abort_code = 65542)]
    // fun test_swap_exact_input_with_not_enough_liquidity(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 1000 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 1000 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, alice, 1000 * pow(10, 8));

    //     let initial_reserve_x = 100 * pow(10, 8);
    //     let initial_reserve_y = 200 * pow(10, 8);
    //     let input_x = 10000 * pow(10, 8);
    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, initial_reserve_x, initial_reserve_y, 0, 0);


    //     router_v2::swap_exact_input<TestCAKE, TestBUSD>(alice, input_x, 0);
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // #[expected_failure(abort_code = 0)]
    // fun test_swap_exact_input_under_min_output(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, alice, 100 * pow(10, 8));

    //     let initial_reserve_x = 5 * pow(10, 8);
    //     let initial_reserve_y = 10 * pow(10, 8);
    //     let input_x = 2 * pow(10, 8);
    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, initial_reserve_x, initial_reserve_y, 0, 0);

    //     let total_fees = swap_v2::token_fees<TestBUSD, TestCAKE>();

    //     let output_y = calc_output_using_input(input_x, initial_reserve_x, initial_reserve_y, total_fees);
    //     router_v2::swap_exact_input<TestCAKE, TestBUSD>(alice, input_x, ((output_y + 1) as u64));
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // fun test_swap_exact_output(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, alice, 100 * pow(10, 8));

    //     let initial_reserve_x = 5 * pow(10, 8);
    //     let initial_reserve_y = 10 * pow(10, 8);
    //     let output_y = 166319299;
    //     let input_x_max = 15 * pow(10, 7);

    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, initial_reserve_x, initial_reserve_y, 0, 0);
    //     let bob_suppose_lp_balance = math::sqrt(((initial_reserve_x as u128) * (initial_reserve_y as u128))) - MINIMUM_LIQUIDITY;
    //     let suppose_total_supply = bob_suppose_lp_balance + MINIMUM_LIQUIDITY;

    //     let alice_token_x_before_balance = coin::balance<TestCAKE>(signer::address_of(alice));

    //     router_v2::swap_exact_output<TestCAKE, TestBUSD>(alice, output_y, input_x_max);

    //     let (treasury_balance_x, treasury_balance_y, team_balance_x, team_balance_y, pool_balance_x, pool_balance_y) = swap_v2::token_fees_accumulated<TestBUSD, TestCAKE>();

    //     assert!(treasury_balance_y > 0, 125);
    //     // assert!(team_balance_x == 4 * pow(10, 6), 126);
    //     // assert!(pool_balance_x == 8 * pow(10, 6), 127);

    //     let alice_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(alice));
    //     let alice_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(alice));

    //     let total_fees = swap_v2::token_fees<TestBUSD, TestCAKE>();

    //     let input_x = calc_input_using_output(output_y, initial_reserve_x, initial_reserve_y, total_fees);

    //     let amount_x_in_with_fee = input_x - (((input_x as u128) * 610u128 / 10000u128));

    //     let new_reserve_x = initial_reserve_x + (amount_x_in_with_fee as u64);
    //     let new_reserve_y = initial_reserve_y - output_y;

    //     let (reserve_y, reserve_x, _) = swap_v2::token_reserves<TestBUSD, TestCAKE>();
    //     assert!((alice_token_x_before_balance - alice_token_x_after_balance) == (input_x as u64), 99);
    //     assert!(alice_token_y_after_balance == output_y, 98);
    //     assert!(reserve_x * reserve_y >= new_reserve_x * new_reserve_y, 97);
    //     // assert!(reserve_y == new_reserve_y, 96);

    //     let bob_token_x_before_balance = coin::balance<TestCAKE>(signer::address_of(bob));
    //     let bob_token_y_before_balance = coin::balance<TestBUSD>(signer::address_of(bob));

    //     router_v2::remove_liquidity<TestCAKE, TestBUSD>(bob, (bob_suppose_lp_balance as u64), 0, 0);

    //     let bob_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(bob));
    //     let bob_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(bob));

    //     // let suppose_k_last = ((initial_reserve_x * initial_reserve_y) as u128);
    //     // let suppose_k = ((new_reserve_x * new_reserve_y) as u128);
    //     // let suppose_fee_amount = calc_fee_lp(suppose_total_supply, suppose_k, suppose_k_last);
    //     // suppose_total_supply = suppose_total_supply + suppose_fee_amount;

    //     let bob_remove_liquidity_x = ((new_reserve_x) as u128) * bob_suppose_lp_balance / suppose_total_supply;
    //     let bob_remove_liquidity_y = ((new_reserve_y) as u128) * bob_suppose_lp_balance / suppose_total_supply;
    //     new_reserve_x = new_reserve_x - (bob_remove_liquidity_x as u64);
    //     new_reserve_y = new_reserve_y - (bob_remove_liquidity_y as u64);
    //     suppose_total_supply = suppose_total_supply - bob_suppose_lp_balance;

    //     // assert!((bob_token_x_after_balance - bob_token_x_before_balance) == (bob_remove_liquidity_x as u64), 95);
    //     // assert!((bob_token_y_after_balance - bob_token_y_before_balance) == (bob_remove_liquidity_y as u64), 94);

    //     // swap_v2::withdraw_fee<TestCAKE, TestBUSD>(treasury);
    //     // let treasury_lp_after_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(treasury));
    //     // router_v2::remove_liquidity<TestCAKE, TestBUSD>(treasury, (suppose_fee_amount as u64), 0, 0);
    //     // let treasury_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(treasury));
    //     // let treasury_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(treasury));

    //     // let treasury_remove_liquidity_x = ((new_reserve_x) as u128) * suppose_fee_amount / suppose_total_supply;
    //     // let treasury_remove_liquidity_y = ((new_reserve_y) as u128) * suppose_fee_amount / suppose_total_supply;

    //     // assert!(treasury_lp_after_balance == (suppose_fee_amount as u64), 93);
    //     // assert!(treasury_token_x_after_balance == (treasury_remove_liquidity_x as u64), 92);
    //     // assert!(treasury_token_y_after_balance == (treasury_remove_liquidity_y as u64), 91);
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // #[expected_failure]
    // fun test_swap_exact_output_with_not_enough_liquidity(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 1000 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 1000 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, alice, 1000 * pow(10, 8));

    //     let initial_reserve_x = 100 * pow(10, 8);
    //     let initial_reserve_y = 200 * pow(10, 8);
    //     let output_y = 1000 * pow(10, 8);
    //     let input_x_max = 1000 * pow(10, 8);

    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, initial_reserve_x, initial_reserve_y, 0, 0);

    //     router_v2::swap_exact_output<TestCAKE, TestBUSD>(alice, output_y, input_x_max);
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // #[expected_failure(abort_code = 1)]
    // fun test_swap_exact_output_excceed_max_input(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 1000 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 1000 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, alice, 1000 * pow(10, 8));

    //     let initial_reserve_x = 50 * pow(10, 8);
    //     let initial_reserve_y = 100 * pow(10, 8);
    //     let output_y = 166319299;

    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, initial_reserve_x, initial_reserve_y, 0, 0);

    //     let total_fees = swap_v2::token_fees<TestBUSD, TestCAKE>();

    //     let input_x = calc_input_using_output(output_y, initial_reserve_x, initial_reserve_y, total_fees);
    //     router_v2::swap_exact_output<TestCAKE, TestBUSD>(alice, output_y, ((input_x - 1) as u64));
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // fun test_swap_x_to_exact_y_direct_external(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, alice, 100 * pow(10, 8));

    //     let initial_reserve_x = 5 * pow(10, 8);
    //     let initial_reserve_y = 10 * pow(10, 8);
    //     let output_y = 166319299;
    //     // let input_x_max = 1 * pow(10, 8);

    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, initial_reserve_x, initial_reserve_y, 0, 0);
    //     let bob_suppose_lp_balance = math::sqrt(((initial_reserve_x as u128) * (initial_reserve_y as u128))) - MINIMUM_LIQUIDITY;
    //     let suppose_total_supply = bob_suppose_lp_balance + MINIMUM_LIQUIDITY;

    //     let alice_addr = signer::address_of(alice);

    //     let alice_token_x_before_balance = coin::balance<TestCAKE>(alice_addr);

    //     let total_fees = swap_v2::token_fees<TestBUSD, TestCAKE>();

    //     let input_x = calc_input_using_output(output_y, initial_reserve_x, initial_reserve_y, total_fees); 

    //     let x_in_amount = router_v2::get_amount_in<TestCAKE, TestBUSD>(output_y);
    //     assert!(x_in_amount == (input_x as u64), 102);

    //     let input_x_coin = coin::withdraw(alice, (input_x as u64));

    //     let (x_out, y_out) =  router_v2::swap_x_to_exact_y_direct_external<TestCAKE, TestBUSD>(input_x_coin, output_y);

    //     assert!(coin::value(&x_out) == 0, 101);
    //     assert!(coin::value(&y_out) == output_y, 100);
    //     coin::register<TestBUSD>(alice);
    //     coin::deposit<TestCAKE>(alice_addr, x_out);
    //     coin::deposit<TestBUSD>(alice_addr, y_out);

    //     let alice_token_x_after_balance = coin::balance<TestCAKE>(alice_addr);
    //     let alice_token_y_after_balance = coin::balance<TestBUSD>(alice_addr);

    //     let new_reserve_x = initial_reserve_x + (input_x as u64);
    //     let new_reserve_y = initial_reserve_y - output_y;

    //     let (reserve_y, reserve_x, _) = swap_v2::token_reserves<TestBUSD, TestCAKE>();
    //     assert!((alice_token_x_before_balance - alice_token_x_after_balance) == (input_x as u64), 99);
    //     assert!(alice_token_y_after_balance == output_y, 98);
    //     // assert!(reserve_x * reserve_y >= new_reserve_x * new_reserve_y, 97);

    //     let bob_token_x_before_balance = coin::balance<TestCAKE>(signer::address_of(bob));
    //     let bob_token_y_before_balance = coin::balance<TestBUSD>(signer::address_of(bob));

    //     router_v2::remove_liquidity<TestCAKE, TestBUSD>(bob, (bob_suppose_lp_balance as u64), 0, 0);

    //     let bob_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(bob));
    //     let bob_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(bob));

    //     // let suppose_k_last = ((initial_reserve_x * initial_reserve_y) as u128);
    //     // let suppose_k = ((new_reserve_x * new_reserve_y) as u128);
    //     // let suppose_fee_amount = calc_fee_lp(suppose_total_supply, suppose_k, suppose_k_last);
    //     // suppose_total_supply = suppose_total_supply + suppose_fee_amount;

    //     let bob_remove_liquidity_x = ((new_reserve_x) as u128) * bob_suppose_lp_balance / suppose_total_supply;
    //     let bob_remove_liquidity_y = ((new_reserve_y) as u128) * bob_suppose_lp_balance / suppose_total_supply;
    //     new_reserve_x = new_reserve_x - (bob_remove_liquidity_x as u64);
    //     new_reserve_y = new_reserve_y - (bob_remove_liquidity_y as u64);
    //     suppose_total_supply = suppose_total_supply - bob_suppose_lp_balance;

    //     // assert!((bob_token_x_after_balance - bob_token_x_before_balance) == (bob_remove_liquidity_x as u64), 95);
    //     // assert!((bob_token_y_after_balance - bob_token_y_before_balance) == (bob_remove_liquidity_y as u64), 94);

    //     // swap_v2::withdraw_fee<TestCAKE, TestBUSD>(treasury);
    //     // let treasury_lp_after_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(treasury));
    //     // router_v2::remove_liquidity<TestCAKE, TestBUSD>(treasury, (suppose_fee_amount as u64), 0, 0);
    //     // let treasury_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(treasury));
    //     // let treasury_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(treasury));

    //     // let treasury_remove_liquidity_x = ((new_reserve_x) as u128) * suppose_fee_amount / suppose_total_supply;
    //     // let treasury_remove_liquidity_y = ((new_reserve_y) as u128) * suppose_fee_amount / suppose_total_supply;

    //     // assert!(treasury_lp_after_balance == (suppose_fee_amount as u64), 93);
    //     // assert!(treasury_token_x_after_balance == (treasury_remove_liquidity_x as u64), 92);
    //     // assert!(treasury_token_y_after_balance == (treasury_remove_liquidity_y as u64), 91);
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // fun test_swap_x_to_exact_y_direct_external_with_more_x_in(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, alice, 100 * pow(10, 8));

    //     let initial_reserve_x = 5 * pow(10, 8);
    //     let initial_reserve_y = 10 * pow(10, 8);
    //     let output_y = 166319299;
    //     // let input_x_max = 1 * pow(10, 8);

    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, initial_reserve_x, initial_reserve_y, 0, 0);
    //     let bob_suppose_lp_balance = math::sqrt(((initial_reserve_x as u128) * (initial_reserve_y as u128))) - MINIMUM_LIQUIDITY;
    //     let suppose_total_supply = bob_suppose_lp_balance + MINIMUM_LIQUIDITY;

    //     let alice_addr = signer::address_of(alice);

    //     let alice_token_x_before_balance = coin::balance<TestCAKE>(alice_addr);

    //     let total_fees = swap_v2::token_fees<TestBUSD, TestCAKE>();

    //     let input_x = calc_input_using_output(output_y, initial_reserve_x, initial_reserve_y, total_fees); 

    //     let x_in_more = 666666;

    //     let input_x_coin = coin::withdraw(alice, (input_x as u64) + x_in_more);

    //     let (x_out, y_out) =  router_v2::swap_x_to_exact_y_direct_external<TestCAKE, TestBUSD>(input_x_coin, output_y);

    //     assert!(coin::value(&x_out) == x_in_more, 101);
    //     assert!(coin::value(&y_out) == output_y, 100);
    //     coin::register<TestBUSD>(alice);
    //     coin::deposit<TestCAKE>(alice_addr, x_out);
    //     coin::deposit<TestBUSD>(alice_addr, y_out);

    //     let alice_token_x_after_balance = coin::balance<TestCAKE>(alice_addr);
    //     let alice_token_y_after_balance = coin::balance<TestBUSD>(alice_addr);

    //     let new_reserve_x = initial_reserve_x + (input_x as u64);
    //     let new_reserve_y = initial_reserve_y - output_y;

    //     let (reserve_y, reserve_x, _) = swap_v2::token_reserves<TestBUSD, TestCAKE>();
    //     assert!((alice_token_x_before_balance - alice_token_x_after_balance) == (input_x as u64), 99);
    //     assert!(alice_token_y_after_balance == output_y, 98);
    //     // assert!(reserve_x * reserve_y >= new_reserve_x * new_reserve_y, 97);

    //     let bob_token_x_before_balance = coin::balance<TestCAKE>(signer::address_of(bob));
    //     let bob_token_y_before_balance = coin::balance<TestBUSD>(signer::address_of(bob));

    //     router_v2::remove_liquidity<TestCAKE, TestBUSD>(bob, (bob_suppose_lp_balance as u64), 0, 0);

    //     let bob_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(bob));
    //     let bob_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(bob));

    //     // let suppose_k_last = ((initial_reserve_x * initial_reserve_y) as u128);
    //     // let suppose_k = ((new_reserve_x * new_reserve_y) as u128);
    //     // let suppose_fee_amount = calc_fee_lp(suppose_total_supply, suppose_k, suppose_k_last);
    //     // suppose_total_supply = suppose_total_supply + suppose_fee_amount;

    //     let bob_remove_liquidity_x = ((new_reserve_x) as u128) * bob_suppose_lp_balance / suppose_total_supply;
    //     let bob_remove_liquidity_y = ((new_reserve_y) as u128) * bob_suppose_lp_balance / suppose_total_supply;
    //     new_reserve_x = new_reserve_x - (bob_remove_liquidity_x as u64);
    //     new_reserve_y = new_reserve_y - (bob_remove_liquidity_y as u64);
    //     suppose_total_supply = suppose_total_supply - bob_suppose_lp_balance;

    //     // assert!((bob_token_x_after_balance - bob_token_x_before_balance) == (bob_remove_liquidity_x as u64), 95);
    //     // assert!((bob_token_y_after_balance - bob_token_y_before_balance) == (bob_remove_liquidity_y as u64), 94);

    //     // swap_v2::withdraw_fee<TestCAKE, TestBUSD>(treasury);
    //     // let treasury_lp_after_balance = coin::balance<LPToken<TestBUSD, TestCAKE>>(signer::address_of(treasury));
    //     // router_v2::remove_liquidity<TestCAKE, TestBUSD>(treasury, (suppose_fee_amount as u64), 0, 0);
    //     // let treasury_token_x_after_balance = coin::balance<TestCAKE>(signer::address_of(treasury));
    //     // let treasury_token_y_after_balance = coin::balance<TestBUSD>(signer::address_of(treasury));

    //     // let treasury_remove_liquidity_x = ((new_reserve_x) as u128) * suppose_fee_amount / suppose_total_supply;
    //     // let treasury_remove_liquidity_y = ((new_reserve_y) as u128) * suppose_fee_amount / suppose_total_supply;

    //     // assert!(treasury_lp_after_balance == (suppose_fee_amount as u64), 93);
    //     // assert!(treasury_token_x_after_balance == (treasury_remove_liquidity_x as u64), 92);
    //     // assert!(treasury_token_y_after_balance == (treasury_remove_liquidity_y as u64), 91);
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // #[expected_failure(abort_code = 2)]
    // fun test_swap_x_to_exact_y_direct_external_with_less_x_in(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, alice, 100 * pow(10, 8));

    //     let initial_reserve_x = 5 * pow(10, 8);
    //     let initial_reserve_y = 10 * pow(10, 8);
    //     let output_y = 166319299;
    //     // let input_x_max = 1 * pow(10, 8);

    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, initial_reserve_x, initial_reserve_y, 0, 0);

    //     let alice_addr = signer::address_of(alice);

    //     let total_fees = swap_v2::token_fees<TestBUSD, TestCAKE>();

    //     let input_x = calc_input_using_output(output_y, initial_reserve_x, initial_reserve_y, total_fees); 

    //     let x_in_less = 66;

    //     let input_x_coin = coin::withdraw(alice, (input_x as u64) - x_in_less);

    //     let (x_out, y_out) =  router_v2::swap_x_to_exact_y_direct_external<TestCAKE, TestBUSD>(input_x_coin, output_y);

    //     coin::register<TestBUSD>(alice);
    //     coin::deposit<TestCAKE>(alice_addr, x_out);
    //     coin::deposit<TestBUSD>(alice_addr, y_out);
    // }

    // #[test(dev = @dev_2, admin = @admin, resource_account = @baptswap_v2, treasury = @treasury, bob = @0x12345, alice = @0x12346)]
    // fun test_get_amount_in(
    //     dev: &signer,
    //     admin: &signer,
    //     resource_account: &signer,
    //     treasury: &signer,
    //     bob: &signer,
    //     alice: &signer,
    // ) {
    //     account::create_account_for_test(signer::address_of(bob));
    //     account::create_account_for_test(signer::address_of(alice));

    //     setup_test_with_genesis(dev, admin, treasury, resource_account);

    //     let coin_owner = test_coins::init_coins();

    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestBUSD>(&coin_owner, bob, 100 * pow(10, 8));
    //     test_coins::register_and_mint<TestCAKE>(&coin_owner, alice, 100 * pow(10, 8));

    //     let initial_reserve_x = 5 * pow(10, 8);
    //     let initial_reserve_y = 10 * pow(10, 8);
    //     let output_y = 166319299;
    //     let output_x = 166319299;
    //     // let input_x_max = 1 * pow(10, 8);

    //     // bob provider liquidity for 5:10 CAKE-BUSD
    //     router_v2::add_liquidity<TestCAKE, TestBUSD>(bob, initial_reserve_x, initial_reserve_y, 0, 0);

    //     let total_fees = swap_v2::token_fees<TestBUSD, TestCAKE>();

    //     let input_x = calc_input_using_output(output_y, initial_reserve_x, initial_reserve_y, total_fees); 

    //     let x_in_amount = router_v2::get_amount_in<TestCAKE, TestBUSD>(output_y);
    //     assert!(x_in_amount == (input_x as u64), 102);

    //     let input_y = calc_input_using_output(output_x, initial_reserve_y, initial_reserve_x, total_fees); 

    //     let y_in_amount = router_v2::get_amount_in<TestBUSD, TestCAKE>(output_x);
    //     assert!(y_in_amount == (input_y as u64), 101);
    // }


    // public fun get_token_reserves<X, Y>(): (u64, u64) {

    //     let is_x_to_y = swap_utils::sort_token_type<X, Y>();
    //     let reserve_x;
    //     let reserve_y;
    //     if(is_x_to_y){
    //         (reserve_x, reserve_y, _) = swap_v2::token_reserves<X, Y>();
    //     }else{
    //         (reserve_y, reserve_x, _) = swap_v2::token_reserves<Y, X>();
    //     };
    //     (reserve_x, reserve_y)

    // }

    // public fun calc_output_using_input(
    //     input_x: u64,
    //     reserve_x: u64,
    //     reserve_y: u64,
    //     total_fees: u128
    // ): u128 {
    //     let fee_denominator = 10000u128 - 20u128 - total_fees;

    //     ((input_x as u128) * fee_denominator * (reserve_y as u128)) / (((reserve_x as u128) * 10000u128) + ((input_x as u128) * fee_denominator))
    // }

    // public fun calc_input_using_output(
    //     output_y: u64,
    //     reserve_x: u64,
    //     reserve_y: u64,
    //     total_fees: u128
    // ): u128 {
    //     let fee_denominator = 10000u128 - 20u128 - total_fees;

    //     ((output_y as u128) * 10000u128 * (reserve_x as u128)) / (fee_denominator * ((reserve_y as u128) - (output_y as u128))) + 1u128
    // }

    // public fun calc_fee_lp(
    //     total_lp_supply: u128,
    //     k: u128,
    //     k_last: u128,
    // ): u128 {
    //     let root_k = math::sqrt(k);
    //     let root_k_last = math::sqrt(k_last);

    //     let numerator = total_lp_supply * (root_k - root_k_last) * 8u128;
    //     let denominator = root_k_last * 17u128 + (root_k * 8u128);
    //     let liquidity = numerator / denominator;
    //     liquidity
    // }
}
