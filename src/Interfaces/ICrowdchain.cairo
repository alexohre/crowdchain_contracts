use crowdchain_contracts::contracts::Crowdchain::Crowdchain::{CamapaignStats, CampaignStatus};
use starknet::ContractAddress;

#[starknet::interface]
pub trait ICrowdchain<TContractState> {
    fn create_campaign(ref self: TContractState, creator: ContractAddress, metadata: felt252);
    fn update_campaign_status(
        ref self: TContractState, campaign_id: u128, new_status: CampaignStatus,
    );
    fn pause_campaign(ref self: TContractState, campaign_id: u128);
    fn unpause_campaign(ref self: TContractState, campaign_id: u128);
    fn get_campaign_stats(self: @TContractState, campaign_id: u128) -> CamapaignStats;
    fn get_top_campaigns(self: @TContractState) -> Array<u128>;
    fn approve_creator(ref self: TContractState, creator: ContractAddress);
    fn get_last_campaign_id(self: @TContractState) -> u128;
    fn add_supporter(ref self: TContractState, campaign_id: u128, supporter: ContractAddress);
    fn admin_get_campaign_stats(self: @TContractState, campaign_id: u128) -> CamapaignStats;
    fn update_campaign_metadata(ref self: TContractState, campaign_id: u128, metadata: felt252);
}
