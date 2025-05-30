// #[cfg(test)]
// mod test_nft_reward {
//     use core::array::ArrayTrait;
//     use core::option::OptionTrait;
//     use core::result::ResultTrait;
//     use core::traits::{Into, TryInto};
//     use crowdchain_contracts::contracts::NFTReward::NFTRewardContract;
//     use crowdchain_contracts::events::NFTRewardEvent::{NFTRewardMinted, TierMetadataUpdated};
//     use crowdchain_contracts::interfaces::ICampaign::{
//         ICampaignDispatcher, ICampaignDispatcherTrait,
//     };

//     use crowdchain_contracts::interfaces::INFTReward::{
//         INFTRewardDispatcher, INFTRewardDispatcherTrait,
//     };
//     use openzeppelin::token::erc721::interface::{
//         IERC721Dispatcher, IERC721DispatcherTrait, IERC721MetadataDispatcher,
//         IERC721MetadataDispatcherTrait,
//     };
//     use snforge_std::{
//         CheatSpan, ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait,
//         cheat_caller_address, declare, spy_events,
//     };
//     use starknet::ContractAddress;

//     // Address constants for testing
//     fn ADMIN() -> ContractAddress {
//         let admin: felt252 = 'admin';
//         admin.try_into().unwrap()
//     }

//     fn OWNER() -> ContractAddress {
//         let owner: felt252 = 'owner';
//         owner.try_into().unwrap()
//     }

//     fn USER_1() -> ContractAddress {
//         let user1: felt252 = 'user1';
//         user1.try_into().unwrap()
//     }

//     fn USER_2() -> ContractAddress {
//         let user2: felt252 = 'user2';
//         user2.try_into().unwrap()
//     }

//     fn ZERO_ADDRESS() -> ContractAddress {
//         0.try_into().unwrap()
//     }

//     // Test constants
//     const CAMPAIGN_ID: u128 = 1;
//     const CAMPAIGN_METADATA: felt252 = 'test_campaign';
//     const PLATFORM_FEE_RATE: u128 = 100; // 1%

//     // Struct to hold deployed contracts for tests
//     #[derive(Drop)]
//     struct TestContracts {
//         campaign_contract: ContractAddress,
//         contribution_contract: ContractAddress,
//         nft_reward_contract: ContractAddress,
//         campaign_dispatcher: ICampaignDispatcher,
//         contribution_dispatcher: IContributionDispatcher,
//         reward_dispatcher: INFTRewardDispatcher,
//     }

//     /// Helper function to deploy all contracts for testing
//     fn deploy_contracts() -> TestContracts {
//         // Declare contract classes
//         let campaign_class = declare("Campaign").unwrap().contract_class();
//         let contribution_class = declare("Contribution").unwrap().contract_class();
//         let nft_reward_class = declare("NFTRewardContract").unwrap().contract_class();

//         // Deploy Campaign contract
//         let mut campaign_calldata = array![];
//         campaign_calldata.append(ADMIN().into());
//         let (campaign_address, _) = campaign_class.deploy(@campaign_calldata).unwrap();

//         // Deploy Contribution contract
//         let mut contribution_calldata = array![];
//         contribution_calldata.append(ADMIN().into());
//         contribution_calldata.append(PLATFORM_FEE_RATE.into());
//         let (contribution_address, _) =
//         contribution_class.deploy(@contribution_calldata).unwrap();

//         // Deploy NFTReward contract
//         let mut nft_reward_calldata = array![];
//         let token_name: ByteArray = "CrowdchainNFT";
//         let token_symbol: ByteArray = "CRDNFTS";

//         nft_reward_calldata.append(OWNER().into());
//         nft_reward_calldata.append(contribution_address.into());
//         nft_reward_calldata.append(campaign_address.into());
//         token_name.serialize(ref nft_reward_calldata);
//         token_symbol.serialize(ref nft_reward_calldata);
//         let (nft_reward_address, _) = nft_reward_class.deploy(@nft_reward_calldata).unwrap();

//         // Create dispatchers
//         let campaign_dispatcher = ICampaignDispatcher { contract_address: campaign_address };
//         let contribution_dispatcher = IContributionDispatcher {
//             contract_address: contribution_address,
//         };
//         let reward_dispatcher = INFTRewardDispatcher { contract_address: nft_reward_address };

