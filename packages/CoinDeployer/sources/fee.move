/*
    fee module
*/

module bapt_framework::fee {
    use std::signer;

    struct Fee has key {
        fee: u64,
        fee_account: address
    }

    // init fee
    public fun init(signer_ref: &signer, fee: u64) {
        // only bapt framework account can init fee
        assert!(signer::address_of(signer_ref) == @bapt_framework, 0);
        // store the resource under the signer account
        move_to(
            signer_ref,
            Fee {
                fee: fee,
                fee_account: signer::address_of(signer_ref)
            }
        );
    }

    // Accessor
    inline fun authorized_mut_borrow(signer_ref: &signer): &mut Fee acquires Fee {
        assert!(signer::address_of(signer_ref) == @bapt_framework, 0);
        borrow_global_mut<Fee>(@bapt_framework)
    }

    // update fee
    public fun update_fee(signer_ref: &signer, new_fee: u64) acquires Fee {
        let fee_resource = authorized_mut_borrow(signer_ref);
        fee_resource.fee = new_fee;
    }

    // update fee account
    public fun update_fee_account(signer_ref: &signer, new_fee_account: address) acquires Fee {
        let fee_resource = authorized_mut_borrow(signer_ref);
        fee_resource.fee_account = new_fee_account;
    }

    #[view]
    // get fee
    public fun get_fee(): u64  acquires Fee {
        borrow_global<Fee>(@bapt_framework).fee
    }

    #[view]
    // get fee account
    public fun get_fee_account(): address  acquires Fee {
        borrow_global<Fee>(@bapt_framework).fee_account
    }

    #[test(bapt = @bapt_framework, new_bapt = @0x123)]
    public fun test_fee(
        bapt: &signer,
        new_bapt: address
    )  acquires Fee {
        init(bapt, 100);
        assert!(get_fee() == 100, 0);
        update_fee(bapt, 200);
        assert!(get_fee() == 200, 0);
        update_fee_account(bapt, new_bapt);
        assert!(
            borrow_global<Fee>(@bapt_framework).fee_account == new_bapt,
            0
        );
    }
}