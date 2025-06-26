// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts for Cairo ^1.0.0

const PAUSER_ROLE: felt252 = selector!("PAUSER_ROLE");
const UPGRADER_ROLE: felt252 = selector!("UPGRADER_ROLE");

#[starknet::contract]
pub mod Crowdchain {
    use core::array::ArrayTrait;
    use core::num::traits::Zero;
    use core::option::Option;
    #[event]
    use crowdchain_contracts::events::CrowdchainEvent::{
        CampaignCreated, CampaignPaused, CampaignUnpaused,
        CampaignStatusUpdated // add to the list when needed
    };
<<<<<<< HEAD:src/contracts/Crowdchain.cairo
    use crowdchain_contracts::interfaces::ICrowdchain::ICrowdchain;
=======
    use crowdchain_contracts::interfaces::ICampaign::ICampaign;
    use openzeppelin::access::accesscontrol::{AccessControlComponent, DEFAULT_ADMIN_ROLE};
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::security::pausable::PausableComponent;
    use openzeppelin::upgrades::UpgradeableComponent;
    use openzeppelin::upgrades::interface::IUpgradeable;
>>>>>>> 206f5bde7da60077f1b400e18ab77ce33129fc80:src/contracts/Campaign.cairo
    use starknet::storage::{
        Map, MutableVecTrait, StorageMapReadAccess, StoragePathEntry, StoragePointerReadAccess,
        StoragePointerWriteAccess, Vec, VecTrait,
    };
    use starknet::{ClassHash, ContractAddress, get_block_timestamp, get_caller_address};
    use super::{PAUSER_ROLE, UPGRADER_ROLE};


