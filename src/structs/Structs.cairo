
#[derive(Drop, Serde, PartialEq, starknet::Store, Clone)]
pub struct Creator {
    pub status: felt252,
}

#[derive(Drop, Serde, PartialEq, starknet::Store, Clone)]
pub struct Campaign {
   pub status: felt252,
}