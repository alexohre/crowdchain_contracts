// inporting interfaces
pub mod interfaces {
    pub mod ICampaign;
    pub mod INFTReward;
}

// importing contract
pub mod contracts {
    pub mod Campaign;
    pub mod NFTReward;
}

pub mod structs {
    pub mod Structs;
}

// importing Events
pub mod events {
    pub mod CampaignEvent;
    pub mod NFTRewardEvent;
}


// importing tests
#[cfg(tests)]
pub mod tests {
    pub mod test_campaign;
    pub mod test_nft_reward;
}
