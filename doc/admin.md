
<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin"></a>

# Module `0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::admin`



-  [Resource `AdminInfo`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_AdminInfo)
-  [Resource `Universal`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_Universal)
-  [Resource `PopularTraded`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_PopularTraded)
-  [Resource `Stable`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_Stable)
-  [Resource `VeryStable`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_VeryStable)
-  [Resource `Pending`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_Pending)
-  [Struct `Admin`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_Admin)
-  [Struct `Treasury`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_Treasury)
-  [Struct `OwnershipTransferRequestEvent`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_OwnershipTransferRequestEvent)
-  [Struct `OwnershipTransferCanceledEvent`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_OwnershipTransferCanceledEvent)
-  [Struct `TreasuryAddressUpdatedEvent`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_TreasuryAddressUpdatedEvent)
-  [Struct `AdminUpdatedEvent`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_AdminUpdatedEvent)
-  [Struct `DexLiquidityFeeUpdatedEvent`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_DexLiquidityFeeUpdatedEvent)
-  [Struct `DexTreasuryFeeUpdatedEvent`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_DexTreasuryFeeUpdatedEvent)
-  [Struct `OwnershipTransferRejectedEvent`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_OwnershipTransferRejectedEvent)
-  [Function `offer_admin_previliges`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_offer_admin_previliges)
-  [Function `offer_treasury_previliges`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_offer_treasury_previliges)
-  [Function `cancel_admin_previliges`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_cancel_admin_previliges)
-  [Function `cancel_treasury_previliges`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_cancel_treasury_previliges)
-  [Function `claim_admin_previliges`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_claim_admin_previliges)
-  [Function `claim_treasury_previliges`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_claim_treasury_previliges)
-  [Function `reject_admin_previliges`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_reject_admin_previliges)
-  [Function `reject_treasury_previliges`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_reject_treasury_previliges)
-  [Function `set_dex_liquidity_fee`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_set_dex_liquidity_fee)
-  [Function `set_dex_treasury_fee`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_set_dex_treasury_fee)
-  [Function `get_resource_signer`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_resource_signer)
-  [Function `get_treasury_address`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_treasury_address)
-  [Function `get_admin`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_admin)
-  [Function `get_liquidity_fee_modifier`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_liquidity_fee_modifier)
-  [Function `get_treasury_fee_modifier`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_treasury_fee_modifier)
-  [Function `get_dex_fees`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_dex_fees)
-  [Function `get_universal_liquidity_fee_modifier`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_universal_liquidity_fee_modifier)
-  [Function `get_popular_traded_liquidity_fee_modifier`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_popular_traded_liquidity_fee_modifier)
-  [Function `get_stable_liquidity_fee_modifier`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_stable_liquidity_fee_modifier)
-  [Function `get_very_stable_liquidity_fee_modifier`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_very_stable_liquidity_fee_modifier)
-  [Function `get_universal_tier_fees`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_universal_tier_fees)
-  [Function `get_popular_traded_tier_fees`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_popular_traded_tier_fees)
-  [Function `get_stable_tier_fees`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_stable_tier_fees)
-  [Function `get_very_stable_tier_fees`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_very_stable_tier_fees)
-  [Function `is_valid_tier`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_is_valid_tier)
-  [Function `does_not_exceed_dex_fee_threshold`](#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_does_not_exceed_dex_fee_threshold)


<pre><code><b>use</b> <a href="">0x1::account</a>;
<b>use</b> <a href="">0x1::event</a>;
<b>use</b> <a href="">0x1::resource_account</a>;
<b>use</b> <a href="">0x1::signer</a>;
<b>use</b> <a href="">0x1::smart_table</a>;
<b>use</b> <a href="">0x1::type_info</a>;
<b>use</b> <a href="constants.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_constants">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::constants</a>;
<b>use</b> <a href="errors.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_errors">0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6::errors</a>;
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_AdminInfo"></a>

## Resource `AdminInfo`



<pre><code><b>struct</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_AdminInfo">AdminInfo</a> <b>has</b> key
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_Universal"></a>

## Resource `Universal`



<pre><code><b>struct</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_Universal">Universal</a> <b>has</b> key
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_PopularTraded"></a>

## Resource `PopularTraded`



<pre><code><b>struct</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_PopularTraded">PopularTraded</a> <b>has</b> key
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_Stable"></a>

## Resource `Stable`



<pre><code><b>struct</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_Stable">Stable</a> <b>has</b> key
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_VeryStable"></a>

## Resource `VeryStable`



<pre><code><b>struct</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_VeryStable">VeryStable</a> <b>has</b> key
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_Pending"></a>

## Resource `Pending`



<pre><code><b>struct</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_Pending">Pending</a>&lt;T&gt; <b>has</b> key
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_Admin"></a>

## Struct `Admin`



<pre><code><b>struct</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_Admin">Admin</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_Treasury"></a>

## Struct `Treasury`



<pre><code><b>struct</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_Treasury">Treasury</a> <b>has</b> <b>copy</b>, drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_OwnershipTransferRequestEvent"></a>

## Struct `OwnershipTransferRequestEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_OwnershipTransferRequestEvent">OwnershipTransferRequestEvent</a> <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_OwnershipTransferCanceledEvent"></a>

## Struct `OwnershipTransferCanceledEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_OwnershipTransferCanceledEvent">OwnershipTransferCanceledEvent</a> <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_TreasuryAddressUpdatedEvent"></a>

## Struct `TreasuryAddressUpdatedEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_TreasuryAddressUpdatedEvent">TreasuryAddressUpdatedEvent</a> <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_AdminUpdatedEvent"></a>

## Struct `AdminUpdatedEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_AdminUpdatedEvent">AdminUpdatedEvent</a> <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_DexLiquidityFeeUpdatedEvent"></a>

## Struct `DexLiquidityFeeUpdatedEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_DexLiquidityFeeUpdatedEvent">DexLiquidityFeeUpdatedEvent</a> <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_DexTreasuryFeeUpdatedEvent"></a>

## Struct `DexTreasuryFeeUpdatedEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_DexTreasuryFeeUpdatedEvent">DexTreasuryFeeUpdatedEvent</a> <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_OwnershipTransferRejectedEvent"></a>

## Struct `OwnershipTransferRejectedEvent`



<pre><code>#[<a href="">event</a>]
<b>struct</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_OwnershipTransferRejectedEvent">OwnershipTransferRejectedEvent</a> <b>has</b> drop, store
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_offer_admin_previliges"></a>

## Function `offer_admin_previliges`



<pre><code><b>public</b> entry <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_offer_admin_previliges">offer_admin_previliges</a>(signer_ref: &<a href="">signer</a>, receiver_addr: <b>address</b>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_offer_treasury_previliges"></a>

## Function `offer_treasury_previliges`



<pre><code><b>public</b> entry <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_offer_treasury_previliges">offer_treasury_previliges</a>(signer_ref: &<a href="">signer</a>, receiver_addr: <b>address</b>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_cancel_admin_previliges"></a>

## Function `cancel_admin_previliges`



<pre><code><b>public</b> entry <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_cancel_admin_previliges">cancel_admin_previliges</a>(signer_ref: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_cancel_treasury_previliges"></a>

## Function `cancel_treasury_previliges`



<pre><code><b>public</b> entry <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_cancel_treasury_previliges">cancel_treasury_previliges</a>(signer_ref: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_claim_admin_previliges"></a>

## Function `claim_admin_previliges`



<pre><code><b>public</b> entry <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_claim_admin_previliges">claim_admin_previliges</a>(signer_ref: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_claim_treasury_previliges"></a>

## Function `claim_treasury_previliges`



<pre><code><b>public</b> entry <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_claim_treasury_previliges">claim_treasury_previliges</a>(signer_ref: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_reject_admin_previliges"></a>

## Function `reject_admin_previliges`



<pre><code><b>public</b> entry <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_reject_admin_previliges">reject_admin_previliges</a>(signer_ref: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_reject_treasury_previliges"></a>

## Function `reject_treasury_previliges`



<pre><code><b>public</b> entry <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_reject_treasury_previliges">reject_treasury_previliges</a>(signer_ref: &<a href="">signer</a>)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_set_dex_liquidity_fee"></a>

## Function `set_dex_liquidity_fee`



<pre><code><b>public</b> entry <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_set_dex_liquidity_fee">set_dex_liquidity_fee</a>(sender: &<a href="">signer</a>, new_fee: u128)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_set_dex_treasury_fee"></a>

## Function `set_dex_treasury_fee`



<pre><code><b>public</b> entry <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_set_dex_treasury_fee">set_dex_treasury_fee</a>(sender: &<a href="">signer</a>, new_fee: u128)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_resource_signer"></a>

## Function `get_resource_signer`



<pre><code><b>public</b>(<b>friend</b>) <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_resource_signer">get_resource_signer</a>(): <a href="">signer</a>
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_treasury_address"></a>

## Function `get_treasury_address`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_treasury_address">get_treasury_address</a>(): <b>address</b>
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_admin"></a>

## Function `get_admin`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_admin">get_admin</a>(): <b>address</b>
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_liquidity_fee_modifier"></a>

## Function `get_liquidity_fee_modifier`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_liquidity_fee_modifier">get_liquidity_fee_modifier</a>(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_treasury_fee_modifier"></a>

## Function `get_treasury_fee_modifier`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_treasury_fee_modifier">get_treasury_fee_modifier</a>(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_dex_fees"></a>

## Function `get_dex_fees`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_dex_fees">get_dex_fees</a>(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_universal_liquidity_fee_modifier"></a>

## Function `get_universal_liquidity_fee_modifier`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_universal_liquidity_fee_modifier">get_universal_liquidity_fee_modifier</a>(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_popular_traded_liquidity_fee_modifier"></a>

## Function `get_popular_traded_liquidity_fee_modifier`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_popular_traded_liquidity_fee_modifier">get_popular_traded_liquidity_fee_modifier</a>(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_stable_liquidity_fee_modifier"></a>

## Function `get_stable_liquidity_fee_modifier`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_stable_liquidity_fee_modifier">get_stable_liquidity_fee_modifier</a>(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_very_stable_liquidity_fee_modifier"></a>

## Function `get_very_stable_liquidity_fee_modifier`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_very_stable_liquidity_fee_modifier">get_very_stable_liquidity_fee_modifier</a>(): u128
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_universal_tier_fees"></a>

## Function `get_universal_tier_fees`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_universal_tier_fees">get_universal_tier_fees</a>(): (u128, u128)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_popular_traded_tier_fees"></a>

## Function `get_popular_traded_tier_fees`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_popular_traded_tier_fees">get_popular_traded_tier_fees</a>(): (u128, u128)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_stable_tier_fees"></a>

## Function `get_stable_tier_fees`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_stable_tier_fees">get_stable_tier_fees</a>(): (u128, u128)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_very_stable_tier_fees"></a>

## Function `get_very_stable_tier_fees`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_get_very_stable_tier_fees">get_very_stable_tier_fees</a>(): (u128, u128)
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_is_valid_tier"></a>

## Function `is_valid_tier`



<pre><code>#[view]
<b>public</b> <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_is_valid_tier">is_valid_tier</a>&lt;Tier&gt;(): bool
</code></pre>



<a id="0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_does_not_exceed_dex_fee_threshold"></a>

## Function `does_not_exceed_dex_fee_threshold`



<pre><code><b>public</b> <b>fun</b> <a href="admin.md#0x91a65207f3a8ac7447da7efe3fd640ef6eaf8f68fcf07f6bec489b89fbef2cd6_admin_does_not_exceed_dex_fee_threshold">does_not_exceed_dex_fee_threshold</a>(total_fees_numerator: u128): bool
</code></pre>
