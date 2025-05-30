use crowdchain_contracts::contracts::Campaign::Campaign::CampaignStatus;
use starknet::ContractAddress;


// ******** CAMPAIGN EVENTS ********* //
// Campaign Created
#[derive(Drop, starknet::Event)]
pub struct CampaignCreated {
    #[key]
    pub creator: ContractAddress,
    #[key]
    pub campaign_id: u128,
    pub metadata: felt252,
    pub status: CampaignStatus,
    pub supporter_count: u128,
}

// Campaign Status Updated
#[derive(Drop, starknet::Event)]
pub struct CampaignStatusUpdated {
    #[key]
    pub campaign_id: u128,
    pub status: CampaignStatus,
    pub supporter_count: u128,
}

// Campaign Paused
#[derive(Drop, starknet::Event)]
pub struct CampaignPaused {
    #[key]
    pub campaign_id: u128,
}

// Campaign Unpaused
#[derive(Drop, starknet::Event)]
pub struct CampaignUnpaused {
    #[key]
    pub campaign_id: u128,
}

// ******** CONTRIBUTION EVENTS ********* //
// Contribution Processed
#[derive(Drop, starknet::Event)]
pub struct ContributionProcessed {
    #[key]
    pub campaign_id: u128,
    #[key]
    pub contributor: ContractAddress,
    pub amount: u128,
}

// Withdrawal Made
#[derive(Drop, starknet::Event)]
pub struct WithdrawalMade {
    #[key]
    pub campaign_id: u128,
    #[key]
    pub recipient: ContractAddress,
    pub amount: u128,
}

// contribution Stats Updated
#[derive(Drop, starknet::Event)]
pub struct ContributionStatsUpdated {
    #[key]
    pub campaign_id: u128,
    #[key]
    pub contributor: ContractAddress,
    pub total_contributed: u128,
    pub total_withdrawn: u128,
}


// ******** ACCOUNT EVENTS ********* //
// Applied as Creator
#[derive(Clone, Drop, Debug, starknet::Event)]
pub struct AppliedAsCreator {
    pub address: ContractAddress,
    pub application_status: felt252,
}

// Application Approved
#[derive(Clone, Drop, Debug, starknet::Event)]
pub struct ApprovedApplication {
    pub address: ContractAddress,
    pub application_status: felt252,
    pub role: felt252,
}

// Application Rejected
#[derive(Clone, Debug, Drop, starknet::Event)]
pub struct RejectedApplication {
    pub address: ContractAddress,
    pub application_status: felt252,
}


// ******** ADMIN EVENTS ********* //
// Admin added
#[derive(Drop, starknet::Event)]
pub struct AdminAdded {
    pub admin_address: ContractAddress,
}

// Admin removed
#[derive(Drop, starknet::Event)]
pub struct AdminRemoved {
    pub admin_address: ContractAddress,
}

// Platform Fee Updated
#[derive(Drop, starknet::Event)]
pub struct PlatformFeeUpdated {
    pub old_fee: u256,
    pub new_fee: u256,
}
