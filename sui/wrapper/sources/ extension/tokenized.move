#[allow(unused_use,duplicate_alias)]
/// Module: tokenized
module wrapper::tokenized {
    use std::type_name;
    use std::option::{Self};
    use std::ascii::{Self};

    use sui::url::{Self, Url};
    use sui::table::{Self,Table};
    use sui::coin::{Self, Coin, TreasuryCap};
    use wrapper::wrapper::{Wrapper};

    // === One Time Witness ===
    public struct TOKENIZED has drop{}
    
    // tokenized module name prefix
    const PREFIX: vector<u8> = b"T_";

    // === Error Codes ===
    const EWRAPPER_ALREADY_REGISTERED: u64 = 0;
    const EWRAPPER_ALREADY_LOCKED: u64 = 1;
    const EWRAPPER_NOT_TOKENIZED: u64 = 2;
    const EWRAPPER_ID_MISMATCH: u64 = 3;
    const ESENDER_NOT_OWNER: u64 = 4;
    const ETOKEN_SUPPLY_MISMATCH: u64 = 5;
    const ECANNOT_UNLOCK_NON_ZERO_SUPPLY: u64 = 6;

    /// WrapperTokenized is a wrapper around a tokenized object
    public struct WrapperTokenized<phantom T> has key, store {
        id: UID,
        treasury: TreasuryCap<T>,
        wrapper: Option<Wrapper>,
        owner: Option<address>,
        tokenized_object: address,
        total_supply: u64,
    }
    
    /// Register a tokenized Coin for a given tokenized object
    /// Allow many WrapperTokenized for a tokenized object
    public fun register<T: drop>(
        witness: T,
        decimals: u8,
        symbol: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        icon_url: Option<Url>,
        tokenized_object: address,
        ctx: &mut TxContext
    ) {
        // check tokenized object is equal to witness type name
        assert!(type_name::get_module(&type_name::get<T>()).into_bytes() == tokenized_object_module_name(tokenized_object), EWRAPPER_ALREADY_REGISTERED);
    
        // create a new currency
        let (treasury, metadata) = coin::create_currency(witness,decimals,symbol,name,description,icon_url,ctx);
        transfer::public_freeze_object(metadata);

        // share the tokenized object wrapper with the treasury
        transfer::public_share_object(
            WrapperTokenized{
                id: object::new(ctx),
                treasury: treasury,
                wrapper: option::none(),
                total_supply: 0,
                tokenized_object: tokenized_object,
                owner: option::none(),
            });
    }

    

    /// Lock a wrapper and take ownership of the wrapper
    /// must give a wrapper that uid equal to tokenized_object
    public entry fun lock<T>(wt: &mut WrapperTokenized<T>,total_supply:u64, w: Wrapper, ctx: &mut TxContext) {
        // check if wrapper is already locked,must be none
        assert!(wt.wrapper.is_none(), EWRAPPER_ALREADY_LOCKED);
        // check if wrapper id is equal to tokenized_object
        assert!(object::id_address(&w) == wt.tokenized_object, EWRAPPER_ID_MISMATCH);
    
        // fill the wrapper and owner
        option::fill(&mut wt.wrapper, w);
        option::fill(&mut wt.owner, tx_context::sender(ctx));

        // mint total supply of tokenized wrapper
        wt.total_supply = total_supply;
    }


    /// Unlock a wrapper
    /// must burn total supply of tokenized wrapper
    public entry fun unlock<T>(wt: &mut WrapperTokenized<T>, ctx: &mut TxContext) {
        // check if wrapper is locked,must be some
        assert!(wt.wrapper.is_some(), EWRAPPER_NOT_TOKENIZED);
        // check if sender is owner
        check_owner(wt, ctx);

        // burn total supply of tokenized wrapper
        let total_supply = wt.treasury.total_supply();
        assert!(total_supply == wt.total_supply, ETOKEN_SUPPLY_MISMATCH);
        assert!(total_supply == 0, ECANNOT_UNLOCK_NON_ZERO_SUPPLY);

        // transfer ownership to sender
        let w: Wrapper = option::extract(&mut wt.wrapper);
        transfer::public_transfer(w, tx_context::sender(ctx));

        // clear owner
        option::extract(&mut wt.owner);
    }



    /// Mint token amount to the owner
    public entry fun mint<T>(wt: &mut WrapperTokenized<T>, value: u64, ctx: &mut TxContext) {
        // check if sender is owner
        check_owner(wt, ctx);
        // check if total supply is less than max supply
        check_token_supply(wt, value);
        // mint token
        let token = coin::mint(&mut wt.treasury, value, ctx);
        transfer::public_transfer(token, tx_context::sender(ctx));
    }

    /// Burn token amount from the owner
    public entry fun burn<T>(wt: &mut WrapperTokenized<T>, c: Coin<T>) {
        let burn_value = c.value();
        coin::burn(&mut wt.treasury, c);
        wt.total_supply = wt.total_supply - burn_value;
    }
    
    /// get the total supply of the tokenized object
    public fun total_supply<T>(wt: &WrapperTokenized<T>): u64 {
        wt.total_supply
    }

    /// get the current supply of the tokenized object
    public fun supply<T>(wt: &WrapperTokenized<T>): u64 {
        wt.treasury.total_supply()
    }
    
    public fun owner<T>(wt: &WrapperTokenized<T>): address {
        if (wt.owner.is_some()) {
            *option::borrow(&wt.owner)
        } else {
            @0x0
        }
    }


    /// tokenized_object_module_name returns the module name for a tokenized object
    fun tokenized_object_module_name(object:address):vector<u8>{
        let mut p = PREFIX;
        vector::append<u8>(&mut p,object.to_ascii_string().into_bytes());
        p
    }

    // === Check Functions ===

    /// check_owner checks if the sender is the owner of the tokenized object
    fun check_owner<T>(wt: &WrapperTokenized<T>, ctx: &TxContext) {
        assert!(tx_context::sender(ctx) == wt.owner.borrow(), ESENDER_NOT_OWNER);
    }
    /// check_token_supply checks if the token supply is less than the max supply
    fun check_token_supply<T>(wt: &WrapperTokenized<T>, value: u64) {
        let total_supply = wt.treasury.total_supply();
        assert!(value + total_supply < wt.total_supply, ETOKEN_SUPPLY_MISMATCH);
    }
}
