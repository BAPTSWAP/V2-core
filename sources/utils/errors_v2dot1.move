/*

*/

module baptswap_v2dot1::errors_v2dot1 {

    use std::error;

    friend baptswap_v2dot1::admin_v2dot1;
    friend baptswap_v2dot1::fee_on_transfer_v2dot1;
    friend baptswap_v2dot1::router_v2dot1;
    friend baptswap_v2dot1::swap_v2dot1;
    friend baptswap_v2dot1::stake_v2dot1;
    friend baptswap_v2dot1::swap_utils_v2dot1;    

    /// Only admin can call this function
    const ERROR_ONLY_ADMIN: u64 = 0;
    /// Already initialized
    const ERROR_ALREADY_INITIALIZED: u64 = 1;
    /// Not creator
    const ERROR_NOT_CREATOR: u64 = 2;
    /// Insufficient liquidity minted
    const ERROR_INSUFFICIENT_LIQUIDITY_MINTED: u64 = 4;
    /// Insufficient amount
    const ERROR_INSUFFICIENT_AMOUNT: u64 = 6;
    /// Insufficient liquidity
    const ERROR_INSUFFICIENT_LIQUIDITY: u64 = 7;
    /// Invalid amount
    const ERROR_INVALID_AMOUNT: u64 = 8;
    /// Tokens not sorted
    const ERROR_TOKENS_NOT_SORTED: u64 = 9;
    /// Insufficient liquidity burned
    const ERROR_INSUFFICIENT_LIQUIDITY_BURNED: u64 = 10;
    /// Insufficient output amount
    const ERROR_INSUFFICIENT_OUTPUT_AMOUNT: u64 = 13;
    /// Insufficient input amount
    const ERROR_INSUFFICIENT_INPUT_AMOUNT: u64 = 14;
    /// K constant error
    const ERROR_K: u64 = 15;
    /// X not registered
    const ERROR_X_NOT_REGISTERED: u64 = 16;
    /// Y not registered
    const ERROR_Y_NOT_REGISTERED: u64 = 16;
    /// Not admin
    const ERROR_NOT_ADMIN: u64 = 17;
    /// Not treasury address
    const ERROR_NOT_TREASURY_ADDRESS: u64 = 18;
    /// Not equal exact amount
    const ERROR_NOT_EQUAL_EXACT_AMOUNT: u64 = 19;
    /// Not resource account
    const ERROR_NOT_RESOURCE_ACCOUNT: u64 = 20;
    /// No fee withdraw
    const ERROR_NO_FEE_WITHDRAW: u64 = 21;
    /// Excessive fee
    const ERROR_EXCESSIVE_FEE: u64 = 22;
    /// Pair not created
    const ERROR_PAIR_NOT_CREATED: u64 = 23;
    /// Must be inferior to twenty
    const ERROR_MUST_BE_INFERIOR_TO_TWENTY: u64 = 24;
    /// Pool not created
    const ERROR_POOL_NOT_CREATED: u64 = 25;
    /// No stake
    const ERROR_NO_STAKE: u64 = 26;
    /// Insufficient balance
    const ERROR_INSUFFICIENT_BALANCE: u64 = 27;
    /// No rewards
    const ERROR_NO_REWARDS: u64 = 28;
    /// Not owner
    const ERROR_NOT_OWNER: u64 = 29;
    /// Fee on transfer not initialized
    const ERROR_FEE_ON_TRANSFER_NOT_INITIALIZED: u64 = 30;
    /// Fee on transfer not registered
    const ERROR_FEE_ON_TRANSFER_NOT_REGISTERED: u64 = 301;
    // Output amount is less than required
    const ERROR_OUTPUT_LESS_THAN_MIN: u64 = 31;
    // Require Input amount is more than max limit
    const ERROR_INPUT_MORE_THAN_MAX: u64 = 32;
    /// Insufficient X
    const ERROR_INSUFFICIENT_X_AMOUNT: u64 = 33;
    /// Insufficient Y
    const ERROR_INSUFFICIENT_Y_AMOUNT: u64 = 34;
    /// Pair is created
    const ERROR_PAIR_CREATED: u64 = 35;
    /// Pool already created
    const ERROR_POOL_EXISTS: u64 = 36;
    /// Max coin name length
    const MAX_COIN_NAME_LENGTH: u64 = 37;
    /// Coin type does not match X or Y
    const COINTYPE_DOES_NOT_MATCH_X_OR_Y: u64 = 38;
    /// Same address
    const ERROR_SAME_ADDRESS: u64 = 39;
    /// Not liquidity provider
    const NOT_LIQUIDITY_PROVIDER: u64 = 40;
    /// Same token
    const ERROR_SAME_TOKEN: u64 = 41;
    /// Pending request
    const ERROR_PENDING_REQUEST: u64 = 42;
    /// Invalid tier
    const ERROR_INVALID_TIER: u64 = 43;
    /// Internal error
    const ERROR_INTERNAL: u64 = 1000;

