use starknet::ContractAddress;

// Event for when a contribution is recorded toward NFT eligibility
#[derive(Drop, starknet::Event)]
pub struct ContributionRecorded {
    pub user: ContractAddress,
    pub campaign_id: u128,
    pub total_projects_supported: u32,
}

// Event for when an NFT reward is minted
#[derive(Drop, starknet::Event)]
pub struct NFTRewardMinted {
    pub recipient: ContractAddress,
    pub campaign_id: u128,
    pub token_id: u128,
    pub tier: u8,
    pub metadata_uri: felt252,
}

// Event for when tier metadata is updated
#[derive(Drop, starknet::Event)]
pub struct TierMetadataUpdated {
    pub tier: u8,
    pub metadata_uri: felt252,
}

// Event for when a user becomes eligible for a new tier
#[derive(Drop, starknet::Event)]
pub struct UserEligibleForNewTier {
    pub user: ContractAddress,
    pub tier: u8,
    pub projects_supported: u32,
}
