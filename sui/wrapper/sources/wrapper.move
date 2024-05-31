/// Module: wrapper
/// Github: https://github.com/0xWrapper/wrapper
/// Provides functionality for managing a collection of objects within a "Wrapper".
/// This module includes functionalities to wrap, unwrap, merge, split, and manage items in a Wrapper.
/// It handles different kinds of objects and ensures that operations are type-safe.
module wrapper::wrapper {
    use std::type_name;
    use sui::dynamic_object_field as dof;
    use sui::dynamic_field as df;
    use sui::display;
    use sui::package;

    // == tokenized ==
    // use wrapper::wrapper::{Wrapper};
    // use std::type_name;
    use std::option::{Self};
    use std::ascii::{Self};

    use sui::url::{Self, Url};
    use sui::table::{Self,Table};
    use sui::coin::{Self, Coin, TreasuryCap};


    // ===== Error Codes =====
    const EItemNotFound: u64 = 0;
    const EIndexOutOfBounds: u64 = 1;
    const EItemNotSameKind: u64 = 2;
    const EItemNotFoundOrNotSameKind: u64 = 3;
    const EWrapperNotEmpty: u64 = 4;
    const EWrapperNotEmptyOrINKSciption: u64 = 5;

    const EMPTY_WRAPPER_KIND: vector<u8> = b"EMPTY WRAPPER";
    const INKSCRIPTION_WRAPPER_KIND: vector<u8> = b"INKSCRIPTION WRAPPER";
    const TOKENIZED_WRAPPER_KIND: vector<u8> = b"TOKENIZED WRAPPER";

    // ===== Wrapper Core Struct =====

    /// A one-time witness object used for claiming packages and transferring ownership within the Sui framework.
    /// This object is used to initialize and setup the display and ownership of newly created Wrappers.
    public struct WRAPPER has drop {}

    /// Represents a container for managing a set of objects.
    /// Each object is identified by an ID and the Wrapper tracks the type of objects it contains.
    /// Fields:
    /// - `id`: Unique identifier for the Wrapper.
    /// - `kind`: ASCII string representing the type of objects the Wrapper can contain.
    /// - `alias`: UTF8 encoded string representing an alias for the Wrapper.
    /// - `items`: Vector of IDs or Other Bytes representing the objects wrapped.
    /// - `image`: Image of the Wrapper.
    public struct Wrapper has key, store {
        id: UID,
        kind: std::ascii::String, //type of wrapped object
        alias: std::string::String, // alias for the Wrapper
        items: vector<vector<u8>>, // wrapped object ids
        image: std::string::String, // image url for the Wrapper
    }

    // ===== Inital functions =====

    #[lint_allow(self_transfer)]
    /// Initializes a new Wrapper and sets up its display and publisher.
    /// Claims a publisher using the provided WRAPPER object and initializes the display.
    /// Parameters:
    /// - `witness`: A one-time witness object for claiming the package.
    /// - `ctx`: Transaction context for managing blockchain-related operations.
    /// Effect:
    /// - Transfers the ownership of the publisher and display to the transaction sender.
    fun init(witness: WRAPPER, ctx:&mut TxContext){
        let publisher = package::claim(witness,ctx);
        let keys = vector[
            std::string::utf8(b"kind"),
            std::string::utf8(b"alias"),
            std::string::utf8(b"items"),
            std::string::utf8(b"image_url"),
            std::string::utf8(b"project_url"),
        ];
        let values = vector[
            std::string::utf8(b"{kind}"),
            std::string::utf8(b"{alias}"),
            std::string::utf8(b"{items}"),
            std::string::utf8(b"{image}"),
            std::string::utf8(b"https://wrapper.space"),
        ];
        let mut display = display::new_with_fields<Wrapper>(&publisher,keys,values,ctx);
        display::update_version<Wrapper>(&mut display);
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
        // Genesis Wrapper
        inception(ctx);
    }

