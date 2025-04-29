use starknet::ContractAddress;

#[event]
#[derive(Drop, starknet::Event)]
pub enum Event {
    ContributionProcessed: ContributionProcessed,
    WithdrawalMade: WithdrawalMade,
    PlatformFeeCollected: PlatformFeeCollected,
    ContributionStatsUpdated: ContributionStatsUpdated,
}

#[derive(Drop, starknet::Event)]
pub struct ContributionProcessed {
    #[key]
    pub campaign_id: u128,
    #[key]
    pub contributor: ContractAddress,
    pub amount: u128,
}

#[derive(Drop, starknet::Event)]
pub struct WithdrawalMade {
    #[key]
    pub campaign_id: u128,
    #[key]
    pub recipient: ContractAddress,
    pub amount: u128,
}

#[derive(Drop, starknet::Event)]
pub struct PlatformFeeCollected {
    #[key]
    pub campaign_id: u128,
    pub fee_amount: u128,
}

#[derive(Drop, starknet::Event)]
pub struct ContributionStatsUpdated {
    #[key]
    pub campaign_id: u128,
    #[key]
    pub contributor: ContractAddress,
    pub total_contributed: u128,
    pub total_withdrawn: u128,
}
