use crate::test_account_events;
use crate::test_demo;
// Constants
const ROLE_CONTRIBUTOR: felt252 = 'Contributor';
const ROLE_CREATOR: felt252 = 'Creator';
const ROLE_ADMIN: felt252 = 'Admin';

const STATUS_NONE: felt252 = 'None';
const STATUS_PENDING: felt252 = 'Pending';
const STATUS_APPROVED: felt252 = 'Approved';
const STATUS_REJECTED: felt252 = 'Rejected';

use crowdchain_contracts::interfaces::IAccount::{IAccountDispatcher, IAccountDispatcherTrait};
// use crowdchain_contracts::contracts::Account::AccountContract;
use crowdchain_contracts::events::AccountEvent::*;
// use cohort_4::SimpleBank::{AccountCreated, DepositMade, Event};
use crowdchain_contracts::contracts::Account::AccountContract::Event;

use starknet::{ContractAddress, contract_address_const};
// use crowdchain_contracts::interfaces::IAccount::{IAccountDispatcher, IAccountDispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, spy_events,
    start_cheat_caller_address, stop_cheat_caller_address,
};


fn setup() -> ContractAddress {
    let contract_class = declare("AccountContract").unwrap().contract_class();
    let (contract_address, _) = contract_class.deploy(@array![]).unwrap();
    contract_address
}



// Testing account creation
#[test]
fn test_create_account(){
    let contract_address = setup();
    let contract_instance = IAccountDispatcher { contract_address };

    let address: ContractAddress = contract_address_const::<1>();

    start_cheat_caller_address(contract_address, address);

    contract_instance.create_account();
    // assert(contract_instance.create_account(), 'Account creation not successful');

    stop_cheat_caller_address(address);
}

// Testind Account Creation
// Testing that each wallet can create only one account.
#[test]
#[should_panic(expected: 'Cannot create multile account')]
fn test_create_account_should_panic(){
    let contract_address = setup();
    let contract_instance = IAccountDispatcher { contract_address };

    let address: ContractAddress = contract_address_const::<1>();

    start_cheat_caller_address(contract_address, address);

    contract_instance.create_account();

    contract_instance.create_account();
    

}

// TESTING APPLY_CREATOR
// ONLY A CONTRIBUTOR CAN APPLY
#[test]
fn test_creator_application_process(){
    let contract_address = setup();
    let contract_instance = IAccountDispatcher { contract_address };

    let address: ContractAddress = contract_address_const::<2>();

    start_cheat_caller_address(contract_address, address);

    // User create an account
    contract_instance.create_account();

    // Apply to be a creator
    contract_instance.apply_creator();
    let user_after_apply = contract_instance.get_role(address);
    

    assert(user_after_apply == ROLE_CONTRIBUTOR, 'Only Contributors can apply');
    assert(contract_instance.get_application_status(address) == STATUS_PENDING, 'user is not pending');
            

     stop_cheat_caller_address(address);
}

// REJECTION APPLICATION PROCESS
// ACCOUNT MUST BE A CONTRIBUTOR BEFORE YOU CAN APPLY 
#[test]
#[should_panic(expected: 'No pending application')]
fn test_creator_application_process_for_rejection(){
    let contract_address = setup();
    let contract_instance = IAccountDispatcher { contract_address };

    let address: ContractAddress = contract_address_const::<3>();

    start_cheat_caller_address(contract_address, address);

    // User create an account
    contract_instance.create_account();

    
    contract_instance.reject_application(address);
    assert(contract_instance.get_application_status(address) == STATUS_PENDING, 'No pending application');
            
     stop_cheat_caller_address(address);
}

// Testing reapply creator function
// Can reapply only when rejected
#[test]
#[should_panic(expected: 'Rejected')]
fn test_creator_application_process_for_reapply(){
    let contract_address = setup();
    let contract_instance = IAccountDispatcher { contract_address };

    let address: ContractAddress = contract_address_const::<4>();

    start_cheat_caller_address(contract_address, address);

    // User create an account
    contract_instance.create_account();

    
    contract_instance.reapply_creator();
    assert(contract_instance.get_application_status(address) == STATUS_REJECTED, 'Rejected');
            
     stop_cheat_caller_address(address);
}

// Testing approve application function
// Can only be approved if user apply for creator
#[test]
fn test_approve_application(){
    let contract_address = setup();
    let contract_instance = IAccountDispatcher { contract_address };

    let address: ContractAddress = contract_address_const::<5>();

    start_cheat_caller_address(contract_address, address);

    // User create an account
    contract_instance.create_account();

    // User applying for creator
    contract_instance.apply_creator();
    assert(contract_instance.get_application_status(address) == STATUS_PENDING, 'No pending application');

    contract_instance.approve_application(address);
    let mut approve = contract_instance.get_application_status(address);
    approve  = STATUS_APPROVED;

    assert(contract_instance.get_role(address) == ROLE_CREATOR, 'Role must be a creator');
     stop_cheat_caller_address(address);
}






