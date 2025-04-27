#[starknet::contract]
pub mod AccountContract {
    // Constants
    const ROLE_CONTRIBUTOR: felt252 = 'Contributor';
    const ROLE_CREATOR: felt252 = 'Creator';
    const ROLE_ADMIN: felt252 = 'Admin';

    const STATUS_NONE: felt252 = 'None';
    const STATUS_PENDING: felt252 = 'Pending';
    const STATUS_APPROVED: felt252 = 'Approved';
    const STATUS_REJECTED: felt252 = 'Rejected';
    use starknet::storage::{Map, StorageMapReadAccess, StorageMapWriteAccess};
    use starknet::{ContractAddress, get_caller_address};
    use crate::events::AccountEvent::*;
    // use traits::Into;
    // use interfaces::IAccount;
    // use events::AccountEvent::*;
    use crate::interfaces::IAccount::IAccount;

    #[event]
    #[derive(Debug, Drop, starknet::Event)]
    // #[derive(starknet::Event)]

    pub enum Event {
        AccountCreated: AccountCreated,
        AppliedAsCreator: AppliedAsCreator,
        ReapplyAsCreator: ReapplyAsCreator,
        ApprovedApplication: ApprovedApplication,
        RejectedApplication: RejectedApplication,
    }


    #[derive(Clone, Debug, Drop, PartialEq, Serde, starknet::Store)]
    pub struct User {
        pub address: ContractAddress,
        pub account: bool,
        pub role: felt252,
        pub application_status: felt252,
        pub stats: felt252,
    }


    #[storage]
    struct Storage {
        accounts: Map<ContractAddress, User>,
    }


    #[abi(embed_v0)]
    impl IAccountImpl of IAccount<ContractState> {
        // function for creating account
        fn create_account(ref self: ContractState) {
            let caller = get_caller_address();

            // retrieving caller details
            let existing = self.accounts.read(caller);

            // checking if user has an existing account
            assert(
                !existing.account, 'Cannot create multile account',
            ); // If not then go on in creating new account

            // creating new account
            let new_user = User {
                address: caller,
                account: true,
                role: ROLE_CONTRIBUTOR,
                application_status: STATUS_NONE,
                stats: 0,
            };

            self.accounts.write(caller, new_user);
            self
                .emit(
                    Event::AccountCreated(
                        AccountCreated {
                            address: caller,
                            role: ROLE_CONTRIBUTOR,
                            application_status: STATUS_NONE,
                        },
                    ),
                );
        }

        // function for appllying for creator
        fn apply_creator(ref self: ContractState) {
            let caller = get_caller_address();

            // retrieving caller details
            let mut user = self.accounts.read(caller);

            // checking if user account exist
            assert(user.account, 'Account does not exist');

            assert(user.role == ROLE_CONTRIBUTOR, 'Only Contributors can apply');
            assert(user.application_status != STATUS_PENDING, 'Application already pending');

            user.application_status = STATUS_PENDING;
            self.accounts.write(caller, user);

            self
                .emit(
                    Event::AppliedAsCreator(
                        AppliedAsCreator { address: caller, application_status: STATUS_PENDING },
                    ),
                );
        }

        // function for reapply for creator
        // You can reapply only when you are rejected
        fn reapply_creator(ref self: ContractState) {
            let caller = get_caller_address();

            // retrieving caller details
            let mut user = self.accounts.read(caller);

            // checking if user account exist
            assert(user.account, 'Account does not exist');

            // checking if user was been rejected before reapplying
            assert(
                user.application_status == STATUS_REJECTED, 'Rejected',
            ); //Can only reapply after rejection

            // setting user status to pending
            user.application_status = STATUS_PENDING;
            self.accounts.write(caller, user);

            self
                .emit(
                    Event::ReapplyAsCreator(
                        ReapplyAsCreator { address: caller, application_status: STATUS_PENDING },
                    ),
                );
        }

        // function for approving applications
        fn approve_application(ref self: ContractState, user: ContractAddress) {
            // retrieving caller details
            let mut target = self.accounts.read(user);

            // checking if user account exist
            assert(target.account, 'Account does not exist');

            // checking if user status is in pending
            // User status must be in pending b4 it can be approved
            assert(target.application_status == STATUS_PENDING, 'No pending application');

            // Setting user status to approved
            target.application_status = STATUS_APPROVED;
            target.role = ROLE_CREATOR;
            self.accounts.write(user, target);

            self
                .emit(
                    Event::ApprovedApplication(
                        ApprovedApplication {
                            address: user, role: ROLE_CREATOR, application_status: STATUS_APPROVED,
                        },
                    ),
                );
        }


        // functon for rejecting applications
        fn reject_application(ref self: ContractState, user: ContractAddress) {
            // retrieving caller details
            let mut target = self.accounts.read(user);
            assert(target.account, 'Account does not exist');

            assert(target.application_status == STATUS_PENDING, 'No pending application');

            target.application_status = STATUS_REJECTED;
            self.accounts.write(user, target);

            self
                .emit(
                    Event::RejectedApplication(
                        RejectedApplication { address: user, application_status: STATUS_REJECTED },
                    ),
                );
        }

        // Function to check if account exist
        fn get_account(self: @ContractState, user: ContractAddress) -> bool {
            self.accounts.read(user).account
        }

        // Function to get role
        fn get_role(self: @ContractState, user: ContractAddress) -> felt252 {
            self.accounts.read(user).role
        }

        // function to get application status
        fn get_application_status(self: @ContractState, user: ContractAddress) -> felt252 {
            self.accounts.read(user).application_status
        }
    }
}
