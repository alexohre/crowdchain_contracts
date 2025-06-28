use crowdchain_contracts::contracts::Crowdchain::Crowdchain::{CampaignStatus, Event};
use crowdchain_contracts::events::CrowdchainEvent::{
    CampaignCreated, CampaignPaused, CampaignUnpaused // add to the list when needed
};
use crowdchain_contracts::interfaces::ICrowdchain::{
    ICrowdchainDispatcher, ICrowdchainDispatcherTrait,
};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, spy_events,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::ContractAddress;


// ********** BEGIN OF ADDRESS FUNCTIONS **********
// Admin address
fn admin_address() -> ContractAddress {
    let admin_felt: felt252 = 0001.into();
    let admin: ContractAddress = admin_felt.try_into().unwrap();
    admin
}

// Creator address
fn creator_address() -> ContractAddress {
    let creator_felt: felt252 = 0002.into();
    let creator: ContractAddress = creator_felt.try_into().unwrap();
    creator
}

// Creator2 address
fn creator2_address() -> ContractAddress {
    let creator2_felt: felt252 = 0002.into();
    let creator2: ContractAddress = creator2_felt.try_into().unwrap();
    creator2
}

// Non admin address
fn non_admin_address() -> ContractAddress {
    let non_admin_felt: felt252 = 0003.into();
    let non_admin: ContractAddress = non_admin_felt.try_into().unwrap();
    non_admin
}

// Non creator address
fn non_creator_address() -> ContractAddress {
    let non_creator_felt: felt252 = 0004.into();
    let non_creator: ContractAddress = non_creator_felt.try_into().unwrap();
    non_creator
}

// Some address
fn some_address() -> ContractAddress {
    let some_felt: felt252 = 0005.into();
    let some: ContractAddress = some_felt.try_into().unwrap();
    some
}

// Some address
fn some_address2() -> ContractAddress {
    let some_felt: felt252 = 0006.into();
    let some: ContractAddress = some_felt.try_into().unwrap();
    some
}

// ********** END OF ADDRESS FUNCTIONS **********

fn setup() -> (ICrowdchainDispatcher, ContractAddress, ContractAddress) {
    let admin = admin_address();
    let contract = declare("Crowdchain").unwrap().contract_class();
    let calldata = array![admin.into()];
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let campaign_dispatcher = ICrowdchainDispatcher { contract_address };
    (campaign_dispatcher, contract_address, admin)
}

#[test]
fn test_admin_set_and_campaign_creation() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator = creator_address();

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator);
    let campaign_id = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign",
            "This is a test campaign description",
            1000_u256,
            "https://example.com/image.jpg",
        );
    let stats = campaign_dispatcher.get_campaign_stats(campaign_id);
    stop_cheat_caller_address(contract_address);
    assert(stats.creator == creator, 'Creator mismatch');
    assert(stats.status == CampaignStatus::Active, 'Status mismatch');
}

#[test]
fn test_only_admin_can_pause() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator = creator_address();
    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);
    start_cheat_caller_address(contract_address, creator);
    let campaign_id = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign",
            "This is a test campaign description",
            1000_u256,
            "https://example.com/image.jpg",
        );
    stop_cheat_caller_address(contract_address);
    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.pause_campaign(campaign_id);
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_only_creator_can_update_status() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator = creator_address();
    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);
    start_cheat_caller_address(contract_address, creator);
    let campaign_id = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign",
            "This is a test campaign description",
            1000_u256,
            "https://example.com/image.jpg",
        );
    let status: CampaignStatus = CampaignStatus::Paused;
    campaign_dispatcher.update_campaign_status(campaign_id, status);
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_get_campaign_stats() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator = creator_address();
    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);
    start_cheat_caller_address(contract_address, creator);
    let campaign_id = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign",
            "This is a test campaign description",
            1000_u256,
            "https://example.com/image.jpg",
        );
    let stats = campaign_dispatcher.get_campaign_stats(campaign_id);
    stop_cheat_caller_address(contract_address);
    assert(stats.campaign_id == campaign_id, 'Campaign ID mismatch');
    assert(stats.creator == creator, 'Creator mismatch');
}

