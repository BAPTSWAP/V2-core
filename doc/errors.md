
<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors"></a>

# Module `0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::errors`



-  [Constants](#@Constants_0)
-  [Function `only_admin`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_only_admin)
-  [Function `already_initialized`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_already_initialized)
-  [Function `not_creator`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_creator)
-  [Function `insufficient_liquidity_minted`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_liquidity_minted)
-  [Function `insufficient_amount`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_amount)
-  [Function `insufficient_liquidity`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_liquidity)
-  [Function `invalid_amount`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_invalid_amount)
-  [Function `tokens_not_sorted`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_tokens_not_sorted)
-  [Function `insufficient_liquidity_burned`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_liquidity_burned)
-  [Function `insufficient_output_amount`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_output_amount)
-  [Function `insufficient_input_amount`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_input_amount)
-  [Function `k`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_k)
-  [Function `x_not_registered`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_x_not_registered)
-  [Function `y_not_registered`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_y_not_registered)
-  [Function `not_admin`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_admin)
-  [Function `not_treasury_address`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_treasury_address)
-  [Function `not_equal_exact_amount`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_equal_exact_amount)
-  [Function `not_resource_account`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_resource_account)
-  [Function `no_fee_withdraw`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_no_fee_withdraw)
-  [Function `excessive_fee`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_excessive_fee)
-  [Function `pair_not_created`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_pair_not_created)
-  [Function `must_be_inferior_to_twenty`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_must_be_inferior_to_twenty)
-  [Function `pool_not_created`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_pool_not_created)
-  [Function `no_stake`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_no_stake)
-  [Function `insufficient_balance`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_balance)
-  [Function `no_rewards`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_no_rewards)
-  [Function `not_owner`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_owner)
-  [Function `fee_on_transfer_not_initialized`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_fee_on_transfer_not_initialized)
-  [Function `output_less_than_min`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_output_less_than_min)
-  [Function `input_more_than_max`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_input_more_than_max)
-  [Function `insufficient_x_amount`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_x_amount)
-  [Function `insufficient_y_amount`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_y_amount)
-  [Function `pair_created`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_pair_created)
-  [Function `pool_exists`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_pool_exists)
-  [Function `max_coin_name_length`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_max_coin_name_length)
-  [Function `coin_type_does_not_match_x_or_y`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_coin_type_does_not_match_x_or_y)
-  [Function `same_address`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_same_address)
-  [Function `not_liquidity_provider`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_liquidity_provider)
-  [Function `same_token`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_same_token)
-  [Function `internal`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_internal)
-  [Function `pending_request`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_pending_request)
-  [Function `invalid_tier`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_invalid_tier)
-  [Function `fee_on_transfer_not_registered`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_fee_on_transfer_not_registered)


<pre><code><b>use</b> <a href="">0x1::error</a>;
</code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_MAX_COIN_NAME_LENGTH"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_MAX_COIN_NAME_LENGTH">MAX_COIN_NAME_LENGTH</a>: u64 = 37;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_COINTYPE_DOES_NOT_MATCH_X_OR_Y"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_COINTYPE_DOES_NOT_MATCH_X_OR_Y">COINTYPE_DOES_NOT_MATCH_X_OR_Y</a>: u64 = 38;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_ALREADY_INITIALIZED"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_ALREADY_INITIALIZED">ERROR_ALREADY_INITIALIZED</a>: u64 = 1;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_EXCESSIVE_FEE"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_EXCESSIVE_FEE">ERROR_EXCESSIVE_FEE</a>: u64 = 22;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_FEE_ON_TRANSFER_NOT_INITIALIZED"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_FEE_ON_TRANSFER_NOT_INITIALIZED">ERROR_FEE_ON_TRANSFER_NOT_INITIALIZED</a>: u64 = 30;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_FEE_ON_TRANSFER_NOT_REGISTERED"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_FEE_ON_TRANSFER_NOT_REGISTERED">ERROR_FEE_ON_TRANSFER_NOT_REGISTERED</a>: u64 = 301;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INPUT_MORE_THAN_MAX"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INPUT_MORE_THAN_MAX">ERROR_INPUT_MORE_THAN_MAX</a>: u64 = 32;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_AMOUNT"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_AMOUNT">ERROR_INSUFFICIENT_AMOUNT</a>: u64 = 6;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_BALANCE"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_BALANCE">ERROR_INSUFFICIENT_BALANCE</a>: u64 = 27;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_INPUT_AMOUNT"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_INPUT_AMOUNT">ERROR_INSUFFICIENT_INPUT_AMOUNT</a>: u64 = 14;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_LIQUIDITY"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_LIQUIDITY">ERROR_INSUFFICIENT_LIQUIDITY</a>: u64 = 7;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_LIQUIDITY_BURNED"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_LIQUIDITY_BURNED">ERROR_INSUFFICIENT_LIQUIDITY_BURNED</a>: u64 = 10;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_LIQUIDITY_MINTED"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_LIQUIDITY_MINTED">ERROR_INSUFFICIENT_LIQUIDITY_MINTED</a>: u64 = 4;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_OUTPUT_AMOUNT"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_OUTPUT_AMOUNT">ERROR_INSUFFICIENT_OUTPUT_AMOUNT</a>: u64 = 13;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_X_AMOUNT"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_X_AMOUNT">ERROR_INSUFFICIENT_X_AMOUNT</a>: u64 = 33;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_Y_AMOUNT"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INSUFFICIENT_Y_AMOUNT">ERROR_INSUFFICIENT_Y_AMOUNT</a>: u64 = 34;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INTERNAL"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INTERNAL">ERROR_INTERNAL</a>: u64 = 1000;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INVALID_AMOUNT"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INVALID_AMOUNT">ERROR_INVALID_AMOUNT</a>: u64 = 8;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INVALID_TIER"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_INVALID_TIER">ERROR_INVALID_TIER</a>: u64 = 43;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_K"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_K">ERROR_K</a>: u64 = 15;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_MUST_BE_INFERIOR_TO_TWENTY"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_MUST_BE_INFERIOR_TO_TWENTY">ERROR_MUST_BE_INFERIOR_TO_TWENTY</a>: u64 = 24;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NOT_ADMIN"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NOT_ADMIN">ERROR_NOT_ADMIN</a>: u64 = 17;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NOT_CREATOR"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NOT_CREATOR">ERROR_NOT_CREATOR</a>: u64 = 2;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NOT_EQUAL_EXACT_AMOUNT"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NOT_EQUAL_EXACT_AMOUNT">ERROR_NOT_EQUAL_EXACT_AMOUNT</a>: u64 = 19;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NOT_OWNER"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NOT_OWNER">ERROR_NOT_OWNER</a>: u64 = 29;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NOT_RESOURCE_ACCOUNT"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NOT_RESOURCE_ACCOUNT">ERROR_NOT_RESOURCE_ACCOUNT</a>: u64 = 20;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NOT_TREASURY_ADDRESS"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NOT_TREASURY_ADDRESS">ERROR_NOT_TREASURY_ADDRESS</a>: u64 = 18;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NO_FEE_WITHDRAW"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NO_FEE_WITHDRAW">ERROR_NO_FEE_WITHDRAW</a>: u64 = 21;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NO_REWARDS"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NO_REWARDS">ERROR_NO_REWARDS</a>: u64 = 28;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NO_STAKE"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_NO_STAKE">ERROR_NO_STAKE</a>: u64 = 26;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_ONLY_ADMIN"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_ONLY_ADMIN">ERROR_ONLY_ADMIN</a>: u64 = 0;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_OUTPUT_LESS_THAN_MIN"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_OUTPUT_LESS_THAN_MIN">ERROR_OUTPUT_LESS_THAN_MIN</a>: u64 = 31;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_PAIR_CREATED"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_PAIR_CREATED">ERROR_PAIR_CREATED</a>: u64 = 35;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_PAIR_NOT_CREATED"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_PAIR_NOT_CREATED">ERROR_PAIR_NOT_CREATED</a>: u64 = 23;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_PENDING_REQUEST"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_PENDING_REQUEST">ERROR_PENDING_REQUEST</a>: u64 = 42;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_POOL_EXISTS"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_POOL_EXISTS">ERROR_POOL_EXISTS</a>: u64 = 36;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_POOL_NOT_CREATED"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_POOL_NOT_CREATED">ERROR_POOL_NOT_CREATED</a>: u64 = 25;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_SAME_ADDRESS"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_SAME_ADDRESS">ERROR_SAME_ADDRESS</a>: u64 = 39;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_SAME_TOKEN"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_SAME_TOKEN">ERROR_SAME_TOKEN</a>: u64 = 41;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_TOKENS_NOT_SORTED"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_TOKENS_NOT_SORTED">ERROR_TOKENS_NOT_SORTED</a>: u64 = 9;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_X_NOT_REGISTERED"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_X_NOT_REGISTERED">ERROR_X_NOT_REGISTERED</a>: u64 = 16;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_Y_NOT_REGISTERED"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_ERROR_Y_NOT_REGISTERED">ERROR_Y_NOT_REGISTERED</a>: u64 = 16;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_NOT_LIQUIDITY_PROVIDER"></a>



<pre><code><b>const</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_NOT_LIQUIDITY_PROVIDER">NOT_LIQUIDITY_PROVIDER</a>: u64 = 40;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_only_admin"></a>

## Function `only_admin`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_only_admin">only_admin</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_already_initialized"></a>

## Function `already_initialized`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_already_initialized">already_initialized</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_creator"></a>

## Function `not_creator`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_creator">not_creator</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_liquidity_minted"></a>

## Function `insufficient_liquidity_minted`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_liquidity_minted">insufficient_liquidity_minted</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_amount"></a>

## Function `insufficient_amount`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_amount">insufficient_amount</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_liquidity"></a>

## Function `insufficient_liquidity`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_liquidity">insufficient_liquidity</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_invalid_amount"></a>

## Function `invalid_amount`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_invalid_amount">invalid_amount</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_tokens_not_sorted"></a>

## Function `tokens_not_sorted`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_tokens_not_sorted">tokens_not_sorted</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_liquidity_burned"></a>

## Function `insufficient_liquidity_burned`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_liquidity_burned">insufficient_liquidity_burned</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_output_amount"></a>

## Function `insufficient_output_amount`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_output_amount">insufficient_output_amount</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_input_amount"></a>

## Function `insufficient_input_amount`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_input_amount">insufficient_input_amount</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_k"></a>

## Function `k`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_k">k</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_x_not_registered"></a>

## Function `x_not_registered`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_x_not_registered">x_not_registered</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_y_not_registered"></a>

## Function `y_not_registered`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_y_not_registered">y_not_registered</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_admin"></a>

## Function `not_admin`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_admin">not_admin</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_treasury_address"></a>

## Function `not_treasury_address`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_treasury_address">not_treasury_address</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_equal_exact_amount"></a>

## Function `not_equal_exact_amount`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_equal_exact_amount">not_equal_exact_amount</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_resource_account"></a>

## Function `not_resource_account`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_resource_account">not_resource_account</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_no_fee_withdraw"></a>

## Function `no_fee_withdraw`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_no_fee_withdraw">no_fee_withdraw</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_excessive_fee"></a>

## Function `excessive_fee`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_excessive_fee">excessive_fee</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_pair_not_created"></a>

## Function `pair_not_created`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_pair_not_created">pair_not_created</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_must_be_inferior_to_twenty"></a>

## Function `must_be_inferior_to_twenty`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_must_be_inferior_to_twenty">must_be_inferior_to_twenty</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_pool_not_created"></a>

## Function `pool_not_created`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_pool_not_created">pool_not_created</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_no_stake"></a>

## Function `no_stake`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_no_stake">no_stake</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_balance"></a>

## Function `insufficient_balance`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_balance">insufficient_balance</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_no_rewards"></a>

## Function `no_rewards`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_no_rewards">no_rewards</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_owner"></a>

## Function `not_owner`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_owner">not_owner</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_fee_on_transfer_not_initialized"></a>

## Function `fee_on_transfer_not_initialized`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_fee_on_transfer_not_initialized">fee_on_transfer_not_initialized</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_output_less_than_min"></a>

## Function `output_less_than_min`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_output_less_than_min">output_less_than_min</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_input_more_than_max"></a>

## Function `input_more_than_max`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_input_more_than_max">input_more_than_max</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_x_amount"></a>

## Function `insufficient_x_amount`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_x_amount">insufficient_x_amount</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_y_amount"></a>

## Function `insufficient_y_amount`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_insufficient_y_amount">insufficient_y_amount</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_pair_created"></a>

## Function `pair_created`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_pair_created">pair_created</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_pool_exists"></a>

## Function `pool_exists`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_pool_exists">pool_exists</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_max_coin_name_length"></a>

## Function `max_coin_name_length`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_max_coin_name_length">max_coin_name_length</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_coin_type_does_not_match_x_or_y"></a>

## Function `coin_type_does_not_match_x_or_y`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_coin_type_does_not_match_x_or_y">coin_type_does_not_match_x_or_y</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_same_address"></a>

## Function `same_address`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_same_address">same_address</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_liquidity_provider"></a>

## Function `not_liquidity_provider`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_not_liquidity_provider">not_liquidity_provider</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_same_token"></a>

## Function `same_token`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_same_token">same_token</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_internal"></a>

## Function `internal`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <b>internal</b>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_pending_request"></a>

## Function `pending_request`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_pending_request">pending_request</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_invalid_tier"></a>

## Function `invalid_tier`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_invalid_tier">invalid_tier</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_fee_on_transfer_not_registered"></a>

## Function `fee_on_transfer_not_registered`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors_fee_on_transfer_not_registered">fee_on_transfer_not_registered</a>(): u64
</code></pre>
