use crowdchain_contracts::Interfaces::IAdmin::{IAdminDispatcher, IAdminDispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address, spy_events,
    stop_cheat_caller_address, EventSpyAssertionsTrait
};
use crowdchain_contracts::AdminEvents::{AdminAdded, AdminRemoved, PlatformFeeUpdated};
use starknet::{ContractAddress, contract_address_const};
use crowdchain_contracts::contracts::Admin::Admin;
use super::Events::*;


fn __setup__() -> (ContractAddress, IAdminDispatcher, ContractAddress) {
    let admin: ContractAddress = contract_address_const::<'admin'>();
    let owner: ContractAddress = contract_address_const::<'owner'>();

    let contract = declare("Admin").unwrap().contract_class();
    let (contract_address, _) = contract.deploy(@array![owner.into()]).unwrap();
    let dispatcher = IAdminDispatcher { contract_address };
    (contract_address, dispatcher, owner)
}

#[test]
fn test_add_admin_by_owner() {
    let (contract_address, dispatcher, owner) = __setup__();
    let anybody = contract_address_const::<'anybody'>();
    let role_before_addition = dispatcher.get_user_role(anybody);
    assert(role_before_addition == 'Not Admin', 'User is already Admin');

    start_cheat_caller_address(contract_address, owner);
    dispatcher.add_admin(anybody);
    let role_after_addition = dispatcher.get_user_role(anybody);
    stop_cheat_caller_address(contract_address);
    assert(role_after_addition == 'Admin', 'An error occurred');
}

#[test]
#[should_panic(expected: 'Unauthorized caller')]
fn test_add_admin_by_non_owner() {
    let (contract_address, dispatcher, owner) = __setup__();
    let anybody = contract_address_const::<'anybody'>();
    let role_before_addition = dispatcher.get_user_role(anybody);
    assert(role_before_addition == 'Not Admin', 'User is already Admin');
    let non_owner: ContractAddress = contract_address_const::<'non_owner'>();

    start_cheat_caller_address(contract_address, non_owner);
    dispatcher.add_admin(anybody);
    let role_after_addition = dispatcher.get_user_role(anybody);
    stop_cheat_caller_address(contract_address);
    assert(role_after_addition == 'Admin', 'An error occurred');
}

#[test]
fn test_add_admin_event() {
    let (contract_address, dispatcher, owner) = __setup__();
    let anybody = contract_address_const::<'anybody'>();
    let role_before_addition = dispatcher.get_user_role(anybody);
    assert(role_before_addition == 'Not Admin', 'User is already Admin');
    let non_owner: ContractAddress = contract_address_const::<'non_owner'>();
    let mut spy = spy_events();

    start_cheat_caller_address(contract_address, owner);
    dispatcher.add_admin(anybody);
    let role_after_addition = dispatcher.get_user_role(anybody);
    stop_cheat_caller_address(contract_address);
    assert(role_after_addition == 'Admin', 'An error occurred');

    spy
        .assert_emitted(
            @array![
                (
                    dispatcher.contract_address,
                    Admin::Event::AdminAdded(
                        AdminAdded {
                             admin_address: anybody,
                        },
                    ),
                ),
            ],
        );
}

#[test]
fn test_remove_admin_by_owner() {
    let (contract_address, dispatcher, owner) = __setup__();
    let anybody = contract_address_const::<'anybody'>();

    start_cheat_caller_address(contract_address, owner);
    dispatcher.add_admin(anybody);
    let role_before_removal = dispatcher.get_user_role(anybody);
    assert(role_before_removal == 'Admin', 'User is Not Admin');

    start_cheat_caller_address(contract_address, owner);
    dispatcher.remove_admin(anybody);
    let role_after_removal = dispatcher.get_user_role(anybody);
    stop_cheat_caller_address(contract_address);
    assert(role_after_removal == 'Not Admin', 'An error occurred');
}

#[test]
#[should_panic(expected: 'Unauthorized caller')]
fn test_remove_admin_by_non_owner() {
    let (contract_address, dispatcher, owner) = __setup__();
    let anybody = contract_address_const::<'anybody'>();

    start_cheat_caller_address(contract_address, owner);
    dispatcher.add_admin(anybody);

    let role_before_removal = dispatcher.get_user_role(anybody);
    assert(role_before_removal == 'Admin', 'User is Not Admin');
    let non_owner: ContractAddress = contract_address_const::<'non_owner'>();

    start_cheat_caller_address(contract_address, non_owner);
    dispatcher.remove_admin(anybody);
    let role_after_removal = dispatcher.get_user_role(anybody);
    stop_cheat_caller_address(contract_address);
    assert(role_after_removal == 'Not Admin', 'An error occurred');
}

#[test]
fn test_remove_admin_event() {
    let (contract_address, dispatcher, owner) = __setup__();
    let anybody = contract_address_const::<'anybody'>();

    start_cheat_caller_address(contract_address, owner);
    dispatcher.add_admin(anybody);
    stop_cheat_caller_address(contract_address);

    let mut spy = spy_events();

    start_cheat_caller_address(contract_address, owner);
    dispatcher.remove_admin(anybody);
    let role_after_removal = dispatcher.get_user_role(anybody);
    stop_cheat_caller_address(contract_address);
    assert(role_after_removal == 'Not Admin', 'An error occurred');

    spy
        .assert_emitted(
            @array![
                (
                    dispatcher.contract_address,
                    Admin::Event::AdminRemoved(
                        AdminRemoved {
                             admin_address: anybody,
                        },
                    ),
                ),
            ],
        );
}

