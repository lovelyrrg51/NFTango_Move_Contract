module overmind::nftango {
    use std::option;
    use std::option::Option;
    use std::string::String;
    use std::error;
    use std::vector;
    use std::signer;
    use aptos_framework::account;
    use aptos_token::token;
    use aptos_token::token::TokenId;

    //
    // Errors
    //
    const ERROR_NFTANGO_STORE_EXISTS: u64 = 0;
    const ERROR_NFTANGO_STORE_DOES_NOT_EXIST: u64 = 1;
    const ERROR_NFTANGO_STORE_IS_ACTIVE: u64 = 2;
    const ERROR_NFTANGO_STORE_IS_NOT_ACTIVE: u64 = 3;
    const ERROR_NFTANGO_STORE_HAS_AN_OPPONENT: u64 = 4;
    const ERROR_NFTANGO_STORE_DOES_NOT_HAVE_AN_OPPONENT: u64 = 5;
    const ERROR_NFTANGO_STORE_JOIN_AMOUNT_REQUIREMENT_NOT_MET: u64 = 6;
    const ERROR_NFTS_ARE_NOT_IN_THE_SAME_COLLECTION: u64 = 7;
    const ERROR_NFTANGO_STORE_DOES_NOT_HAVE_DID_CREATOR_WIN: u64 = 8;
    const ERROR_NFTANGO_STORE_HAS_CLAIMED: u64 = 9;
    const ERROR_NFTANGO_STORE_IS_NOT_PLAYER: u64 = 10;
    const ERROR_VECTOR_LENGTHS_NOT_EQUAL: u64 = 11;

    //
    // Data structures
    //
    struct NFTangoStore has key {
        creator_token_id: TokenId,
        // The number of NFTs (one more more) from the same collection that the opponent needs to bet to enter the game
        join_amount_requirement: u64,
        opponent_address: Option<address>,
        opponent_token_ids: vector<TokenId>,
        active: bool,
        has_claimed: bool,
        did_creator_win: Option<bool>,
        signer_capability: account::SignerCapability
    }

    //
    // Assert functions
    //
    public fun assert_nftango_store_exists(
        account_address: address,
    ) {
        // Assert that `NFTangoStore` exists
        assert!(exists<NFTangoStore>(account_address), error::invalid_state(ERROR_NFTANGO_STORE_DOES_NOT_EXIST));
    }

    public fun assert_nftango_store_does_not_exist(
        account_address: address,
    ) {
        // Assert that `NFTangoStore` does not exist
        assert!(!exists<NFTangoStore>(account_address), error::invalid_state(ERROR_NFTANGO_STORE_EXISTS));
    }

    public fun assert_nftango_store_is_active(
        account_address: address,
    ) acquires NFTangoStore {
        // Assert that `NFTangoStore.active` is active
        assert!(borrow_global<NFTangoStore>(account_address).active, error::invalid_argument(ERROR_NFTANGO_STORE_IS_NOT_ACTIVE));
    }

    public fun assert_nftango_store_is_not_active(
        account_address: address,
    ) acquires NFTangoStore {
        // Assert that `NFTangoStore.active` is not active
        assert!(!borrow_global<NFTangoStore>(account_address).active, error::invalid_argument(ERROR_NFTANGO_STORE_IS_ACTIVE));
    }

    public fun assert_nftango_store_has_an_opponent(
        account_address: address,
    ) acquires NFTangoStore {
        // Get `NFTangoStore.opponent_address`
        let opponent_address: Option<address> = borrow_global<NFTangoStore>(account_address).opponent_address;
        // Assert `NFTangoStore.opponent_address` is set
        assert!(option::is_some(&opponent_address), error::invalid_argument(ERROR_NFTANGO_STORE_DOES_NOT_HAVE_AN_OPPONENT));
    }

    public fun assert_nftango_store_does_not_have_an_opponent(
        account_address: address,
    ) acquires NFTangoStore {
        // Get `NFTangoStore.opponent_address`
        let opponent_address: Option<address> = borrow_global<NFTangoStore>(account_address).opponent_address;
        // Assert `NFTangoStore.opponent_address` is not set
        assert!(option::is_none(&opponent_address), error::invalid_argument(ERROR_NFTANGO_STORE_HAS_AN_OPPONENT));
    }

    public fun assert_nftango_store_join_amount_requirement_is_met(
        game_address: address,
        token_ids: vector<TokenId>,
    ) acquires NFTangoStore {
        // Get `NFTangoStore.join_amount_requirement` from game_address
        let join_amount_requirement: u64 = borrow_global<NFTangoStore>(game_address).join_amount_requirement;
        // Assert that `NFTangoStore.join_amount_requirement` is met
        assert!(vector::length(&token_ids) == join_amount_requirement, error::invalid_argument(ERROR_NFTANGO_STORE_JOIN_AMOUNT_REQUIREMENT_NOT_MET));
    }

    public fun assert_nftango_store_has_did_creator_win(
        game_address: address,
    ) acquires NFTangoStore {
        // Get `NFTangoStore.did_creator_win` from game_address
        let did_creator_win: Option<bool> = borrow_global<NFTangoStore>(game_address).did_creator_win;
        // Assert that `NFTangoStore.did_creator_win` is set
        assert!(option::is_none(&did_creator_win), error::invalid_argument(ERROR_NFTANGO_STORE_DOES_NOT_HAVE_DID_CREATOR_WIN));
    }

    public fun assert_nftango_store_has_not_claimed(
        game_address: address,
    ) acquires NFTangoStore {
        // Assert that `NFTangoStore.has_claimed` is false
        assert!(!borrow_global<NFTangoStore>(game_address).has_claimed, error::invalid_argument(ERROR_NFTANGO_STORE_HAS_CLAIMED));
    }

    public fun assert_nftango_store_is_player(account_address: address, game_address: address) acquires NFTangoStore {
        // `NFTangoStore.opponent_address`
        let opponent_address: Option<address> = borrow_global<NFTangoStore>(game_address).opponent_address;
        // Assert that `account_address` is either the equal to `game_address` or `NFTangoStore.opponent_address`
        assert!(account_address == game_address || account_address == *option::borrow(&opponent_address), error::invalid_argument(ERROR_NFTANGO_STORE_IS_NOT_PLAYER));
    }

    public fun assert_vector_lengths_are_equal(creator: vector<address>,
                                               collection_name: vector<String>,
                                               token_name: vector<String>,
                                               property_version: vector<u64>) {
        // Get length of creator
        let creator_length: u64 = vector::length(&creator);
        // Assert all vector lengths are equal
        assert!(vector::length(&collection_name) == creator_length, error::invalid_argument(ERROR_VECTOR_LENGTHS_NOT_EQUAL));
        assert!(vector::length(&token_name) == creator_length, error::invalid_argument(ERROR_VECTOR_LENGTHS_NOT_EQUAL));
        assert!(vector::length(&property_version) == creator_length, error::invalid_argument(ERROR_VECTOR_LENGTHS_NOT_EQUAL));
    }

    //
    // Entry functions
    //
    public entry fun initialize_game(
        account: &signer,
        creator: address,
        collection_name: String,
        token_name: String,
        property_version: u64,
        join_amount_requirement: u64
    ) {
        // Assert_nftango_store_does_not_exist
        assert_nftango_store_does_not_exist(signer::address_of(account));

        // Create resource account
        let (resource, signer_cap) = account::create_resource_account(account, vector::empty<u8>());
        // Get token::create_token_id_raw
        let token_id: TokenId = token::create_token_id_raw(
            creator,
            collection_name,
            token_name,
            property_version
        );

        // Opt in to direct transfer for resource account
        token::opt_in_direct_transfer(&resource, true);
        // Transfer NFT to resource account
        token::transfer(account, token_id, signer::address_of(&resource), 1);

        // move_to resource `NFTangoStore` to account signer
        move_to(account, NFTangoStore {
            creator_token_id: token_id,
            join_amount_requirement: join_amount_requirement,
            opponent_address: option::none<address>(),
            opponent_token_ids: vector::empty<TokenId>(),
            active: true,
            has_claimed: false,
            did_creator_win: option::none<bool>(),
            signer_capability: signer_cap
        });
    }

    public entry fun cancel_game(
        account: &signer,
    ) acquires NFTangoStore {
        // Get account address
        let account_address: address = signer::address_of(account);

        // Run assert_nftango_store_exists
        assert_nftango_store_exists(account_address);

        // Run assert_nftango_store_is_active
        assert_nftango_store_is_active(account_address);

        // Run assert_nftango_store_does_not_have_an_opponent
        assert_nftango_store_does_not_have_an_opponent(account_address);

        // Opt in to direct transfer for account
        token::opt_in_direct_transfer(account, true);

        // Get NFTangoStore
        let nftango_store = borrow_global_mut<NFTangoStore>(account_address);
        // Get Resource Account
        let resource_account: signer = account::create_signer_with_capability(&nftango_store.signer_capability);
        // Transfer NFT to account address
        token::transfer(&resource_account, nftango_store.creator_token_id, account_address, nftango_store.join_amount_requirement);

        // Set `NFTangoStore.active` to false
        nftango_store.active = false;
    }

    public fun join_game(
        account: &signer,
        game_address: address,
        creators: vector<address>,
        collection_names: vector<String>,
        token_names: vector<String>,
        property_versions: vector<u64>,
    ) acquires NFTangoStore {
        // Get account address
        let account_address: address = signer::address_of(account);

        // Run assert_vector_lengths_are_equal
        assert_vector_lengths_are_equal(creators, collection_names, token_names, property_versions);

        // Initialize Variables
        let i = 0;
        let nft_length: u64 = vector::length(&creators);
        let vc_token_ids: vector<TokenId> = vector::empty();
        // Loop through and create token_ids vector<TokenId>
        while(i < nft_length) {
            // Get TokenID
            let token_id: TokenId = token::create_token_id_raw(
                *vector::borrow(&creators, i),
                *vector::borrow(&collection_names, i),
                *vector::borrow(&token_names, i),
                *vector::borrow(&property_versions, i)
            );
            // Push TokenID
            vector::push_back(&mut vc_token_ids, token_id);

            // Update Index
            i = i + 1;
        };

        // Run assert_nftango_store_exists
        assert_nftango_store_exists(game_address);

        // Run assert_nftango_store_is_active
        assert_nftango_store_is_active(game_address);

        // Run assert_nftango_store_does_not_have_an_opponent
        assert_nftango_store_does_not_have_an_opponent(game_address);

        // Run assert_nftango_store_join_amount_requirement_is_met
        assert_nftango_store_join_amount_requirement_is_met(game_address, vc_token_ids);

        i = 0;
        // Get NFTangoStore
        let nftango_store = borrow_global_mut<NFTangoStore>(game_address);
        // Get Resource Account
        let resource_account: signer = account::create_signer_with_capability(&nftango_store.signer_capability);
        // Loop through token_ids and transfer each NFT to the resource account
        while (i < nft_length) {
            // Transfer each NFT to the resource account
            token::transfer(account, *vector::borrow(&vc_token_ids, i), signer::address_of(&resource_account), 1);

            // Update Index
            i = i + 1;
        };

        // Set `NFTangoStore.opponent_address` to account_address
        option::fill(&mut nftango_store.opponent_address, account_address);
        // Set `NFTangoStore.opponent_token_ids` to token_ids
        vector::append(&mut nftango_store.opponent_token_ids, vc_token_ids);
    }

    public entry fun play_game(account: &signer, did_creator_win: bool) acquires NFTangoStore {
        // Get account address
        let account_address: address = signer::address_of(account);

        // Run assert_nftango_store_exists
        assert_nftango_store_exists(account_address);

        // Run assert_nftango_store_is_active
        assert_nftango_store_is_active(account_address);
        
        // Run assert_nftango_store_has_an_opponent
        assert_nftango_store_has_an_opponent(account_address);

        // Get NFTangoStore
        let nftango_store = borrow_global_mut<NFTangoStore>(account_address);
        // Set `NFTangoStore.did_creator_win` to did_creator_win
        option::fill(&mut nftango_store.did_creator_win, did_creator_win);
        // TODO: set `NFTangoStore.active` to false
        nftango_store.active = false;
    }

    public entry fun claim(account: &signer, game_address: address) acquires NFTangoStore {
        // Get account & game address
        let account_address: address = signer::address_of(account);

        // Run assert_nftango_store_exists
        assert_nftango_store_exists(game_address);

        // Run assert_nftango_store_is_not_active
        assert_nftango_store_is_not_active(game_address);

        // Run assert_nftango_store_has_not_claimed
        assert_nftango_store_has_not_claimed(game_address);

        // Run assert_nftango_store_is_player
        assert_nftango_store_is_player(account_address, game_address);

        // Get NFTangoStore
        let nftango_store = borrow_global_mut<NFTangoStore>(game_address);
        // Get Resource Account
        let resource_account: signer = account::create_signer_with_capability(&nftango_store.signer_capability);
        // If the player won, send them all the NFTs
        if(*option::borrow(&nftango_store.did_creator_win) == true) {
            token::transfer(&resource_account, nftango_store.creator_token_id, account_address, 1);

            let i = 0;
            let nft_length: u64 = vector::length(&nftango_store.opponent_token_ids);
            while(i < nft_length) {
                // Transfer NFT to Player
                token::transfer(&resource_account, *vector::borrow(&nftango_store.opponent_token_ids, i), account_address, 1);

                // Update Index
                i = i + 1;
            };
        } else {
            let opponent_address: address = *option::borrow(&nftango_store.opponent_address);

            token::transfer(&resource_account, nftango_store.creator_token_id, opponent_address, 1);

            let i = 0;
            let nft_length: u64 = vector::length(&nftango_store.opponent_token_ids);
            while(i < nft_length) {
                // Transfer NFT to Player
                token::transfer(&resource_account, *vector::borrow(&nftango_store.opponent_token_ids, i), opponent_address, 1);

                // Update Index
                i = i + 1;
            };

        };

        // Set `NFTangoStore.has_claimed` to true
        nftango_store.has_claimed = true;
    }
}