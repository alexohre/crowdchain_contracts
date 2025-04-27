// use super::*;

// // Testing account creation
// #[test]
// fn test_create_account_should_emit(){
//     let contract_address = setup();
//     let contract_instance = IAccountDispatcher { contract_address };

//     let address: ContractAddress = contract_address_const::<1>();

//     let mut spy = spy_events();

//     start_cheat_caller_address(contract_address, address);

//     contract_instance.create_account();
//     // assert(contract_instance.create_account(), 'Account creation not successful');

//     stop_cheat_caller_address(address);

//     let expected_event = Event::AccountCreated(AccountCreated{address: caller, role:
//     ROLE_CONTRIBUTOR, application_status: STATUS_NONE});
//     spy.assert_emitted(@array![(contract_address, expected_event)]);
// }

// // testing apply creation Event should emit
// #[test]
// fn test_creator_application_process(){
//     let contract_address = setup();
//     let contract_instance = IAccountDispatcher { contract_address };

//     let address: ContractAddress = contract_address_const::<2>();

//     let mut spy = spy_events();

//     start_cheat_caller_address(contract_address, address);

//     // User create an account
//     contract_instance.create_account();

//     // Apply to be a creator
//     contract_instance.apply_creator();
//     let user_after_apply = contract_instance.get_role(address);

//     assert(user_after_apply == ROLE_CONTRIBUTOR, 'Only Contributors can apply');
//     assert(contract_instance.get_application_status(address) == STATUS_PENDING, 'user is not
//     pending');

//      stop_cheat_caller_address(address);

//      let expected_event = Event::AppliedAsCreator(AppliedAsCreator{address: caller,
//      application_status: STATUS_PENDING});
//      spy.assert_emitted(@array![(contract_address, expected_event)]);

//     // Testing reject application event should emit
//      #[test]
//     #[should_panic(expected: 'No pending application')]
//     fn test_creator_application_process_for_rejection(){
//     let contract_address = setup();
//     let contract_instance = IAccountDispatcher { contract_address };

//     let address: ContractAddress = contract_address_const::<3>();

//     let mut spy = spy_events();

//     start_cheat_caller_address(contract_address, address);

//     // User create an account
//     contract_instance.create_account();

//     contract_instance.reject_application(address);
//     assert(contract_instance.get_application_status(address) == STATUS_PENDING, 'No pending
//     application');

//      stop_cheat_caller_address(address);

//      let expected_event = Event::RejectedApplication(RejectedApplication{address: user,
//      application_status: STATUS_REJECTED});
//      spy.assert_emitted(@array![(contract_address, expected_event)]);

// }

// // Testing reapply event should emit
// #[test]
// #[should_panic(expected: 'Rejected')]
// fn test_creator_application_process_for_reapply(){
//     let contract_address = setup();
//     let contract_instance = IAccountDispatcher { contract_address };

//     let address: ContractAddress = contract_address_const::<4>();

//     let mut spy = spy_events();
//     start_cheat_caller_address(contract_address, address);

//     // User create an account
//     contract_instance.create_account();

//     contract_instance.reapply_creator();
//     assert(contract_instance.get_application_status(address) == STATUS_REJECTED, 'Rejected');

//      stop_cheat_caller_address(address);

//      let expected_event = Event::ReapplyAsCreator(ReapplyAsCreator { address: caller,
//      application_status:STATUS_PENDING });
//      spy.assert_emitted(@array![(contract_address, expected_event)]);

// }

// // Testing approve application event should emit
// #[test]
// fn test_approve_application(){
//     let contract_address = setup();
//     let contract_instance = IAccountDispatcher { contract_address };

//     let address: ContractAddress = contract_address_const::<5>();

//     let mut spy = spy_events();
//     start_cheat_caller_address(contract_address, address);

//     // User create an account
//     contract_instance.create_account();

//     // User applying for creator
//     contract_instance.apply_creator();
//     assert(contract_instance.get_application_status(address) == STATUS_PENDING, 'No pending
//     application');

//     contract_instance.approve_application(address);
//     let mut approve = contract_instance.get_application_status(address);
//     approve  = STATUS_APPROVED;

//     assert(contract_instance.get_role(address) == ROLE_CREATOR, 'Role must be a creator');
//      stop_cheat_caller_address(address);

//      let expected_event = Event::ApprovedApplication(ApprovedApplication { address: user, role:
//      ROLE_CREATOR, application_status:STATUS_APPROVED });
//      spy.assert_emitted(@array![(contract_address, expected_event)]);

//     }
