#[starknet::contract]
pub mod Admin {
    use core::num::traits::Zero;
    use core::starknet::storage::{
        Map, MutableVecTrait, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess, Vec,
    };
    use openzeppelin::access::accesscontrol::AccessControlComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use starknet::{ContractAddress, contract_address_const, get_caller_address};
    use crate::AdminEvents::{AdminAdded, AdminRemoved, PlatformFeeUpdated};
    use crate::Interfaces::IAdmin::IAdmin;
    use crate::structs::Structs::{Creator, Campaign};
    const ADMIN_ROLE: felt252 = selector!("ADMIN_ROLE");
    const OWNER_ROLE: felt252 = selector!("OWNER_ROLE");

    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    // AccessControl
    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    // SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;

    #[storage]
    struct Storage {
        owner: ContractAddress,
        admin: Vec<ContractAddress>,
        creator: Map<ContractAddress, Creator>,
        campaign: Map<u256, Campaign>,
        platform_fee: u256,
        #[substorage(v0)]
        pub accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
    }

    // Events
    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        PlatformFeeUpdated: PlatformFeeUpdated,
        AdminAdded: AdminAdded,
        AdminRemoved: AdminRemoved,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
    }


    #[constructor]
    fn constructor(ref self: ContractState, owner: ContractAddress) {
        self.owner.write(owner);
        self.accesscontrol._grant_role(OWNER_ROLE, owner)
    }

    #[abi(embed_v0)]
    impl Admin of IAdmin<ContractState> {
        fn add_admin(ref self: ContractState, admin_address: ContractAddress) -> bool {
            assert(admin_address.is_non_zero(), 'Address cannot be Zero');
            assert(get_caller_address() == self.owner.read(), 'Unauthorized caller');

            // Check if address is already an admin
            let get_role = self.get_user_role(get_caller_address());

            // Grant the admin role
            self.accesscontrol._grant_role(ADMIN_ROLE, admin_address);

            // Emit event
            self.emit(Event::AdminAdded(AdminAdded { admin_address }));

            true
        }

        fn remove_admin(ref self: ContractState, admin_address: ContractAddress) -> bool {
            assert(admin_address.is_non_zero(), 'Address cannot be Zero');
            assert(get_caller_address() == self.owner.read(), 'Unauthorized caller');

            // Check if the address is an admin
            assert(self.accesscontrol.has_role(ADMIN_ROLE, admin_address), 'Admin not found');

            // Remove the admin role
            self.accesscontrol._revoke_role(ADMIN_ROLE, admin_address);

            // Emit event
            self.emit(Event::AdminRemoved(AdminRemoved { admin_address }));

            true
        }

        fn get_user_role(self: @ContractState, user: ContractAddress) -> felt252 {
            let Check_user_role = self.accesscontrol.has_role(ADMIN_ROLE, user);            
            if (Check_user_role){
                'Admin'
            }else{
                'Not Admin'
            }
        }


        fn set_platform_fee(ref self: ContractState, new_fee: u256) {
            assert(get_caller_address() == self.owner.read(), 'Unauthorized caller');
            assert(new_fee > 0, 'Fee cannot be zero');
            let old_fee = self.get_platform_fee();
            self.platform_fee.write(new_fee);
            self.emit(Event::PlatformFeeUpdated(PlatformFeeUpdated { old_fee, new_fee }));
        }

        fn get_platform_fee(self: @ContractState) -> u256 {
            self.platform_fee.read()
        }

        fn approve_creator_application(ref self: ContractState, creator_address: ContractAddress)-> felt252 {
            let caller = get_caller_address();
            let check_owner = self.owner.read();
            assert(caller == check_owner  || self.accesscontrol.has_role(ADMIN_ROLE, caller), 'Caller is not owner or admin');
        
            let mut creator_profile = self.creator.read(creator_address);
            assert(
                creator_profile.status != 'Approved',
                'Application is approved already',
            );
            creator_profile.status = 'Approved';

            // Write the updated profile back to storage
            self.creator.write(creator_address, creator_profile);
            'Approved'
        }

        fn reject_creator_application(ref self: ContractState, creator_address: ContractAddress)-> felt252 {
            let caller = get_caller_address();
            assert(
                self.accesscontrol.has_role(OWNER_ROLE, caller)
                    || self.accesscontrol.has_role(ADMIN_ROLE, caller),
                'Caller is not owner or admin',
            );
            let mut creator_profile = self.creator.read(creator_address);
            assert(
                creator_profile.status != 'Rejected',
                'Application is already rejected',
            );
            creator_profile.status = 'Rejected';
            'Rejected'
        }

        fn pause_campaign(ref self: ContractState, campaign_id: u256)-> felt252 {
            let caller = get_caller_address();
            assert(
                self.accesscontrol.has_role(OWNER_ROLE, caller)
                    || self.accesscontrol.has_role(ADMIN_ROLE, caller),
                'Caller is not owner or admin',
            );
            assert(campaign_id.is_non_zero(), 'invalid campaign ID');
            let mut campaign = self.campaign.read(campaign_id);
            assert(campaign.status == 'Running', 'Campaign is not running');
            campaign.status = 'Paused';
            'Paused'
        }
        fn unpause_campaign(ref self: ContractState, campaign_id: u256)->felt252 {
            let caller = get_caller_address();
            assert(
                self.accesscontrol.has_role(OWNER_ROLE, caller)
                    || self.accesscontrol.has_role(ADMIN_ROLE, caller),
                'Caller is not owner or admin',
            );
            assert(campaign_id.is_non_zero(), 'invalid campaign ID');
            let mut campaign = self.campaign.read(campaign_id);
            assert(campaign.status == 'Paused', 'Campaign is not paused');
            campaign.status = 'Running';
            'Running'

        }
        fn suspend_user(ref self: ContractState, user_address: ContractAddress, reason: felt252) {
            let caller = get_caller_address();
            assert(
                self.accesscontrol.has_role(OWNER_ROLE, caller)
                    || self.accesscontrol.has_role(ADMIN_ROLE, caller),
                'Caller is not owner or admin',
            );
        }
        fn unsuspend_user(ref self: ContractState, user_address: ContractAddress) {
            let caller = get_caller_address();
            assert(
                self.accesscontrol.has_role(OWNER_ROLE, caller)
                    || self.accesscontrol.has_role(ADMIN_ROLE, caller),
                'Caller is not owner or admin',
            );
        }
        fn flag_user(ref self: ContractState, user_address: ContractAddress, flag_reason: felt252) {
            let caller = get_caller_address();
            assert(
                self.accesscontrol.has_role(OWNER_ROLE, caller)
                    || self.accesscontrol.has_role(ADMIN_ROLE, caller),
                'Caller is not owner or admin',
            );
        }
        fn unflag_user(ref self: ContractState, user_address: ContractAddress) {
            let caller = get_caller_address();
            assert(
                self.accesscontrol.has_role(OWNER_ROLE, caller)
                    || self.accesscontrol.has_role(ADMIN_ROLE, caller),
                'Caller is not owner or admin',
            );
        }
    }
}
