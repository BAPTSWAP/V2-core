/*
    Tool for deploying coins.
    - Capabilities are destroyed after the coin is created (will add a way to keep them if needed)
    - The deployer is initialized with a fee that is paid in APT
    - The deployer is initialized with an owner address that can change the fee and owner address
    - The deployer is initialized with a coins table that maps coin addresses to their addresses
    - coins can be added/removed to the map manually by the deployer owner
    - can view the coins table
*/

module bapt_framework::deployer {

    use aptos_framework::coin::{Self, BurnCapability, FreezeCapability};
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::event;
    use aptos_std::type_info;
    use std::error;
    use std::option::{Self, Option};
    use std::signer;
    use std::string::{String};

    struct Config has key {
        owner: address,
        fee: u64
    }

    struct Caps<phantom CoinType> has key {
        burn_cap: Option<BurnCapability<CoinType>>,
        freeze_cap: Option<FreezeCapability<CoinType>>
    }
    
    #[event]
    struct NewFeeEvent has drop, store { new_fee: u64 }
    fun emit_new_fee_event(new_fee: u64) {
        event::emit<NewFeeEvent>(NewFeeEvent { new_fee })
    }

    #[event]
    struct NewOwnerEvent has drop, store { new_owner: address }
    fun emit_new_owner_event(new_owner: address) {
        event::emit<NewOwnerEvent>(NewOwnerEvent { new_owner })
    }

    /// Error Codes 
    
    /// The account passed is not the BAPT account
    const ERROR_INVALID_BAPT_ACCOUNT: u64 = 0;
    /// The caller does not have enough APT to pay
    const ERROR_ERROR_INSUFFICIENT_APT_BALANCE: u64 = 1;
    /// The caller does not have enough APT to pay
    const INSUFFICIENT_APT_BALANCE: u64 = 2;
    /// The coin type is not initialized
    const ERROR_NOT_INITIALIZED: u64 = 3;
    /// The account does not the required capabilities
    const ERROR_NO_CAPABILITIES: u64 = 4;


    entry public fun init(bapt_framework: &signer, fee: u64, owner: address){
        assert!(signer::address_of(bapt_framework) == @bapt_framework, ERROR_INVALID_BAPT_ACCOUNT);
        move_to(bapt_framework, Config { owner, fee })
    }

    entry public fun update_fee(bapt_framework: &signer, new_fee: u64) acquires Config {
        assert!(
            signer::address_of(bapt_framework) == @bapt_framework, 
            ERROR_INVALID_BAPT_ACCOUNT
        );
        // only allowed after the deployer is initialized
        let config = borrow_global_mut<Config>(@bapt_framework);
        config.fee = new_fee;
        emit_new_fee_event(new_fee);
    }

    // update fee account
    entry public fun update_fee_account(signer_ref: &signer, new_fee_account: address) acquires Config {
        assert!(
            signer::address_of(signer_ref) == @bapt_framework, 
            ERROR_INVALID_BAPT_ACCOUNT
        );
        let config = borrow_global_mut<Config>(@bapt_framework);
        config.owner = new_fee_account;
        emit_new_owner_event(new_fee_account);
    }

    // Generate a coin with options to choose if the coin should be burnable, freezable, or both.
    entry public fun generate_coin_with_caps<CoinType>(
        deployer: &signer,
        name: String,
        symbol: String,
        decimals: u8,
        total_supply: u64,
        monitor_supply: bool,
        is_burnable: bool,
        is_freezable: bool
    ) acquires Config {
        // only allowed after the deployer is initialized
        assert!(exists<Config>(@bapt_framework), ERROR_INVALID_BAPT_ACCOUNT);
        // the deployer must have enough APT to pay for the fee
        assert!(
            coin::balance<AptosCoin>(signer::address_of(deployer)) >= borrow_global<Config>(@bapt_framework).fee,
            INSUFFICIENT_APT_BALANCE
        );
        let deployer_addr = signer::address_of(deployer);
        let (
            burn_cap, 
            freeze_cap, 
            mint_cap
        ) = coin::initialize<CoinType>(
            deployer, 
            name, 
            symbol, 
            decimals, 
            monitor_supply
        );

        coin::register<CoinType>(deployer);
        mint_internal<CoinType>(deployer_addr, total_supply, mint_cap);

        let option_burn_cap = if (is_burnable) {
            option::some(burn_cap) } else {
                coin::destroy_burn_cap<CoinType>(burn_cap);
                option::none() 
            };
        let option_freeze_cap = if (is_freezable) {
            option::some(freeze_cap) } else { 
                coin::destroy_freeze_cap<CoinType>(freeze_cap);
                option::none() 
            };
        move_to(
            deployer, 
            Caps { 
                burn_cap: option_burn_cap, 
                freeze_cap: option_freeze_cap 
            }
        );
        collect_fee(deployer);
    }