    /// Creates a new Wrapper with the INKSCRIPTION kind.
    fun inception(ctx: &mut TxContext) {
        let mut inception = new(ctx);
        inception.kind = std::ascii::string(b"INCEPTION WRAPPER");
        inception.alias = std::string::utf8(b"The Dawn of Wrapper Protocol");
        let mut poem = inception.items;
        vector::push_back(&mut poem, b"In Genesis, the birth of vision's light,");
        vector::push_back(&mut poem, b"Prime movers seek the endless flight.");
        vector::push_back(&mut poem, b"Origin of dreams in tokens cast,");
        vector::push_back(&mut poem, b"Alpha minds, forging futures vast.");

        vector::push_back(&mut poem, b"Pioneers of liquidity's rise,");
        vector::push_back(&mut poem, b"Inception's brilliance in our eyes.");
        vector::push_back(&mut poem, b"First steps in a realm so grand,");
        vector::push_back(&mut poem, b"Proto solutions, deftly planned.");

        vector::push_back(&mut poem, b"Founding pillars of trust and trade,");
        vector::push_back(&mut poem, b"Eureka moments that never fade.");
        vector::push_back(&mut poem, b"In Wrapper's embrace, assets entwine,");
        vector::push_back(&mut poem, b"Revolution in every design.");

        vector::push_back(&mut poem, b"Smart contracts, decentralized might,");
        vector::push_back(&mut poem, b"Liquidity pools, shining bright.");
        vector::push_back(&mut poem, b"Tokenization's seamless grace,");
        vector::push_back(&mut poem, b"In every swap, a better place.");

        vector::push_back(&mut poem, b"Yield and NFTs display,");
        vector::push_back(&mut poem, b"In dynamic, flexible sway.");
        vector::push_back(&mut poem, b"From blind boxes to swap's exchange,");
        vector::push_back(&mut poem, b"In Wrapper's world, nothing's strange.");

        vector::push_back(&mut poem, b"Cross-chain bridges, assets glide,");
        vector::push_back(&mut poem, b"Security, our trusted guide.");
        vector::push_back(&mut poem, b"Community's voice, governance strong,");
        vector::push_back(&mut poem, b"Together we thrive, our path is long.");

        vector::push_back(&mut poem, b"In Genesis, we lay the ground,");
        vector::push_back(&mut poem, b"Prime visions in Wrapper found.");
        vector::push_back(&mut poem, b"With every step, we redefine,");
        vector::push_back(&mut poem, b"A future bright, in Wrapper's line.");
        transfer::public_transfer(inception, tx_context::sender(ctx));
    }

    // ===== Basic Functions =====

    /// Creates a new, empty Wrapper.
    /// Parameters:
    /// - `ctx`: Transaction context used for creating the Wrapper.
    /// Returns:
    /// - A new Wrapper with no items and a generic kind.
    public fun new(ctx: &mut TxContext): Wrapper {
        Wrapper {
            id: object::new(ctx),
            kind: std::ascii::string(EMPTY_WRAPPER_KIND),
            alias: std::string::utf8(EMPTY_WRAPPER_KIND),
            items: vector[],
            image: std::string::utf8(b""),
        }
    }

    /// Destroys the Wrapper, ensuring it is empty before deletion.
    /// Parameters:
    /// - `w`: The Wrapper to destroy.
    /// Effects:
    /// - The Wrapper and its identifier are deleted.
    /// Errors:
    /// - `EWrapperNotEmpty`: If the Wrapper is not empty at the time of destruction.
    public fun destroy_empty(w: Wrapper) {
        // remove all items from the Wrapper
        assert!(w.is_empty(), EWrapperNotEmpty);
        // delete the Wrapper
        let Wrapper { id, kind: _, alias:_, items:_,  image:_ } = w;
        id.delete();
    }

    // ===== Basic Check functions =====

    /// Checks if the specified type T matches the kind of items stored in the Wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - True if the type T matches the Wrapper's kind, false otherwise.
    public fun is_same_kind<T: key + store>(w: &Wrapper): bool {
        w.kind == type_name::into_string(type_name::get<T>())
    }

