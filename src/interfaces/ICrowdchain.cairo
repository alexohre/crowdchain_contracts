use crowdchain_contracts::contracts::Crowdchain::Crowdchain::CampaignStatus;
use crowdchain_contracts::structs::Structs::CamapaignStats;
use starknet::ContractAddress;

#[starknet::interface]
pub trait ICrowdchain<TContractState> {
    fn create_campaign(
        ref self: TContractState,
        creator: ContractAddress,
        title: ByteArray,
        description: ByteArray,
        goal: u256,
        image_url: ByteArray,
    ) -> u64;
    // fn get_campaign(self: @TContractState, campaign_id: u64) -> Array<Campaigns>;
    fn update_campaign_status(
        ref self: TContractState, campaign_id: u64, new_status: CampaignStatus,
    );
    fn pause_campaign(ref self: TContractState, campaign_id: u64);
    fn unpause_campaign(ref self: TContractState, campaign_id: u64);
    fn get_campaign_stats(self: @TContractState, campaign_id: u64) -> CamapaignStats;
    fn get_top_campaigns(self: @TContractState) -> Array<u64>;
    fn approve_creator(ref self: TContractState, creator: ContractAddress);
    fn get_last_campaign_id(self: @TContractState) -> u64;
    fn add_supporter(ref self: TContractState, campaign_id: u64, supporter: ContractAddress);
    fn admin_get_campaign_stats(self: @TContractState, campaign_id: u64) -> CamapaignStats;
    fn update_campaign_metadata(ref self: TContractState, campaign_id: u64, metadata: felt252);
    fn get_campaigns(self: @TContractState) -> Array<u64>;
    fn get_featured_campaigns(self: @TContractState) -> Array<u64>;
    fn get_user_campaigns(self: @TContractState, user: ContractAddress) -> Array<u64>;
    fn contribute(
        ref self: TContractState, campaign_id: u64, amount: u256, token_address: ContractAddress,
    );
    fn get_contribution(
        self: @TContractState, campaign_id: u64, contributor: ContractAddress,
    ) -> u256;
    fn get_campaign_contributions(self: @TContractState, campaign_id: u64) -> u256;
}