    // Withdraw an `amount` of coin `CoinType` from `account` and burn it.
    public entry fun burn<CoinType>(
        account: &signer,
        amount: u64,
    ) acquires Caps {
        let account_addr = signer::address_of(account);

        assert!(
            exists<Caps<CoinType>>(account_addr),
            error::not_found(ERROR_NO_CAPABILITIES),
        );
        // borrow cap resource and get burn cap option
        let burn_cap = option::borrow(&borrow_global<Caps<CoinType>>(signer::address_of(account)).burn_cap);

        let to_burn = coin::withdraw<CoinType>(account, amount);

        coin::burn(to_burn, burn_cap);
    }

    // Freeze a coin store `CoinType` from `account`.
    public entry fun freeze_coinstore<CoinType>(
        account: &signer,
        acc_addr_to_freeze: address
    ) acquires Caps {
        let account_addr = signer::address_of(account);
        assert!(
            exists<Caps<CoinType>>(account_addr),
            error::not_found(ERROR_NO_CAPABILITIES),
        );
        // borrow cap resource and get freeze cap option
        let freeze_cap = option::borrow(&borrow_global<Caps<CoinType>>(account_addr).freeze_cap);
        coin::freeze_coin_store(acc_addr_to_freeze, freeze_cap);
    }

    // Unfreeze a coin store `CoinType` from `account`.
    public entry fun unfreeze_coinstore<CoinType>(
        account: &signer,
        acc_addr_to_unfreeze: address
    ) acquires Caps {
        let account_addr = signer::address_of(account);
        assert!(
            exists<Caps<CoinType>>(account_addr),
            error::not_found(ERROR_NO_CAPABILITIES),
        );
        // borrow cap resource and get freeze cap option
        let freeze_cap = option::borrow(&borrow_global<Caps<CoinType>>(account_addr).freeze_cap);
        coin::unfreeze_coin_store(acc_addr_to_unfreeze, freeze_cap);
    }

    // Generates a new coin and mints the total supply to the deployer. capabilties are then destroyed
    entry public fun generate_coin<CoinType>(
        deployer: &signer,
        name: String,
        symbol: String,
        decimals: u8,
        total_supply: u64,
        monitor_supply: bool,
    ) acquires Config {        
        // only allowed after the deployer is initialized
        assert!(exists<Config>(@bapt_framework), ERROR_INVALID_BAPT_ACCOUNT);
        // the deployer must have enough APT to pay for the fee
        assert!(
            coin::balance<AptosCoin>(signer::address_of(deployer)) >= borrow_global<Config>(@bapt_framework).fee,
            INSUFFICIENT_APT_BALANCE
        );
        let monitor_supply = true;
        let deployer_addr = signer::address_of(deployer);
        let (
            burn_cap, 
            freeze_cap, 
            mint_cap
        ) = coin::initialize<CoinType>(
            deployer, 
            name, 
            symbol, 
            decimals, 
            monitor_supply
        );

        coin::register<CoinType>(deployer);
        mint_internal<CoinType>(deployer_addr, total_supply, mint_cap);

        collect_fee(deployer);

        // destroy caps
        coin::destroy_freeze_cap<CoinType>(freeze_cap);
        coin::destroy_burn_cap<CoinType>(burn_cap);

        assert!(coin::is_coin_initialized<CoinType>(), ERROR_NOT_INITIALIZED);
    }
    
    // checks if a given owner address + coin_type exists in coin_table; callable only by anyone
    public fun is_coin_owner<CoinType>(sender: &signer): bool {
        let sender_addr = signer::address_of(sender);
        if (owner_address<CoinType>() == sender_addr) 
        { true } else false
    }

    // Helper function; used to mint freshly created coin
    fun mint_internal<CoinType>(
        deployer_addr: address,
        total_supply: u64,
        mint_cap: coin::MintCapability<CoinType>
    ) {
        let coins_minted = coin::mint(total_supply, &mint_cap);
        coin::deposit(deployer_addr, coins_minted);
        
        coin::destroy_mint_cap<CoinType>(mint_cap);
    }

    fun collect_fee(deployer: &signer) acquires Config {
        let config = borrow_global_mut<Config>(@bapt_framework);
        coin::transfer<AptosCoin>(deployer, config.owner, config.fee);
    }

    #[view]
    // get fee
    public fun get_fee(): u64  acquires Config {
        borrow_global<Config>(@bapt_framework).fee
    }

    #[view]
    // get fee account
    public fun get_fee_account(): address  acquires Config {
        borrow_global<Config>(@bapt_framework).owner
    }

    public fun owner_address<CoinType>(): address {
        let type_info = type_info::type_of<CoinType>();
        type_info::account_address(&type_info)
    }

