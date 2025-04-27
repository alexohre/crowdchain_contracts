// inporting interfaces
pub mod interfaces {
    pub mod IAccount;
    pub mod ICampaign;
    pub mod IAdmin;
}

// importing contract
pub mod contracts {
    pub mod Account;
    pub mod Campaign;
    pub mod Admin;
}

pub mod structs{
    pub mod Structs;
}

pub mod base {
    pub mod types;
}

// importing Events
pub mod events {
    pub mod AccountEvent;
    pub mod CampaignEvent;
    pub mod AdminEvents;
}


// importing tests
#[cfg(tests)]
pub mod tests {
    pub mod test_account;
    pub mod test_account_events;
    pub mod test_demo;
}
