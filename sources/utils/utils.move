module baptswap_v2::utils {

    use std::signer;
    // use aptos_std::debug;
    use aptos_framework::coin::{Self, Coin};

    friend baptswap_v2::stake;
    friend baptswap_v2::swap_v2;

    // calculates an amount given a numerator; amount = amount in * numerator / (100*100)
    public(friend) inline fun calculate_amount(numerator: u128, amount_in: u64): u128 {
        (amount_in as u128) * numerator / 10000u128
    }

    public fun check_or_register_coin_store<X>(sender: &signer) {
        if (!coin::is_account_registered<X>(signer::address_of(sender))) {
            coin::register<X>(sender);
        };
    }

    public(friend) fun transfer_in<CoinType>(own_coin: &mut Coin<CoinType>, account: &signer, amount: u64) {
        let coin = coin::withdraw<CoinType>(account, amount);
        coin::merge(own_coin, coin);
    }

    public(friend) fun transfer_out<CoinType>(own_coin: &mut Coin<CoinType>, receiver: &signer, amount: u64) {
        check_or_register_coin_store<CoinType>(receiver);
        let extract_coin = coin::extract<CoinType>(own_coin, amount);
        coin::deposit<CoinType>(signer::address_of(receiver), extract_coin);
    }
}