    component!(path: PausableComponent, storage: pausable, event: PausableEvent);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: UpgradeableComponent, storage: upgradeable, event: UpgradeableEvent);

    // External
    #[abi(embed_v0)]
    impl PausableImpl = PausableComponent::PausableImpl<ContractState>;
    #[abi(embed_v0)]
    impl AccessControlMixinImpl =
        AccessControlComponent::AccessControlMixinImpl<ContractState>;

    // Internal
    impl PausableInternalImpl = PausableComponent::InternalImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;
    impl UpgradeableInternalImpl = UpgradeableComponent::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        pausable: PausableComponent::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        upgradeable: UpgradeableComponent::Storage,
        approved_creators: Map<ContractAddress, bool>,
        campaigns: Map<u128, CampaignNode>,
        campaign_counter: u128,
        campaign_ids: Vec<u128>,
        admin: ContractAddress,
    }


    #[derive(Drop, Serde)]
    pub struct CamapaignStats {
        pub campaign_id: u128,
        pub status: CampaignStatus,
        pub supporter_count: u128,
        pub metadata: felt252,
        pub creator: ContractAddress,
        pub created_at: u64,
        pub updated_at: u64,
        pub paused_at: u64,
        pub completed_at: u64,
    }

    #[derive(Copy, Drop, Serde, PartialEq, starknet::Store)]
    pub enum CampaignStatus {
        Active,
        Paused,
        Completed,
        #[default]
        Unknown,
    }

    #[starknet::storage_node]
    pub struct CampaignNode {
        creator: ContractAddress,
        metadata: felt252,
        status: CampaignStatus,
        supporters: Map<ContractAddress, bool>, // To know who supported the campaign
        supporter_count: u128,
        created_at: u64,
        updated_at: u64,
        paused_at: u64,
        completed_at: u64,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        #[flat]
        PausableEvent: PausableComponent::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        UpgradeableEvent: UpgradeableComponent::Event,
        Created: CampaignCreated,
        StatusUpdated: CampaignStatusUpdated,
        HoldCampaign: CampaignPaused,
        UnholdCampaign: CampaignUnpaused,
        // Add Events after importing it above
    }

    #[constructor]
    fn constructor(ref self: ContractState, default_admin: ContractAddress) {
        self.accesscontrol.initializer();

        self.accesscontrol._grant_role(DEFAULT_ADMIN_ROLE, default_admin);
        self.accesscontrol._grant_role(PAUSER_ROLE, default_admin);
        self.accesscontrol._grant_role(UPGRADER_ROLE, default_admin);

        self.admin.write(default_admin);
    }

    #[generate_trait]
    #[abi(per_item)]
    impl ExternalImpl of ExternalTrait {
        #[external(v0)]
        fn pause(ref self: ContractState) {
            self.accesscontrol.assert_only_role(PAUSER_ROLE);
            self.pausable.pause();
        }

        #[external(v0)]
        fn unpause(ref self: ContractState) {
            self.accesscontrol.assert_only_role(PAUSER_ROLE);
            self.pausable.unpause();
        }
    }

    //
    // Upgradeable
    //

    #[abi(embed_v0)]
    impl UpgradeableImpl of IUpgradeable<ContractState> {
        fn upgrade(ref self: ContractState, new_class_hash: ClassHash) {
            self.accesscontrol.assert_only_role(UPGRADER_ROLE);
            self.upgradeable.upgrade(new_class_hash);
        }
    }

    #[abi(embed_v0)]
    impl Crowdchain of ICrowdchain<ContractState> {
        fn create_campaign(ref self: ContractState, creator: ContractAddress, metadata: felt252) {
            assert(!creator.is_zero(), 'Creator cannot be the 0 address');
            let is_approved = self.approved_creators.read(creator);
            assert(is_approved, 'Creator not approved');
            let new_campaign_id = self.campaign_counter.read() + 1;
            self.campaign_counter.write(new_campaign_id);

            let mut campaign = self.campaigns.entry(new_campaign_id);
            campaign.creator.write(creator);
            campaign.metadata.write(metadata);
            campaign.status.write(CampaignStatus::Active);
            campaign.supporter_count.write(0);
            campaign.created_at.write(get_block_timestamp());
            campaign.updated_at.write(get_block_timestamp());
            campaign.paused_at.write(0);
            campaign.completed_at.write(0);

            self.campaign_ids.push(new_campaign_id);

            self
                .emit(
                    Event::Created(
                        CampaignCreated {
                            campaign_id: new_campaign_id,
                            creator: creator,
                            metadata: metadata,
                            status: CampaignStatus::Active,
                            supporter_count: 0,
                        },
                    ),
                );
        }

        fn update_campaign_status(
            ref self: ContractState, campaign_id: u128, new_status: CampaignStatus,
        ) {
            self.assert_is_creator(campaign_id);
            let campaign = self.campaigns.entry(campaign_id);
            let status = campaign.status.read();
            assert(
                status == CampaignStatus::Active || status == CampaignStatus::Paused,
                'Invalid status',
            );

            campaign.status.write(new_status);
            campaign.updated_at.write(get_block_timestamp());

            self
                .emit(
                    Event::StatusUpdated(
                        CampaignStatusUpdated {
                            campaign_id: campaign_id,
                            status: status,
                            // supporters: campaign.supporters.read(),
                            supporter_count: campaign.supporter_count.read(),
                        },
                    ),
                );
        }


        fn pause_campaign(ref self: ContractState, campaign_id: u128) {
            self.assert_is_admin();

            let campaign = self.campaigns.entry(campaign_id);

            campaign.status.write(CampaignStatus::Paused);
            campaign.updated_at.write(get_block_timestamp());
            campaign.paused_at.write(get_block_timestamp());
            self.emit(Event::HoldCampaign(CampaignPaused { campaign_id }));
        }

        fn unpause_campaign(ref self: ContractState, campaign_id: u128) {
            self.assert_is_admin();
            let campaign = self.campaigns.entry(campaign_id);

            campaign.status.write(CampaignStatus::Active);
            campaign.updated_at.write(get_block_timestamp());
            campaign.paused_at.write(0);

            self.emit(Event::UnholdCampaign(CampaignUnpaused { campaign_id: campaign_id }));
        }

        fn get_campaign_stats(self: @ContractState, campaign_id: u128) -> CamapaignStats {
            self.assert_is_creator(campaign_id);
            let campaign = self.campaigns.entry(campaign_id);

            CamapaignStats {
                campaign_id: campaign_id,
                status: campaign.status.read(),
                supporter_count: campaign.supporter_count.read(),
                metadata: campaign.metadata.read(),
                creator: campaign.creator.read(),
                created_at: campaign.created_at.read(),
                updated_at: campaign.updated_at.read(),
                paused_at: campaign.paused_at.read(),
                completed_at: campaign.completed_at.read(),
            }
        }

        fn admin_get_campaign_stats(self: @ContractState, campaign_id: u128) -> CamapaignStats {
            self.assert_is_admin();
            let campaign = self.campaigns.entry(campaign_id);

            CamapaignStats {
                campaign_id: campaign_id,
                status: campaign.status.read(),
                supporter_count: campaign.supporter_count.read(),
                metadata: campaign.metadata.read(),
                creator: campaign.creator.read(),
                created_at: campaign.created_at.read(),
                updated_at: campaign.updated_at.read(),
                paused_at: campaign.paused_at.read(),
                completed_at: campaign.completed_at.read(),
            }
        }

        fn get_top_campaigns(self: @ContractState) -> Array<u128> {
            let mut top_campaigns = ArrayTrait::new();
            let mut max_supporters = 0_u128;
            let mut i = 0;
            let len = self.campaign_ids.len();

            // Find the max supporter count
            while i != len {
                if let Option::Some(campaign_id_path) = self.campaign_ids.get(i) {
                    let campaign_id_val = campaign_id_path.read();
                    let mut campaign = self.campaigns.entry(campaign_id_val);
                    let supporters = campaign.supporter_count.read();
                    if supporters > max_supporters {
                        max_supporters = supporters;
                    }
                }
                i += 1;
            }

            // Collect all campaigns with max supporter count
            i = 0;
            while i != len {
                if let Option::Some(campaign_id_path) = self.campaign_ids.get(i) {
                    let campaign_id_val = campaign_id_path.read();
                    let mut campaign = self.campaigns.entry(campaign_id_val);
                    if campaign.supporter_count.read() == max_supporters {
                        top_campaigns.append(campaign_id_val);
                    }
                }
                i += 1;
            }

            top_campaigns
        }

        fn approve_creator(ref self: ContractState, creator: ContractAddress) {
            self.assert_is_admin();
            self.approved_creators.entry(creator).write(true);
        }

        fn get_last_campaign_id(self: @ContractState) -> u128 {
            self.campaign_counter.read()
        }

        fn add_supporter(ref self: ContractState, campaign_id: u128, supporter: ContractAddress) {
            self.assert_is_creator(campaign_id);
            let campaign = self.campaigns.entry(campaign_id);
            campaign.supporter_count.write(campaign.supporter_count.read() + 1);
            campaign.supporters.entry(supporter).write(true);
        }

        fn update_campaign_metadata(ref self: ContractState, campaign_id: u128, metadata: felt252) {
            self.assert_is_creator(campaign_id);
            let campaign = self.campaigns.entry(campaign_id);
            campaign.metadata.write(metadata);
            campaign.updated_at.write(get_block_timestamp());
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn assert_is_admin(self: @ContractState) {
            let caller = get_caller_address();
            let admin = self.admin.read();
            assert(caller == admin, 'Caller is not admin');
        }

        fn assert_is_creator(self: @ContractState, campaign_id: u128) {
            let campaign = self.campaigns.entry(campaign_id);
            let creator = campaign.creator.read();
            let caller = get_caller_address();
            assert(creator == caller, 'Caller is not the creator');
        }
    }
}

