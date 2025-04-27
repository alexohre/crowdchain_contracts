use starknet::ContractAddress;

#[derive(Drop, starknet::Event)]
pub struct AdminAdded {
    pub admin_address: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct AdminRemoved {
    pub admin_address: ContractAddress,
}
#[derive(Drop, starknet::Event)]
pub struct PlatformFeeUpdated {
    pub old_fee: u256,
    pub new_fee: u256,
}
