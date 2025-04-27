use crowdchain_contracts::contracts::Campaign::Campaign::CampaignStatus;
use starknet::ContractAddress;

#[event]
#[derive(Drop, starknet::Event)]
pub enum Event {
    Created: CampaignCreated,
    StatusUpdated: CampaignStatusUpdated,
    Paused: CampaignPaused,
    Unpaused: CampaignUnpaused,
    StatsUpdated: CampaignStatsUpdated,
}

#[derive(Drop, starknet::Event)]
pub struct CampaignCreated {
    #[key]
    pub creator: ContractAddress,
    #[key]
    pub campaign_id: u128,
    pub metadata: felt252,
    pub status: CampaignStatus,
    pub supporter_count: u128,
}

#[derive(Drop, starknet::Event)]
pub struct CampaignStatusUpdated {
    #[key]
    pub campaign_id: u128,
    pub status: CampaignStatus,
}

#[derive(Drop, starknet::Event)]
pub struct CampaignPaused {
    #[key]
    pub campaign_id: u128,
}

#[derive(Drop, starknet::Event)]
pub struct CampaignUnpaused {
    #[key]
    pub campaign_id: u128,
}

#[derive(Drop, starknet::Event)]
pub struct CampaignStatsUpdated {
    #[key]
    pub campaign_id: u128,
    pub status: CampaignStatus,
    pub supporter_count: u128,
}
