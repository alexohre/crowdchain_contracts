#[starknet::contract]
pub mod NFTRewardContract {
    use core::array::ArrayTrait;
    use core::option::OptionTrait;
    use core::traits::{Into, TryInto};
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::{ERC721Component, ERC721HooksEmptyImpl};
    use starknet::ContractAddress;
    use starknet::storage::{
        Map, MutableVecTrait, StoragePathEntry, StoragePointerReadAccess, StoragePointerWriteAccess,
        Vec, VecTrait,
    };

    // Crate imports
    use crate::events::NFTRewardEvent::{
        NFTRewardMinted, TierMetadataUpdated, UserEligibleForNewTier, UserTotalContributionUpdated,
    };
    use crate::interfaces::ICampaign::{ICampaignDispatcher, ICampaignDispatcherTrait};
    use crate::interfaces::IContribution::{IContributionDispatcher, IContributionDispatcherTrait};
    use crate::interfaces::INFTReward::INFTReward;

    // Component declarations
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // External ERC721 Implementation
    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;

    // Internal ERC721 Implementation
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

    #[derive(Drop, Serde, starknet::Store, Clone)]
    pub struct NFTReward {
        recipient: ContractAddress,
        token_id: u256,
        tier: u8,
        claimed: bool,
        metadata_uri: felt252,
    }

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
        nft_rewards: Map<u256, NFTReward>,
        tier_metadata: Map<u8, felt252>,
        reward_claimed: Map<ContractAddress, Map<u8, bool>>,
        next_token_id: u256,
        user_nfts: Map<ContractAddress, Vec<u256>>,
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
        NFTRewardMinted: NFTRewardMinted,
        TierMetadataUpdated: TierMetadataUpdated,
    }

    // Constants for tier thresholds
    const TIER_1_THRESHOLD: u32 = 1; // 1 project supported
    const TIER_2_THRESHOLD: u32 = 2; // 2 projects supported
    const TIER_3_THRESHOLD: u32 = 3; // 3 projects supported
    const TIER_4_THRESHOLD: u32 = 4; // 4 projects supported
    const TIER_5_THRESHOLD: u32 = 5; // 5 projects supported

    // Address Constant
    const ZERO_ADDRESS: ContractAddress = 0.try_into.unwrap();

    #[constructor]
    fn constructor(
        ref self: ContractState,
        owner: ContractAddress,
        name: ByteArray,
        symbol: ByteArray,
        contribution_contract: ContractAddress,
        campaign_contract: ContractAddress,
    ) {
        // Perform sanity checks
        assert(owner != ZERO_ADDRESS, 'Zero address forbidden');
        assert(contribution_contract != ZERO_ADDRESS, 'Zero address forbidden');
        assert(campaign_contract != ZERO_ADDRESS, 'Zero address forbidden');
        assert(name.len() > 0, 'Empty name forbidden');
        assert(symbol.len() > 0, 'Empty symbol forbidden');

        // Initialize ERC721 and Ownable components
        self.erc721.initializer(name, symbol, "");
        self.ownable.initializer(owner);

        // Set contract addresses
        self.contribution_contract.write(contribution_contract);
        self.campaign_contract.write(campaign_contract);

        // Initialize ERC721 metadata
        self.next_token_id.write(1);

        // Set default metadata URIs for each tier
        self.tier_metadata.entry(1).write('ipfs://tier1_metadata');
        self.tier_metadata.entry(2).write('ipfs://tier2_metadata');
        self.tier_metadata.entry(3).write('ipfs://tier3_metadata');
        self.tier_metadata.entry(4).write('ipfs://tier4_metadata');
        self.tier_metadata.entry(5).write('ipfs://tier5_metadata');
    }

    #[abi(embed_v0)]
    impl NFTRewardContractImpl of INFTReward<ContractState> {
        /// Mint an NFT reward for an eligible user for a specific campaign
        fn mint_nft_reward(ref self: ContractState, recipient: ContractAddress) {
            // Ensure recipient is not zero address
            assert(recipient != ZERO_ADDRESS, 'Recipient cannot be zero address');

            // Get the contribution dispatcher
            let contribution_dispatcher = IContributionDispatcher {
                contract_address: contribution_contract,
            };

            // Get total contribution count
            let campaign_count = contribution_dispatcher.get_total_contribution_count(recipient);
            assert(campaign_count > 0, 'No contributions found');

            // Determine the appropriate tier based on total contribution count
            let tier = self.get_nft_tier(campaign_count);
            assert(tier > 0, 'Not eligible for any tier');

            // Check if user has already claimed a reward for this tier
            let already_claimed = self.reward_claimed.entry(recipient).entry(tier).read();
            assert(!already_claimed, 'Tier reward already claimed');

            // Get the metadata URI for this tier
            let metadata_uri = self.tier_metadata.entry(tier).read();

            // Get the next token ID
            let token_id = self.next_token_id.read();
            self.next_token_id.write(token_id + 1);

            // Create new NFT reward struct (with campaign_id = 0 for global rewards)
            let nft_reward = NFTReward { recipient, token_id, tier, claimed: true, metadata_uri };

            // Store the NFT reward
            self.nft_rewards.entry(token_id).write(nft_reward);

            // Mark that this user has claimed a reward for this tier
            self.reward_claimed.entry(recipient).entry(tier).write(true);

            // Add the token to the user's owned NFTs
            let mut user_nfts = self.user_nfts.entry(recipient);
            user_nfts.push(token_id);

            // Mint the token using the ERC721 component
            assert(!self.erc721.exists(token_id), 'NFT with id already exists');
            self.erc721.mint(recipient, token_id);

            // Emit event for minting
            self.emit(NFTRewardMinted { recipient, token_id, tier, metadata_uri });
        }

        /// Check if a user has claimed a specific tier reward for a campaign
        fn has_claimed_reward(self: @ContractState, user: ContractAddress, tier: u8) -> bool {
            assert(tier >= 1 && tier <= 5, 'Invalid tier: must be 1-5');
            // Changed to check only user and tier (global tier check)
            self.reward_claimed.entry(user).entry(tier).read()
        }

        /// Check if a user is eligible for a specific tier NFT for a campaign
        fn can_claim_tier_reward(self: @ContractState, user: ContractAddress, tier: u8) -> bool {
            assert(tier >= 1 && tier <= 5, 'Invalid tier: must be 1-5');

            // Get the contribution count directly from the Contribution contract
            let contribution_dispatcher = IContributionDispatcher {
                contract_address: self.contribution_contract.read(),
            };

            let campaign_count = contribution_dispatcher.get_total_contribution_count(user);

            // Determine tier eligibility based on the number of campaigns the user has contributed
            // to
            if tier == 1 {
                campaign_count >= TIER_1_THRESHOLD
            } else if tier == 2 {
                campaign_count >= TIER_2_THRESHOLD
            } else if tier == 3 {
                campaign_count >= TIER_3_THRESHOLD
            } else if tier == 4 {
                campaign_count >= TIER_4_THRESHOLD
            } else if tier == 5 {
                campaign_count >= TIER_5_THRESHOLD
            } else {
                false
            }
        }

        /// Get all NFTs owned by a user
        fn get_user_nfts(self: @ContractState, user: ContractAddress) -> Array<u256> {
            let mut user_nfts = array![];

            for i in 0..self.user_nfts.entry(user).len() {
                user_nfts.append(self.user_nfts.entry(user).at(i).read());
            }

            user_nfts
        }

        /// Get the NFT tier based on the number of supported projects
        fn get_nft_tier(self: @ContractState, campaign_count: u32) -> u8 {
            if campaign_count >= TIER_5_THRESHOLD {
                5
            } else if campaign_count >= TIER_4_THRESHOLD {
                4
            } else if campaign_count >= TIER_3_THRESHOLD {
                3
            } else if campaign_count >= TIER_2_THRESHOLD {
                2
            } else if campaign_count >= TIER_1_THRESHOLD {
                1
            } else {
                0 // Not eligible for any tier
            }
        }

        /// Get the tier of a specific NFT token
        fn get_token_tier(self: @ContractState, token_id: u256) -> u8 {
            // Ensure token exists
            self.erc721._owner_of(token_id);

            // Get NFT reward
            let reward = self.nft_rewards.entry(token_id).read();
            reward.tier
        }

        /// Get all tiers a user is eligible for but hasn't claimed yet
        fn get_available_tiers(self: @ContractState, user: ContractAddress) -> Array<u8> {
            let contribution_contract = self.contribution_contract.read();
            assert(contribution_contract != ZERO_ADDRESS, 'Contribution contract not set');

            let contribution_dispatcher = IContributionDispatcher {
                contract_address: contribution_contract,
            };

            let campaign_count = contribution_dispatcher.get_total_contribution_count(user);
            let max_tier = self.get_nft_tier(campaign_count);

            let mut available_tiers = array![];

            // Check each tier from 1 to max_tier
            let mut tier = 1;
            while tier <= max_tier {
                let claimed = self.reward_claimed.entry(user).entry(tier).read();
                if !claimed {
                    available_tiers.append(tier);
                }
                tier += 1;
            }

            available_tiers
        }

        /// Get the metadata URI for a specific tier
        fn get_tier_metadata(self: @ContractState, tier: u8) -> felt252 {
            assert(tier >= 1 && tier <= 5, 'Invalid tier: must be 1-5');
            self.tier_metadata.entry(tier).read()
        }

        /// Set the metadata URI for a specific tier
        fn set_tier_metadata(ref self: ContractState, tier: u8, metadata_uri: felt252) {
            // Only owner can set tier metadata
            self.ownable.assert_only_owner();

            assert(tier >= 1 && tier <= 5, 'Invalid tier: must be 1-5');

            self.tier_metadata.entry(tier).write(metadata_uri);

            self.emit(TierMetadataUpdated { tier, metadata_uri });
        }

        /// Set the contribution contract address
        fn set_contribution_contract(
            ref self: ContractState, contribution_contract: ContractAddress,
        ) {
            // Only owner can set contract addresses
            self.ownable.assert_only_owner();
            self.contribution_contract.write(contribution_contract);
        }

        /// Set the campaign contract address
        fn set_campaign_contract(ref self: ContractState, campaign_contract: ContractAddress) {
            // Only owner can set contract addresses
            self.ownable.assert_only_owner();
            self.campaign_contract.write(campaign_contract);
        }
    }
}
