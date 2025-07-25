use crowdchain_contracts::contracts::Crowdchain::Crowdchain::Event;
use crowdchain_contracts::events::CrowdchainEvent::ContributionProcessed;
use crowdchain_contracts::interfaces::ICrowdchain::{
    ICrowdchainDispatcher, ICrowdchainDispatcherTrait,
};
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
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

// Contributor address
fn contributor_address() -> ContractAddress {
    let contributor_felt: felt252 = 0003.into();
    let contributor: ContractAddress = contributor_felt.try_into().unwrap();
    contributor
}

// Contributor2 address
fn contributor2_address() -> ContractAddress {
    let contributor2_felt: felt252 = 0004.into();
    let contributor2: ContractAddress = contributor2_felt.try_into().unwrap();
    contributor2
}

// ********** END OF ADDRESS FUNCTIONS **********

// Main setup function following the existing pattern
fn setup() -> (ICrowdchainDispatcher, ContractAddress, ContractAddress) {
    let admin = admin_address();
    let contract = declare("Crowdchain").unwrap().contract_class();
    let calldata = array![admin.into()];
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let campaign_dispatcher = ICrowdchainDispatcher { contract_address };
    (campaign_dispatcher, contract_address, admin)
}

// Deploy MockToken contract
fn deploy_mock_token() -> ContractAddress {
    let contract = declare("MockToken").unwrap().contract_class();
    let constructor_calldata = array![
        contributor_address().into(), // recipient
        admin_address().into() // owner
    ];
    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    contract_address
}

// Helper function to setup campaign with token
fn setup_campaign_and_token() -> (ICrowdchainDispatcher, ContractAddress, ContractAddress, u64) {
    let (campaign_dispatcher, contract_address, admin) = setup();
    let token_address = deploy_mock_token();
    let creator = creator_address();

    // Approve creator
    start_cheat_caller_address(contract_address, admin);
    campaign_dispatcher.approve_creator(creator);
    stop_cheat_caller_address(contract_address);

    // Create campaign
    start_cheat_caller_address(contract_address, creator);
    let campaign_id = campaign_dispatcher
        .create_campaign(
            creator,
            "Test Campaign",
            "A test campaign for contribution testing",
            1000000_u256, // goal: 1M tokens
            "https://example.com/image.jpg",
        );
    stop_cheat_caller_address(contract_address);

    (campaign_dispatcher, contract_address, token_address, campaign_id)
}

#[test]
fn test_successful_contribution() {
    let (campaign_dispatcher, contract_address, token_address, campaign_id) =
        setup_campaign_and_token();

    let token = IERC20Dispatcher { contract_address: token_address };
    let contributor = contributor_address();
    let contribution_amount = 1000_u256;

    // Check initial balances
    let initial_contributor_balance = token.balance_of(contributor);
    let initial_contract_balance = token.balance_of(contract_address);

    // Approve tokens for contribution
    start_cheat_caller_address(token_address, contributor);
    token.approve(contract_address, contribution_amount);
    stop_cheat_caller_address(token_address);

    // Setup event spy
    let mut spy = spy_events();

    // Make contribution
    start_cheat_caller_address(contract_address, contributor);
    campaign_dispatcher.contribute(campaign_id, contribution_amount, token_address);
    stop_cheat_caller_address(contract_address);

    // Verify token transfer
    let final_contributor_balance = token.balance_of(contributor);
    let final_contract_balance = token.balance_of(contract_address);

    assert(
        final_contributor_balance == initial_contributor_balance - contribution_amount,
        'Contributor balance incorrect',
    );
    assert(
        final_contract_balance == initial_contract_balance + contribution_amount,
        'Contract balance incorrect',
    );

    // Verify contribution tracking
    let contribution = campaign_dispatcher.get_contribution(campaign_id, contributor);
    assert(contribution == contribution_amount, 'Contribution amount incorrect');

    let total_contributions = campaign_dispatcher.get_campaign_contributions(campaign_id);
    assert(total_contributions == contribution_amount, 'Total contributions incorrect');

    // Verify event emission
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    Event::ContributionProcessed(
                        ContributionProcessed {
                            campaign_id, contributor, amount: contribution_amount,
                        },
                    ),
                ),
            ],
        );
}

