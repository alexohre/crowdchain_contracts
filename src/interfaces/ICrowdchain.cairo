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
        token_address: ContractAddress,
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
    fn contribute(ref self: TContractState, campaign_id: u64, amount: u256);
    fn get_contribution(
        self: @TContractState, campaign_id: u64, contributor: ContractAddress,
    ) -> u256;
    fn get_campaign_contributions(self: @TContractState, campaign_id: u64) -> u256;

    // Enhanced role verification functions
    fn is_admin_or_owner(self: @TContractState, address: ContractAddress) -> bool;
    fn is_approved_creator(self: @TContractState, address: ContractAddress) -> bool;
    fn get_owner(self: @TContractState) -> ContractAddress;

    // Admin management functions
    fn add_admin(ref self: TContractState, admin: ContractAddress);
    fn remove_admin(ref self: TContractState, admin: ContractAddress);
    fn is_admin(self: @TContractState, address: ContractAddress) -> bool;
    fn get_admin_count(self: @TContractState) -> u32;
    fn get_admin_by_index(self: @TContractState, index: u32) -> ContractAddress;
    fn get_all_admins(self: @TContractState) -> Array<ContractAddress>;

    // Fund withdrawal and platform fee functions
    fn withdraw_campaign_funds(ref self: TContractState, campaign_id: u64);
    /// Refund contributors for fraudulent campaigns (owner/admin only)
    fn refund_campaign(
        ref self: TContractState, campaign_id: u64, contributors: Array<ContractAddress>,
    );
    fn get_campaign_funds_by_token(
        self: @TContractState, campaign_id: u64, token_address: ContractAddress,
    ) -> u256;
    fn get_campaign_token(self: @TContractState, campaign_id: u64) -> ContractAddress;
    fn is_campaign_disbursed(self: @TContractState, campaign_id: u64) -> bool;
    fn get_platform_fees_collected(
        self: @TContractState, campaign_id: u64, token_address: ContractAddress,
    ) -> u256;
    fn update_platform_fee_settings(
        ref self: TContractState,
        fee_percentage: u256,
        fee_threshold: u256,
        platform_wallet: ContractAddress,
    );
    fn get_platform_fee_settings(self: @TContractState) -> (u256, u256, ContractAddress);
    fn register_token_decimals(
        ref self: TContractState, token_address: ContractAddress, decimals: u8,
    );
    fn get_token_decimals(self: @TContractState, token_address: ContractAddress) -> u8;


    // Creator application functions
    fn submit_creator_application(ref self: TContractState);
    fn is_creator_application_pending(self: @TContractState, address: ContractAddress) -> bool;
}
