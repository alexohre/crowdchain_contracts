
// inporting interfaces
pub mod interfaces {
    pub mod IAccount;
    pub mod ICampaign;
}

// importing contract
pub mod contracts {
    pub mod Account;
    pub mod Campaign;
}

// importing Events
pub mod events {
    pub mod AccountEvent;
    pub mod CampaignEvent;
}


// importing tests
#[cfg(tests)]
pub mod tests {
    pub mod test_account;
    pub mod test_account_events;
    pub mod test_demo;
}
