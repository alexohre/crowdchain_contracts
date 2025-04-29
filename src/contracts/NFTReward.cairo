#[starknet::contract]
pub mod NFTRewardContract {
    use core::array::ArrayTrait;
    use core::option::OptionTrait;
    use core::traits::Into;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePointerReadAccess,
        StoragePointerWriteAccess, Vec, VecTrait,
    };
    use starknet::{
        ContractAddress, contract_address_const, get_block_timestamp, get_caller_address,
    };

    // Crate imports
    use crate::events::NFTRewardEvent::{
        ContributionRecorded, NFTRewardMinted, TierMetadataUpdated, UserEligibleForNewTier,
    };
    use crate::interfaces::ICampaign::{ICampaignDispatcher, ICampaignDispatcherTrait};
    use crate::interfaces::IContribution::{IContributionDispatcher, IContributionDispatcherTrait};
    use crate::interfaces::INFTReward::INFTReward;
    use crate::structs::Structs::NFTReward;

    // Component declarations
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // External ERC721 Implementation
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    // Internal ERC721 Implementation
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;


    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        contribution_contract: ContractAddress,
        campaign_contract: ContractAddress,
        user_supported_campaigns: Map<(ContractAddress, u128), bool>,
        user_supported_campaign_count: Map<ContractAddress, u32>,
        user_nfts: Map<ContractAddress, Vec<u256>>,
        nft_rewards: Map<u256, NFTReward>,
        next_token_id: u256,
        tier_metadata: Map<u8, felt252>,
        reward_claimed: Map<(ContractAddress, u128), bool>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
        ContributionRecorded: ContributionRecorded,
        NFTRewardMinted: NFTRewardMinted,
        TierMetadataUpdated: TierMetadataUpdated,
        UserEligibleForNewTier: UserEligibleForNewTier,
    }

    // Constants for tier thresholds
    const TIER_1_THRESHOLD: u32 = 1; // 1 project supported
    const TIER_2_THRESHOLD: u32 = 2; // 2 projects supported
    const TIER_3_THRESHOLD: u32 = 3; // 3 projects supported
    const TIER_4_THRESHOLD: u32 = 4; // 4 projects supported
    const TIER_5_THRESHOLD: u32 = 5; // 5 projects supported

    #[constructor]
    fn constructor(
        ref self: ContractState, owner: ContractAddress, name: felt252, symbol: felt252,
    ) {
        // Perform sanity checks
        assert(owner != contract_address_const::<0>(), 'Zero address forbidden');
        assert(name != contract_address_const::<''>(), 'Empty name forbidden');
        assert(symbol != contract_address_const::<''>(), 'Empty symbol forbidden');

        // Initialize ERC721 and Ownable components
        self.erc721.initializer(name, symbol, "");
        self.ownable.initializer(owner);

        // Initialize ERC721 metadata
        self.next_token_id.write(1);

        // Set default metadata URIs for each tier
        self.tier_metadata.write(1, 'ipfs://tier1_metadata');
        self.tier_metadata.write(2, 'ipfs://tier2_metadata');
        self.tier_metadata.write(3, 'ipfs://tier3_metadata');
        self.tier_metadata.write(4, 'ipfs://tier4_metadata');
        self.tier_metadata.write(5, 'ipfs://tier5_metadata');
    }

    #[abi(embed_v0)]
    impl NFTRewardContractImpl of INFTReward<ContractState> {
        fn is_eligible_for_tier(self: @ContractState, user: ContractAddress, tier: u8) -> bool {
            assert(tier >= 1 && tier <= 5, 'Invalid tier: must be 1-5');

            let project_count = self.user_supported_campaign_count.read(user);

            // User is eligible for tier X if they supported at least X projects
            match tier {
                1 => project_count >= TIER_1_THRESHOLD,
                2 => project_count >= TIER_2_THRESHOLD,
                3 => project_count >= TIER_3_THRESHOLD,
                4 => project_count >= TIER_4_THRESHOLD,
                5 => project_count >= TIER_5_THRESHOLD,
                _ => false,
            }
        }

        fn get_supported_projects_count(self: @ContractState, user: ContractAddress) -> u32 {
            self.user_supported_campaign_count.read(user)
        }

        fn record_contribution(ref self: ContractState, user: ContractAddress, campaign_id: u128) {
            // Ensure contribution contract is set
            let contribution_contract = self.contribution_contract.read();
            assert(
                contribution_contract != contract_address_const::<0>(),
                'Contribution contract not set',
            );

            // Ensure campaign contract is set
            let campaign_contract = self.campaign_contract.read();
            assert(campaign_contract != contract_address_const::<0>(), 'Campaign contract not set');

            // Get actual contribution data from the contribution contract
            let contribution_dispatcher = IContributionDispatcher {
                contract_address: contribution_contract,
            };
            let (total_contributed, _) = contribution_dispatcher
                .get_contribution_stats(campaign_id, user);

            // Verify user has actually contributed to this campaign
            assert(total_contributed > 0, 'No contribution found');

            // Check if this is a new campaign for this user
            let has_supported = self.user_supported_campaigns.read((user, campaign_id));

            if !has_supported {
                // Record that this user has supported this campaign
                self.user_supported_campaigns.write((user, campaign_id), true);

                // Increment the user's supported project count
                let current_count = self.user_supported_campaign_count.read(user);
                let new_count = current_count + 1;
                self.user_supported_campaign_count.write(user, new_count);

                // Update the campaign contract to register the user as a supporter
                let campaign_dispatcher = ICampaignDispatcher {
                    contract_address: campaign_contract,
                };
                campaign_dispatcher.add_supporter(campaign_id, user);

                // Emit event for the contribution
                self
                    .emit(
                        ContributionRecorded {
                            user, campaign_id, total_projects_supported: new_count,
                        },
                    );

                // Check if user is now eligible for a new tier and emit event if so
                let new_tier = self.get_nft_tier(new_count);
                let old_tier = self.get_nft_tier(current_count);

                if new_tier > old_tier {
                    self
                        .emit(
                            UserEligibleForNewTier {
                                user, tier: new_tier, projects_supported: new_count,
                            },
                        );
                }
            }
        }

        fn mint_nft_reward(ref self: ContractState, recipient: ContractAddress, campaign_id: u128) {
            // Ensure recipient has contributed to this campaign
            let has_supported = self.user_supported_campaigns.read((recipient, campaign_id));
            assert(has_supported, 'Must support campaign first');

            // Ensure recipient hasn't already claimed a reward for this campaign
            let already_claimed = self.reward_claimed.read((recipient, campaign_id));
            assert(!already_claimed, 'Campaign reward already claimed');

            // Get the number of projects supported by this user
            let project_count = self.user_supported_campaign_count.read(recipient);
            assert(project_count > 0, 'Must support at least 1 project');

            // Determine the appropriate tier based on project count
            let tier = self.get_nft_tier(project_count);

            // Get the metadata URI for this tier
            let metadata_uri = self.tier_metadata.read(tier);

            // Get the next token ID
            let token_id = self.next_token_id.read();
            self.next_token_id.write(token_id + 1);

            // Create the NFT reward
            let nft_reward = NFTReward {
                campaign_id, recipient, token_id, tier, claimed: true, metadata_uri,
            };

            // Store the NFT reward
            self.nft_rewards.write(token_id, nft_reward);

            // Mark that this user has claimed a reward for this campaign
            self.reward_claimed.write((recipient, campaign_id), true);

            // Add the token to the user's owned NFTs
            let mut user_nfts = self.get_user_nfts_internal(recipient);
            user_nfts.append(token_id);

            let mut vec_ref = self.user_nfts.try_write(recipient);
            match vec_ref {
                Option::Some(vec_ref) => { vec_ref.append(token_id) },
                Option::None => {
                    let mut new_vec = VecTrait::new();
                    new_vec.append(token_id);
                    self.user_nfts.write(recipient, new_vec);
                },
            }

            // Mint the token using the ERC721 component
            self.erc721._mint(recipient, token_id);

            // Emit event for minting
            self
                .emit(
                    NFTRewardMinted {
                        recipient,
                        campaign_id,
                        token_id: token_id.try_into().unwrap(),
                        tier,
                        metadata_uri,
                    },
                );
        }

        fn get_nft_tier(self: @ContractState, project_count: u32) -> u8 {
            if project_count >= TIER_5_THRESHOLD {
                return 5;
            } else if project_count >= TIER_4_THRESHOLD {
                return 4;
            } else if project_count >= TIER_3_THRESHOLD {
                return 3;
            } else if project_count >= TIER_2_THRESHOLD {
                return 2;
            } else if project_count >= TIER_1_THRESHOLD {
                return 1;
            } else {
                return 0; // Not eligible for any tier
            }
        }

        fn has_claimed_reward(
            self: @ContractState, user: ContractAddress, campaign_id: u128,
        ) -> bool {
            self.reward_claimed.read((user, campaign_id))
        }

        fn get_user_nfts(self: @ContractState, user: ContractAddress) -> Array<u256> {
            let mut result = ArrayTrait::new();

            let user_nfts = self.get_user_nfts_internal(user);
            let mut i = 0;
            let len = user_nfts.len();

            while i != len {
                if let Option::Some(token_id_path) = user_nfts.get(i) {
                    let token_id = token_id_path.read();
                    result.append(token_id);
                }
                i += 1;
            }

            result
        }

        fn set_tier_metadata(ref self: ContractState, tier: u8, metadata_uri: felt252) {
            // Only admin can set tier metadata
            self.ownable.assert_only_owner();

            assert(tier >= 1 && tier <= 5, 'Invalid tier: must be 1-5');

            self.tier_metadata.write(tier, metadata_uri);

            self.emit(TierMetadataUpdated { tier, metadata_uri });
        }

        fn get_tier_metadata(self: @ContractState, tier: u8) -> felt252 {
            assert(tier >= 1 && tier <= 5, 'Invalid tier: must be 1-5');
            self.tier_metadata.read(tier)
        }

        fn get_token_tier(self: @ContractState, token_id: u256) -> u8 {
            // Ensure token exists
            self.erc721._owner_of(token_id);

            // Get NFT reward
            let reward = self.nft_rewards.read(token_id);
            reward.tier
        }

        fn set_contribution_contract(
            ref self: ContractState, contribution_contract: ContractAddress,
        ) {
            // Only admin can set contract addresses
            self.ownable.assert_only_owner();

            self.contribution_contract.write(contribution_contract);

            self
                .emit(
                    Event::NFTRewardEvent(
                        crate::events::NFTRewardEvent::Event::ContractAddressUpdated(
                            ContractAddressUpdated {
                                contract_type: 'contribution', address: contribution_contract,
                            },
                        ),
                    ),
                );
        }

        fn set_campaign_contract(ref self: ContractState, campaign_contract: ContractAddress) {
            // Only admin can set contract addresses
            self.ownBle.assert_only_owner();

            self.campaign_contract.write(campaign_contract);

            self
                .emit(
                    ContractAddressUpdated {
                        contract_type: 'campaign', address: campaign_contract,
                    },
                );
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn assert_is_admin(self: @ContractState) {
            let caller = get_caller_address();
            let admin = self.admin.read();
            assert(caller == admin, 'Caller is not admin');
        }

        fn get_user_nfts_internal(self: @ContractState, user: ContractAddress) -> Vec<u256> {
            let mut vec_ref = self.user_nfts.try_read(user);
            match vec_ref {
                Option::Some(vec) => vec,
                Option::None => VecTrait::new(),
            }
        }
    }
}
