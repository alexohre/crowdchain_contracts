// use openzeppelin::token::erc721::interface::{IERC721, IERC721Metadata};
use starknet::ContractAddress;

#[starknet::interface]
pub trait INFTReward<TContractState> {
    // Check if a user is eligible for a specific NFT tier
    fn is_eligible_for_tier(self: @TContractState, user: ContractAddress, tier: u8) -> bool;

    // Get the number of projects a user has supported
    fn get_supported_projects_count(self: @TContractState, user: ContractAddress) -> u32;

    // Record a user's contribution to a campaign
    fn record_contribution(ref self: TContractState, user: ContractAddress, campaign_id: u128);

    // Mint an NFT reward for an eligible user for a specific campaign
    fn mint_nft_reward(ref self: TContractState, recipient: ContractAddress, campaign_id: u128);

    // Get the NFT tier based on the number of supported projects
    fn get_nft_tier(self: @TContractState, project_count: u32) -> u8;

    // Check if a user has already claimed an NFT reward for a specific campaign
    fn has_claimed_reward(self: @TContractState, user: ContractAddress, campaign_id: u128) -> bool;

    // Get all NFTs owned by a user
    fn get_user_nfts(self: @TContractState, user: ContractAddress) -> Array<u256>;

    // Set the metadata URI for a specific tier
    fn set_tier_metadata(ref self: TContractState, tier: u8, metadata_uri: felt252);

    // Get the metadata URI for a specific tier
    fn get_tier_metadata(self: @TContractState, tier: u8) -> felt252;

    // Get tier info for a token
    fn get_token_tier(self: @TContractState, token_id: u256) -> u8;

    // Set contribution contract address
    fn set_contribution_contract(ref self: TContractState, contribution_contract: ContractAddress);

    // Set campaign contract address
    fn set_campaign_contract(ref self: TContractState, campaign_contract: ContractAddress);
}
