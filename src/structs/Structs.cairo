
#[derive(Drop, Serde, PartialEq, starknet::Store, Clone)]
pub struct Creator {
    pub status: felt252,
}
