#[test_only]
module test_coin::test_coins {
    use aptos_framework::account;
    use aptos_framework::managed_coin;
    use std::signer;

    struct TestCAKE {}
    struct TestBUSD {}
    struct TestUSDC {}
    struct TestBNB {}
    struct TestAPT {}

    public entry fun init_coins(): signer {
        let account = account::create_account_for_test(@test_coin);

        // init coins
        managed_coin::initialize<TestCAKE>(
            &account,
            b"Cake",
            b"CAKE",
            9,
            false,
        );
        managed_coin::initialize<TestBUSD>(
            &account,
            b"Busd",
            b"BUSD",
            9,
            false,
        );

        managed_coin::initialize<TestUSDC>(
            &account,
            b"USDC",
            b"USDC",
            9,
            false,
        );

        managed_coin::initialize<TestBNB>(
            &account,
            b"BNB",
            b"BNB",
            9,
            false,
        );

        managed_coin::initialize<TestAPT>(
            &account,
            b"Aptos",
            b"APT",
            9,
            false,
        );

        account
    }


    public entry fun register_and_mint<CoinType>(account: &signer, to: &signer, amount: u64) {
      managed_coin::register<CoinType>(to);
      managed_coin::mint<CoinType>(account, signer::address_of(to), amount)
    }

    public entry fun mint<CoinType>(account: &signer, to: &signer, amount: u64) {
        managed_coin::mint<CoinType>(account, signer::address_of(to), amount)
    }
}

#[test_only]
module alice::alice_coins {
    use std::string;
    use bapt_framework::deployer;
    use aptos_std::math64::pow;
    use aptos_framework::managed_coin;

    struct TestBAPT has key {}

    public fun init_module(alice: &signer) {
        deployer::generate_coin<TestBAPT>(
            alice,
            string::utf8(b"Test BAPT Coin"),
            string::utf8(b"TestBAPT"),
            2,
            1000 * pow(10, 8),
            true
        );
    }
}

#[test_only]
module bob::bob_coins {
    use std::string;
    use bapt_framework::deployer;
    use aptos_std::math64::pow;
    use aptos_framework::coin;

    struct TestMAU has key {}

    public fun init_module(bob: &signer) {
        deployer::generate_coin<TestMAU>(
            bob,
            string::utf8(b"Test MAU Coin"),
            string::utf8(b"TestMAU"),
            2,
            1000 * pow(10, 8),
            true
        );

        coin::register<TestMAU>(bob);
    }
}