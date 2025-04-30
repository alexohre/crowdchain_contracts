use crowdchain_contracts::contracts::NFTVerifier::NFTVerifier;
use crowdchain_contracts::events::NFTVerifierEvent::{
    NFTRegistered, DuplicateNFTAttempt, Event
};
use crowdchain_contracts::interfaces::INFTVerifier::{INFTVerifierDispatcher, INFTVerifierDispatcherTrait};
use crowdchain_contracts::structs::Structs::NFTReward;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, spy_events,
    start_cheat_caller_address, stop_cheat_caller_address, event_name_hash, EventSpy
};
use starknet::{ContractAddress, contract_address_const};
use core::option::OptionTrait;
use core::array::ArrayTrait;

fn setup() -> (INFTVerifierDispatcher, ContractAddress, ContractAddress) {
    let admin: ContractAddress = contract_address_const::<'admin'>();
    let contract = declare("NFTVerifier").unwrap().contract_class();
    let calldata = array![admin.into()];
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let nft_verifier_dispatcher = INFTVerifierDispatcher { contract_address };
    (nft_verifier_dispatcher, contract_address, admin)
}

#[test]
fn test_verify_nft_uniqueness() {
    let (nft_verifier, contract_address, admin) = setup();
    
    // A new token ID should be unique
    let is_unique = nft_verifier.verify_nft_uniqueness(1);
    assert(is_unique, "New token should be unique");
    
    // Register an NFT
    let recipient: ContractAddress = contract_address_const::<'recipient'>();
    let campaign_id: u32 = 1;
    let token_id: u128 = 1;
    let tier: u8 = 1;
    let metadata_uri: felt252 = 'ipfs://QmExample';
    
    let success = nft_verifier.register_nft(campaign_id, recipient, token_id, tier, metadata_uri);
    assert(success, "NFT registration should succeed");
    
    // Now the token ID should no longer be unique
    let is_unique = nft_verifier.verify_nft_uniqueness(token_id);
    assert(!is_unique, "Registered token should not be unique");
}

#[test]
fn test_register_nft() {
    let (nft_verifier, contract_address, admin) = setup();
    let recipient: ContractAddress = contract_address_const::<'recipient'>();
    
    // Set up event spy
    let mut spy = spy_events(contract_address);
    
    // Register a new NFT
    let campaign_id: u32 = 1;
    let token_id: u128 = 1;
    let tier: u8 = 1;
    let metadata_uri: felt252 = 'ipfs://QmExample';
    
    let success = nft_verifier.register_nft(campaign_id, recipient, token_id, tier, metadata_uri);
    assert(success, "NFT registration should succeed");
    
    // Verify the NFT was registered correctly
    let nft_exists = nft_verifier.nft_exists_for_campaign(campaign_id, token_id);
    assert(nft_exists, "NFT should exist for campaign");
    
    let recipient_has_nft = nft_verifier.recipient_has_nft_for_campaign(campaign_id, recipient);
    assert(recipient_has_nft, "Recipient should have NFT for campaign");
    
    // Check that the correct event was emitted
    spy.assert_emitted(@array![
        (
            contract_address,
            event_name_hash('NFTRegistered'),
            @array![campaign_id.into(), recipient.into(), token_id.into(), tier.into()]
        )
    ]);
}

#[test]
fn test_duplicate_nft_registration() {
    let (nft_verifier, contract_address, admin) = setup();
    let recipient: ContractAddress = contract_address_const::<'recipient'>();
    
    // Set up event spy
    let mut spy = spy_events(contract_address);
    
    // Register a new NFT
    let campaign_id: u32 = 1;
    let token_id: u128 = 1;
    let tier: u8 = 1;
    let metadata_uri: felt252 = 'ipfs://QmExample';
    
    let success = nft_verifier.register_nft(campaign_id, recipient, token_id, tier, metadata_uri);
    assert(success, "First NFT registration should succeed");
    
    // Try to register the same NFT again
    let duplicate_success = nft_verifier.register_nft(campaign_id, recipient, token_id, tier, metadata_uri);
    assert(!duplicate_success, "Duplicate NFT registration should fail");
    
    // Check that the correct event was emitted for the duplicate attempt
    spy.assert_emitted(@array![
        (
            contract_address,
            event_name_hash('DuplicateNFTAttempt'),
            @array![campaign_id.into(), recipient.into(), token_id.into()]
        )
    ]);
}