    public(friend) fun only_admin(): u64 { error::permission_denied(ERROR_ONLY_ADMIN) }
    public(friend) fun already_initialized(): u64 { error::invalid_argument(ERROR_ALREADY_INITIALIZED) }
    public(friend) fun not_creator(): u64 { error::permission_denied(ERROR_NOT_CREATOR) }
    public(friend) fun insufficient_liquidity_minted(): u64 { error::invalid_argument(ERROR_INSUFFICIENT_LIQUIDITY_MINTED) }
    public(friend) fun insufficient_amount(): u64 { error::invalid_argument(ERROR_INSUFFICIENT_AMOUNT) }
    public(friend) fun insufficient_liquidity(): u64 { error::invalid_argument(ERROR_INSUFFICIENT_LIQUIDITY) }
    public(friend) fun invalid_amount(): u64 { error::invalid_argument(ERROR_INVALID_AMOUNT) }
    public(friend) fun tokens_not_sorted(): u64 { error::invalid_argument(ERROR_TOKENS_NOT_SORTED) }
    public(friend) fun insufficient_liquidity_burned(): u64 { error::invalid_argument(ERROR_INSUFFICIENT_LIQUIDITY_BURNED) }
    public(friend) fun insufficient_output_amount(): u64 { error::invalid_argument(ERROR_INSUFFICIENT_OUTPUT_AMOUNT) }
    public(friend) fun insufficient_input_amount(): u64 { error::invalid_argument(ERROR_INSUFFICIENT_INPUT_AMOUNT) }
    public(friend) fun k(): u64 { error::invalid_state(ERROR_K) }
    public(friend) fun x_not_registered(): u64 { error::aborted(ERROR_X_NOT_REGISTERED) }
    public(friend) fun y_not_registered(): u64 { error::aborted(ERROR_Y_NOT_REGISTERED) }
    public(friend) fun not_admin(): u64 { error::permission_denied(ERROR_NOT_ADMIN) }
    public(friend) fun not_treasury_address(): u64 { error::permission_denied(ERROR_NOT_TREASURY_ADDRESS) }
    public(friend) fun not_equal_exact_amount(): u64 { error::invalid_argument(ERROR_NOT_EQUAL_EXACT_AMOUNT) }
    public(friend) fun not_resource_account(): u64 { error::permission_denied(ERROR_NOT_RESOURCE_ACCOUNT) }
    public(friend) fun no_fee_withdraw(): u64 { error::invalid_argument(ERROR_NO_FEE_WITHDRAW) }
    public(friend) fun excessive_fee(): u64 { error::out_of_range(ERROR_EXCESSIVE_FEE) }
    public(friend) fun pair_not_created(): u64 { error::not_found(ERROR_PAIR_NOT_CREATED) }
    public(friend) fun must_be_inferior_to_twenty(): u64 { error::out_of_range(ERROR_MUST_BE_INFERIOR_TO_TWENTY) } 
    public(friend) fun pool_not_created(): u64 { error::not_found(ERROR_POOL_NOT_CREATED) }
    public(friend) fun no_stake(): u64 { error::not_found(ERROR_NO_STAKE) }
    public(friend) fun insufficient_balance(): u64 { error::aborted(ERROR_INSUFFICIENT_BALANCE) }  
    public(friend) fun no_rewards(): u64 { error::aborted(ERROR_NO_REWARDS) }
    public(friend) fun not_owner(): u64 { error::permission_denied(ERROR_NOT_OWNER) }
    public(friend) fun fee_on_transfer_not_initialized(): u64 { error::not_found(ERROR_FEE_ON_TRANSFER_NOT_INITIALIZED) }
    public(friend) fun output_less_than_min(): u64 { error::out_of_range(ERROR_OUTPUT_LESS_THAN_MIN) }
    public(friend) fun input_more_than_max(): u64 { error::out_of_range(ERROR_INPUT_MORE_THAN_MAX) }
    public(friend) fun insufficient_x_amount(): u64 { error::aborted(ERROR_INSUFFICIENT_X_AMOUNT) }
    public(friend) fun insufficient_y_amount(): u64 { error::aborted(ERROR_INSUFFICIENT_Y_AMOUNT) }
    public(friend) fun pair_created(): u64 { error::already_exists(ERROR_PAIR_CREATED) }
    public(friend) fun pool_exists(): u64 { error::already_exists(ERROR_POOL_EXISTS) }
    public(friend) fun max_coin_name_length(): u64 { error::out_of_range(MAX_COIN_NAME_LENGTH) }
    public(friend) fun coin_type_does_not_match_x_or_y(): u64 { error::internal(COINTYPE_DOES_NOT_MATCH_X_OR_Y) }
    public(friend) fun same_address(): u64 { error::invalid_argument(ERROR_SAME_ADDRESS) }
    public(friend) fun not_liquidity_provider(): u64 { error::aborted(NOT_LIQUIDITY_PROVIDER) }
    public(friend) fun same_token(): u64 { error::invalid_argument(ERROR_SAME_TOKEN) }
    public(friend) fun internal(): u64 { error::internal(ERROR_INTERNAL) }
    public(friend) fun pending_request(): u64 { error::aborted(ERROR_PENDING_REQUEST) } 
    public(friend) fun invalid_tier(): u64 { error::invalid_argument(ERROR_INVALID_TIER) }
    public(friend) fun fee_on_transfer_not_registered(): u64 { error::not_found(ERROR_FEE_ON_TRANSFER_NOT_REGISTERED) }
}