//         // Return all deployed contracts
//         TestContracts {
//             campaign_contract: campaign_address,
//             contribution_contract: contribution_address,
//             nft_reward_contract: nft_reward_address,
//             campaign_dispatcher,
//             contribution_dispatcher,
//             reward_dispatcher,
//         }
//     }

//     #[test]
//     fn test_nft_reward_initialization() {
//         // Deploy contracts
//         let contracts = deploy_contracts();
//         let token_name: ByteArray = "CrowdchainNFT";
//         let token_symbol: ByteArray = "CRDNFTS";

//         // Verify NFTReward contract initialization
//         assert(
//             IERC721MetadataDispatcher { contract_address: contracts.nft_reward_contract }
//                 .name() == token_name,
//             'Name mismatch',
//         );
//         assert(
//             IERC721MetadataDispatcher { contract_address: contracts.nft_reward_contract }
//                 .symbol() == token_symbol,
//             'Symbol mismatch',
//         );
//         // Check tier metadata initialization
//         assert(contracts.reward_dispatcher.get_tier_metadata(1) != 0, 'Tier 1 metadata not set');
//         assert(contracts.reward_dispatcher.get_tier_metadata(2) != 0, 'Tier 2 metadata not set');
//         assert(contracts.reward_dispatcher.get_tier_metadata(3) != 0, 'Tier 3 metadata not set');
//         assert(contracts.reward_dispatcher.get_tier_metadata(4) != 0, 'Tier 4 metadata not set');
//         assert(contracts.reward_dispatcher.get_tier_metadata(5) != 0, 'Tier 5 metadata not set');
//     }

//     #[test]
//     fn test_mint_nft_reward() {
//         // Deploy contracts
//         let mut contracts = deploy_contracts();

//         // Setup test user
//         let user = USER_1();
//         let owner = OWNER();

//         // Create a campaign and approve creator
//         cheat_caller_address(contracts.campaign_contract, ADMIN(), CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.approve_creator(owner);

//         // Create campaign
//         cheat_caller_address(contracts.campaign_contract, owner, CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.create_campaign(owner, CAMPAIGN_METADATA);

//         // Make a contribution to the campaign
//         let contribution_amount = 500;
//         cheat_caller_address(contracts.contribution_contract, user, CheatSpan::TargetCalls(1));
//         contracts
//             .contribution_dispatcher
//             .process_contribution(CAMPAIGN_ID, user, contribution_amount);

//         // Verify contribution was recorded
//         let (total_contributed, _) = contracts
//             .contribution_dispatcher
//             .get_contribution_stats(CAMPAIGN_ID, user);
//         assert(total_contributed == contribution_amount, 'Contribution not recorded');

//         // Verify contribution count is 1
//         let contribution_count = contracts
//             .contribution_dispatcher
//             .get_total_contribution_count(user);
//         assert(contribution_count == 1, 'Should have 1 contribution');

//         // Verify tier eligibility is based on campaign count, not amount
//         assert(
//             contracts.reward_dispatcher.get_nft_tier(contribution_count) == 1, 'Should be tier
//             1',
//         );

//         // Mint NFT reward
//         cheat_caller_address(contracts.nft_reward_contract, user, CheatSpan::TargetCalls(1));
//         contracts.reward_dispatcher.mint_nft_reward(user);

//         // Verify the NFT was minted
//         assert(contracts.reward_dispatcher.has_claimed_reward(user, 1), 'Reward should be
//         claimed');
//         assert(
//             IERC721Dispatcher { contract_address: contracts.nft_reward_contract }
//                 .balance_of(user) == 1,
//             'Should have 1 NFT',
//         );

//         // Get user NFTs
//         let user_nfts = contracts.reward_dispatcher.get_user_nfts(user);
//         assert(user_nfts.len() == 1, 'User should have 1 token');

//         // Verify token tier
//         let token_id = *user_nfts.at(0);
//         assert(contracts.reward_dispatcher.get_token_tier(token_id) == 1, 'Token should be tier
//         1');

//         // Verify ownership
//         assert(
//             IERC721Dispatcher { contract_address: contracts.nft_reward_contract }
//                 .owner_of(token_id) == user,
//             'User should own token',
//         );
//     }

