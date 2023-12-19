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