#[test]
fn test_multiple_contributions_same_user() {
    let (campaign_dispatcher, contract_address, token_address, campaign_id) =
        setup_campaign_and_token();

    let token = IERC20Dispatcher { contract_address: token_address };
    let contributor = contributor_address();
    let first_amount = 500_u256;
    let second_amount = 300_u256;
    let total_amount = first_amount + second_amount;

    // First contribution
    start_cheat_caller_address(token_address, contributor);
    token.approve(contract_address, first_amount);
    stop_cheat_caller_address(token_address);

    start_cheat_caller_address(contract_address, contributor);
    campaign_dispatcher.contribute(campaign_id, first_amount, token_address);
    stop_cheat_caller_address(contract_address);

    // Second contribution
    start_cheat_caller_address(token_address, contributor);
    token.approve(contract_address, second_amount);
    stop_cheat_caller_address(token_address);

    start_cheat_caller_address(contract_address, contributor);
    campaign_dispatcher.contribute(campaign_id, second_amount, token_address);
    stop_cheat_caller_address(contract_address);

    // Verify total contribution
    let contribution = campaign_dispatcher.get_contribution(campaign_id, contributor);
    assert(contribution == total_amount, 'Total contribution incorrect');

    let total_contributions = campaign_dispatcher.get_campaign_contributions(campaign_id);
    assert(total_contributions == total_amount, 'Campaign total incorrect');
}

#[test]
fn test_multiple_contributors() {
    let (campaign_dispatcher, contract_address, token_address, campaign_id) =
        setup_campaign_and_token();

    let token = IERC20Dispatcher { contract_address: token_address };
    let contributor1 = contributor_address();
    let contributor2 = contributor2_address();
    let amount1 = 600_u256;
    let amount2 = 400_u256;
    let total_expected = amount1 + amount2;

    // First contributor
    start_cheat_caller_address(token_address, contributor1);
    token.approve(contract_address, amount1);
    stop_cheat_caller_address(token_address);

    start_cheat_caller_address(contract_address, contributor1);
    campaign_dispatcher.contribute(campaign_id, amount1, token_address);
    stop_cheat_caller_address(contract_address);

    // Second contributor (need to give them tokens first)
    start_cheat_caller_address(token_address, contributor1);
    token.transfer(contributor2, amount2);
    stop_cheat_caller_address(token_address);

    start_cheat_caller_address(token_address, contributor2);
    token.approve(contract_address, amount2);
    stop_cheat_caller_address(token_address);

    start_cheat_caller_address(contract_address, contributor2);
    campaign_dispatcher.contribute(campaign_id, amount2, token_address);
    stop_cheat_caller_address(contract_address);

    // Verify individual contributions
    let contrib1 = campaign_dispatcher.get_contribution(campaign_id, contributor1);
    let contrib2 = campaign_dispatcher.get_contribution(campaign_id, contributor2);
    assert(contrib1 == amount1, 'Contributor1 amount incorrect');
    assert(contrib2 == amount2, 'Contributor2 amount incorrect');

    // Verify total
    let total_contributions = campaign_dispatcher.get_campaign_contributions(campaign_id);
    assert(total_contributions == total_expected, 'Total contributions incorrect');
}

#[test]
#[should_panic(expected: 'Invalid campaign ID')]
fn test_contribute_invalid_campaign_id() {
    let (campaign_dispatcher, contract_address, token_address, _campaign_id) =
        setup_campaign_and_token();

    start_cheat_caller_address(contract_address, contributor_address());
    campaign_dispatcher.contribute(0, 1000_u256, token_address); // Invalid campaign ID
    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expected: 'Amount must be greater than 0')]
fn test_contribute_zero_amount() {
    let (campaign_dispatcher, contract_address, token_address, campaign_id) =
        setup_campaign_and_token();

    start_cheat_caller_address(contract_address, contributor_address());
    campaign_dispatcher.contribute(campaign_id, 0_u256, token_address); // Zero amount
    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expected: 'Campaign does not exist')]
fn test_contribute_nonexistent_campaign() {
    let (campaign_dispatcher, contract_address, token_address, _campaign_id) =
        setup_campaign_and_token();

    start_cheat_caller_address(contract_address, contributor_address());
    campaign_dispatcher.contribute(999, 1000_u256, token_address); // Non-existent campaign
    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expected: 'ERC20: insufficient allowance')]
fn test_contribute_insufficient_allowance() {
    let (campaign_dispatcher, contract_address, token_address, campaign_id) =
        setup_campaign_and_token();

    // Don't approve tokens, so transfer should fail
    start_cheat_caller_address(contract_address, contributor_address());
    campaign_dispatcher.contribute(campaign_id, 1000_u256, token_address);
    stop_cheat_caller_address(contract_address);
}
