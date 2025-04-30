use starknet::ContractAddress;

// Event for when an NFT reward is minted
#[derive(Drop, starknet::Event)]
pub struct NFTRewardMinted {
    pub recipient: ContractAddress,
    pub token_id: u256,
    pub tier: u8,
    pub metadata_uri: felt252,
}

// Event for when tier metadata is updated
#[derive(Drop, starknet::Event)]
pub struct TierMetadataUpdated {
    pub tier: u8,
    pub metadata_uri: felt252,
}
