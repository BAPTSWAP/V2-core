
<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake"></a>

# Module `0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::stake`



-  [Resource `TokenPairRewardsPool`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_TokenPairRewardsPool)
-  [Resource `RewardsPoolUserInfo`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_RewardsPoolUserInfo)
-  [Function `create_pool`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_create_pool)
-  [Function `deposit`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_deposit)
-  [Function `withdraw`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_withdraw)
-  [Function `claim_rewards`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_claim_rewards)
-  [Function `is_pool_created`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_is_pool_created)
-  [Function `token_rewards_pool_info`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_token_rewards_pool_info)
-  [Function `get_rewards_fees_accumulated`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_get_rewards_fees_accumulated)
-  [Function `distribute_rewards`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_distribute_rewards)


<pre><code><b>use</b> <a href="">0x1::coin</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::type_info</a>;
<b>use</b> <a href="">0x4c26798a23239e4758267ba86fce11a5c7039a28bf1a4ea1207b74e930012a6f::math</a>;
<b>use</b> <a href="">0x4c26798a23239e4758267ba86fce11a5c7039a28bf1a4ea1207b74e930012a6f::u256</a>;
<b>use</b> <a href="">0x4dfbdb89ec2e6f9cf082df0fc8b4b95b0d9b4406a686b8f39bfd39ef1bb030e6::deployer</a>;
<b>use</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::admin</a>;
<b>use</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::constants</a>;
<b>use</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::errors</a>;
<b>use</b> <a href="fee_on_transfer.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_fee_on_transfer">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::fee_on_transfer</a>;
<b>use</b> <a href="utils.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_utils">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::utils</a>;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_TokenPairRewardsPool"></a>

## Resource `TokenPairRewardsPool`



<pre><code><b>struct</b> <a href="stake.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_TokenPairRewardsPool">TokenPairRewardsPool</a>&lt;X, Y&gt; <b>has</b> key
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_RewardsPoolUserInfo"></a>

## Resource `RewardsPoolUserInfo`



<pre><code><b>struct</b> <a href="stake.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_RewardsPoolUserInfo">RewardsPoolUserInfo</a>&lt;X, Y, StakeToken&gt; <b>has</b> store, key
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_create_pool"></a>

## Function `create_pool`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_create_pool">create_pool</a>&lt;CoinType, X, Y&gt;(sender: &<a href="">signer</a>, is_x_staked: bool)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_deposit"></a>

## Function `deposit`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_deposit">deposit</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, amount: u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_withdraw"></a>

## Function `withdraw`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_withdraw">withdraw</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, amount: u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_claim_rewards"></a>

## Function `claim_rewards`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_claim_rewards">claim_rewards</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_is_pool_created"></a>

## Function `is_pool_created`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="stake.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_is_pool_created">is_pool_created</a>&lt;X, Y&gt;(): bool
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_token_rewards_pool_info"></a>

## Function `token_rewards_pool_info`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="stake.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_token_rewards_pool_info">token_rewards_pool_info</a>&lt;X, Y&gt;(): (u64, u64, u64, u128, u128, u128, bool)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_get_rewards_fees_accumulated"></a>

## Function `get_rewards_fees_accumulated`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="stake.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_get_rewards_fees_accumulated">get_rewards_fees_accumulated</a>&lt;X, Y&gt;(): (u64, u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_distribute_rewards"></a>

## Function `distribute_rewards`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="stake.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake_distribute_rewards">distribute_rewards</a>&lt;X, Y&gt;(rewards_x: <a href="_Coin">coin::Coin</a>&lt;X&gt;, rewards_y: <a href="_Coin">coin::Coin</a>&lt;Y&gt;)
</code></pre>
