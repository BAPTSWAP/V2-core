
<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2"></a>

# Module `0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::swap_v2`



-  [Resource `LPToken`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_LPToken)
-  [Resource `TokenPairMetadata`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_TokenPairMetadata)
-  [Resource `TokenPairReserve`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_TokenPairReserve)
-  [Struct `PairCreatedEvent`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_PairCreatedEvent)
-  [Resource `PairEventHolder`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_PairEventHolder)
-  [Struct `AddLiquidityEvent`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_AddLiquidityEvent)
-  [Struct `RemoveLiquidityEvent`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_RemoveLiquidityEvent)
-  [Struct `SwapEvent`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_SwapEvent)
-  [Struct `FeeOnTransferRegistered`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_FeeOnTransferRegistered)
-  [Function `add_swap_event`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_add_swap_event)
-  [Function `add_swap_event_with_address`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_add_swap_event_with_address)
-  [Function `emit_pair_created_event`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_emit_pair_created_event)
-  [Function `toggle_all_fees`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_toggle_all_fees)
-  [Function `toggle_liquidity_fee`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_toggle_liquidity_fee)
-  [Function `toggle_team_fee`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_toggle_team_fee)
-  [Function `toggle_rewards_fee`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_toggle_rewards_fee)
-  [Function `add_liquidity`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_add_liquidity)
-  [Function `remove_liquidity`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_remove_liquidity)
-  [Function `create_pair`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_create_pair)
-  [Function `add_fee_on_transfer_in_pair`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_add_fee_on_transfer_in_pair)
-  [Function `swap_exact_x_to_y`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_exact_x_to_y)
-  [Function `swap_x_to_exact_y`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_x_to_exact_y)
-  [Function `swap_x_to_exact_y_direct`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_x_to_exact_y_direct)
-  [Function `swap_exact_y_to_x`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_exact_y_to_x)
-  [Function `swap_y_to_exact_x`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_y_to_exact_x)
-  [Function `swap_y_to_exact_x_direct`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_y_to_exact_x_direct)
-  [Function `is_pair_created`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_is_pair_created)
-  [Function `total_lp_supply`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_total_lp_supply)
-  [Function `liquidity_fee`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_liquidity_fee)
-  [Function `token_fees`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_token_fees)
-  [Function `token_reserves`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_token_reserves)
-  [Function `token_balances`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_token_balances)
-  [Function `lp_balance`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_lp_balance)
-  [Function `get_reserve`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_get_reserve)
-  [Function `is_fee_on_transfer_registered`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_is_fee_on_transfer_registered)
-  [Function `get_dex_fees_in_a_pair`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_get_dex_fees_in_a_pair)
-  [Function `register_lp`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_register_lp)
-  [Function `update_fee_tier`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_update_fee_tier)


<pre><code><b>use</b> <a href="">0x1::account</a>;
<b>use</b> <a href="">0x1::aptos_account</a>;
<b>use</b> <a href="">0x1::coin</a>;
<b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::option</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::timestamp</a>;
<b>use</b> <a href="">0x1::type_info</a>;
<b>use</b> <a href="">0x4c26798a23239e4758267ba86fce11a5c7039a28bf1a4ea1207b74e930012a6f::math</a>;
<b>use</b> <a href="">0x4c26798a23239e4758267ba86fce11a5c7039a28bf1a4ea1207b74e930012a6f::u256</a>;
<b>use</b> <a href="">0x4dfbdb89ec2e6f9cf082df0fc8b4b95b0d9b4406a686b8f39bfd39ef1bb030e6::deployer</a>;
<b>use</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::admin</a>;
<b>use</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::constants</a>;
<b>use</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::errors</a>;
<b>use</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::fee_on_transfer</a>;
<b>use</b> <a href="stake.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::stake</a>;
<b>use</b> <a href="swap_utils_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_utils_v2">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::swap_utils_v2</a>;
<b>use</b> <a href="utils.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_utils">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::utils</a>;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_LPToken"></a>

## Resource `LPToken`



