
<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer"></a>

# Module `0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::fee_on_transfer`



-  [Resource `FeeOnTransferInfo`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_FeeOnTransferInfo)
-  [Struct `FeeOnTransferInfoInitializedEvent`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_FeeOnTransferInfoInitializedEvent)
-  [Struct `LiquidityChangeEvent`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_LiquidityChangeEvent)
-  [Struct `RewardsChangeEvent`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_RewardsChangeEvent)
-  [Struct `TeamChangeEvent`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_TeamChangeEvent)
-  [Function `initialize_fee_on_transfer`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_initialize_fee_on_transfer)
-  [Function `set_liquidity_fee`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_set_liquidity_fee)
-  [Function `set_rewards_fee`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_set_rewards_fee)
-  [Function `set_team_fee`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_set_team_fee)
-  [Function `does_not_exceed_fee_on_transfer_threshold`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_does_not_exceed_fee_on_transfer_threshold)
-  [Function `get_info`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_info)
-  [Function `get_owner`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_owner)
-  [Function `get_liquidity_fee`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_liquidity_fee)
-  [Function `get_team_fee`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_team_fee)
-  [Function `get_rewards_fee`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_rewards_fee)
-  [Function `get_all_fee_on_transfer`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_all_fee_on_transfer)
-  [Function `is_created`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_is_created)


<pre><code><b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::string</a>;
<b>use</b> <a href="">0x1::type_info</a>;
<b>use</b> <a href="">0x4dfbdb89ec2e6f9cf082df0fc8b4b95b0d9b4406a686b8f39bfd39ef1bb030e6::deployer</a>;
<b>use</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::admin</a>;
<b>use</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::constants</a>;
<b>use</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::errors</a>;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_FeeOnTransferInfo"></a>

## Resource `FeeOnTransferInfo`



<pre><code><b>struct</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_FeeOnTransferInfo">FeeOnTransferInfo</a>&lt;CoinType&gt; <b>has</b> <b>copy</b>, drop, store, key
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_FeeOnTransferInfoInitializedEvent"></a>

## Struct `FeeOnTransferInfoInitializedEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_FeeOnTransferInfoInitializedEvent">FeeOnTransferInfoInitializedEvent</a> <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_LiquidityChangeEvent"></a>

## Struct `LiquidityChangeEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_LiquidityChangeEvent">LiquidityChangeEvent</a> <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_RewardsChangeEvent"></a>

## Struct `RewardsChangeEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_RewardsChangeEvent">RewardsChangeEvent</a> <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_TeamChangeEvent"></a>

## Struct `TeamChangeEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_TeamChangeEvent">TeamChangeEvent</a> <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_initialize_fee_on_transfer"></a>

## Function `initialize_fee_on_transfer`



<pre><code><b>public</b> entry <b>fun</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_initialize_fee_on_transfer">initialize_fee_on_transfer</a>&lt;CoinType&gt;(sender: &<a href="">signer</a>, liquidity_fee: u128, rewards_fee: u128, team_fee: u128)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_set_liquidity_fee"></a>

## Function `set_liquidity_fee`



<pre><code><b>public</b> entry <b>fun</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_set_liquidity_fee">set_liquidity_fee</a>&lt;CoinType&gt;(sender: &<a href="">signer</a>, new_fee: u128)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_set_rewards_fee"></a>

## Function `set_rewards_fee`



<pre><code><b>public</b> entry <b>fun</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_set_rewards_fee">set_rewards_fee</a>&lt;CoinType&gt;(sender: &<a href="">signer</a>, new_fee: u128)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_set_team_fee"></a>

## Function `set_team_fee`



<pre><code><b>public</b> entry <b>fun</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_set_team_fee">set_team_fee</a>&lt;CoinType&gt;(sender: &<a href="">signer</a>, new_fee: u128)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_does_not_exceed_fee_on_transfer_threshold"></a>

## Function `does_not_exceed_fee_on_transfer_threshold`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_does_not_exceed_fee_on_transfer_threshold">does_not_exceed_fee_on_transfer_threshold</a>(total_fees_numerator: u128): bool
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_info"></a>

## Function `get_info`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_info">get_info</a>&lt;CoinType&gt;(): <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_FeeOnTransferInfo">fee_on_transfer::FeeOnTransferInfo</a>&lt;CoinType&gt;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_owner"></a>

## Function `get_owner`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_owner">get_owner</a>&lt;CoinType&gt;(): <b>address</b>
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_liquidity_fee"></a>

## Function `get_liquidity_fee`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_liquidity_fee">get_liquidity_fee</a>&lt;CoinType&gt;(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_team_fee"></a>

## Function `get_team_fee`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_team_fee">get_team_fee</a>&lt;CoinType&gt;(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_rewards_fee"></a>

## Function `get_rewards_fee`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_rewards_fee">get_rewards_fee</a>&lt;CoinType&gt;(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_all_fee_on_transfer"></a>

## Function `get_all_fee_on_transfer`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_get_all_fee_on_transfer">get_all_fee_on_transfer</a>&lt;CoinType&gt;(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_is_created"></a>

## Function `is_created`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer_is_created">is_created</a>&lt;CoinType&gt;(): bool
</code></pre>
