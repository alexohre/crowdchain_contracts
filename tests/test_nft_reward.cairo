#[cfg(test)]
mod test_nft_reward {
    use core::array::ArrayTrait;
    use core::result::ResultTrait;
    use core::traits::Into;
    use crowdchain_contracts::contracts::NFTReward::{
        INFTRewardDispatcher, INFTRewardDispatcherTrait, NFTRewardContract,
    };
    use crowdchain_contracts::interfaces::ICampaign::{
        ICampaignDispatcher, ICampaignDispatcherTrait,
    };
    use crowdchain_contracts::interfaces::IContribution::{
        IContributionDispatcher, IContributionDispatcherTrait,
    };
    use crowdchain_contracts::contracts::NFTReward::NFTRewardContract;
    use crowdchain_contracts::interfaces::INFTReward::{INFTRewardDispatcher, INFTRewardDispatcherTrait};
    use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
    use snforge_std::{
        CheatSpan, ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait,
        cheat_caller_address, declare, mock_call, spy_events,
    };
    use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};
    use starknet::{ClassHash, ContractAddress, contract_address_const};

    // Address constants for testing
    fn USER_1() -> ContractAddress {
        contract_address_const::<'user_1'>()
    }

    fn USER_2() -> ContractAddress {
        contract_address_const::<'user_2'>()
    }

    fn OWNER() -> ContractAddress {
        contract_address_const::<'owner'>()
    }

    fn ZERO_ADDRESS() -> ContractAddress {
        contract_address_const::<0>()
    }

    // Test token constants
    const TOKEN_NAME: felt252 = 'CrowdchainNFT';
    const TOKEN_SYMBOL: felt252 = 'CRDNFTS';
    const CAMPAIGN_1: u128 = 1;
    const CAMPAIGN_2: u128 = 2;
    const CAMPAIGN_3: u128 = 3;

    /// Helper function to deploy the NFTReward contract
    fn deploy_nft_reward(owner: ContractAddress) -> (ContractAddress, INFTRewardDispatcher) {
        // Declare the NFTReward contract to get contract class
        let contract_class = declare("NFTRewardContract").unwrap().contract_class();

        // Initialize NFT reward contract calldata
        let mut calldata = array![];
        calldata.append(owner.into());
        calldata.append(TOKEN_NAME);
        calldata.append(TOKEN_SYMBOL);

        // Deploy NFTReward contract and return address and dispatcher
        let (contract_address, _) = contract_class.deploy(@calldata).unwrap();
        (contract_address, INFTRewardDispatcher { contract_address })
    }

    /// Set up mock for the contribution contract
    fn setup_contribution_mock(
        reward_address: ContractAddress,
        user: ContractAddress,
        campaign_id: u128,
        contribution_amount: u128,
    ) {
        // Mock the get_contribution_stats function to return valid contributions
        mock_call(
            reward_address,
            CONTRIBUTION_CONTRACT(),
            selector!("get_contribution_stats"),
            array![campaign_id.into(), user.into(), contribution_amount.into(), 0],
        )
            .unwrap();
    }

    #[test]
    fn test_nft_reward_initialization() {
        // Deploy NFT reward contract
        let owner = OWNER();
        let (reward_address, reward_dispatcher) = deploy_nft_reward(owner);

        // Verify contract initialization
        assert(reward_dispatcher.name() == TOKEN_NAME, 'Name mismatch');
        assert(reward_dispatcher.symbol() == TOKEN_SYMBOL, 'Symbol mismatch');

        // Check tier metadata initialization
        assert(reward_dispatcher.get_tier_metadata(1) != 0, 'Tier 1 metadata not set');
        assert(reward_dispatcher.get_tier_metadata(2) != 0, 'Tier 2 metadata not set');
        assert(reward_dispatcher.get_tier_metadata(3) != 0, 'Tier 3 metadata not set');
        assert(reward_dispatcher.get_tier_metadata(4) != 0, 'Tier 4 metadata not set');
        assert(reward_dispatcher.get_tier_metadata(5) != 0, 'Tier 5 metadata not set');

        // Set contract addresses as owner
        cheat_caller_address(reward_address, owner, CheatSpan::TargetCalls(2));
        reward_dispatcher.set_contribution_contract(CONTRIBUTION_CONTRACT());
        reward_dispatcher.set_campaign_contract(CAMPAIGN_CONTRACT());
    }

    #[test]
    fn test_record_contribution() {
        // Deploy NFT reward contract
        let owner = OWNER();
        let (reward_address, reward_dispatcher) = deploy_nft_reward(owner);

        // Setup test users
        let user_1 = USER_1();

        // Set contract addresses
        cheat_caller_address(reward_address, owner, CheatSpan::TargetCalls(2));
        reward_dispatcher.set_contribution_contract(CONTRIBUTION_CONTRACT());
        reward_dispatcher.set_campaign_contract(CAMPAIGN_CONTRACT());

        // Set up contribution mock
        setup_contribution_mock(reward_address, user_1, CAMPAIGN_1, 100);

        // Mock campaign contract add_supporter call
        mock_call(
            reward_address,
            CAMPAIGN_CONTRACT(),
            selector!("add_supporter"),
            array![CAMPAIGN_1.into(), user_1.into()],
        )
            .unwrap();

        // Spy on events
        let mut event_spy = spy_events();

        // Record a contribution for user_1
        cheat_caller_address(reward_address, owner, CheatSpan::TargetCalls(1));
        reward_dispatcher.record_contribution(user_1, CAMPAIGN_1);

        // Verify contribution was recorded
        assert(
            reward_dispatcher.get_supported_projects_count(user_1) == 1,
            'Project count should be 1',
        );
        assert(
            reward_dispatcher.is_eligible_for_tier(user_1, 1), 'User should be eligible for tier 1',
        );
        assert(
            !reward_dispatcher.is_eligible_for_tier(user_1, 2),
            'User should not be eligible for tier 2',
        );

        // Verify events were emitted
        event_spy
            .assert_emitted(
                @array![
                    (
                        reward_address,
                        NFTRewardContract::Event::ContributionRecorded(
                            NFTRewardContract::ContributionRecorded {
                                user: user_1,
                                campaign_id: CAMPAIGN_1,
                                total_projects_supported: 1,
                            },
                        ),
                    ),
                    (
                        reward_address,
                        NFTRewardContract::Event::UserEligibleForNewTier(
                            NFTRewardContract::UserEligibleForNewTier {
                                user: user_1, tier: 1, projects_supported: 1,
                            },
                        ),
                    ),
                ],
            );
    }

    #[test]
    fn test_multiple_campaigns_tier_progression() {
        // Deploy NFT reward contract
        let owner = OWNER();
        let (reward_address, reward_dispatcher) = deploy_nft_reward(owner);

        // Setup test users
        let user_1 = USER_1();

        // Set contract addresses
        cheat_caller_address(reward_address, owner, CheatSpan::TargetCalls(2));
        reward_dispatcher.set_contribution_contract(CONTRIBUTION_CONTRACT());
        reward_dispatcher.set_campaign_contract(CAMPAIGN_CONTRACT());

        // Set up campaign mock to accept any add_supporter call
        mock_call(reward_address, CAMPAIGN_CONTRACT(), selector!("add_supporter"), array![])
            .unwrap();

        // Set owner as caller for all contribution recording
        cheat_caller_address(reward_address, owner, CheatSpan::Indefinite);

        // Record contributions across multiple campaigns
        // Campaign 1
        setup_contribution_mock(reward_address, user_1, CAMPAIGN_1, 100);
        reward_dispatcher.record_contribution(user_1, CAMPAIGN_1);
        assert(
            reward_dispatcher
                .get_nft_tier(reward_dispatcher.get_supported_projects_count(user_1)) == 1,
            'Should be tier 1',
        );

        // Campaign 2
        setup_contribution_mock(reward_address, user_1, CAMPAIGN_2, 200);
        reward_dispatcher.record_contribution(user_1, CAMPAIGN_2);
        assert(
            reward_dispatcher
                .get_nft_tier(reward_dispatcher.get_supported_projects_count(user_1)) == 2,
            'Should be tier 2',
        );

        // Campaign 3
        setup_contribution_mock(reward_address, user_1, CAMPAIGN_3, 300);
        reward_dispatcher.record_contribution(user_1, CAMPAIGN_3);
        assert(
            reward_dispatcher
                .get_nft_tier(reward_dispatcher.get_supported_projects_count(user_1)) == 3,
            'Should be tier 3',
        );

        // Campaign 4
        setup_contribution_mock(reward_address, user_1, 4, 400);
        reward_dispatcher.record_contribution(user_1, 4);
        assert(
            reward_dispatcher
                .get_nft_tier(reward_dispatcher.get_supported_projects_count(user_1)) == 4,
            'Should be tier 4',
        );

        // Campaign 5
        setup_contribution_mock(reward_address, user_1, 5, 500);
        reward_dispatcher.record_contribution(user_1, 5);
        assert(
            reward_dispatcher
                .get_nft_tier(reward_dispatcher.get_supported_projects_count(user_1)) == 5,
            'Should be tier 5',
        );

        // Verify final eligibility
        assert(reward_dispatcher.is_eligible_for_tier(user_1, 1), 'Should be eligible for tier 1');
        assert(reward_dispatcher.is_eligible_for_tier(user_1, 2), 'Should be eligible for tier 2');
        assert(reward_dispatcher.is_eligible_for_tier(user_1, 3), 'Should be eligible for tier 3');
        assert(reward_dispatcher.is_eligible_for_tier(user_1, 4), 'Should be eligible for tier 4');
        assert(reward_dispatcher.is_eligible_for_tier(user_1, 5), 'Should be eligible for tier 5');
    }

    #[test]
    fn test_mint_nft_reward_for_campaign() {
        // Deploy NFT reward contract
        let owner = OWNER();
        let (reward_address, reward_dispatcher) = deploy_nft_reward(owner);

        // Setup test users
        let user_1 = USER_1();

        // Set contract addresses
        cheat_caller_address(reward_address, owner, CheatSpan::TargetCalls(2));
        reward_dispatcher.set_contribution_contract(CONTRIBUTION_CONTRACT());
        reward_dispatcher.set_campaign_contract(CAMPAIGN_CONTRACT());

        // Set up mock for the contribution contract
        setup_contribution_mock(reward_address, user_1, CAMPAIGN_1, 100);

        // Mock campaign contract add_supporter call
        mock_call(
            reward_address,
            CAMPAIGN_CONTRACT(),
            selector!("add_supporter"),
            array![CAMPAIGN_1.into(), user_1.into()],
        )
            .unwrap();

        // Record a contribution
        cheat_caller_address(reward_address, owner, CheatSpan::TargetCalls(1));
        reward_dispatcher.record_contribution(user_1, CAMPAIGN_1);

        // Spy on events for the mint
        let mut event_spy = spy_events();

        // Mint NFT reward for the specific campaign
        cheat_caller_address(reward_address, owner, CheatSpan::TargetCalls(1));
        reward_dispatcher.mint_nft_reward(user_1, CAMPAIGN_1);

        // Verify the NFT was minted and user claimed status
        assert(
            reward_dispatcher.has_claimed_reward(user_1, CAMPAIGN_1),
            'User should have claimed reward',
        );
        assert(reward_dispatcher.balance_of(user_1) == 1, 'User should have 1 NFT');

        // Get the token ID (should be 1)
        let user_nfts = reward_dispatcher.get_user_nfts(user_1);
        assert(user_nfts.len() == 1, 'User should have 1 token');

        // Verify token tier
        let token_id = *user_nfts.at(0);
        assert(reward_dispatcher.get_token_tier(token_id) == 1, 'Token should be tier 1');

        // Verify token ownership
        assert(reward_dispatcher.owner_of(token_id) == user_1, 'User should own the token');

        // Check token URI
        assert(reward_dispatcher.token_uri(token_id) != 0, 'Token URI should be set');

        // Verify minting event
        event_spy
            .assert_emitted(
                @array![
                    (
                        reward_address,
                        NFTRewardContract::Event::NFTRewardEvent(
                            crowdchain_contracts::events::NFTRewardEvent::Event::NFTRewardMinted(
                                crowdchain_contracts::events::NFTRewardEvent::NFTRewardMinted {
                                    recipient: user_1,
                                    campaign_id: CAMPAIGN_1,
                                    token_id: token_id.try_into().unwrap(),
                                    tier: 1,
                                    metadata_uri: reward_dispatcher.get_tier_metadata(1),
                                },
                            ),
                        ),
                    ),
                ],
            );
    }

    #[test]
    #[should_panic(expected: 'Campaign reward already claimed')]
    fn test_cannot_mint_reward_twice_for_same_campaign() {
        // Deploy NFT reward contract
        let owner = OWNER();
        let (reward_address, reward_dispatcher) = deploy_nft_reward(owner);

        // Setup test users
        let user_1 = USER_1();

        // Set contract addresses
        cheat_caller_address(reward_address, owner, CheatSpan::TargetCalls(2));
        reward_dispatcher.set_contribution_contract(CONTRIBUTION_CONTRACT());
        reward_dispatcher.set_campaign_contract(CAMPAIGN_CONTRACT());

        // Set up mock for the contribution contract
        setup_contribution_mock(reward_address, user_1, CAMPAIGN_1, 100);

        // Mock campaign contract add_supporter call
        mock_call(
            reward_address,
            CAMPAIGN_CONTRACT(),
            selector!("add_supporter"),
            array![CAMPAIGN_1.into(), user_1.into()],
        )
            .unwrap();

        // Record a contribution
        cheat_caller_address(reward_address, owner, CheatSpan::Indefinite);
        reward_dispatcher.record_contribution(user_1, CAMPAIGN_1);

        // Mint first reward (should succeed)
        reward_dispatcher.mint_nft_reward(user_1, CAMPAIGN_1);

        // Try to mint second reward for same campaign (should fail)
        reward_dispatcher.mint_nft_reward(user_1, CAMPAIGN_1);
    }

    #[test]
    fn test_multiple_campaign_rewards() {
        // Deploy NFT reward contract
        let owner = OWNER();
        let (reward_address, reward_dispatcher) = deploy_nft_reward(owner);

        // Setup test users
        let user_1 = USER_1();

        // Set contract addresses
        cheat_caller_address(reward_address, owner, CheatSpan::TargetCalls(2));
        reward_dispatcher.set_contribution_contract(CONTRIBUTION_CONTRACT());
        reward_dispatcher.set_campaign_contract(CAMPAIGN_CONTRACT());

        // Set up mock for campaign contract
        mock_call(reward_address, CAMPAIGN_CONTRACT(), selector!("add_supporter"), array![])
            .unwrap();

        // Record contributions to multiple campaigns
        cheat_caller_address(reward_address, owner, CheatSpan::Indefinite);

        // Campaign 1
        setup_contribution_mock(reward_address, user_1, CAMPAIGN_1, 100);
        reward_dispatcher.record_contribution(user_1, CAMPAIGN_1);

        // Campaign 2
        setup_contribution_mock(reward_address, user_1, CAMPAIGN_2, 200);
        reward_dispatcher.record_contribution(user_1, CAMPAIGN_2);

        // Mint rewards for each campaign
        reward_dispatcher.mint_nft_reward(user_1, CAMPAIGN_1);
        reward_dispatcher.mint_nft_reward(user_1, CAMPAIGN_2);

        // Verify rewards were claimed for each campaign
        assert(
            reward_dispatcher.has_claimed_reward(user_1, CAMPAIGN_1),
            'Campaign 1 reward not claimed',
        );
        assert(
            reward_dispatcher.has_claimed_reward(user_1, CAMPAIGN_2),
            'Campaign 2 reward not claimed',
        );

        // Verify user has 2 NFTs
        assert(reward_dispatcher.balance_of(user_1) == 2, 'User should have 2 NFTs');

        // Get the tokens
        let user_nfts = reward_dispatcher.get_user_nfts(user_1);
        assert(user_nfts.len() == 2, 'User should have 2 tokens');
    }

    #[test]
    fn test_set_tier_metadata() {
        // Deploy NFT reward contract
        let owner = OWNER();
        let (reward_address, reward_dispatcher) = deploy_nft_reward(owner);

        // Spy on events
        let mut event_spy = spy_events();

        // Set new metadata for tier 1
        let new_metadata: felt252 = 'ipfs://new_tier1_metadata';
        cheat_caller_address(reward_address, owner, CheatSpan::TargetCalls(1));
        reward_dispatcher.set_tier_metadata(1, new_metadata);

        // Verify metadata was updated
        assert(
            reward_dispatcher.get_tier_metadata(1) == new_metadata, 'Metadata should be updated',
        );

        // Verify event emission
        event_spy
            .assert_emitted(
                @array![
                    (
                        reward_address,
                        NFTRewardContract::Event::NFTRewardEvent(
                            crowdchain_contracts::events::NFTRewardEvent::Event::TierMetadataUpdated(
                                crowdchain_contracts::events::NFTRewardEvent::TierMetadataUpdated {
                                    tier: 1, metadata_uri: new_metadata,
                                },
                            ),
                        ),
                    ),
                ],
            );
    }

    #[test]
    #[should_panic(expected: 'Caller is not owner')]
    fn test_only_admin_can_set_tier_metadata() {
        // Deploy NFT reward contract
        let owner = OWNER();
        let (reward_address, reward_dispatcher) = deploy_nft_reward(owner);

        // Attempt to set tier metadata as non-owner
        let user_1 = USER_1();
        cheat_caller_address(reward_address, user_1, CheatSpan::TargetCalls(1));
        reward_dispatcher.set_tier_metadata(1, 'ipfs://unauthorized_metadata');
    }

    #[test]
    fn test_erc721_transfer_functionality() {
        // Deploy NFT reward contract
        let owner = OWNER();
        let (reward_address, reward_dispatcher) = deploy_nft_reward(owner);

        // Setup test users
        let user_1 = USER_1();
        let user_2 = USER_2();

        // Set contract addresses
        cheat_caller_address(reward_address, owner, CheatSpan::TargetCalls(2));
        reward_dispatcher.set_contribution_contract(CONTRIBUTION_CONTRACT());
        reward_dispatcher.set_campaign_contract(CAMPAIGN_CONTRACT());

        // Set up mock for the contribution contract
        setup_contribution_mock(reward_address, user_1, CAMPAIGN_1, 100);

        // Mock campaign contract add_supporter call
        mock_call(
            reward_address,
            CAMPAIGN_CONTRACT(),
            selector!("add_supporter"),
            array![CAMPAIGN_1.into(), user_1.into()],
        )
            .unwrap();

        // Record a contribution and mint NFT
        cheat_caller_address(reward_address, owner, CheatSpan::Indefinite);
        reward_dispatcher.record_contribution(user_1, CAMPAIGN_1);
        reward_dispatcher.mint_nft_reward(user_1, CAMPAIGN_1);

        // Get token ID
        let user_nfts = reward_dispatcher.get_user_nfts(user_1);
        let token_id = *user_nfts.at(0);

        // Transfer token from user_1 to user_2
        cheat_caller_address(reward_address, user_1, CheatSpan::TargetCalls(1));
        reward_dispatcher.transfer_from(user_1, user_2, token_id);

        // Verify token ownership after transfer
        assert(reward_dispatcher.owner_of(token_id) == user_2, 'User 2 should own the token');
        assert(reward_dispatcher.balance_of(user_1) == 0, 'User 1 should have 0 tokens');
        assert(reward_dispatcher.balance_of(user_2) == 1, 'User 2 should have 1 token');
    }
}