    #[test_only]
    use aptos_framework::aptos_coin;
    #[test_only]
    struct FakeBAPT {}
    #[test_only]
    struct FakeUSDC {}
    #[test_only]
    use std::string;
    #[test_only]
    use std::features;
    #[test_only]
    use aptos_std::debug;

    #[test_only]
    public fun init_test(bapt_framework: &signer, fee: u64, owner: address) {
        assert!(
            signer::address_of(bapt_framework) == @bapt_framework, 
            ERROR_INVALID_BAPT_ACCOUNT
        );

        move_to(bapt_framework, Config { owner, fee });
    }

    #[test(aptos_framework = @0x1, bapt_framework = @bapt_framework)]
    // #[expected_failure, code = 65537]
    fun test_user_deploys_coin(
        aptos_framework: signer,
        bapt_framework: signer
    ) acquires Config {
        aptos_framework::account::create_account_for_test(signer::address_of(&bapt_framework));
        // aptos_framework::account::create_account_for_test(signer::address_of(user));
        init(&bapt_framework, 1, signer::address_of(&bapt_framework));
        assert!(get_fee() == 1, 0);
        // register aptos coin and mint some APT to be able to pay for the fee of generate_coin
        coin::register<AptosCoin>(&bapt_framework);
        let (aptos_coin_burn_cap, aptos_coin_mint_cap) = aptos_coin::initialize_for_test(&aptos_framework);
        // mint some APT to be able to pay for the fee of generate_coin
        aptos_coin::mint(&aptos_framework, signer::address_of(&bapt_framework), 1000);
        
        generate_coin<FakeBAPT>(
            &bapt_framework,
            string::utf8(b"Fake BAPT"),
            string::utf8(b"BAPT"),
            4,
            1000000,
            true,
        );

        // destroy APT mint and burn caps
        coin::destroy_mint_cap<AptosCoin>(aptos_coin_mint_cap);
        coin::destroy_burn_cap<AptosCoin>(aptos_coin_burn_cap);

        // assert FakeBAPT is generated and supply is moved under the deployer's wallet
        assert!(coin::balance<FakeBAPT>(signer::address_of(&bapt_framework)) == 1000000, 1);

        // assert coins table contains the newly created coin
        assert!(is_coin_owner<FakeBAPT>(&bapt_framework), 1);
    }

    #[test(aptos_framework = @0x1, bapt_framework = @bapt_framework, user = @0x123, new_bapt = @0x456)]
    public fun test_fee(
        aptos_framework: signer,
        bapt_framework: signer,
        user: signer,
        new_bapt: signer
    )  acquires Config {
        let new_bapt_addr = signer::address_of(&new_bapt);
        aptos_framework::account::create_account_for_test(signer::address_of(&bapt_framework));
        aptos_framework::account::create_account_for_test(signer::address_of(&user));
        aptos_framework::account::create_account_for_test(new_bapt_addr);
        features::change_feature_flags(&aptos_framework, vector[26], vector[]);
        // aptos_framework::account::create_account_for_test(signer::address_of(user));
        init(&bapt_framework, 100, signer::address_of(&bapt_framework));
        assert!(get_fee() == 100, 0);
        update_fee(&bapt_framework, 200);
        assert!(get_fee() == 200, 0);
        update_fee_account(&bapt_framework, new_bapt_addr);
        assert!(
            borrow_global<Config>(@bapt_framework).owner == new_bapt_addr,
            0
        );

        // Deploy a new coin
        // register aptos coin and mint some APT to be able to pay for the fee of generate_coin
        coin::register<AptosCoin>(&new_bapt);
        coin::register<AptosCoin>(&bapt_framework);
        let (aptos_coin_burn_cap, aptos_coin_mint_cap) = aptos_coin::initialize_for_test(&aptos_framework);
        // mint some APT to be able to pay for the fee of generate_coin
        aptos_coin::mint(&aptos_framework, signer::address_of(&bapt_framework), 10000000);
        
        generate_coin<FakeBAPT>(
            &bapt_framework,
            string::utf8(b"Fake BAPT"),
            string::utf8(b"BAPT"),
            4,
            1000000,
            true,
        );

        // destroy APT mint and burn caps
        coin::destroy_mint_cap<AptosCoin>(aptos_coin_mint_cap);
        coin::destroy_burn_cap<AptosCoin>(aptos_coin_burn_cap);

        // assert FakeBAPT is generated and supply is moved under the deployer's wallet
        assert!(coin::balance<FakeBAPT>(signer::address_of(&bapt_framework)) == 1000000, 1);
        // assert fees are collected
        debug::print<u64>(&coin::balance<AptosCoin>(new_bapt_addr));
        assert!(coin::balance<AptosCoin>(new_bapt_addr) == 200, 1);
    
        // assert coins table contains the newly created coin
        assert!(is_coin_owner<FakeBAPT>(&bapt_framework), 1);
    }
}