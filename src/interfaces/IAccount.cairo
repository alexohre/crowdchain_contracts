use starknet::ContractAddress;

#[starknet::interface]
pub trait IAccount<TContractState> {
    fn apply_creator(ref self: TContractState);
    fn approve_application(ref self: TContractState, user: ContractAddress);
    fn reject_application(ref self: TContractState, user: ContractAddress);
    fn get_account_contribution_count(self: @TContractState, user: ContractAddress) -> bool;
    fn get_account_role(self: @TContractState, user: ContractAddress) -> felt252;
    fn get_application_status(self: @TContractState, user: ContractAddress) -> felt252;
    // THE ABOVE FUNCTIONS IS TO BE MOVED TO ICAMPAIGN INTERFACE AND IMPLEMENTED ON THE CAMPAIGN
// CONTRACT
}