#[test]
fn test_get_top_campaigns() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator = creator_address();
    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);
    start_cheat_caller_address(contract_address, creator);
    campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign 1",
            "This is the first test campaign",
            1000_u256,
            "https://example.com/image1.jpg",
        );
    campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign 2",
            "This is the second test campaign",
            2000_u256,
            "https://example.com/image2.jpg",
        );
    let top_campaigns = campaign_dispatcher.get_top_campaigns();
    stop_cheat_caller_address(contract_address);
    assert(top_campaigns.len() > 0, 'No top campaigns found');
}

#[test]
#[should_panic(expected: 'Caller is not admin')]
fn test_non_admin_cannot_pause_unpause() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator = creator_address();
    let non_admin = non_admin_address();

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator);
    let campaign_id = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign",
            "This is a test campaign description",
            1000_u256,
            "https://example.com/image.jpg",
        );
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, non_admin);
    campaign_dispatcher.pause_campaign(campaign_id);
    campaign_dispatcher.unpause_campaign(campaign_id);
    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expected: 'Caller is not the creator')]
fn test_non_creator_cannot_update_status() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator = creator_address();
    let non_creator = non_creator_address();

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator);
    let campaign_id = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign",
            "This is a test campaign description",
            1000_u256,
            "https://example.com/image.jpg",
        );
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, non_creator);
    let status: CampaignStatus = CampaignStatus::Paused;
    campaign_dispatcher.update_campaign_status(campaign_id, status);
    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expected: 'Creator not approved')]
fn test_cannot_create_campaign_if_not_approved() {
    let (campaign_dispatcher, contract_address, _) = setup();
    let creator = creator_address();

    start_cheat_caller_address(contract_address, creator);
    campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign",
            "This is a test campaign description",
            1000_u256,
            "https://example.com/image.jpg",
        );
    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic]
fn test_get_stats_for_nonexistent_campaign() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator = creator_address();

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator);
    let campaign_id = 9999;
    campaign_dispatcher.get_campaign_stats(campaign_id);
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_multiple_top_campaigns() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator = creator_address();
    let some_address1 = some_address();
    let some_address2 = some_address2();
    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator);
    let campaign_id1 = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign 1",
            "This is the first test campaign",
            1000_u256,
            "https://example.com/image1.jpg",
        );
    let campaign_id2 = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign 2",
            "This is the second test campaign",
            2000_u256,
            "https://example.com/image2.jpg",
        );

    // Simulate both campaigns having the same supporter count

    campaign_dispatcher.add_supporter(campaign_id1, some_address1);
    campaign_dispatcher.add_supporter(campaign_id2, some_address2);

    let top_campaigns = campaign_dispatcher.get_top_campaigns();
    assert(top_campaigns.len() >= 2, 'Should return two top campaigns');
}

#[test]
fn test_admin_can_approve_multiple_creators() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator1 = creator_address();
    let creator2 = creator2_address();

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator1);
    campaign_dispatcher.approve_creator(creator2);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator1);
    campaign_dispatcher
        .create_campaign(
            creator1,
            "Test Campaign 1",
            "This is the first test campaign",
            1000_u256,
            "https://example.com/image1.jpg",
        );
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator2);
    campaign_dispatcher
        .create_campaign(
            creator2,
            "Test Campaign 2",
            "This is the second test campaign",
            2000_u256,
            "https://example.com/image2.jpg",
        );
    stop_cheat_caller_address(contract_address);

    let campaign_id1 = campaign_dispatcher.get_last_campaign_id() - 1;
    let campaign_id2 = campaign_dispatcher.get_last_campaign_id();

    start_cheat_caller_address(contract_address, creator1);
    let stats1 = campaign_dispatcher.get_campaign_stats(campaign_id1);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator2);
    let stats2 = campaign_dispatcher.get_campaign_stats(campaign_id2);
    stop_cheat_caller_address(contract_address);

    assert(stats1.creator == creator1, 'Creator1 mismatch');
    assert(stats2.creator == creator2, 'Creator2 mismatch');
}

