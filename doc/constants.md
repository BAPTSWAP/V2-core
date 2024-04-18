
<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants"></a>

# Module `0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::constants`



-  [Constants](#@Constants_0)
-  [Function `get_resource_account_address`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_resource_account_address)
-  [Function `get_dev_address`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_dev_address)
-  [Function `get_fee_threshold_numerator`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_fee_threshold_numerator)
-  [Function `get_minimum_liquidity`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_minimum_liquidity)
-  [Function `get_max_coin_name_length`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_max_coin_name_length)
-  [Function `get_precision`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_precision)
-  [Function `get_max_u128`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_max_u128)
-  [Function `get_fee_on_transfer_threshold_numerator`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_fee_on_transfer_threshold_numerator)


<pre><code></code></pre>



<a id="@Constants_0"></a>

## Constants


<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_MAX_U128"></a>



<pre><code><b>const</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_MAX_U128">MAX_U128</a>: u128 = 340282366920938463463374607431768211455;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_MAX_COIN_NAME_LENGTH"></a>



<pre><code><b>const</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_MAX_COIN_NAME_LENGTH">MAX_COIN_NAME_LENGTH</a>: u64 = 32;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_DEV"></a>



<pre><code><b>const</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_DEV">DEV</a>: <b>address</b> = 0x4dfbdb89ec2e6f9cf082df0fc8b4b95b0d9b4406a686b8f39bfd39ef1bb030e6;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_DEX_FEE_THRESHOLD_NUMERATOR"></a>



<pre><code><b>const</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_DEX_FEE_THRESHOLD_NUMERATOR">DEX_FEE_THRESHOLD_NUMERATOR</a>: u128 = 90;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_FEE_ON_TRANSFER_THRESHOLD_NUMERATOR"></a>



<pre><code><b>const</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_FEE_ON_TRANSFER_THRESHOLD_NUMERATOR">FEE_ON_TRANSFER_THRESHOLD_NUMERATOR</a>: u128 = 1500;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_MINIMUM_LIQUIDITY"></a>



<pre><code><b>const</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_MINIMUM_LIQUIDITY">MINIMUM_LIQUIDITY</a>: u128 = 1000;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_PRECISION"></a>



<pre><code><b>const</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_PRECISION">PRECISION</a>: u64 = 10000;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_RESOURCE_ACCOUNT"></a>



<pre><code><b>const</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_RESOURCE_ACCOUNT">RESOURCE_ACCOUNT</a>: <b>address</b> = 0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_resource_account_address"></a>

## Function `get_resource_account_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_resource_account_address">get_resource_account_address</a>(): <b>address</b>
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_dev_address"></a>

## Function `get_dev_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_dev_address">get_dev_address</a>(): <b>address</b>
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_fee_threshold_numerator"></a>

## Function `get_fee_threshold_numerator`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_fee_threshold_numerator">get_fee_threshold_numerator</a>(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_minimum_liquidity"></a>

## Function `get_minimum_liquidity`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_minimum_liquidity">get_minimum_liquidity</a>(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_max_coin_name_length"></a>

## Function `get_max_coin_name_length`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_max_coin_name_length">get_max_coin_name_length</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_precision"></a>

## Function `get_precision`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_precision">get_precision</a>(): u64
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_max_u128"></a>

## Function `get_max_u128`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_max_u128">get_max_u128</a>(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_fee_on_transfer_threshold_numerator"></a>

## Function `get_fee_on_transfer_threshold_numerator`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants_get_fee_on_transfer_threshold_numerator">get_fee_on_transfer_threshold_numerator</a>(): u128
</code></pre>