#[test]
fn test_approve_creator_application_by_owner() {
    let (contract_address, dispatcher, owner) = __setup__();
    let anybody = contract_address_const::<'anybody'>();
    let test_creator = contract_address_const::<'test_creator'>();    


    start_cheat_caller_address(contract_address, owner);
    let create_status = dispatcher.approve_creator_application(test_creator);
    stop_cheat_caller_address(contract_address);
    assert(create_status == 'Approved', 'An error occurred');
}
#[test]
fn test_approve_creator_application_by_admin() {
    let (contract_address, dispatcher, owner) = __setup__();
    let anybody = contract_address_const::<'anybody'>();
    let test_creator = contract_address_const::<'test_creator'>();    

    start_cheat_caller_address(contract_address, owner);
    dispatcher.add_admin(anybody);

    start_cheat_caller_address(contract_address, anybody);
    let create_status = dispatcher.approve_creator_application(test_creator);
    stop_cheat_caller_address(contract_address);
    assert(create_status == 'Approved', 'An error occurred');
}
#[test]
#[should_panic(expected: 'Caller is not owner or admin')]
fn test_approve_creator_application_by_non_owner_or_non_admin() {
    let (contract_address, dispatcher, owner) = __setup__();
    let anybody = contract_address_const::<'anybody'>();
    let non_owner = contract_address_const::<'non_owner'>();
    let test_creator = contract_address_const::<'test_creator'>();    


    start_cheat_caller_address(contract_address, non_owner);
    let create_status = dispatcher.approve_creator_application(test_creator);
    stop_cheat_caller_address(contract_address);
    assert(create_status == 'Approved', 'An error occurred');
}

#[test]
fn test_reject_creator_application_by_owner() {
    let (contract_address, dispatcher, owner) = __setup__();
    let anybody = contract_address_const::<'anybody'>();
    let test_creator = contract_address_const::<'test_creator'>();    


    start_cheat_caller_address(contract_address, owner);
    let create_status = dispatcher.reject_creator_application(test_creator);
    stop_cheat_caller_address(contract_address);
    assert(create_status == 'Rejected', 'An error occurred');
}
#[test]
fn test_reject_creator_application_by_admin() {
    let (contract_address, dispatcher, owner) = __setup__();
    let anybody = contract_address_const::<'anybody'>();
    let test_creator = contract_address_const::<'test_creator'>();    

    start_cheat_caller_address(contract_address, owner);
    dispatcher.add_admin(anybody);

    start_cheat_caller_address(contract_address, anybody);
    let create_status = dispatcher.reject_creator_application(test_creator);
    stop_cheat_caller_address(contract_address);
    assert(create_status == 'Rejected', 'An error occurred');
}
#[test]
#[should_panic(expected: 'Caller is not owner or admin')]
fn test_reject_creator_application_by_non_owner_or_non_admin() {
    let (contract_address, dispatcher, owner) = __setup__();
    let anybody = contract_address_const::<'anybody'>();
    let non_owner = contract_address_const::<'non_owner'>();
    let test_creator = contract_address_const::<'test_creator'>();    


    start_cheat_caller_address(contract_address, non_owner);
    let create_status = dispatcher.reject_creator_application(test_creator);
    stop_cheat_caller_address(contract_address);
    assert(create_status == 'Rejected', 'An error occurred');
}

#[test]
#[should_panic(expected: 'Campaign is not running')]
fn test_pause_campaign_by_owner() {
    let (contract_address, dispatcher, owner) = __setup__();

    start_cheat_caller_address(contract_address, owner);
    let create_status = dispatcher.pause_campaign(15);
    assert(create_status == 'Paused', 'Error occured');
    stop_cheat_caller_address(contract_address);
}
#[test]
#[should_panic(expected: 'Campaign is not running')]
fn test_pause_campaign_by_admin() {
    let (contract_address, dispatcher, owner) = __setup__();
    let anybody = contract_address_const::<'anybody'>();
    let test_creator = contract_address_const::<'test_creator'>();    

    start_cheat_caller_address(contract_address, owner);
    dispatcher.add_admin(anybody);

    start_cheat_caller_address(contract_address, anybody);
    let create_status = dispatcher.pause_campaign(15);
    stop_cheat_caller_address(contract_address);
    assert(create_status == 'Paused', 'An error occurred');
}
#[test]
#[should_panic(expected: 'Caller is not owner or admin')]
fn test_pause_campaign_by_non_owner_or_non_admin() {
    let (contract_address, dispatcher, owner) = __setup__();
    let non_owner = contract_address_const::<'non_owner'>();

    start_cheat_caller_address(contract_address, non_owner);
    let create_status = dispatcher.pause_campaign(15);
    stop_cheat_caller_address(contract_address);
  
}
#[test]
fn test_set_platform_fee_by_owner() {
    let (contract_address, dispatcher, owner) = __setup__();

    start_cheat_caller_address(contract_address, owner);
    dispatcher.set_platform_fee(20_000);

    let fee = dispatcher.get_platform_fee();
    assert(fee == 20_000, 'platform fee not set');
}

#[test]
#[should_panic(expected: 'Unauthorized caller')]
fn test_set_platform_fee_by_non_owner() {
    let (contract_address, dispatcher, owner) = __setup__();
    let non_owner = contract_address_const::<'non_owner'>();


    start_cheat_caller_address(contract_address, non_owner);
    dispatcher.set_platform_fee(20_000);

    let fee = dispatcher.get_platform_fee();
    assert(fee == 20_000, 'platform fee not set');
}