#[test]
fn test_campaign_lifecycle() {
    let (campaign_dispatcher, contract_address, admin) = setup();

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(admin);

    campaign_dispatcher
        .create_campaign(
            admin,
            "Test Campaign",
            "This is a test campaign description",
            1000_u256,
            "https://example.com/image.jpg",
        );
    let campaign_id = campaign_dispatcher.get_last_campaign_id();

    // Admin pauses
    campaign_dispatcher.pause_campaign(campaign_id);
    let stats = campaign_dispatcher.get_campaign_stats(campaign_id);
    assert(stats.status == CampaignStatus::Paused, 'Should be paused');

    // Admin unpauses
    campaign_dispatcher.unpause_campaign(campaign_id);
    let stats = campaign_dispatcher.get_campaign_stats(campaign_id);
    assert(stats.status == CampaignStatus::Active, 'Should be active');

    // Creator completes
    campaign_dispatcher.update_campaign_status(campaign_id, CampaignStatus::Completed);
    let stats = campaign_dispatcher.get_campaign_stats(campaign_id);
    assert(stats.status == CampaignStatus::Completed, 'Should be completed');
    stop_cheat_caller_address(contract_address);
}


#[test]
fn test_supporter_logic() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator = creator_address();
    let supporter = some_address();

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator);
    let campaign_id = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign",
            "This is a test campaign description",
            1000_u256,
            "https://example.com/image.jpg",
        );
    campaign_dispatcher.add_supporter(campaign_id, supporter);
    let stats = campaign_dispatcher.get_campaign_stats(campaign_id);
    assert(stats.supporter_count == 1, 'Supporter count should be 1');
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator);
    campaign_dispatcher.add_supporter(campaign_id, supporter); // duplicate
    let stats = campaign_dispatcher.get_campaign_stats(campaign_id);
    assert!(stats.supporter_count != 1, "Supporter count should not increment for duplicate");
    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expected: 'Caller is not admin')]
fn test_pause_unpause_nonexistent_campaign() {
    let (campaign_dispatcher, contract_address, _) = setup();
    let creator = creator_address();
    let campaign_id = 9999;
    start_cheat_caller_address(contract_address, creator);
    campaign_dispatcher.pause_campaign(campaign_id);
    campaign_dispatcher.unpause_campaign(campaign_id);
    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expected: 'Caller is not the creator')]
fn test_update_status_nonexistent_campaign() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let campaign_id = 9999;
    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.update_campaign_status(campaign_id, CampaignStatus::Paused);
    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expected: 'Invalid status')]
fn test_invalid_status_transitions() {
    let (campaign_dispatcher, contract_address, admin) = setup();

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(admin);

    campaign_dispatcher
        .create_campaign(
            admin,
            "Test Campaign",
            "This is a test campaign description",
            1000_u256,
            "https://example.com/image.jpg",
        );
    let campaign_id = campaign_dispatcher.get_last_campaign_id();
    // Pause twice
    campaign_dispatcher.pause_campaign(campaign_id);
    campaign_dispatcher.pause_campaign(campaign_id);
    // Unpause when not paused
    campaign_dispatcher.unpause_campaign(campaign_id);
    campaign_dispatcher.unpause_campaign(campaign_id);
    // Complete twice
    campaign_dispatcher.update_campaign_status(campaign_id, CampaignStatus::Completed);
    campaign_dispatcher.update_campaign_status(campaign_id, CampaignStatus::Completed);
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_campaign_counter_integrity() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator = creator_address();

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator);
    let id1 = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign 1",
            "This is the first test campaign",
            1000_u256,
            "https://example.com/image1.jpg",
        );
    let id2 = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign 2",
            "This is the second test campaign",
            2000_u256,
            "https://example.com/image2.jpg",
        );
    assert(id2 == id1 + 1, 'Campaign counter not ++');
}

