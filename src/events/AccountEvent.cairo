use starknet::ContractAddress;

#[derive(Clone, Drop, Debug, starknet::Event)]
pub struct AccountCreated {
    pub address: ContractAddress,
    pub role: felt252,
    pub application_status: felt252,
}

#[derive(Clone, Drop, Debug, starknet::Event)]
pub struct AppliedAsCreator {
    pub address: ContractAddress,
    pub application_status: felt252,
}

#[derive(Clone, Drop, Debug, starknet::Event)]
pub struct ReapplyAsCreator {
    pub address: ContractAddress,
    pub application_status: felt252,
}

#[derive(Clone, Drop, Debug, starknet::Event)]
pub struct ApprovedApplication {
    pub address: ContractAddress,
    pub application_status: felt252,
    pub role: felt252,
}

#[derive(Clone, Debug, Drop, starknet::Event)]
pub struct RejectedApplication {
    pub address: ContractAddress,
    pub application_status: felt252,
}
