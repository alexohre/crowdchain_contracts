use starknet::ContractAddress;

#[starknet::interface]
pub trait IAdmin<TContractState> {
    // Owner functions
    fn add_admin(ref self: TContractState, admin_address: ContractAddress) -> bool;
    fn remove_admin(ref self: TContractState, admin_address: ContractAddress) -> bool;
    fn set_platform_fee(ref self: TContractState, new_fee: u256);
    fn get_platform_fee(self: @TContractState) -> u256;
    fn get_user_role(self: @TContractState, user: ContractAddress) -> felt252;

    // Admin functions
    fn approve_creator_application(
        ref self: TContractState, creator_address: ContractAddress,
    ) -> felt252;
    fn reject_creator_application(
        ref self: TContractState, creator_address: ContractAddress,
    ) -> felt252;
    fn pause_campaign(ref self: TContractState, campaign_id: u256) -> felt252;
    fn unpause_campaign(ref self: TContractState, campaign_id: u256) -> felt252;
    fn suspend_user(ref self: TContractState, user_address: ContractAddress, reason: felt252);
    fn unsuspend_user(ref self: TContractState, user_address: ContractAddress);
    fn flag_user(ref self: TContractState, user_address: ContractAddress, flag_reason: felt252);
    fn unflag_user(ref self: TContractState, user_address: ContractAddress);
}