<pre><code><b>struct</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_LPToken">LPToken</a>&lt;X, Y&gt; <b>has</b> key
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_TokenPairMetadata"></a>

## Resource `TokenPairMetadata`



<pre><code><b>struct</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_TokenPairMetadata">TokenPairMetadata</a>&lt;X, Y&gt; <b>has</b> key
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_TokenPairReserve"></a>

## Resource `TokenPairReserve`



<pre><code><b>struct</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_TokenPairReserve">TokenPairReserve</a>&lt;X, Y&gt; <b>has</b> key
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_PairCreatedEvent"></a>

## Struct `PairCreatedEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_PairCreatedEvent">PairCreatedEvent</a> <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_PairEventHolder"></a>

## Resource `PairEventHolder`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_PairEventHolder">PairEventHolder</a>&lt;X, Y&gt; <b>has</b> key
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_AddLiquidityEvent"></a>

## Struct `AddLiquidityEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_AddLiquidityEvent">AddLiquidityEvent</a>&lt;X, Y&gt; <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_RemoveLiquidityEvent"></a>

## Struct `RemoveLiquidityEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_RemoveLiquidityEvent">RemoveLiquidityEvent</a>&lt;X, Y&gt; <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_SwapEvent"></a>

## Struct `SwapEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_SwapEvent">SwapEvent</a>&lt;X, Y&gt; <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_FeeOnTransferRegistered"></a>

## Struct `FeeOnTransferRegistered`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_FeeOnTransferRegistered">FeeOnTransferRegistered</a>&lt;X, Y&gt; <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_add_swap_event"></a>

## Function `add_swap_event`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_add_swap_event">add_swap_event</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, amount_x_in: u64, amount_y_in: u64, amount_x_out: u64, amount_y_out: u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_add_swap_event_with_address"></a>

## Function `add_swap_event_with_address`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_add_swap_event_with_address">add_swap_event_with_address</a>&lt;X, Y&gt;(sender_addr: <b>address</b>, amount_x_in: u64, amount_y_in: u64, amount_x_out: u64, amount_y_out: u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_emit_pair_created_event"></a>

## Function `emit_pair_created_event`



<pre><code><b>public</b> <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_emit_pair_created_event">emit_pair_created_event</a>(user: <b>address</b>, token_x: <a href="_String">string::String</a>, token_y: <a href="_String">string::String</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_toggle_all_fees"></a>

## Function `toggle_all_fees`



<pre><code><b>public</b> entry <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_toggle_all_fees">toggle_all_fees</a>&lt;CoinType, X, Y&gt;(sender: &<a href="">signer</a>, activate: bool)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_toggle_liquidity_fee"></a>

## Function `toggle_liquidity_fee`



<pre><code><b>public</b> entry <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_toggle_liquidity_fee">toggle_liquidity_fee</a>&lt;CoinType, X, Y&gt;(sender: &<a href="">signer</a>, activate: bool)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_toggle_team_fee"></a>

## Function `toggle_team_fee`



<pre><code><b>public</b> entry <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_toggle_team_fee">toggle_team_fee</a>&lt;CoinType, X, Y&gt;(sender: &<a href="">signer</a>, activate: bool)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_toggle_rewards_fee"></a>

## Function `toggle_rewards_fee`



<pre><code><b>public</b> entry <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_toggle_rewards_fee">toggle_rewards_fee</a>&lt;CoinType, X, Y&gt;(sender: &<a href="">signer</a>, activate: bool)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_add_liquidity"></a>

## Function `add_liquidity`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_add_liquidity">add_liquidity</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, amount_x: u64, amount_y: u64): (u64, u64, u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_remove_liquidity"></a>

## Function `remove_liquidity`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_remove_liquidity">remove_liquidity</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, liquidity: u64): (u64, u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_create_pair"></a>

## Function `create_pair`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_create_pair">create_pair</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_add_fee_on_transfer_in_pair"></a>

## Function `add_fee_on_transfer_in_pair`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_add_fee_on_transfer_in_pair">add_fee_on_transfer_in_pair</a>&lt;CoinType, X, Y&gt;(sender: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_exact_x_to_y"></a>

