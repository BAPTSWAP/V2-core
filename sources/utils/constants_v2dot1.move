
module baptswap_v2dot1::constants_v2dot1 {

    friend baptswap_v2dot1::admin_v2dot1;
    friend baptswap_v2dot1::router_v2dot1;
    friend baptswap_v2dot1::swap_v2dot1;
    friend baptswap_v2dot1::stake_v2dot1;
    friend baptswap_v2dot1::fee_on_transfer_v2dot1;

    const RESOURCE_ACCOUNT: address = @baptswap_v2dot1;
    const DEV: address = @dev_v2dot1;

    /// Max DEX fee: 0.9%; (90 / (100*100))
    const DEX_FEE_THRESHOLD_NUMERATOR: u128 = 90;
    /// Minimum liquidity: 1000
    const MINIMUM_LIQUIDITY: u128 = 1000;
    /// Max coin name length: 32
    const MAX_COIN_NAME_LENGTH: u64 = 32;
    /// Precision: 10000
    const PRECISION: u64 = 10000;
    /// Max u128: 2^128 - 1
    const MAX_U128: u128 = 340282366920938463463374607431768211455;
    /// Max individual token fee: 15%; (1500 / (100*100))
    const FEE_ON_TRANSFER_THRESHOLD_NUMERATOR: u128 = 1500;

    #[view]
    public fun get_resource_account_address(): address { RESOURCE_ACCOUNT }

    #[view]
    public fun get_dev_address(): address { DEV }

    #[view]
    public fun get_fee_threshold_numerator(): u128 { DEX_FEE_THRESHOLD_NUMERATOR }

    #[view]
    public fun get_minimum_liquidity(): u128 { MINIMUM_LIQUIDITY }

    #[view]
    public fun get_max_coin_name_length(): u64 { MAX_COIN_NAME_LENGTH }

    #[view]
    public fun get_precision(): u64 { PRECISION }

    #[view]
    public fun get_max_u128(): u128 { MAX_U128 }

    #[view]
    public fun get_fee_on_transfer_threshold_numerator(): u128 { FEE_ON_TRANSFER_THRESHOLD_NUMERATOR }

}