#[starknet::contract]
pub mod Campaign {
    use core::array::ArrayTrait;
    use core::num::traits::Zero;
    use core::option::Option;
    #[event]
    use crowdchain_contracts::events::CampaignEvent::Event;
    use crowdchain_contracts::events::CampaignEvent::{
        CampaignCreated, CampaignPaused, CampaignStatsUpdated, CampaignUnpaused,
    };
    use crowdchain_contracts::interfaces::ICampaign::ICampaign;
    use starknet::storage::{
        Map, MutableVecTrait, StorageMapReadAccess, StoragePathEntry, StoragePointerReadAccess,
        StoragePointerWriteAccess, Vec, VecTrait,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};

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

    #[storage]
    struct Storage {
        approved_creators: Map<ContractAddress, bool>,
        campaigns: Map<u128, CampaignNode>,
        campaign_counter: u128,
        campaign_ids: Vec<u128>,
        admin: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        self.admin.write(admin);
    }

    #[abi(embed_v0)]
    impl Campaign of ICampaign<ContractState> {
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
                    Event::StatsUpdated(
                        CampaignStatsUpdated {
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
            self.emit(Event::Paused(CampaignPaused { campaign_id }));
        }

        fn unpause_campaign(ref self: ContractState, campaign_id: u128) {
            self.assert_is_admin();
            let campaign = self.campaigns.entry(campaign_id);

            campaign.status.write(CampaignStatus::Active);
            campaign.updated_at.write(get_block_timestamp());
            campaign.paused_at.write(0);

            self.emit(Event::Unpaused(CampaignUnpaused { campaign_id: campaign_id }));
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
