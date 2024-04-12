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

    use aptos_framework::coin::{
        Self, 
        BurnCapability, 
        FreezeCapability, 
        MintCapability
    };
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_std::type_info;
    use std::signer;
    use std::string::{String};

    struct Config has key {
        owner: address,
        fee: u64
    }

    // Error Codes 
    const ERROR_INVALID_BAPT_ACCOUNT: u64 = 0;
    const ERROR_ERROR_INSUFFICIENT_APT_BALANCE: u64 = 1;
    const INSUFFICIENT_APT_BALANCE: u64 = 2;
    const ERROR_NOT_INITIALIZED: u64 = 3;


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
        assert!(exists<Config>(@bapt_framework), ERROR_ERROR_INSUFFICIENT_APT_BALANCE);

        let config = borrow_global_mut<Config>(@bapt_framework);
        config.fee = new_fee;
    }

    entry public fun update_owner(bapt_framework: &signer, new_owner: address) acquires Config {
        assert!(
            signer::address_of(bapt_framework) == @bapt_framework, 
            ERROR_INVALID_BAPT_ACCOUNT
        );
        // only allowed after the deployer is initialized
        assert!(exists<Config>(@bapt_framework), ERROR_ERROR_INSUFFICIENT_APT_BALANCE);

        let config = borrow_global_mut<Config>(@bapt_framework);
        config.owner = new_owner;
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
        assert!(exists<Config>(@bapt_framework), ERROR_ERROR_INSUFFICIENT_APT_BALANCE);
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
        mint_cap: MintCapability<CoinType>
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
    public fun init_test(bapt_framework: &signer, fee: u64, owner: address) {
        assert!(
            signer::address_of(bapt_framework) == @bapt_framework, 
            ERROR_INVALID_BAPT_ACCOUNT
        );

        move_to(bapt_framework, Config { owner, fee });
    }

    #[test(aptos_framework = @0x1, bapt_framework = @bapt_framework, user = @0x123)]
    // #[expected_failure, code = 65537]
    fun test_user_deploys_coin(
        aptos_framework: signer,
        bapt_framework: signer,
        user: &signer,
    ) acquires Config {
        aptos_framework::account::create_account_for_test(signer::address_of(&bapt_framework));
        // aptos_framework::account::create_account_for_test(signer::address_of(user));
        init(&bapt_framework, 1, signer::address_of(&bapt_framework));
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
        let config = borrow_global<Config>(@bapt_framework);
        let coin_address = owner_address<FakeBAPT>();
        assert!(is_coin_owner<FakeBAPT>(&bapt_framework), 1);
    }
}