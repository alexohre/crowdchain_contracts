use crowdchain_contracts::contracts::Contribution::Contribution;
use crowdchain_contracts::events::ContributionEvent::{
    ContributionProcessed, WithdrawalMade, PlatformFeeCollected, ContributionStatsUpdated, Event,
};
use crowdchain_contracts::interfaces::IContribution::{IContributionDispatcher, IContributionDispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, spy_events,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::{ContractAddress, contract_address_const};

fn setup() -> (IContributionDispatcher, ContractAddress, ContractAddress) {
    let admin: ContractAddress = contract_address_const::<'admin'>();
    let contract = declare("Contribution").unwrap().contract_class();
    let calldata = array![admin.into(), 100u128.into()]; // 1% fee
    let (contract_address, _) = contract.deploy(@calldata).unwrap();
    let contribution_dispatcher = IContributionDispatcher { contract_address };
    (contribution_dispatcher, contract_address, admin)
}

#[test]
fn test_process_contribution() {
    let (contribution_dispatcher, contract_address, admin) = setup();
    let contributor: ContractAddress = contract_address_const::<'contributor'>();

    start_cheat_caller_address(contract_address, contributor);
    contribution_dispatcher.process_contribution(1, contributor, 1000);
    stop_cheat_caller_address(contract_address);

    let (total_contributed, total_withdrawn) = contribution_dispatcher.get_contribution_stats(1, contributor);
    assert(total_contributed == 1000, "Total contributed mismatch");
    assert(total_withdrawn == 0, "Total withdrawn mismatch");
}

#[test]
fn test_withdraw_funds() {
    let (contribution_dispatcher, contract_address, admin) = setup();
    let contributor: ContractAddress = contract_address_const::<'contributor'>();

    start_cheat_caller_address(contract_address, contributor);
    contribution_dispatcher.process_contribution(1, contributor, 1000);
    contribution_dispatcher.withdraw_funds(1, contributor, 500);
    stop_cheat_caller_address(contract_address);

    let (total_contributed, total_withdrawn) = contribution_dispatcher.get_contribution_stats(1, contributor);
    assert(total_contributed == 1000, "Total contributed mismatch");
    assert(total_withdrawn == 500, "Total withdrawn mismatch");
}

#[test]
fn test_calculate_platform_fee() {
    let (contribution_dispatcher, contract_address, admin) = setup();

    let fee = contribution_dispatcher.calculate_platform_fee(10000);
    assert(fee == 100, "Platform fee calculation mismatch"); // 1% of 10000
}

#[test]
fn test_get_top_contributors() {
    let (contribution_dispatcher, contract_address, admin) = setup();
    let contributor1: ContractAddress = contract_address_const::<'contrib1'>();
    let contributor2: ContractAddress = contract_address_const::<'contrib2'>();

    start_cheat_caller_address(contract_address, contributor1);
    contribution_dispatcher.process_contribution(1, contributor1, 1000);
    stop_cheat_caller_address(contract_address);

    start_cheat_caller_address(contract_address, contributor2);
    contribution_dispatcher.process_contribution(1, contributor2, 2000);
    stop_cheat_caller_address(contract_address);

    let top_contributors = contribution_dispatcher.get_top_contributors();
    assert(top_contributors.len() >= 2, "Top contributors count mismatch");
}

#[test]
#[should_panic(expected = "Contribution amount must be positive")]
fn test_process_contribution_zero_amount() {
    let (contribution_dispatcher, contract_address, admin) = setup();
    let contributor: ContractAddress = contract_address_const::<'contributor'>();

    start_cheat_caller_address(contract_address, contributor);
    contribution_dispatcher.process_contribution(1, contributor, 0);
    stop_cheat_caller_address(contract_address);
}

#[test]
#[should_panic(expected = "Withdrawal amount exceeds available balance")]
fn test_withdraw_exceeding_amount() {
    let (contribution_dispatcher, contract_address, admin) = setup();
    let contributor: ContractAddress = contract_address_const::<'contributor'>();

    start_cheat_caller_address(contract_address, contributor);
    contribution_dispatcher.process_contribution(1, contributor, 1000);
    contribution_dispatcher.withdraw_funds(1, contributor, 1500);
    stop_cheat_caller_address(contract_address);
}