#[test]
fn test_nft_exists_for_campaign() {
    let (nft_verifier, contract_address, admin) = setup();
    let recipient: ContractAddress = contract_address_const::<'recipient'>();
    
    // Register NFTs for different campaigns
    let campaign_id_1: u32 = 1;
    let campaign_id_2: u32 = 2;
    let token_id_1: u128 = 1;
    let token_id_2: u128 = 2;
    let tier: u8 = 1;
    let metadata_uri: felt252 = 'ipfs://QmExample';
    
    nft_verifier.register_nft(campaign_id_1, recipient, token_id_1, tier, metadata_uri);
    nft_verifier.register_nft(campaign_id_2, recipient, token_id_2, tier, metadata_uri);
    
    // Check NFT existence for specific campaigns
    let nft1_exists_for_campaign1 = nft_verifier.nft_exists_for_campaign(campaign_id_1, token_id_1);
    let nft1_exists_for_campaign2 = nft_verifier.nft_exists_for_campaign(campaign_id_2, token_id_1);
    let nft2_exists_for_campaign2 = nft_verifier.nft_exists_for_campaign(campaign_id_2, token_id_2);
    
    assert(nft1_exists_for_campaign1, "NFT 1 should exist for campaign 1");
    assert(!nft1_exists_for_campaign2, "NFT 1 should not exist for campaign 2");
    assert(nft2_exists_for_campaign2, "NFT 2 should exist for campaign 2");
}

#[test]
fn test_recipient_has_nft_for_campaign() {
    let (nft_verifier, contract_address, admin) = setup();
    let recipient1: ContractAddress = contract_address_const::<'recipient1'>();
    let recipient2: ContractAddress = contract_address_const::<'recipient2'>();
    
    // Register NFTs for different recipients
    let campaign_id: u32 = 1;
    let token_id_1: u128 = 1;
    let token_id_2: u128 = 2;
    let tier: u8 = 1;
    let metadata_uri: felt252 = 'ipfs://QmExample';
    
    nft_verifier.register_nft(campaign_id, recipient1, token_id_1, tier, metadata_uri);
    
    // Check if recipients have NFTs for the campaign
    let recipient1_has_nft = nft_verifier.recipient_has_nft_for_campaign(campaign_id, recipient1);
    let recipient2_has_nft = nft_verifier.recipient_has_nft_for_campaign(campaign_id, recipient2);
    
    assert(recipient1_has_nft, "Recipient 1 should have an NFT for the campaign");
    assert(!recipient2_has_nft, "Recipient 2 should not have an NFT for the campaign");
}

#[test]
fn test_get_nft_by_token_id() {
    let (nft_verifier, contract_address, admin) = setup();
    let recipient: ContractAddress = contract_address_const::<'recipient'>();
    
    // Register a new NFT
    let campaign_id: u32 = 1;
    let token_id: u128 = 1;
    let tier: u8 = 1;
    let metadata_uri: felt252 = 'ipfs://QmExample';
    
    nft_verifier.register_nft(campaign_id, recipient, token_id, tier, metadata_uri);
    
    // Get the NFT by token ID
    let nft_option = nft_verifier.get_nft_by_token_id(token_id);
    assert(nft_option.is_some(), "NFT should be found");
    
    let nft = nft_option.unwrap();
    assert(nft.campaign_id == campaign_id, "Campaign ID mismatch");
    assert(nft.recipient == recipient, "Recipient mismatch");
    assert(nft.token_id == token_id, "Token ID mismatch");
    assert(nft.tier == tier, "Tier mismatch");
    assert(nft.metadata_uri == metadata_uri, "Metadata URI mismatch");
    
    // Try to get a non-existent NFT
    let non_existent_nft = nft_verifier.get_nft_by_token_id(999);
    assert(non_existent_nft.is_none(), "Non-existent NFT should not be found");
}