//     #[test]
//     fn test_tier_eligibility() {
//         // Deploy contracts
//         let mut contracts = deploy_contracts();

//         // Setup test users
//         let owner = OWNER();
//         let tier1_user = USER_1();
//         let tier3_user = USER_2();

//         // Create a campaign and approve creator
//         cheat_caller_address(contracts.campaign_contract, ADMIN(), CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.approve_creator(owner);

//         // Create first campaign
//         cheat_caller_address(contracts.campaign_contract, owner, CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.create_campaign(owner, CAMPAIGN_METADATA);

//         // Create second campaign
//         cheat_caller_address(contracts.campaign_contract, owner, CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.create_campaign(owner, 'second_campaign');

//         // Create third campaign
//         cheat_caller_address(contracts.campaign_contract, owner, CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.create_campaign(owner, 'third_campaign');

//         // User 1 contributes to 1 campaign
//         cheat_caller_address(
//             contracts.contribution_contract, tier1_user, CheatSpan::TargetCalls(1),
//         );
//         contracts.contribution_dispatcher.process_contribution(CAMPAIGN_ID, tier1_user, 500);

//         // User 2 contributes to 3 campaigns
//         cheat_caller_address(
//             contracts.contribution_contract, tier3_user, CheatSpan::TargetCalls(1),
//         );
//         contracts.contribution_dispatcher.process_contribution(CAMPAIGN_ID, tier3_user, 500);

//         cheat_caller_address(
//             contracts.contribution_contract, tier3_user, CheatSpan::TargetCalls(1),
//         );
//         contracts.contribution_dispatcher.process_contribution(CAMPAIGN_ID + 1, tier3_user, 500);

//         cheat_caller_address(
//             contracts.contribution_contract, tier3_user, CheatSpan::TargetCalls(1),
//         );
//         contracts.contribution_dispatcher.process_contribution(CAMPAIGN_ID + 2, tier3_user, 500);

//         // Verify tier eligibility is based on campaign count, not contribution amount
//         // User 1 contributed to 1 campaign, should be eligible for tier 1
//         assert(
//             contracts.contribution_dispatcher.get_total_contribution_count(tier1_user) == 1,
//             'User1 should have 1 contrib',
//         );

//         assert(
//             contracts.reward_dispatcher.can_claim_tier_reward(tier1_user, 1),
//             'User1 tier 1 eligible',
//         );

//         assert(
//             !contracts.reward_dispatcher.can_claim_tier_reward(tier1_user, 2),
//             'User1 not tier 2 eligible',
//         );

//         // User 2 contributed to 3 campaigns, should be eligible for tier 3
//         assert(
//             contracts.contribution_dispatcher.get_total_contribution_count(tier3_user) == 3,
//             'User2 should have 3 contrib',
//         );

//         assert(
//             contracts.reward_dispatcher.can_claim_tier_reward(tier3_user, 1),
//             'User2 tier 1 eligible',
//         );

//         assert(
//             contracts.reward_dispatcher.can_claim_tier_reward(tier3_user, 2),
//             'User2 tier 2 eligible',
//         );

//         assert(
//             contracts.reward_dispatcher.can_claim_tier_reward(tier3_user, 3),
//             'User2 tier 3 eligible',
//         );

//         assert(
//             !contracts.reward_dispatcher.can_claim_tier_reward(tier3_user, 4),
//             'User2 not tier 4 eligible',
//         );

//         // Verify get_nft_tier returns the correct tier based on campaign count
//         assert(contracts.reward_dispatcher.get_nft_tier(1) == 1, 'Should return tier 1');
//         assert(contracts.reward_dispatcher.get_nft_tier(2) == 2, 'Should return tier 2');
//         assert(contracts.reward_dispatcher.get_nft_tier(3) == 3, 'Should return tier 3');
//         assert(contracts.reward_dispatcher.get_nft_tier(4) == 4, 'Should return tier 4');
//         assert(contracts.reward_dispatcher.get_nft_tier(5) == 5, 'Should return tier 5');
//     }

//     #[test]
//     #[should_panic(expected: 'Tier reward already claimed')]
//     fn test_cannot_claim_reward_twice() {
//         // Deploy contracts
//         let mut contracts = deploy_contracts();

