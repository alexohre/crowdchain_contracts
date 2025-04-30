use starknet::ContractAddress;
use crowdchain_contracts::structs::Structs::NFTReward;

#[starknet::interface]
trait INFTVerifier<TContractState> {
    /// Verifies if an NFT with the given token_id is unique across all campaigns
    /// Returns true if the NFT is unique, false otherwise
    fn verify_nft_uniqueness(self: @TContractState, token_id: u128) -> bool;
    
    /// Registers a new NFT in the uniqueness registry
    /// Returns true if registration was successful, false if the NFT already exists
    fn register_nft(
        ref self: TContractState, 
        campaign_id: u32, 
        recipient: ContractAddress, 
        token_id: u128, 
        tier: u8, 
        metadata_uri: felt252
    ) -> bool;
    
    /// Checks if an NFT with the given token_id exists for a specific campaign
    fn nft_exists_for_campaign(self: @TContractState, campaign_id: u32, token_id: u128) -> bool;
    
    /// Checks if a recipient already has an NFT for a specific campaign
    fn recipient_has_nft_for_campaign(self: @TContractState, campaign_id: u32, recipient: ContractAddress) -> bool;
    
    /// Gets the NFT reward details by token_id
    fn get_nft_by_token_id(self: @TContractState, token_id: u128) -> Option<NFTReward>;
    
    /// Gets all NFTs associated with a campaign
    fn get_campaign_nfts(self: @TContractState, campaign_id: u32) -> Array<NFTReward>;
    
    /// Gets all NFTs owned by a recipient
    fn get_recipient_nfts(self: @TContractState, recipient: ContractAddress) -> Array<NFTReward>;
}