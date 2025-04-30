#[starknet::contract]
pub mod NFTVerifier {
    use core::array::ArrayTrait;
    use core::option::OptionTrait;
    use core::option::Option;
    use core::traits::Into;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::storage::{
        Map, MutableVecTrait, StorageMapReadAccess, StoragePathEntry, StoragePointerReadAccess,
        StoragePointerWriteAccess, Vec, VecTrait,
    };
    
    #[event]
    use crowdchain_contracts::events::NFTVerifierEvent::Event;
    use crowdchain_contracts::events::NFTVerifierEvent::{
        NFTRegistered, DuplicateNFTAttempt
    };
    
    use crowdchain_contracts::interfaces::INFTVerifier::INFTVerifier;
    use crowdchain_contracts::structs::Structs::NFTReward;

    #[storage]
    struct Storage {
        /// Maps token_id to NFTReward
        nft_registry: Map<u128, NFTReward>,
        
        /// Maps campaign_id to an array of token_ids
        campaign_nfts: Map<u32, Vec<u128>>,
        
        /// Maps recipient address to an array of token_ids
        recipient_nfts: Map<ContractAddress, Vec<u128>>,
        
        /// Maps (campaign_id, recipient) to a boolean indicating if the recipient has an NFT for the campaign
        campaign_recipient_nfts: Map<(u32, ContractAddress), bool>,
        
        /// Admin address
        admin: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, admin: ContractAddress) {
        self.admin.write(admin);
    }

    #[abi(embed_v0)]
    impl NFTVerifier of INFTVerifier<ContractState> {
        fn verify_nft_uniqueness(self: @ContractState, token_id: u128) -> bool {
            // Check if the token_id already exists in the registry
            let nft_exists = self.nft_registry.contains(token_id);
            return !nft_exists;
        }
        
        fn register_nft(
            ref self: ContractState, 
            campaign_id: u32, 
            recipient: ContractAddress, 
            token_id: u128, 
            tier: u8, 
            metadata_uri: felt252
        ) -> bool {
            // First, verify that the NFT is unique
            if !self.verify_nft_uniqueness(token_id) {
                // Emit an event for the duplicate attempt
                self.emit(Event::DuplicateNFTAttempt(DuplicateNFTAttempt {
                    campaign_id,
                    recipient,
                    token_id,
                }));
                return false;
            }
            
            // Create the NFT reward
            let nft_reward = NFTReward {
                campaign_id,
                recipient,
                token_id,
                tier,
                claimed: false,
                metadata_uri,
            };
            
            // Register the NFT in the registry
            self.nft_registry.write(token_id, nft_reward);
            
            // Add the token_id to the campaign's NFTs
            let mut campaign_tokens = self.campaign_nfts.entry(campaign_id);
            campaign_tokens.push(token_id);
            
            // Add the token_id to the recipient's NFTs
            let mut recipient_tokens = self.recipient_nfts.entry(recipient);
            recipient_tokens.push(token_id);
            
            // Mark that the recipient has an NFT for this campaign
            self.campaign_recipient_nfts.write((campaign_id, recipient), true);
            
            // Emit an event for the successful registration
            self.emit(Event::NFTRegistered(NFTRegistered {
                campaign_id,
                recipient,
                token_id,
                tier,
            }));
            
            return true;
        }
        
        fn nft_exists_for_campaign(self: @ContractState, campaign_id: u32, token_id: u128) -> bool {
            // Check if the token_id exists in the registry
            if !self.nft_registry.contains(token_id) {
                return false;
            }
            
            // Get the NFT reward
            let nft_reward = self.nft_registry.read(token_id);
            
            // Check if the NFT is associated with the given campaign
            return nft_reward.campaign_id == campaign_id;
        }
        
        fn recipient_has_nft_for_campaign(self: @ContractState, campaign_id: u32, recipient: ContractAddress) -> bool {
            // Check if the recipient has an NFT for the given campaign
            return self.campaign_recipient_nfts.read((campaign_id, recipient));
        }
        
        fn get_nft_by_token_id(self: @ContractState, token_id: u128) -> Option<NFTReward> {
            // Check if the token_id exists in the registry
            if !self.nft_registry.contains(token_id) {
                return Option::None;
            }
            
            // Get the NFT reward
            let nft_reward = self.nft_registry.read(token_id);
            return Option::Some(nft_reward);
        }
        
        fn get_campaign_nfts(self: @ContractState, campaign_id: u32) -> Array<NFTReward> {
            let mut nfts = ArrayTrait::new();
            let campaign_tokens = self.campaign_nfts.entry(campaign_id);
            let len = campaign_tokens.len();
            
            let mut i = 0;
            while i < len {
                if let Option::Some(token_id_path) = campaign_tokens.get(i) {
                    let token_id = token_id_path.read();
                    let nft_reward = self.nft_registry.read(token_id);
                    nfts.append(nft_reward);
                }
                i += 1;
            }
            
            return nfts;
        }
        
        fn get_recipient_nfts(self: @ContractState, recipient: ContractAddress) -> Array<NFTReward> {
            let mut nfts = ArrayTrait::new();
            let recipient_tokens = self.recipient_nfts.entry(recipient);
            let len = recipient_tokens.len();
            
            let mut i = 0;
            while i < len {
                if let Option::Some(token_id_path) = recipient_tokens.get(i) {
                    let token_id = token_id_path.read();
                    let nft_reward = self.nft_registry.read(token_id);
                    nfts.append(nft_reward);
                }
                i += 1;
            }
            
            return nfts;
        }
    }

    #[generate_trait]
    impl Private of PrivateTrait {
        fn assert_is_admin(self: @ContractState) {
            let caller = get_caller_address();
            let admin = self.admin.read();
            assert(caller == admin, 'Caller is not admin');
        }
    }
}