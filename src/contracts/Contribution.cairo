#[starknet::contract]
pub mod Contribution {
    use core::array::ArrayTrait;
    use core::num::traits::Zero;
    use core::option::Option;
    #[event]
    use crowdchain_contracts::events::ContributionEvent::Event;
    use crowdchain_contracts::events::ContributionEvent::{
        ContributionProcessed, WithdrawalMade, PlatformFeeCollected, ContributionStatsUpdated,
    };
    use crowdchain_contracts::interfaces::IContribution::IContribution;
    use starknet::storage::{
        Map, MutableVecTrait, StorageMapReadAccess, StoragePathEntry, StoragePointerReadAccess,
        StoragePointerWriteAccess, Vec, VecTrait,
    };
    use starknet::{ContractAddress, get_block_timestamp, get_caller_address};

    #[derive(Drop, Serde)]
    pub struct ContributionStats {
        pub total_contributed: u128,
        pub total_withdrawn: u128,
    }

    #[starknet::storage_node]
    pub struct ContributorNode {
        total_contributed: u128,
        total_withdrawn: u128,
    }

    #[storage]
    struct Storage {
        contributions: Map<(u128, ContractAddress), ContributorNode>, // (campaign_id, contributor) -> stats
        total_contributions: Map<u128, u128>, // campaign_id -> total amount contributed
        total_withdrawn: Map<u128, u128>, // campaign_id -> total amount withdrawn
        platform_fee_rate: u128, // fee rate in basis points (e.g., 100 = 1%)
        top_contributors: Vec<ContractAddress>,
        admin: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress, platform_fee_rate: u128) {
        self.admin.write(admin);
        self.platform_fee_rate.write(platform_fee_rate);
    }

    #[abi(embed_v0)]
    impl Contribution of IContribution<ContractState> {
        fn process_contribution(
            ref self: ContractState,
            campaign_id: u128,
            contributor: ContractAddress,
            amount: u128,
        ) {
            assert(amount > 0, 'Contribution amount must be positive');
            let caller = get_caller_address();
            assert(caller == contributor, 'Caller must be the contributor');

            // Update contributor stats
            let mut contributor_node = self.contributions.entry((campaign_id, contributor));
            let prev_contributed = contributor_node.total_contributed.read();
            contributor_node.total_contributed.write(prev_contributed + amount);

            // Update total contributions for campaign
            let prev_total = self.total_contributions.read(campaign_id);
            self.total_contributions.write(campaign_id, prev_total + amount);

            // Calculate platform fee
            let fee = self.calculate_platform_fee(amount);
            self.emit(Event::PlatformFeeCollected(PlatformFeeCollected {
                campaign_id,
                fee_amount: fee,
            }));

            // Emit contribution processed event
            self.emit(Event::ContributionProcessed(ContributionProcessed {
                campaign_id,
                contributor,
                amount,
            }));

            // Update top contributors list (simplified: add if not present)
            let mut found = false;
            let len = self.top_contributors.len();
            let mut i = 0;
            while i < len {
                if let Option::Some(addr) = self.top_contributors.get(i) {
                    if addr == contributor {
                        found = true;
                        break;
                    }
                }
                i += 1;
            }
            if !found {
                // Limit top contributors list to max 100 entries
                if len >= 100 {
                    // Remove oldest contributor (index 0)
                    self.top_contributors.remove(0);
                }
                self.top_contributors.push(contributor);
            }

            // Emit updated stats event
            self.emit(Event::ContributionStatsUpdated(ContributionStatsUpdated {
                campaign_id,
                contributor,
                total_contributed: prev_contributed + amount,
                total_withdrawn: contributor_node.total_withdrawn.read(),
            }));
        }

        fn withdraw_funds(
            ref self: ContractState,
            campaign_id: u128,
            recipient: ContractAddress,
            amount: u128,
        ) {
            assert(amount > 0, 'Withdrawal amount must be positive');
            let caller = get_caller_address();
            assert(caller == recipient, 'Caller must be the recipient');

            // Check contributor stats
            let mut contributor_node = self.contributions.entry((campaign_id, recipient));
            let contributed = contributor_node.total_contributed.read();
            let withdrawn = contributor_node.total_withdrawn.read();
            let available = contributed - withdrawn;
            assert(amount <= available, 'Withdrawal amount exceeds available balance');

            // Update withdrawn amount
            contributor_node.total_withdrawn.write(withdrawn + amount);

            // Update total withdrawn for campaign
            let prev_total_withdrawn = self.total_withdrawn.read(campaign_id);
            self.total_withdrawn.write(campaign_id, prev_total_withdrawn + amount);

            // Emit withdrawal event
            self.emit(Event::WithdrawalMade(WithdrawalMade {
                campaign_id,
                recipient,
                amount,
            }));

            // Emit updated stats event
            self.emit(Event::ContributionStatsUpdated(ContributionStatsUpdated {
                campaign_id,
                contributor: recipient,
                total_contributed: contributed,
                total_withdrawn: withdrawn + amount,
            }));
        }

        fn calculate_platform_fee(self: @ContractState, amount: u128) -> u128 {
            let fee_rate = self.platform_fee_rate.read();
            (amount * fee_rate) / 10000u128
        }

        /// Returns the platform fee rate in basis points (e.g., 100 = 1%)
        fn get_platform_fee_rate(self: @ContractState) -> u128 {
            self.platform_fee_rate.read()
        }

        fn get_contribution_stats(
            self: @ContractState,
            campaign_id: u128,
            contributor: ContractAddress,
        ) -> (u128, u128) {
            let contributor_node = self.contributions.read((campaign_id, contributor));
            (
                contributor_node.total_contributed,
                contributor_node.total_withdrawn,
            )
        }

        fn get_top_contributors(self: @ContractState) -> Array<ContractAddress> {
            let mut contributors = ArrayTrait::new();
            let len = self.top_contributors.len();
            let mut i = 0;
            while i < len {
                if let Option::Some(addr) = self.top_contributors.get(i) {
                    contributors.append(addr);
                }
                i += 1;
            }
            contributors
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn assert_is_admin(self: @ContractState) {
            let caller = get_caller_address();
            let admin = self.admin.read();
            assert(caller == admin, 'Caller is not admin');
        }
    }
}
}
