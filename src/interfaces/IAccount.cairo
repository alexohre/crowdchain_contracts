use crowdchain_contracts::contracts::Account::AccountContract::User;
use starknet::ContractAddress;

#[starknet::interface]
pub trait IAccount<TContractState> {
    fn create_account(ref self: TContractState);
    fn apply_creator(ref self: TContractState);
    fn reapply_creator(ref self: TContractState);
    fn approve_application(ref self: TContractState, user: ContractAddress);
    fn reject_application(ref self: TContractState, user: ContractAddress);
    fn get_account(self: @TContractState, user: ContractAddress) -> bool;
    fn get_role(self: @TContractState, user: ContractAddress) -> felt252;
    fn get_application_status(self: @TContractState, user: ContractAddress) -> felt252;
}

