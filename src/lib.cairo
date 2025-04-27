// inporting interfaces
pub mod interfaces {
    pub mod IAccount;
}

// importing contract
pub mod contracts {
    pub mod Account;
}

// importing Events
pub mod events {
    pub mod AccountEvent;
}


// importing tests
#[cfg(tests)]
pub mod tests {
    pub mod test_account;
    pub mod test_account_events;
    pub mod test_demo;
}
// /// Interface representing `HelloContract`.
// /// This interface allows modification and retrieval of the contract balance.
// #[starknet::interface]
// pub trait IHelloStarknet<TContractState> {
//     /// Increase contract balance.
//     fn increase_balance(ref self: TContractState, amount: felt252);
//     /// Retrieve contract balance.
//     fn get_balance(self: @TContractState) -> felt252;
// }

// /// Simple contract for managing balance.
// #[starknet::contract]
// mod HelloStarknet {
//     use core::starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};

//     #[storage]
//     struct Storage {
//         balance: felt252,
//     }

//     #[abi(embed_v0)]
//     impl HelloStarknetImpl of super::IHelloStarknet<ContractState> {
//         fn increase_balance(ref self: ContractState, amount: felt252) {
//             assert(amount != 0, 'Amount cannot be 0');
//             self.balance.write(self.balance.read() + amount);
//         }

//         fn get_balance(self: @ContractState) -> felt252 {
//             self.balance.read()
//         }
//     }
// }


