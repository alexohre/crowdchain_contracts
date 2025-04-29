use starknet::ContractAddress;

#[starknet::interface]
pub trait IContribution<TContractState> {
    fn process_contribution(ref self: TContractState, campaign_id: u128, contributor: ContractAddress, amount: u128);
    fn withdraw_funds(ref self: TContractState, campaign_id: u128, recipient: ContractAddress, amount: u128);
    fn calculate_platform_fee(self: @TContractState, amount: u128) -> u128;
    fn get_contribution_stats(self: @TContractState, campaign_id: u128, contributor: ContractAddress) -> (u128, u128); // (total_contributed, total_withdrawn)
    fn get_top_contributors(self: @TContractState) -> Array<ContractAddress>;
}
