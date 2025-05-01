#[starknet::contract]
pub mod Contribution {
    use core::array::ArrayTrait;
    use core::option::Option;
    #[event]
    use crowdchain_contracts::events::ContributionEvent::Event;
    use crowdchain_contracts::events::ContributionEvent::{
        ContributionProcessed, ContributionStatsUpdated, PlatformFeeCollected, WithdrawalMade,
    };
    use crowdchain_contracts::interfaces::IContribution::IContribution;
    use starknet::storage::{
        Map, MutableVecTrait, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
        Vec, VecTrait,
    };
    use starknet::{ContractAddress, get_caller_address};

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
        contributions: Map<
            u128, Map<ContractAddress, ContributorNode>,
        >, // (campaign_id, contributor) -> stats
        total_contributions: Map<u128, u128>, // campaign_id -> total amount contributed
        total_contribution_count: Map<
            ContractAddress, u32,
        >, // contributor -> total contribution count
        total_withdrawn: Map<u128, u128>, // campaign_id -> total amount withdrawn
        platform_fee_rate: u128, // fee rate in basis points (e.g., 100 = 1%)
        top_contributors: Vec<ContractAddress>,
        top_contributors_count: u32, // Count of contributors in the list
        top_contributors_max_size: u32, // Maximum size of the top contributors list
        admin: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress, platform_fee_rate: u128) {
        self.admin.write(admin);
        self.platform_fee_rate.write(platform_fee_rate);
        self.top_contributors_count.write(0);
        self.top_contributors_max_size.write(100); // Set max size to 100
    }

    #[abi(embed_v0)]
    impl Contribution of IContribution<ContractState> {
        fn process_contribution(
            ref self: ContractState, campaign_id: u128, contributor: ContractAddress, amount: u128,
        ) {
            assert(amount > 0, 'Contribution must be positive');
            let caller = get_caller_address();
            assert(caller == contributor, 'Caller must be the contributor');

            // Update contributor stats
            let mut contributor_node = self.contributions.entry(campaign_id).entry(contributor);
            let prev_contributed = contributor_node.total_contributed.read();
            contributor_node.total_contributed.write(prev_contributed + amount);

            // Update total contributions for campaign
            let prev_total = self.total_contributions.entry(campaign_id).read();
            self.total_contributions.entry(campaign_id).write(prev_total + amount);

            // Update total contribution count for contributor
            let prev_count = self.total_contribution_count.entry(contributor).read();
            self.total_contribution_count.entry(contributor).write(prev_count + 1);

            // Calculate platform fee
            let fee = self.calculate_platform_fee(amount);
            self
                .emit(
                    Event::PlatformFeeCollected(
                        PlatformFeeCollected { campaign_id, fee_amount: fee },
                    ),
                );

            // Emit contribution processed event
            self
                .emit(
                    Event::ContributionProcessed(
                        ContributionProcessed { campaign_id, contributor, amount },
                    ),
                );

            // Update top contributors list
            let mut found = false;
            let len = self.top_contributors.len();
            let mut i = 0;
            while i < len {
                if let Option::Some(addr_path) = self.top_contributors.get(i) {
                    let addr_value = addr_path.read();
                    if addr_value == contributor {
                        found = true;
                        break;
                    }
                }
                i += 1;
            }

            if !found {
                let max_size = self.top_contributors_max_size.read();
                let current_count = self.top_contributors_count.read();

                if current_count < max_size {
                    // Still have space, just add
                    self.top_contributors.push(contributor);
                    self.top_contributors_count.write(current_count + 1);
                } else if len > 0 {
                    // We're at capacity, replace oldest contributor
                    // Shift all elements one position forward (dropping the first one)
                    let mut j = 0;
                    while j < len - 1 {
                        if let (Option::Some(current_path), Option::Some(next_path)) =
                            (self.top_contributors.get(j), self.top_contributors.get(j + 1)) {
                            let next_value = next_path.read();
                            current_path.write(next_value);
                        }
                        j += 1;
                    }

                    // Add new contributor at the end
                    if let Option::Some(last_path) = self.top_contributors.get(len - 1) {
                        last_path.write(contributor);
                    }
                } else {
                    // First element in empty list
                    self.top_contributors.push(contributor);
                    self.top_contributors_count.write(1);
                }
            }

            // Emit updated stats event
            self
                .emit(
                    Event::ContributionStatsUpdated(
                        ContributionStatsUpdated {
                            campaign_id,
                            contributor,
                            total_contributed: prev_contributed + amount,
                            total_withdrawn: contributor_node.total_withdrawn.read(),
                        },
                    ),
                );
        }

        fn withdraw_funds(
            ref self: ContractState, campaign_id: u128, recipient: ContractAddress, amount: u128,
        ) {
            assert(amount > 0, 'Withdrawal amount must be >0');
            let caller = get_caller_address();
            assert(caller == recipient, 'Caller must be the recipient');

            // Check contributor stats
            let mut contributor_node = self.contributions.entry(campaign_id).entry(recipient);
            let contributed = contributor_node.total_contributed.read();
            let withdrawn = contributor_node.total_withdrawn.read();
            let available = contributed - withdrawn;
            assert(amount <= available, 'Withdrawal amt exceeds balance');

            // Update withdrawn amount
            contributor_node.total_withdrawn.write(withdrawn + amount);

            // Update total withdrawn for campaign
            let prev_total_withdrawn = self.total_withdrawn.entry(campaign_id).read();
            self.total_withdrawn.entry(campaign_id).write(prev_total_withdrawn + amount);

            // Emit withdrawal event
            self.emit(Event::WithdrawalMade(WithdrawalMade { campaign_id, recipient, amount }));

            // Emit updated stats event
            self
                .emit(
                    Event::ContributionStatsUpdated(
                        ContributionStatsUpdated {
                            campaign_id,
                            contributor: recipient,
                            total_contributed: contributed,
                            total_withdrawn: withdrawn + amount,
                        },
                    ),
                );
        }

        fn calculate_platform_fee(self: @ContractState, amount: u128) -> u128 {
            let fee_rate = self.platform_fee_rate.read();
            (amount * fee_rate) / 10000_u128
        }

        /// Returns the platform fee rate in basis points (e.g., 100 = 1%)
        fn get_platform_fee_rate(self: @ContractState) -> u128 {
            self.platform_fee_rate.read()
        }

        fn get_contribution_stats(
            self: @ContractState, campaign_id: u128, contributor: ContractAddress,
        ) -> (u128, u128) {
            let contributor_node = self.contributions.entry(campaign_id).entry(contributor);
            (contributor_node.total_contributed.read(), contributor_node.total_withdrawn.read())
        }

        fn get_total_contribution_count(self: @ContractState, contributor: ContractAddress) -> u32 {
            self.total_contribution_count.entry(contributor).read()
        }

        fn get_top_contributors(self: @ContractState) -> Array<ContractAddress> {
            let mut contributors = ArrayTrait::new();

            for i in 0..self.top_contributors.len() {
                contributors.append(self.top_contributors.at(i).read());
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