//         // Setup test user
//         let user = USER_1();
//         let owner = OWNER();

//         // Create a campaign and approve creator
//         cheat_caller_address(contracts.campaign_contract, ADMIN(), CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.approve_creator(owner);

//         // Create campaign
//         cheat_caller_address(contracts.campaign_contract, owner, CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.create_campaign(owner, CAMPAIGN_METADATA);

//         // Make a contribution
//         cheat_caller_address(contracts.contribution_contract, user, CheatSpan::TargetCalls(1));
//         contracts.contribution_dispatcher.process_contribution(CAMPAIGN_ID, user, 500);

//         // Mint first reward (should succeed)
//         cheat_caller_address(contracts.nft_reward_contract, user, CheatSpan::TargetCalls(1));
//         contracts.reward_dispatcher.mint_nft_reward(user);

//         // Try to mint again (should fail)
//         cheat_caller_address(contracts.nft_reward_contract, user, CheatSpan::TargetCalls(1));
//         contracts.reward_dispatcher.mint_nft_reward(user);
//     }

//     #[test]
//     #[should_panic(expected: 'No contributions found')]
//     fn test_cannot_mint_without_contribution() {
//         // Deploy contracts
//         let mut contracts = deploy_contracts();

//         // Setup test user
//         let user = USER_1();

//         // Try to mint without any contribution (should fail)
//         cheat_caller_address(contracts.nft_reward_contract, user, CheatSpan::TargetCalls(1));
//         contracts.reward_dispatcher.mint_nft_reward(user);
//     }

//     #[test]
//     fn test_set_tier_metadata() {
//         // Deploy contracts
//         let mut contracts = deploy_contracts();

//         // New metadata URI
//         let new_metadata = 'ipfs://new_tier_metadata';

//         // Set tier metadata as owner
//         cheat_caller_address(contracts.nft_reward_contract, OWNER(), CheatSpan::TargetCalls(1));
//         contracts.reward_dispatcher.set_tier_metadata(1, new_metadata);

//         // Verify metadata was updated
//         assert(
//             contracts.reward_dispatcher.get_tier_metadata(1) == new_metadata,
//             'Metadata should be updated',
//         );
//     }

//     #[test]
//     fn test_get_available_tiers() {
//         // Deploy contracts
//         let mut contracts = deploy_contracts();

//         // Setup test user
//         let user = USER_1();
//         let owner = OWNER();

//         // Create and approve three campaigns
//         cheat_caller_address(contracts.campaign_contract, ADMIN(), CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.approve_creator(owner);

//         cheat_caller_address(contracts.campaign_contract, owner, CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.create_campaign(owner, CAMPAIGN_METADATA);

//         cheat_caller_address(contracts.campaign_contract, owner, CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.create_campaign(owner, 'second_campaign');

//         cheat_caller_address(contracts.campaign_contract, owner, CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.create_campaign(owner, 'third_campaign');

//         // No contributions yet
//         let tiers = contracts.reward_dispatcher.get_available_tiers(user);
//         assert(tiers.len() == 0, 'No available tiers yet');

//         // Contribute to first campaign - now eligible for tier 1
//         cheat_caller_address(contracts.contribution_contract, user, CheatSpan::TargetCalls(1));
//         contracts.contribution_dispatcher.process_contribution(CAMPAIGN_ID, user, 500);

//         let tiers_after_one = contracts.reward_dispatcher.get_available_tiers(user);
//         assert(tiers_after_one.len() == 1, 'Should have 1 available tier');
//         assert(*tiers_after_one.at(0) == 1, 'Should be tier 1 eligible');

//         // Contribute to second campaign - now eligible for tier 2 as well
//         cheat_caller_address(contracts.contribution_contract, user, CheatSpan::TargetCalls(1));
//         contracts.contribution_dispatcher.process_contribution(CAMPAIGN_ID + 1, user, 500);

//         let tiers_after_two = contracts.reward_dispatcher.get_available_tiers(user);
//         assert(tiers_after_two.len() == 2, 'Should have 2 available tiers');
//         assert(*tiers_after_two.at(0) == 1, 'Should be tier 1 eligible');
//         assert(*tiers_after_two.at(1) == 2, 'Should be tier 2 eligiblea');