    /// Checks if the Wrapper is empty.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - True if the Wrapper contains no items, false otherwise.
    public fun is_empty(w: &Wrapper): bool {
        w.kind == std::ascii::string(EMPTY_WRAPPER_KIND) || w.count() == 0
    }

    // ===== Basic property functions =====

    /// Retrieves the kind of objects contained within the Wrapper.
    /// Returns an ASCII string representing the type of the wrapped objects.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - ASCII string indicating the kind of objects in the Wrapper.
    public fun kind(w: &Wrapper): std::ascii::String {
        w.kind
    }

    /// Retrieves the alias of the Wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - UTF8 encoded string representing the alias of the Wrapper.
    public fun alias(w: &Wrapper): std::string::String {
        w.alias
    }

    /// Retrieves all object IDs contained within the Wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - A vector of some items or IDs representing all objects within the Wrapper.
    public fun items(w: &Wrapper): vector<vector<u8>> {
        w.items
    }

    /// Returns the number of objects contained within the Wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - The count of items in the Wrapper as a 64-bit unsigned integer.
    public fun count(w: &Wrapper): u64 {
        w.items.length()
    }

    /// Retrieves the ID of the object at a specified index within the Wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// - `i`: Index of the item to retrieve.
    /// Returns:
    /// - item or ID of the object at the specified index.
    /// Errors:
    /// - `EIndexOutOfBounds`: If the provided index is out of bounds.
    public fun item(w: &Wrapper, i: u64): vector<u8> {
        if (w.count() <= i) {
            abort EIndexOutOfBounds
        }else{
            w.items[i]
        }
    }

    // ===== Basic Public Entry functions =====

    /// Sets a new alias for the Wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `alias`: New alias to set for the Wrapper.
    /// Effects:
    /// - Updates the alias field of the Wrapper.
    public entry fun set_alias(w: &mut Wrapper, alias: std::string::String) {
        w.alias = alias;
    }

    /// Sets a new image for the Wrapper
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `image`: New image to set for the Wrapper.
    /// Effects:
    /// - Updates the image field of the Wrapper.
    public entry fun set_image(w: &mut Wrapper, image: std::string::String) {
        w.image = image;
    }


    // =============== Ink Extension Functions ===============

    // ===== Ink Check functions =====

    /// Checks if the Wrapper is inkscription.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - True if the Wrapper only contains items, false otherwise.
    public fun is_inkscription(w: &Wrapper): bool {
        w.kind == std::ascii::string(INKSCRIPTION_WRAPPER_KIND)
    }

    // ===== Ink Public Entry functions =====
    
    /// Appends an ink inscription to the Wrapper.
    /// Ensures that the operation is type-safe and the Wrapper is either empty or already contains ink inscriptions.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `ink`: The string to be inscribed.
    /// Errors:
    /// - `EWrapperNotEmptyOrINKSciption`: If the Wrapper is neither empty nor an inscription.
    public entry fun inkscribe(w: &mut Wrapper, mut ink:vector<std::string::String>) {
        assert!(w.is_inkscription() || w.is_empty(), EWrapperNotEmptyOrINKSciption);
        if (w.is_empty()) {
            w.kind = std::ascii::string(INKSCRIPTION_WRAPPER_KIND)
        };
        while (ink.length() > 0){
            vector::push_back(&mut w.items, *ink.pop_back().bytes());
        };
        ink.destroy_empty();
    }

    /// Removes an ink inscription from the Wrapper at a specified index.
    /// Ensures that the operation is type-safe and the index is within bounds.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `index`: Index of the inscription to remove.
    /// Errors:
    /// - `EWrapperNotEmptyOrINKSciption`: If the Wrapper is not an inscription.
    /// - `EIndexOutOfBounds`: If the index is out of bounds.
    public entry fun erase(w: &mut Wrapper, index: u64) {
        assert!(w.is_inkscription(), EWrapperNotEmptyOrINKSciption);
        assert!(w.count() > index, EIndexOutOfBounds);
        vector::remove(&mut w.items, index);
        if (w.count() == 0) {
            w.kind = std::ascii::string(EMPTY_WRAPPER_KIND)
        };
    }

