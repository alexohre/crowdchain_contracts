use starknet::ContractAddress;

#[derive(Drop, starknet::Event)]
pub enum Event {
    NFTRegistered: NFTRegistered,
    DuplicateNFTAttempt: DuplicateNFTAttempt,
}

#[derive(Drop, starknet::Event)]
pub struct NFTRegistered {
    pub campaign_id: u32,
    pub recipient: ContractAddress,
    pub token_id: u128,
    pub tier: u8,
}

#[derive(Drop, starknet::Event)]
pub struct DuplicateNFTAttempt {
    pub campaign_id: u32,
    pub recipient: ContractAddress,
    pub token_id: u128,
}