//         // Claim tier 2 reward
//         cheat_caller_address(contracts.nft_reward_contract, user, CheatSpan::TargetCalls(1));
//         contracts.reward_dispatcher.mint_nft_reward(user);

//         let tiers_after_claim = contracts.reward_dispatcher.get_available_tiers(user);
//         assert(tiers_after_claim.len() == 1, 'Should have 1 available tier');
//         assert(*tiers_after_claim.at(0) == 1, 'Should be tier 2 eligibleb');

//         // Contribute to third campaign - now eligible for tier 3 as well
//         cheat_caller_address(contracts.contribution_contract, user, CheatSpan::TargetCalls(1));
//         contracts.contribution_dispatcher.process_contribution(CAMPAIGN_ID + 2, user, 500);

//         let tiers_after_three = contracts.reward_dispatcher.get_available_tiers(user);
//         assert(tiers_after_three.len() == 2, 'Should have 2 available tiers');
//         assert(*tiers_after_three.at(0) == 1, 'Should be tier 2 eligiblec');
//         assert(*tiers_after_three.at(1) == 3, 'Should be tier 3 eligible');
//     }

//     #[test]
//     #[should_panic(expected: 'Recipient is zero address')]
//     fn test_mint_zero_address() {
//         // Deploy contracts
//         let mut contracts = deploy_contracts();

//         // Try to mint for zero address
//         cheat_caller_address(contracts.nft_reward_contract, OWNER(), CheatSpan::TargetCalls(1));
//         contracts.reward_dispatcher.mint_nft_reward(ZERO_ADDRESS());
//     }

//     #[test]
//     #[should_panic(expected: 'Contribution contract not set')]
//     fn test_set_invalid_contract_addresses() {
//         // Deploy contracts
//         let mut contracts = deploy_contracts();

//         // Try to set zero address as campaign contract
//         cheat_caller_address(contracts.nft_reward_contract, OWNER(), CheatSpan::TargetCalls(1));
//         contracts.reward_dispatcher.set_campaign_contract(ZERO_ADDRESS());
//     }

//     #[test]
//     #[should_panic(expected: 'Caller is not the owner')]
//     fn test_set_metadata_unauthorized() {
//         // Deploy contracts
//         let mut contracts = deploy_contracts();

//         // Try to set metadata as non-owner
//         cheat_caller_address(contracts.nft_reward_contract, USER_1(), CheatSpan::TargetCalls(1));
//         contracts.reward_dispatcher.set_tier_metadata(1, 'unauthorized');
//     }

//     #[test]
//     fn test_multiple_user_rewards() {
//         // Deploy contracts
//         let mut contracts = deploy_contracts();

//         // Setup test users
//         let user1 = USER_1();
//         let user2 = USER_2();
//         let owner = OWNER();

//         // Create a campaign and approve creator
//         cheat_caller_address(contracts.campaign_contract, ADMIN(), CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.approve_creator(owner);

//         cheat_caller_address(contracts.campaign_contract, owner, CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.create_campaign(owner, CAMPAIGN_METADATA);

//         cheat_caller_address(contracts.campaign_contract, owner, CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.create_campaign(owner, 'second_campaign');

//         // User 1 contributes to one campaign
//         cheat_caller_address(contracts.contribution_contract, user1, CheatSpan::TargetCalls(1));
//         contracts.contribution_dispatcher.process_contribution(CAMPAIGN_ID, user1, 500);

//         // User 2 contributes to two campaigns
//         cheat_caller_address(contracts.contribution_contract, user2, CheatSpan::TargetCalls(1));
//         contracts.contribution_dispatcher.process_contribution(CAMPAIGN_ID, user2, 500);

//         cheat_caller_address(contracts.contribution_contract, user2, CheatSpan::TargetCalls(1));
//         contracts.contribution_dispatcher.process_contribution(CAMPAIGN_ID + 1, user2, 500);

//         // Mint rewards for both users
//         cheat_caller_address(contracts.nft_reward_contract, user1, CheatSpan::TargetCalls(1));
//         contracts.reward_dispatcher.mint_nft_reward(user1);