    /// Shred all ink inscriptions in the Wrapper, effectively clearing it.
    /// Ensures that the operation is type-safe and the Wrapper is either empty or already contains ink inscriptions.
    /// Parameters:
    /// - `w`: The Wrapper to be burned.
    /// Errors:
    /// - `EWrapperNotEmptyOrINKSciption`: If the Wrapper is neither empty nor an ink inscription.
    public entry fun shred(mut w: Wrapper) {
        assert!(w.is_inkscription() || w.is_empty(), EWrapperNotEmptyOrINKSciption);
        while (w.count() > 0) {
            vector::pop_back(&mut w.items);
        };
        w.destroy_empty()
    }
    

    // =============== Object Extension Functions ===============

    /// Represents a dynamic field key for an item in a Wrapper.
    /// Each item in a Wrapper has a unique identifier of type ID.
    public struct Item has store, copy, drop { id: ID }

    // ===== Object Check functions =====
    
    /// Checks if an item with the specified ID exists within the Wrapper and is of type T.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// - `id`: ID of the item to check.
    /// Returns:
    /// - True if the item exists and is of type T, false otherwise.
    public fun has_item_with_type<T: key + store>(w: &Wrapper, id: ID): bool {
        dof::exists_with_type<Item, T>(&w.id, Item { id }) && w.items.contains(&id.to_bytes()) && w.is_same_kind<T>()
    }

    // ===== Object property functions =====

    #[syntax(index)]
    /// Borrow an immutable reference to the item at a specified index within the Wrapper.
    /// Ensures the item exists and is of type T before borrowing.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// - `i`: Index of the object to borrow.
    /// Returns:
    /// - Immutable reference to the item of type T.
    /// Errors:
    /// - `EItemNotFoundOrNotSameKind`: If no item exists at the index or if the item is not of type T.
    public fun borrow<T:store + key>(w: &Wrapper,i: u64): &T {
        let id = object::id_from_bytes(w.item(i));
        assert!(w.has_item_with_type<T>(id), EItemNotFoundOrNotSameKind);
        dof::borrow(&w.id, Item { id })
    }

    #[syntax(index)]
    /// Borrow a mutable reference to the item at a specified index within the Wrapper.
    /// Ensures the item exists and is of type T before borrowing.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `i`: Index of the object to borrow.
    /// Returns:
    /// - Mutable reference to the item of type T.
    /// Errors:
    /// - `EItemNotFoundOrNotSameKind`: If no item exists at the index or if the item is not of type T.
    public fun borrow_mut<T:store + key>(w: &mut Wrapper, i: u64): &mut T {
        let id = object::id_from_bytes(w.item(i));
        assert!(w.has_item_with_type<T>(id), EItemNotFoundOrNotSameKind);
        dof::borrow_mut(&mut w.id, Item { id })
    }


    // ===== Object Public Entry functions =====
    
    /// Wraps object list into a new Wrapper.
    /// Parameters:
    /// - `w`: The Wrapper to unwrap.
    /// - `object`: The object to wrap.
    /// Returns:
    /// - all objects of type T warp the Wrapper.
    /// Errors:
    /// - `EItemNotSameKind`: If any contained item is not of type T.
    public entry fun wrap<T: store + key>(w:&mut Wrapper, mut objects:vector<T>){
        assert!(w.is_same_kind<T>(), EItemNotSameKind);
        // add the object to the Wrapper
        while (objects.length() > 0){
            w.add(objects.pop_back());
        };
        objects.destroy_empty();
    }

    /// TODO: USE THE INCEPTION WRAPPER TOKENIZED COIN TO UNWRAP
    /// Unwraps all objects from the Wrapper, ensuring all are of type T, then destroys the Wrapper.
    /// Parameters:
    /// - `w`: The Wrapper to unwrap.
    /// Returns:
    /// - Vector of all objects of type T from the Wrapper.
    /// Errors:
    /// - `EItemNotSameKind`: If any contained item is not of type T.
    public entry fun unwrap<T:store + key>(mut w: Wrapper, ctx: &mut TxContext) {
        assert!(w.is_same_kind<T>(), EItemNotSameKind);
        // unwrap all objects from the Wrapper
        while (w.count() > 0){
            transfer::public_transfer(w.remove<T>(0), ctx.sender());
        };
        // destroy the Wrapper
        w.destroy_empty();
    }