// Testing account creation
#[test]
fn test_create_account_should_emit(){
    let contract_address = setup();
    let contract_instance = IAccountDispatcher { contract_address };

    let address: ContractAddress = contract_address_const::<1>();


    let mut spy = spy_events();

    start_cheat_caller_address(contract_address, address);

    contract_instance.create_account();
    // assert(contract_instance.create_account(), 'Account creation not successful');

    stop_cheat_caller_address(address);

    let expected_event = Event::AccountCreated(AccountCreated{address: address, role: ROLE_CONTRIBUTOR, application_status: STATUS_NONE});
    spy.assert_emitted(@array![(contract_address, expected_event)]);
}


// testing apply creation Event should emit
#[test]
fn test_creator_application_process_should_emit(){
    let contract_address = setup();
    let contract_instance = IAccountDispatcher { contract_address };

    let address: ContractAddress = contract_address_const::<2>();

    let mut spy = spy_events();

    start_cheat_caller_address(contract_address, address);

    // User create an account
    contract_instance.create_account();

    // Apply to be a creator
    contract_instance.apply_creator();
    let user_after_apply = contract_instance.get_role(address);
    

    assert(user_after_apply == ROLE_CONTRIBUTOR, 'Only Contributors can apply');
    assert(contract_instance.get_application_status(address) == STATUS_PENDING, 'user is not pending');
            

     stop_cheat_caller_address(address);

     let expected_event = Event::AppliedAsCreator(AppliedAsCreator{address: address, application_status: STATUS_PENDING});
     spy.assert_emitted(@array![(contract_address, expected_event)]);

}
     
    // Testing reject application event should emit
     #[test]
    #[should_panic(expected: 'No pending application')]
    fn test_creator_application_process_for_rejection_should_emit(){
    let contract_address = setup();
    let contract_instance = IAccountDispatcher { contract_address };

    let address: ContractAddress = contract_address_const::<3>();

    let mut spy = spy_events();

    start_cheat_caller_address(contract_address, address);

    // User create an account
    contract_instance.create_account();

    
    contract_instance.reject_application(address);
    assert(contract_instance.get_application_status(address) == STATUS_PENDING, 'No pending application');
            
     stop_cheat_caller_address(address);

     let expected_event = Event::RejectedApplication(RejectedApplication{address: address, application_status: STATUS_REJECTED});
     spy.assert_emitted(@array![(contract_address, expected_event)]);

}


// Testing reapply event should emit
#[test]
#[should_panic(expected: 'Rejected')]
fn test_creator_application_process_for_reapply_should_emit(){
    let contract_address = setup();
    let contract_instance = IAccountDispatcher { contract_address };

    let address: ContractAddress = contract_address_const::<4>();

    let mut spy = spy_events();
    start_cheat_caller_address(contract_address, address);

    // User create an account
    contract_instance.create_account();

    
    contract_instance.reapply_creator();
    assert(contract_instance.get_application_status(address) == STATUS_REJECTED, 'Rejected');
            
     stop_cheat_caller_address(address);


     let expected_event = Event::ReapplyAsCreator(ReapplyAsCreator { address: address, application_status:STATUS_PENDING });
     spy.assert_emitted(@array![(contract_address, expected_event)]);

}

// Testing approve application event should emit
#[test]
fn test_approve_application_should_emit(){
    let contract_address = setup();
    let contract_instance = IAccountDispatcher { contract_address };

    let address: ContractAddress = contract_address_const::<5>();


    let mut spy = spy_events();
    start_cheat_caller_address(contract_address, address);

    // User create an account
    contract_instance.create_account();

    // User applying for creator
    contract_instance.apply_creator();
    assert(contract_instance.get_application_status(address) == STATUS_PENDING, 'No pending application');

    contract_instance.approve_application(address);
    let mut approve = contract_instance.get_application_status(address);
    approve  = STATUS_APPROVED;

    assert(contract_instance.get_role(address) == ROLE_CREATOR, 'Role must be a creator');
     stop_cheat_caller_address(address);

     let expected_event = Event::ApprovedApplication(ApprovedApplication { address: address, role: ROLE_CREATOR, application_status:STATUS_APPROVED });
     spy.assert_emitted(@array![(contract_address, expected_event)]);

    }