#[test]
fn test_get_campaign_nfts() {
    let (nft_verifier, contract_address, admin) = setup();
    let recipient: ContractAddress = contract_address_const::<'recipient'>();
    
    // Register multiple NFTs for the same campaign
    let campaign_id: u32 = 1;
    let token_id_1: u128 = 1;
    let token_id_2: u128 = 2;
    let tier: u8 = 1;
    let metadata_uri: felt252 = 'ipfs://QmExample';
    
    nft_verifier.register_nft(campaign_id, recipient, token_id_1, tier, metadata_uri);
    nft_verifier.register_nft(campaign_id, recipient, token_id_2, tier, metadata_uri);
    
    // Get all NFTs for the campaign
    let campaign_nfts = nft_verifier.get_campaign_nfts(campaign_id);
    assert(campaign_nfts.len() == 2, "Campaign should have 2 NFTs");
    
    // Check a campaign with no NFTs
    let empty_campaign_nfts = nft_verifier.get_campaign_nfts(999);
    assert(empty_campaign_nfts.len() == 0, "Empty campaign should have 0 NFTs");
}

#[test]
fn test_get_recipient_nfts() {
    let (nft_verifier, contract_address, admin) = setup();
    let recipient: ContractAddress = contract_address_const::<'recipient'>();
    
    // Register multiple NFTs for the same recipient across different campaigns
    let campaign_id_1: u32 = 1;
    let campaign_id_2: u32 = 2;
    let token_id_1: u128 = 1;
    let token_id_2: u128 = 2;
    let tier: u8 = 1;
    let metadata_uri: felt252 = 'ipfs://QmExample';
    
    nft_verifier.register_nft(campaign_id_1, recipient, token_id_1, tier, metadata_uri);
    nft_verifier.register_nft(campaign_id_2, recipient, token_id_2, tier, metadata_uri);
    
    // Get all NFTs for the recipient
    let recipient_nfts = nft_verifier.get_recipient_nfts(recipient);
    assert(recipient_nfts.len() == 2, "Recipient should have 2 NFTs");
    
    // Check a recipient with no NFTs
    let empty_recipient: ContractAddress = contract_address_const::<'empty'>();
    let empty_recipient_nfts = nft_verifier.get_recipient_nfts(empty_recipient);
    assert(empty_recipient_nfts.len() == 0, "Empty recipient should have 0 NFTs");
}

#[test]
fn test_multiple_campaigns_and_recipients() {
    let (nft_verifier, contract_address, admin) = setup();
    let recipient1: ContractAddress = contract_address_const::<'recipient1'>();
    let recipient2: ContractAddress = contract_address_const::<'recipient2'>();
    
    // Register NFTs for different campaigns and recipients
    let campaign_id_1: u32 = 1;
    let campaign_id_2: u32 = 2;
    let token_id_1: u128 = 1;
    let token_id_2: u128 = 2;
    let token_id_3: u128 = 3;
    let tier: u8 = 1;
    let metadata_uri: felt252 = 'ipfs://QmExample';
    
    nft_verifier.register_nft(campaign_id_1, recipient1, token_id_1, tier, metadata_uri);
    nft_verifier.register_nft(campaign_id_2, recipient1, token_id_2, tier, metadata_uri);
    nft_verifier.register_nft(campaign_id_1, recipient2, token_id_3, tier, metadata_uri);
    
    // Check campaign NFTs
    let campaign1_nfts = nft_verifier.get_campaign_nfts(campaign_id_1);
    let campaign2_nfts = nft_verifier.get_campaign_nfts(campaign_id_2);
    assert(campaign1_nfts.len() == 2, "Campaign 1 should have 2 NFTs");
    assert(campaign2_nfts.len() == 1, "Campaign 2 should have 1 NFT");
    
    // Check recipient NFTs
    let recipient1_nfts = nft_verifier.get_recipient_nfts(recipient1);
    let recipient2_nfts = nft_verifier.get_recipient_nfts(recipient2);
    assert(recipient1_nfts.len() == 2, "Recipient 1 should have 2 NFTs");
    assert(recipient2_nfts.len() == 1, "Recipient 2 should have 1 NFT");
}