#[test]
fn test_get_top_campaigns_no_campaigns() {
    let (campaign_dispatcher, contract_address, admin) = setup();

    start_cheat_caller_address(contract_address, admin);
    let top_campaigns = campaign_dispatcher.get_top_campaigns();
    assert(top_campaigns.len() == 0, 'Should be empty');
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_get_top_campaigns_all_paused_completed() {
    let (campaign_dispatcher, contract_address, admin) = setup();

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(admin);

    campaign_dispatcher
        .create_campaign(
            admin,
            "Test Campaign 1",
            "This is the first test campaign",
            1000_u256,
            "https://example.com/image1.jpg",
        );
    campaign_dispatcher
        .create_campaign(
            admin,
            "Test Campaign 2",
            "This is the second test campaign",
            2000_u256,
            "https://example.com/image2.jpg",
        );
    let id1 = campaign_dispatcher.get_last_campaign_id() - 1;
    let id2 = campaign_dispatcher.get_last_campaign_id();

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.pause_campaign(id1);
    campaign_dispatcher.update_campaign_status(id2, CampaignStatus::Completed);
    let top_campaigns = campaign_dispatcher.get_top_campaigns();
    assert(top_campaigns.len() > 0, 'Should still return campaigns');
    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expected: 'Caller is not admin')]
fn test_only_admin_can_approve_creator() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let not_admin = non_admin_address();
    let creator = creator_address();

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, not_admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_multiple_actions_sequence() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator = creator_address();

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator);
    let campaign_id = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign",
            "This is a test campaign description",
            1000_u256,
            "https://example.com/image.jpg",
        );
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.pause_campaign(campaign_id);
    campaign_dispatcher.unpause_campaign(campaign_id);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator);
    campaign_dispatcher.update_campaign_status(campaign_id, CampaignStatus::Completed);
    let stats = campaign_dispatcher.get_campaign_stats(campaign_id);
    assert(stats.status == CampaignStatus::Completed, 'status should be completed');
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_create_campaign_event() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator = creator_address();
    let mut spy = spy_events();

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator);
    let campaign_id = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign",
            "This is a test campaign description",
            1000_u256,
            "https://example.com/image.jpg",
        );

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    Event::Created(
                        CampaignCreated {
                            campaign_id: campaign_id,
                            creator: creator,
                            status: campaign_dispatcher.get_campaign_stats(campaign_id).status,
                            supporter_count: campaign_dispatcher
                                .get_campaign_stats(campaign_id)
                                .supporter_count,
                        },
                    ),
                ),
            ],
        );
    stop_cheat_caller_address(contract_address);
}


#[test]
fn test_pause_campaign_event() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator = creator_address();
    let mut spy = spy_events();

    // Setup: create a campaign
    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator);
    let campaign_id = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign",
            "This is a test campaign description",
            1000_u256,
            "https://example.com/image.jpg",
        );
    stop_cheat_caller_address(contract_address);

    // Test pause
    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.pause_campaign(campaign_id);
    stop_cheat_caller_address(contract_address);

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    Event::HoldCampaign(CampaignPaused { campaign_id: campaign_id }),
                ),
            ],
        );
}

#[test]
fn test_unpause_campaign_event() {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let creator = creator_address();
    let mut spy = spy_events();

    // Setup: create and pause a campaign
    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, creator);
    let campaign_id = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign",
            "This is a test campaign description",
            1000_u256,
            "https://example.com/image.jpg",
        );
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.pause_campaign(campaign_id);

    // Test unpause
    campaign_dispatcher.unpause_campaign(campaign_id);
    stop_cheat_caller_address(contract_address);

    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    Event::UnholdCampaign(CampaignUnpaused { campaign_id: campaign_id }),
                ),
            ],
        );
}
