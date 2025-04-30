use starknet::ContractAddress;

#[starknet::interface]
pub trait INFTReward<TContractState> {
    fn mint_nft_reward(ref self: TContractState, recipient: ContractAddress);
    fn has_claimed_reward(self: @TContractState, user: ContractAddress, tier: u8) -> bool;
    fn can_claim_tier_reward(self: @TContractState, user: ContractAddress, tier: u8) -> bool;
    fn get_user_nfts(self: @TContractState, user: ContractAddress) -> Array<u256>;
    fn get_nft_tier(self: @TContractState, project_count: u32) -> u8;
    fn get_token_tier(self: @TContractState, token_id: u256) -> u8;
    fn get_available_tiers(self: @TContractState, user: ContractAddress) -> Array<u8>;
    fn get_tier_metadata(self: @TContractState, tier: u8) -> felt252;
    fn set_tier_metadata(ref self: TContractState, tier: u8, metadata_uri: felt252);
    fn set_contribution_contract(ref self: TContractState, contribution_contract: ContractAddress);
    fn set_campaign_contract(ref self: TContractState, campaign_contract: ContractAddress);
}
