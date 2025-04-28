
#[derive(Drop, Serde, PartialEq, starknet::Store, Clone)]
pub struct Creator {
    pub status: felt252,
}

#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct User {
    address: ContractAddress,
    name: felt252,
    role: felt252,  // 'admin', 'creator', 'donor'
    is_creator: bool,
    total_contributed: u128,
    campaigns_created: u32,
    nfts_owned: u32
}

#[derive(Drop, Serde, starknet::Store, PartialEq)]
pub struct Campaign {
    id: u32,
    creator: ContractAddress,
    title: felt252,
    description: felt252,
    target_amount: u128,
    amount_raised: u128,
    start_timestamp: u64,
    end_timestamp: u64,
    is_active: bool,
    contributors_count: u32,
    rewards_issued: bool
}

#[derive(Drop, Serde, starknet::Store)]
pub struct Contribution {
    campaign_id: u32,
    contributor: ContractAddress,
    amount: u128,
    timestamp: u64,
    reward_tier: u8  // 0 = no reward, 1-3 = tier levels
}

#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct NFTReward {
    campaign_id: u32,
    recipient: ContractAddress,
    token_id: u128,
    tier: u8,
    claimed: bool,
    metadata_uri: felt252
}