## Function `swap_exact_x_to_y`

Swap X to Y, X is in and Y is out. This method assumes amount_out_min is 0


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_exact_x_to_y">swap_exact_x_to_y</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, amount_in: u64, <b>to</b>: <b>address</b>): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_x_to_exact_y"></a>

## Function `swap_x_to_exact_y`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_x_to_exact_y">swap_x_to_exact_y</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, amount_in: u64, amount_out: u64, <b>to</b>: <b>address</b>): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_x_to_exact_y_direct"></a>

## Function `swap_x_to_exact_y_direct`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_x_to_exact_y_direct">swap_x_to_exact_y_direct</a>&lt;X, Y&gt;(coins_in: <a href="_Coin">coin::Coin</a>&lt;X&gt;, amount_out: u64): (<a href="_Coin">coin::Coin</a>&lt;X&gt;, <a href="_Coin">coin::Coin</a>&lt;Y&gt;)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_exact_y_to_x"></a>

## Function `swap_exact_y_to_x`

Swap Y to X, Y is in and X is out. This method assumes amount_out_min is 0


<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_exact_y_to_x">swap_exact_y_to_x</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, amount_in: u64, <b>to</b>: <b>address</b>): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_y_to_exact_x"></a>

## Function `swap_y_to_exact_x`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_y_to_exact_x">swap_y_to_exact_x</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, amount_in: u64, amount_out: u64, <b>to</b>: <b>address</b>): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_y_to_exact_x_direct"></a>

## Function `swap_y_to_exact_x_direct`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_swap_y_to_exact_x_direct">swap_y_to_exact_x_direct</a>&lt;X, Y&gt;(coins_in: <a href="_Coin">coin::Coin</a>&lt;Y&gt;, amount_out: u64): (<a href="_Coin">coin::Coin</a>&lt;X&gt;, <a href="_Coin">coin::Coin</a>&lt;Y&gt;)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_is_pair_created"></a>

## Function `is_pair_created`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_is_pair_created">is_pair_created</a>&lt;X, Y&gt;(): bool
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_total_lp_supply"></a>

## Function `total_lp_supply`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_total_lp_supply">total_lp_supply</a>&lt;X, Y&gt;(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_liquidity_fee"></a>

## Function `liquidity_fee`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_liquidity_fee">liquidity_fee</a>&lt;X, Y&gt;(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_token_fees"></a>

## Function `token_fees`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_token_fees">token_fees</a>&lt;X, Y&gt;(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_token_reserves"></a>

## Function `token_reserves`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_token_reserves">token_reserves</a>&lt;X, Y&gt;(): (u64, u64, u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_token_balances"></a>

## Function `token_balances`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_token_balances">token_balances</a>&lt;X, Y&gt;(): (u64, u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_lp_balance"></a>

## Function `lp_balance`



<pre><code><b>public</b> <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_lp_balance">lp_balance</a>&lt;X, Y&gt;(addr: <b>address</b>): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_get_reserve"></a>

## Function `get_reserve`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_get_reserve">get_reserve</a>&lt;X, Y&gt;(): <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_TokenPairReserve">swap_v2::TokenPairReserve</a>&lt;X, Y&gt;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_is_fee_on_transfer_registered"></a>

## Function `is_fee_on_transfer_registered`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_is_fee_on_transfer_registered">is_fee_on_transfer_registered</a>&lt;CoinType, X, Y&gt;(): bool
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_get_dex_fees_in_a_pair"></a>

## Function `get_dex_fees_in_a_pair`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_get_dex_fees_in_a_pair">get_dex_fees_in_a_pair</a>&lt;X, Y&gt;(): (u128, u128)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_register_lp"></a>

## Function `register_lp`



<pre><code><b>public</b> <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_register_lp">register_lp</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_update_fee_tier"></a>

## Function `update_fee_tier`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2_update_fee_tier">update_fee_tier</a>&lt;Tier, X, Y&gt;(signer_ref: &<a href="">signer</a>)
</code></pre>
