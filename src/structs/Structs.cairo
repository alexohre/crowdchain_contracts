use crowdchain_contracts::contracts::Crowdchain::Crowdchain::CampaignStatus;
use starknet::ContractAddress;

#[derive(Drop, Serde, PartialEq, starknet::Store, Clone)]
pub struct Creator {
    pub status: felt252,
}

#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct User {
    address: ContractAddress,
    name: felt252,
    role: felt252, // 'admin', 'creator', 'donor'
    is_creator: bool,
    total_contributed: u128,
    campaigns_created: u64,
    nfts_owned: u64,
}

#[derive(Drop, Serde, starknet::Store, PartialEq)]
pub struct Campaign {
    pub id: u64,
    pub creator: ContractAddress,
    pub title: ByteArray,
    pub description: ByteArray,
    pub goal: u256,
    pub amount_raised: u256,
    pub start_timestamp: u64,
    pub end_timestamp: u64,
    pub is_active: bool,
    pub contributors_count: u64,
    pub rewards_issued: bool,
}

#[derive(Drop, Serde)]
pub struct CamapaignStats {
    pub campaign_id: u64,
    pub status: CampaignStatus,
    pub supporter_count: u64,
    pub creator: ContractAddress,
    pub created_at: u64,
    pub updated_at: u64,
    pub paused_at: u64,
    pub completed_at: u64,
}

#[derive(Drop, Serde, starknet::Store)]
pub struct Contribution {
    campaign_id: u64,
    contributor: ContractAddress,
    amount: u128,
    timestamp: u64,
    reward_tier: u8 // 0 = no reward, 1-3 = tier levels
}

#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct NFTReward {
    campaign_id: u64,
    recipient: ContractAddress,
    token_id: u256,
    tier: u8,
    claimed: bool,
    metadata_uri: felt252,
}