    /// Adds a single object to the Wrapper. If the Wrapper is empty, sets the kind based on the object's type.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `object`: The object to add to the Wrapper.
    /// Effects:
    /// - The object is added to the Wrapper, and its ID is stored.
    /// Errors:
    /// - `EItemNotSameKind`: If the Wrapper is not empty and the object's type does not match the Wrapper's kind.
    public entry fun add<T:store + key>(w: &mut Wrapper, object:T) {
        // check the object's kind
        if (w.kind == std::ascii::string(EMPTY_WRAPPER_KIND)) {
            w.kind = type_name::into_string(type_name::get<T>())
        } else {
            assert!(w.is_same_kind<T>(), EItemNotSameKind)
        };
        // add the object to the Wrapper
        let oid = object::id(&object);
        dof::add(&mut w.id, Item{ id: oid }, object);
        w.items.push_back(oid.to_bytes());
    }

    /// Transfers all objects from one Wrapper (`self`) to another (`w`).
    /// Both Wrappers must contain items of the same type T.
    /// Parameters:
    /// - `self`: Mutable reference to the source Wrapper.
    /// - `w`: Mutable reference to the destination Wrapper.
    /// Effects:
    /// - Objects are moved from the source to the destination Wrapper.
    /// - The source Wrapper is left empty after the operation.
    /// Errors:
    /// - `EItemNotSameKind`: If the Wrappers do not contain the same type of items.
    public entry fun shift<T: store + key>(self:&mut Wrapper, w: &mut Wrapper) {
        assert!(self.is_same_kind<T>(), EItemNotSameKind);
        while (self.count() > 0){
            w.add(self.remove<T>(0));
        };
    }

    // ===== Object Internal functions =====
    
    /// Removes an object from the Wrapper at a specified index and returns it.
    /// Checks that the operation is type-safe.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `i`: Index of the item to remove.
    /// Returns:
    /// - The object of type T removed from the Wrapper.
    /// Effects:
    /// - If the Wrapper is empty after removing the item, its kind is set to an empty string.
    /// Errors:
    /// - `EItemNotSameKind`: If the item type does not match the Wrapper's kind.
    public(package) fun remove<T:store + key>(w: &mut Wrapper, i: u64): T {
        assert!(w.count() > i, EIndexOutOfBounds);
        assert!(w.is_same_kind<T>(), EItemNotSameKind);
        // remove the item from the Wrapper
        let id = object::id_from_bytes(w.item(i));
        let object:T = dof::remove<Item,T>(&mut w.id, Item { id });
        w.items.swap_remove(i);
        // if the Wrapper is empty, set the kind to empty
        if (w.count() == 0) {
            w.kind = std::ascii::string(EMPTY_WRAPPER_KIND)
        };
        object
    }

    /// Removes and returns a single object from the Wrapper by its ID.
    /// Ensures the object exists and is of type T.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `id`: ID of the object to remove.
    /// Returns:
    /// - The object of type T.
    /// Errors:
    /// - `EItemNotFound`: If no item with the specified ID exists.
    public(package) fun take<T:store + key>(w: &mut Wrapper, id: ID): T {
        assert!(w.has_item_with_type<T>(id), EItemNotFound);
        // remove the item from the Wrapper
        let (has_item,index) = w.items.index_of(&id.to_bytes());
        if (has_item) {
            w.remove(index)
        }else{
            abort EItemNotFound 
        }
    }

    // ===== Object Public functions =====

