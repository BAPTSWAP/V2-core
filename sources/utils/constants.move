
module baptswap_v2::constants {

    friend baptswap_v2::admin;
    friend baptswap_v2::router_v2;
    friend baptswap_v2::swap_v2;
    friend baptswap_v2::stake;
    friend baptswap_v2::fee_on_transfer;

    const DEFAULT_ADMIN: address = @default_admin;
    const RESOURCE_ACCOUNT: address = @baptswap_v2;
    const DEV: address = @dev_2;

    // Max DEX fee: 0.9%; (90 / (100*100))
    const DEX_FEE_THRESHOLD_NUMERATOR: u128 = 90;
    const MINIMUM_LIQUIDITY: u128 = 1000;
    const MAX_COIN_NAME_LENGTH: u64 = 32;
    const PRECISION: u64 = 10000;
    const MAX_U128: u128 = 340282366920938463463374607431768211455;
    // Max individual token fee: 15%; (1500 / (100*100))
    const FEE_ON_TRANSFER_THRESHOLD_NUMERATOR: u128 = 1500;

    #[view]
    public fun get_admin_address(): address { DEFAULT_ADMIN }

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