//         cheat_caller_address(contracts.nft_reward_contract, user2, CheatSpan::TargetCalls(1));
//         contracts.reward_dispatcher.mint_nft_reward(user2);

//         // Verify NFT ownership
//         let user1_nfts = contracts.reward_dispatcher.get_user_nfts(user1);
//         let user2_nfts = contracts.reward_dispatcher.get_user_nfts(user2);

//         assert(user1_nfts.len() == 1, 'User1 should have 1 NFT');
//         assert(user2_nfts.len() == 1, 'User2 should have 1 NFT');

//         // Verify token tiers
//         let user1_token = *user1_nfts.at(0);
//         let user2_token = *user2_nfts.at(0);

//         assert(
//             contracts.reward_dispatcher.get_token_tier(user1_token) == 1,
//             'User1 NFT should be tier 1',
//         );
//         assert(
//             contracts.reward_dispatcher.get_token_tier(user2_token) == 2,
//             'User2 NFT should be tier 2',
//         );

//         // Verify claim status
//         assert(contracts.reward_dispatcher.has_claimed_reward(user1, 1), 'User1 claimed tier 1');
//         assert(
//             !contracts.reward_dispatcher.has_claimed_reward(user1, 2), 'User1 not claimed tier
//             2',
//         );

//         assert(
//             !contracts.reward_dispatcher.has_claimed_reward(user2, 1), 'User2 not claimed tier
//             1',
//         );
//         assert(contracts.reward_dispatcher.has_claimed_reward(user2, 2), 'User2 claimed tier 2');
//     }

//     #[test]
//     fn test_nft_reward_minted_event() {
//         // Deploy contracts
//         let mut contracts = deploy_contracts();

//         // Setup test user
//         let user = USER_1();
//         let owner = OWNER();

//         // Create a campaign and approve creator
//         cheat_caller_address(contracts.campaign_contract, ADMIN(), CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.approve_creator(owner);

//         // Create campaign
//         cheat_caller_address(contracts.campaign_contract, owner, CheatSpan::TargetCalls(1));
//         contracts.campaign_dispatcher.create_campaign(owner, CAMPAIGN_METADATA);

//         // Make a contribution to the campaign
//         cheat_caller_address(contracts.contribution_contract, user, CheatSpan::TargetCalls(1));
//         contracts.contribution_dispatcher.process_contribution(CAMPAIGN_ID, user, 500);

//         // Start listening for events
//         let mut spy = spy_events();

//         // Mint NFT reward
//         cheat_caller_address(contracts.nft_reward_contract, user, CheatSpan::TargetCalls(1));
//         contracts.reward_dispatcher.mint_nft_reward(user);

//         // Get user NFTs
//         let user_nfts = contracts.reward_dispatcher.get_user_nfts(user);
//         let token_id = *user_nfts.at(0);
//         let tier = contracts.reward_dispatcher.get_token_tier(token_id);
//         let metadata_uri = contracts.reward_dispatcher.get_tier_metadata(tier);

//         // Assert NFTRewardMinted event was emitted
//         spy
//             .assert_emitted(
//                 @array![
//                     (
//                         contracts.nft_reward_contract,
//                         NFTRewardContract::Event::NFTRewardMinted(
//                             NFTRewardMinted { recipient: user, token_id, tier, metadata_uri },
//                         ),
//                     ),
//                 ],
//             );
//     }

//     #[test]
//     fn test_tier_metadata_updated_event() {
//         // Deploy contracts
//         let mut contracts = deploy_contracts();

//         // New metadata URI
//         let new_metadata = 'ipfs://new_tier_metadata';

//         // Start listening for events
//         let mut spy = spy_events();

//         // Set tier metadata as owner
//         cheat_caller_address(contracts.nft_reward_contract, OWNER(), CheatSpan::TargetCalls(1));
//         contracts.reward_dispatcher.set_tier_metadata(1, new_metadata);

//         // Assert TierMetadataUpdated event was emitted
//         spy
//             .assert_emitted(
//                 @array![
//                     (
//                         contracts.nft_reward_contract,
//                         NFTRewardContract::Event::TierMetadataUpdated(
//                             TierMetadataUpdated { tier: 1, metadata_uri: new_metadata },
//                         ),
//                     ),
//                 ],
//             );
//     }
// }