    /// Merges two Wrappers into one. If both Wrappers are of the same kind, merges the smaller into the larger.
    /// If they are of different kinds or if one is empty, handles accordingly.
    /// If the two Wrappers have the same kind, merge the less Wrapper into the greater Wrapper.
    /// Otherwise, create a new Wrapper and add the two Wrappers.
    /// If the two Wrappers are empty, return an empty Wrapper.
    /// If one Wrapper is empty, return the other Wrapper.
    /// Parameters:
    /// - `w1`: First Wrapper to merge.
    /// - `w2`: Second Wrapper to merge.
    /// - `ctx`: Transaction context.
    /// Returns:
    /// - A single merged Wrapper.
    /// Errors:
    /// - `EItemNotSameKind`: If the Wrappers contain different kinds of items and cannot be merged.
    public fun merge<T:store + key>(mut w1: Wrapper, mut w2: Wrapper, ctx: &mut TxContext): Wrapper{
        let kind = type_name::into_string(type_name::get<T>());
        // if one of the Wrappers is empty, return the other Wrapper
        if (w1.is_empty()) {
            w1.destroy_empty();
            w2
        } else if (w2.is_empty()) {
            w2.destroy_empty();
            w1
        } else if (w1.kind == w2.kind && w2.kind == kind) {
            // check the count of the two Wrappers
            if (w1.count() > w2.count()) {
                w2.shift<T>(&mut w1);
                w2.destroy_empty();
                w1
            } else {
                w1.shift<T>(&mut w2);
                w1.destroy_empty();
                w2
            }
        } else {
            // create a new Wrapper
            let mut w = new(ctx);
            w.add(w1);
            w.add(w2);
            w
        }
    }

    /// Splits objects from the Wrapper based on the specified list of IDs, moving them into a new Wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the original Wrapper.
    /// - `ids`: Vector of IDs indicating which items to split.
    /// - `ctx`: Transaction context.
    /// Returns:
    /// - A new Wrapper containing the split items.
    /// Errors:
    /// - `EItemNotFoundOrNotSameKind`: If any specified ID does not exist or the item is not of the expected type.
    public fun split<T:store + key>(w: &mut Wrapper,mut ids: vector<ID>, ctx: &mut TxContext): Wrapper{
        // create a new Wrapper
        let mut w2 = new(ctx);
        // take the objects from the first Wrapper and add them to the second Wrapper
        while (ids.length() > 0){
            assert!(w.has_item_with_type<T>(ids[ids.length()-1]), EItemNotFoundOrNotSameKind);
            w2.add(w.take<T>(ids.pop_back()));
        };
        ids.destroy_empty();
        w2
    }

    // =============== Tokenized Extension Functions ===============

    public struct Lock has store, copy, drop {     
        id: ID,
        total_supply: u64,
        owner: Option<address>,
    }

    // tokenized module name prefix
    const WRAPPER_TOKENIZED_PREFIX: vector<u8> = b"T_";

    // === Error Codes ===
    const ENOT_TOKENIZED_WRAPPER: u64 = 0;
    const EWRAPPER_TOKENIZED_NOT_TREASURY: u64 = 1;
    const EWRAPPER_TOKENIZED_NOT_LOCK: u64 = 2;
    const EWRAPPER_TOKENIZED_MISMATCH: u64 = 3;
    const EWRAPPER_TOKENIZED_NOT_TOKENIZED: u64 = 4;
    const EWRAPPER_TOKENIZED_NOT_ACCESS: u64 = 5;
    const EWRAPPER_TOKENIZED_HAS_OWNER: u64 = 6;
    const ETOKEN_SUPPLY_MISMATCH: u64 = 7;
    const ECANNOT_UNLOCK_NON_ZERO_SUPPLY: u64 = 8;
    const EWRAPPER_TOKENIZED_HAS_TOKENIZED: u64 = 9;


    // === Tokenized Public Check Functions ===
    public fun is_tokenized(w: &Wrapper) {
        assert!(w.kind == std::ascii::string(TOKENIZED_WRAPPER_KIND), ENOT_TOKENIZED_WRAPPER);
    }

