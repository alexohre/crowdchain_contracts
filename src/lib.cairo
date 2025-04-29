// inporting interfaces
pub mod interfaces {
    pub mod IAccount;
    pub mod IAdmin;
    pub mod ICampaign;
    pub mod IContribution;
}

// importing contract
pub mod contracts {
    pub mod Account;
    pub mod Admin;
    pub mod Campaign;
    pub mod Contribution;
}

pub mod structs {
    pub mod Structs;
}

pub mod base {
    pub mod types;
}

// importing Events
pub mod events {
    pub mod AccountEvent;
    pub mod AdminEvents;
    pub mod CampaignEvent;
    pub mod ContributionEvent;
}


// importing tests
#[cfg(tests)]
pub mod tests {
    pub mod test_account;
    // pub mod test_account_events;
    pub mod test_admin;
    pub mod test_campaign;
    pub mod test_contribution;
    pub mod test_demo;
    pub mod test_nft_reward;
}
