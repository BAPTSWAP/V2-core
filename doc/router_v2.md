
<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2"></a>

# Module `0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::router_v2`



-  [Function `create_pair`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_create_pair)
-  [Function `register_fee_on_transfer_in_a_pair`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_register_fee_on_transfer_in_a_pair)
-  [Function `stake_tokens_in_pool`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_stake_tokens_in_pool)
-  [Function `unstake_tokens_from_pool`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_unstake_tokens_from_pool)
-  [Function `claim_rewards_from_pool`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_claim_rewards_from_pool)
-  [Function `add_liquidity`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_add_liquidity)
-  [Function `remove_liquidity`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_remove_liquidity)
-  [Function `swap_exact_input`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_swap_exact_input)
-  [Function `multi_hop_exact_input`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_multi_hop_exact_input)
-  [Function `swap_exact_input_with_one_intermediate_coin`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_swap_exact_input_with_one_intermediate_coin)
-  [Function `swap_exact_input_with_apt_as_intermidiate`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_swap_exact_input_with_apt_as_intermidiate)
-  [Function `swap_exact_input_with_two_intermediate_coins`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_swap_exact_input_with_two_intermediate_coins)
-  [Function `swap_exact_output`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_swap_exact_output)
-  [Function `get_amount_in`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_get_amount_in)
-  [Function `register_lp`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_register_lp)
-  [Function `register_token`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_register_token)
-  [Function `update_fee_tier`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_update_fee_tier)


<pre><code><b>use</b> <a href="">0x1::aptos_coin</a>;
<b>use</b> <a href="">0x1::coin</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::errors</a>;
<b>use</b> <a href="stake.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_stake">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::stake</a>;
<b>use</b> <a href="swap_utils_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_utils_v2">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::swap_utils_v2</a>;
<b>use</b> <a href="swap_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_swap_v2">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::swap_v2</a>;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_create_pair"></a>

## Function `create_pair`



<pre><code><b>public</b> entry <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_create_pair">create_pair</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_register_fee_on_transfer_in_a_pair"></a>

## Function `register_fee_on_transfer_in_a_pair`



<pre><code><b>public</b> entry <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_register_fee_on_transfer_in_a_pair">register_fee_on_transfer_in_a_pair</a>&lt;CoinType, X, Y&gt;(sender: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_stake_tokens_in_pool"></a>

## Function `stake_tokens_in_pool`



<pre><code><b>public</b> entry <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_stake_tokens_in_pool">stake_tokens_in_pool</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, amount: u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_unstake_tokens_from_pool"></a>

## Function `unstake_tokens_from_pool`



<pre><code><b>public</b> entry <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_unstake_tokens_from_pool">unstake_tokens_from_pool</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, amount: u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_claim_rewards_from_pool"></a>

## Function `claim_rewards_from_pool`



<pre><code><b>public</b> entry <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_claim_rewards_from_pool">claim_rewards_from_pool</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_add_liquidity"></a>

## Function `add_liquidity`



<pre><code><b>public</b> entry <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_add_liquidity">add_liquidity</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, amount_x_desired: u64, amount_y_desired: u64, amount_x_min: u64, amount_y_min: u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_remove_liquidity"></a>

## Function `remove_liquidity`



<pre><code><b>public</b> entry <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_remove_liquidity">remove_liquidity</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, liquidity: u64, amount_x_min: u64, amount_y_min: u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_swap_exact_input"></a>

## Function `swap_exact_input`



<pre><code><b>public</b> entry <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_swap_exact_input">swap_exact_input</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, x_in: u64, y_min_out: u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_multi_hop_exact_input"></a>

## Function `multi_hop_exact_input`



<pre><code><b>public</b> <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_multi_hop_exact_input">multi_hop_exact_input</a>&lt;X, Y, Z&gt;(sender: &<a href="">signer</a>, x_in: u64, y_min_out: u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_swap_exact_input_with_one_intermediate_coin"></a>

## Function `swap_exact_input_with_one_intermediate_coin`



<pre><code><b>public</b> entry <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_swap_exact_input_with_one_intermediate_coin">swap_exact_input_with_one_intermediate_coin</a>&lt;X, Y, Z&gt;(sender: &<a href="">signer</a>, x_in: u64, y_min_out: u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_swap_exact_input_with_apt_as_intermidiate"></a>

## Function `swap_exact_input_with_apt_as_intermidiate`



<pre><code><b>public</b> entry <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_swap_exact_input_with_apt_as_intermidiate">swap_exact_input_with_apt_as_intermidiate</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, x_in: u64, y_min_out: u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_swap_exact_input_with_two_intermediate_coins"></a>

## Function `swap_exact_input_with_two_intermediate_coins`



<pre><code><b>public</b> entry <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_swap_exact_input_with_two_intermediate_coins">swap_exact_input_with_two_intermediate_coins</a>&lt;X, Y, Z, W&gt;(sender: &<a href="">signer</a>, x_in: u64, y_min_out: u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_swap_exact_output"></a>

## Function `swap_exact_output`



<pre><code><b>public</b> entry <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_swap_exact_output">swap_exact_output</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>, y_out: u64, x_max_in: u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_get_amount_in"></a>

## Function `get_amount_in`



<pre><code><b>public</b> <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_get_amount_in">get_amount_in</a>&lt;X, Y&gt;(y_out_amount: u64): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_register_lp"></a>

## Function `register_lp`



<pre><code><b>public</b> entry <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_register_lp">register_lp</a>&lt;X, Y&gt;(sender: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_register_token"></a>

## Function `register_token`



<pre><code><b>public</b> entry <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_register_token">register_token</a>&lt;X&gt;(sender: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_update_fee_tier"></a>

## Function `update_fee_tier`



<pre><code><b>public</b> entry <b>fun</b> <a href="router_v2.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_router_v2_update_fee_tier">update_fee_tier</a>&lt;Tier, X, Y&gt;(signer_ref: &<a href="">signer</a>)
</code></pre>