    fun have_treasury<T: drop>(wt: &Wrapper, id: ID) {
        is_tokenized(wt);
        assert!(dof::exists_with_type<Item, TreasuryCap<T>>(&wt.id, Item { id }) && wt.items.contains(&id.to_bytes()), EWRAPPER_TOKENIZED_NOT_TREASURY);
    }

    fun have_lock(wt: &Wrapper) {
        is_tokenized(wt);
        assert!(df::exists_with_type<Item, Lock>(&wt.id, Item { id:object::id(wt) }), EWRAPPER_TOKENIZED_NOT_LOCK);
    }

    fun check_tokenized_object<T: drop>(object: address) {
        let mut p = WRAPPER_TOKENIZED_PREFIX;
        vector::append<u8>(&mut p,object.to_ascii_string().into_bytes());
        assert!(type_name::get_module(&type_name::get<T>()).into_bytes() == p, EWRAPPER_TOKENIZED_MISMATCH);
    }
    
    fun has_wrapper(wt: &Wrapper, id: ID) {
        is_tokenized(wt);
        assert!(dof::exists_with_type<Item, Wrapper>(&wt.id, Item { id }) && vector::contains<vector<u8>>(&wt.items,&id.to_bytes()) , EWRAPPER_TOKENIZED_NOT_TOKENIZED);
    }

    fun not_wrapper(wt: &Wrapper, id: ID) {
        is_tokenized(wt);
        assert!(!dof::exists_with_type<Item, Wrapper>(&wt.id, Item { id }) && vector::contains<vector<u8>>(&wt.items,&id.to_bytes()) , EWRAPPER_TOKENIZED_HAS_TOKENIZED);
    }


    fun has_access(wt: &Wrapper, ctx: &TxContext) {
        is_tokenized(wt);
        let lock = df::borrow<Item,Lock>(&wt.id, Item { id: object::id(wt) });
        assert!(lock.owner.is_some() && ctx.sender() == lock.owner.borrow(),EWRAPPER_TOKENIZED_NOT_ACCESS)
    }

    fun not_owner(wt: &Wrapper) {
        is_tokenized(wt);
        let lock = df::borrow<Item,Lock>(&wt.id, Item { id: object::id(wt) });
        assert!(lock.owner.is_none(), EWRAPPER_TOKENIZED_HAS_OWNER);
    }

    // ===== Tokenized Public Entry functions =====

    public entry fun register<T: drop>(
        witness: T,
        decimals: u8,
        symbol: vector<u8>,
        name: vector<u8>,
        description: vector<u8>,
        icon_url: vector<u8>,
        object: address,
        ctx: &mut TxContext
    ) {
        // check tokenized object is equal to witness type name
        check_tokenized_object<T>(object);
        let icon_url = if (icon_url == b"") {
            option::none()
        } else {
            option::some(url::new_unsafe_from_bytes(icon_url))
        };
        // create a new currency
        let (treasury, metadata) = coin::create_currency(witness,decimals,symbol,name,description,icon_url,ctx);
        transfer::public_freeze_object(metadata);

        // share the tokenized object wrapper with the treasury
        tokenized<T>(treasury,object,ctx);
    }

    public entry fun tokenized<T: drop>(treasury:TreasuryCap<T>,object:address,ctx: &mut TxContext) {
        check_tokenized_object<T>(object);
        let mut wt = new(ctx);
        wt.kind = std::ascii::string(TOKENIZED_WRAPPER_KIND);
        wt.alias = std::string::from_ascii(type_name::get_module(&type_name::get<T>()));
        // core internal
        let oid = object::id_from_address(object);
        let tid = object::id(&treasury);
        let wtid = object::id(&wt);
        df::add(&mut wt.id,
            Item{ id: wtid },
            Lock { 
                id: oid,
                owner: option::none(),
                total_supply: 0,
            }
        );
        // add items ,but not dof add item,means not add to the object store
        wt.items.push_back(oid.to_bytes());
        // dof::add(&mut wt.id, Item{ id: oid }, wrapper_tokenized);
        // add treasury,means the treasury is in the object store
        wt.items.push_back(tid.to_bytes());
        dof::add(&mut wt.id, Item{ id: tid }, treasury);

        transfer::public_share_object(wt);
    }

