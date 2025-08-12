use crowdchain_contracts::interfaces::ICrowdchain::{
    ICrowdchainDispatcher, ICrowdchainDispatcherTrait,
};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::ContractAddress;

// ********** ADDRESS HELPERS **********

fn owner_address() -> ContractAddress {
    let owner_felt: felt252 = 0x123.into();
    let owner: ContractAddress = owner_felt.try_into().unwrap();
    owner
}

fn creator_address() -> ContractAddress {
    let creator_felt: felt252 = 0x456.into();
    let creator: ContractAddress = creator_felt.try_into().unwrap();
    creator
}

fn creator2_address() -> ContractAddress {
    let creator2_felt: felt252 = 0x789.into();
    let creator2: ContractAddress = creator2_felt.try_into().unwrap();
    creator2
}

fn admin_address() -> ContractAddress {
    let admin_felt: felt252 = 0xabc.into();
    let admin: ContractAddress = admin_felt.try_into().unwrap();
    admin
}

fn user_address() -> ContractAddress {
    let user_felt: felt252 = 0xdef.into();
    let user: ContractAddress = user_felt.try_into().unwrap();
    user
}

// ********** SETUP FUNCTION **********

fn setup() -> (ICrowdchainDispatcher, ContractAddress, ContractAddress) {
    let contract = declare("Crowdchain").unwrap().contract_class();
    let owner = owner_address();

    let (contract_address, _) = contract.deploy(@array![owner.into()]).unwrap();
    let dispatcher = ICrowdchainDispatcher { contract_address };

    (dispatcher, contract_address, owner)
}

// ********** CREATOR APPLICATION TESTS **********

#[test]
fn test_submit_creator_application_success() {
    let (dispatcher, _, _) = setup();
    let creator = creator_address();

    // Set caller to creator
    start_cheat_caller_address(dispatcher.contract_address, creator);

    // Submit creator application
    dispatcher.submit_creator_application();

    // Check that application is now pending
    let is_pending = dispatcher.is_creator_application_pending(creator);
    assert(is_pending, 'Should be pending');

    // Check that creator is not yet approved
    let is_approved = dispatcher.is_approved_creator(creator);
    assert(!is_approved, 'Should not be approved');

    stop_cheat_caller_address(dispatcher.contract_address);
}

#[test]
fn test_is_creator_application_pending_false_initially() {
    let (dispatcher, _, _) = setup();
    let creator = creator_address();

    // Check that creator application is not pending initially
    let is_pending = dispatcher.is_creator_application_pending(creator);
    assert(!is_pending, 'Not pending initially');
}

#[test]
fn test_is_creator_application_pending_true_after_submission() {
    let (dispatcher, _, _) = setup();
    let creator = creator_address();

    // Submit creator application
    start_cheat_caller_address(dispatcher.contract_address, creator);
    dispatcher.submit_creator_application();
    stop_cheat_caller_address(dispatcher.contract_address);

    // Check that application is pending
    let is_pending = dispatcher.is_creator_application_pending(creator);
    assert(is_pending, 'Pending after submission');
}

#[test]
fn test_is_creator_application_pending_false_after_approval() {
    let (dispatcher, _, owner) = setup();
    let creator = creator_address();

    // Submit creator application
    start_cheat_caller_address(dispatcher.contract_address, creator);
    dispatcher.submit_creator_application();
    stop_cheat_caller_address(dispatcher.contract_address);

    // Approve creator as admin
    start_cheat_caller_address(dispatcher.contract_address, owner);
    dispatcher.approve_creator(creator);
    stop_cheat_caller_address(dispatcher.contract_address);

    // Check that application is no longer pending
    let is_pending = dispatcher.is_creator_application_pending(creator);
    assert(!is_pending, 'Not pending after approval');

    // Check that creator is now approved
    let is_approved = dispatcher.is_approved_creator(creator);
    assert(is_approved, 'Creator should be approved');
}

#[test]
fn test_multiple_creators_can_submit_applications() {
    let (dispatcher, _, _) = setup();
    let creator1 = creator_address();
    let creator2 = creator2_address();

    // Submit applications from multiple creators
    start_cheat_caller_address(dispatcher.contract_address, creator1);
    dispatcher.submit_creator_application();
    stop_cheat_caller_address(dispatcher.contract_address);

    start_cheat_caller_address(dispatcher.contract_address, creator2);
    dispatcher.submit_creator_application();
    stop_cheat_caller_address(dispatcher.contract_address);

    // Check that all applications are pending
    assert(dispatcher.is_creator_application_pending(creator1), 'Creator1 pending');
    assert(dispatcher.is_creator_application_pending(creator2), 'Creator2 pending');

    // Check that none are approved yet
    assert(!dispatcher.is_approved_creator(creator1), 'Creator1 not approved');
    assert(!dispatcher.is_approved_creator(creator2), 'Creator2 not approved');
}
