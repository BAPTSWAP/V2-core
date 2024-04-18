
<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_utils"></a>

# Module `0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::utils`



-  [Function `calculate_amount`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_utils_calculate_amount)
-  [Function `check_or_register_coin_store`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_utils_check_or_register_coin_store)
-  [Function `transfer_in`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_utils_transfer_in)
-  [Function `transfer_out`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_utils_transfer_out)


<pre><code><b>use</b> <a href="">0x1::coin</a>;
<b>use</b> <a href="">0x1::signer</a>;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_utils_calculate_amount"></a>

## Function `calculate_amount`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="utils.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_utils_calculate_amount">calculate_amount</a>(numerator: u128, amount_in: u64): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_utils_check_or_register_coin_store"></a>

## Function `check_or_register_coin_store`



<pre><code><b>public</b> <b>fun</b> <a href="utils.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_utils_check_or_register_coin_store">check_or_register_coin_store</a>&lt;X&gt;(sender: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_utils_transfer_in"></a>

## Function `transfer_in`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="utils.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_utils_transfer_in">transfer_in</a>&lt;CoinType&gt;(own_coin: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;CoinType&gt;, <a href="">account</a>: &<a href="">signer</a>, amount: u64)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_utils_transfer_out"></a>

## Function `transfer_out`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="utils.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_utils_transfer_out">transfer_out</a>&lt;CoinType&gt;(own_coin: &<b>mut</b> <a href="_Coin">coin::Coin</a>&lt;CoinType&gt;, receiver: &<a href="">signer</a>, amount: u64)
</code></pre>