    public entry fun lock<T: drop>(wt: &mut Wrapper,total_supply:u64, w: Wrapper, ctx: &mut TxContext) {
        // check if wrapper is not locked,must be none
        has_wrapper(wt,object::id(&w));
        // check if wrapper id is equal to tokenized_object
        not_owner(wt);

        // fill the wrapper and owner
        dof::add(&mut wt.id, Item{ id: object::id(&w) }, w);
        have_lock(wt);
        let wtid = object::id(wt);
        let mut lock = df::borrow_mut<Item,Lock>(&mut wt.id, Item { id: wtid });
        option::fill(&mut lock.owner, ctx.sender());
        // mint total supply of tokenized wrapper
        lock.total_supply = total_supply;
    }

    public entry fun unlock<T: drop>(wt: &mut Wrapper, ctx: &mut TxContext) {
        // check has access
        has_access(wt,ctx);
        // burn total supply of tokenized wrapper to unlock wrapper
        let total_supply = total_supply(wt);
        let treasury_supply = supply<T>(wt);
        assert!(total_supply == treasury_supply, ETOKEN_SUPPLY_MISMATCH);
        assert!(total_supply == 0, ECANNOT_UNLOCK_NON_ZERO_SUPPLY);

        // transfer ownership to sender
        let object_id = object::id_from_bytes(wt.item(0));
        has_wrapper(wt,object_id);
        let object: Wrapper = dof::remove<Item,Wrapper>(&mut wt.id, Item { id:object_id });
        transfer::public_transfer(object, tx_context::sender(ctx));

        // clear owner
        have_lock(wt);
        let wtid = object::id(wt);
        let mut lock = df::borrow_mut<Item,Lock>(&mut wt.id, Item { id: wtid });
        option::extract(&mut lock.owner);
    }

    public entry fun mint<T:drop>(wt: &mut Wrapper, value: u64, ctx: &mut TxContext) {
        // check has access
        has_access(wt,ctx);
        // check if total supply is less than max supply
        let total_supply = total_supply(wt);
        let treasury_supply = supply<T>(wt);
        assert!(value + treasury_supply < total_supply, ETOKEN_SUPPLY_MISMATCH);

        // mint token
        let treasury_id = object::id_from_bytes(wt.item(1));
        have_treasury<T>(wt,treasury_id);
        let mut treasury = dof::borrow_mut<Item,TreasuryCap<T>>(&mut wt.id, Item { id: treasury_id });
        let token = coin::mint(treasury, value, ctx);

        // transfer token to owner
        transfer::public_transfer(token, tx_context::sender(ctx));
    }

    public entry fun burn<T:drop>(wt: &mut Wrapper, c: Coin<T>) {
        is_tokenized(wt);

        // burn token
        let treasury_id = object::id_from_bytes(wt.item(1));
        have_treasury<T>(wt,treasury_id);
        let burn_value = c.value();
        let mut treasury = dof::borrow_mut<Item,TreasuryCap<T>>(&mut wt.id, Item { id: treasury_id });
        coin::burn(treasury, c);
        
        // update total supply
        have_lock(wt);
        let wtid = object::id(wt);
        let mut lock = df::borrow_mut<Item,Lock>(&mut wt.id, Item { id: wtid });
        lock.total_supply = lock.total_supply - burn_value;
    }

    public fun total_supply(wt: &Wrapper): u64 {
        have_lock(wt);
        let lock = df::borrow<Item,Lock>(&wt.id, Item { id: object::id(wt) });
        lock.total_supply
    }

    public fun supply<T:drop>(wt: &Wrapper): u64 {
        is_tokenized(wt);
        let treasury_id = object::id_from_bytes(wt.item(1));
        have_treasury<T>(wt,treasury_id);
        let treasury = dof::borrow<Item,TreasuryCap<T>>(&wt.id, Item { id: treasury_id });
        treasury.total_supply()
    }
}