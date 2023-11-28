/*
    used to transfer admintration previliges from one address to another.
    - offer claim pattern
    TODO: 
        - add events
        - add errors
*/
module baptswap_v2::ownership_transfers {

    use aptos_framework::account;
    use aptos_framework::resource_account;

    use aptos_std::smart_table::{Self, SmartTable};
    use std::signer;

    use baptswap_v2::admin;
    use baptswap_v2::constants;
    use baptswap_v2::errors;

    // Global storage for pending ownership transfer
    struct Pending has key {
        table: SmartTable<u64, address>  // <id, ownership offer>
    }

    fun init_module(sender: &signer) {
        let signer_cap = resource_account::retrieve_resource_account_cap(sender, @dev_2);
        let resource_signer = account::create_signer_with_capability(&signer_cap);
        move_to(&resource_signer, Pending { table: smart_table::new() });
    }

    // from the perspective of the sender
    public entry fun offer_admin_previliges(signer_ref: &signer, receiver_addr: address, id: u64) acquires Pending {
        // assert signer is the admin
        assert!(signer::address_of(signer_ref) == admin::get_admin(), errors::not_admin());
        // assert receiver_addr is not the admin
        assert!(receiver_addr != admin::get_admin(), errors::same_address());
        // create a new table entry
        smart_table::add<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id, receiver_addr)
    }

    public entry fun offer_treasury_previliges(signer_ref: &signer, receiver_addr: address, id: u64) acquires Pending {
        // assert signer is the admin
        assert!(signer::address_of(signer_ref) == admin::get_admin(), errors::not_admin());
        // assert receiver_addr is not the admin
        assert!(receiver_addr != admin::get_treasury_address(), errors::same_address());
        // create a new table entry
        smart_table::add<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id, receiver_addr)
    }

    public entry fun cancel_admin_previliges(signer_ref: &signer, id: u64) acquires Pending {
        // destruct the pending resource
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id);
    }

    public entry fun cancel_treasury_previliges(signer_ref: &signer, id: u64) acquires Pending {
        // destruct the pending resource
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id);
    }

    // from the perspective of the receiver
    public entry fun claim_admin_previliges(signer_ref: &signer, id: u64) acquires Pending {
        // assert id exists and the signer is the receiver
        assert!(smart_table::contains<u64, address>(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        assert!(signer::address_of(signer_ref) == *smart_table::borrow(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        // update admin info 
        admin::set_admin(*smart_table::borrow(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id));
        // remove the entry
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id);
    }

    public entry fun claim_treasury_previliges(signer_ref: &signer, id: u64) acquires Pending {
        // assert id exists and the signer is the receiver
        assert!(smart_table::contains<u64, address>(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        assert!(signer::address_of(signer_ref) == *smart_table::borrow(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        // update admin info 
        admin::set_treasury_address(*smart_table::borrow(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id));
        // remove the entry
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id);
    }

    public entry fun reject_admin_previliges(signer_ref: &signer, id: u64) acquires Pending {
        // assert signer is the receiver
        assert!(smart_table::contains<u64, address>(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        assert!(signer::address_of(signer_ref) == *smart_table::borrow(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        // remove the entry
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id);
    }

    public entry fun reject_treasury_previliges(signer_ref: &signer, id: u64) acquires Pending {
        // assert signer is the receiver
        assert!(smart_table::contains<u64, address>(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        assert!(signer::address_of(signer_ref) == *smart_table::borrow(&borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id), 1);
        // remove the entry
        smart_table::remove<u64, address>(&mut borrow_global_mut<Pending>(constants::get_resource_account_address()).table, id);
    }
}
