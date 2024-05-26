/// Module: wrapper
/// Github: https://github.com/DefiBound/wrapper
/// Provides functionality for managing a collection of objects within a "Wrapper".
/// This module includes functionalities to wrap, unwrap, merge, split, and manage items in a Wrapper.
/// It handles different kinds of objects and ensures that operations are type-safe.
module wrapper::wrapper {
    use sui::dynamic_object_field as field;
    use sui::display;
    use sui::package;
    use sui::coin::{Coin};
    use std::type_name;

    // ===== Error Codes =====
    const EItemNotFound: u64 = 0;
    const EIndexOutOfBounds: u64 = 1;
    const EItemNotSameKind: u64 = 2;
    const EItemNotFoundOrNotSameKind: u64 = 3;
    const EWrapperNotEmpty: u64 = 4;

    // ===== Public types =====
        
    /// A one-time witness object used for claiming packages and transferring ownership within the Sui framework.
    /// This object is used to initialize and setup the display and ownership of newly created Wrappers.
    public struct WRAPPER has drop {}

    /// Represents a dynamic field key for an item in a Wrapper.
    /// Each item in a Wrapper has a unique identifier of type ID.
    public struct Item has store, copy, drop { id: ID }

    // ===== Wrapper Struct =====
    /// Represents a container for managing a set of objects.
    /// Each object is identified by an ID and the Wrapper tracks the type of objects it contains.
    /// Fields:
    /// - `id`: Unique identifier for the Wrapper.
    /// - `items`: Vector of IDs representing the objects wrapped.
    /// - `kind`: ASCII string representing the type of objects the Wrapper can contain.
    /// - `alias`: UTF8 encoded string representing an alias for the Wrapper.
    public struct Wrapper has key, store {
        id: UID,
        items: vector<ID>, // wrapped object ids
        kind: std::ascii::String, //type of wrapped object
        alias: std::string::String, // alias for the Wrapper
        image_url: std::string::String, // image url for the Wrapper
    }

    // ===== Public view functions =====

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
            std::string::utf8(b"alias"),
            std::string::utf8(b"kind"),
            std::string::utf8(b"image_url"),
            std::string::utf8(b"project_url"),
        ];
        let values = vector[
            std::string::utf8(b"{alias}"),
            std::string::utf8(b"{kind}"),
            std::string::utf8(b"{image_url}"),
            std::string::utf8(b"https://defibound.online"),
        ];
        let mut display = display::new_with_fields<Wrapper>(&publisher,keys,values,ctx);
        display::update_version<Wrapper>(&mut display);
        transfer::public_transfer(publisher, tx_context::sender(ctx));
        transfer::public_transfer(display, tx_context::sender(ctx));
    }


    // ===== property functions =====

    /// Retrieves the alias of the Wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - UTF8 encoded string representing the alias of the Wrapper.
    public fun alias(w: &Wrapper): std::string::String {
        w.alias
    }

    /// Retrieves the kind of objects contained within the Wrapper.
    /// Returns an ASCII string representing the type of the wrapped objects.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - ASCII string indicating the kind of objects in the Wrapper.
    public fun kind(w: &Wrapper): std::ascii::String {
        w.kind
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
    /// - ID of the object at the specified index.
    /// Errors:
    /// - `EIndexOutOfBounds`: If the provided index is out of bounds.
    public fun item(w: &Wrapper, i: u64): ID {
        if (w.count() <= i) {
            abort EIndexOutOfBounds
        }else{
            w.items[i]
        }
    }

    /// Retrieves all object IDs contained within the Wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// Returns:
    /// - A vector of IDs representing all objects within the Wrapper.
    public fun items(w: &Wrapper): vector<ID> {
        w.items
    }

    #[syntax(index)]
    /// Borrow an immutable reference to the item at a specified index within the Wrapper.
    /// Ensures the item exists and is of type T before borrowing.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// - `i`: Index of the item to borrow.
    /// Returns:
    /// - Immutable reference to the item of type T.
    /// Errors:
    /// - `EItemNotFoundOrNotSameKind`: If no item exists at the index or if the item is not of type T.
    public fun borrow<T:store + key>(w: &Wrapper,i: u64): &T {
        let id = w.item(i);
        assert!(w.has_item_with_type<T>(id), EItemNotFoundOrNotSameKind);
        field::borrow(&w.id, Item { id })
    }

    #[syntax(index)]
    /// Borrow a mutable reference to the item at a specified index within the Wrapper.
    /// Ensures the item exists and is of type T before borrowing.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `i`: Index of the item to borrow.
    /// Returns:
    /// - Mutable reference to the item of type T.
    /// Errors:
    /// - `EItemNotFoundOrNotSameKind`: If no item exists at the index or if the item is not of type T.
    public fun borrow_mut<T:store + key>(w: &mut Wrapper, i: u64): &mut T {
        let id = w.item(i);
        assert!(w.has_item_with_type<T>(id), EItemNotFoundOrNotSameKind);
        field::borrow_mut(&mut w.id, Item { id })
    }

    // ===== Check functions =====
    
    /// Checks if an item with the specified ID exists within the Wrapper.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// - `id`: ID of the item to check.
    /// Returns:
    /// - True if the item exists, false otherwise.
    public fun has_item(w: &Wrapper, id: ID): bool {
        field::exists_(&w.id, Item { id }) && w.items.contains(&id)
    }
    
    /// Checks if an item with the specified ID exists within the Wrapper and is of type T.
    /// Parameters:
    /// - `w`: Reference to the Wrapper.
    /// - `id`: ID of the item to check.
    /// Returns:
    /// - True if the item exists and is of type T, false otherwise.
    public fun has_item_with_type<T: key + store>(w: &Wrapper, id: ID): bool {
        field::exists_with_type<Item, T>(&w.id, Item { id }) && w.items.contains(&id) && w.is_same_kind<T>()
    }

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
        w.count() == 0 && w.kind == std::ascii::string(b"")
    }

    // ===== Public functions =====
    /// Sets a new alias for the Wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `alias`: New alias to set for the Wrapper.
    /// Effects:
    /// - Updates the alias field of the Wrapper.
    public entry fun set_alias(w: &mut Wrapper, alias: std::string::String) {
        w.alias = alias;
    }

    /// Sets a new image_url for the Wrapper
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `image_url`: New image_url to set for the Wrapper.
    /// Effects:
    /// - Updates the image_url field of the Wrapper.
    public entry fun set_image_url(w: &mut Wrapper, image_url: std::string::String) {
        w.image_url = image_url;
    }


    /// Sets a new image url for the Wrapper.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `image_url`: New image url to set for the Wrapper.
    /// Effects:
    /// - Updates the image_url field of the Wrapper.
    public entry fun set_image(w:&mut Wrapper, image_url: std::string::String){
        w.image_url = image_url;
    }

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
    public fun remove<T:store + key>(w: &mut Wrapper, i: u64): T {
        assert!(w.count() > i, EIndexOutOfBounds);
        assert!(w.is_same_kind<T>(), EItemNotSameKind);
        // remove the item from the Wrapper
        let id = w.item(i);
        let object:T = field::remove<Item,T>(&mut w.id, Item { id });
        w.items.swap_remove(i);

        // if the Wrapper is empty, set the kind to empty
        if (w.count() == 0) {
            w.kind = std::ascii::string(b"")
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
    public fun take<T:store + key>(w: &mut Wrapper, id: ID): T {
        assert!(w.has_item_with_type<T>(id), EItemNotFound);
        // remove the item from the Wrapper
        let (has_item,index) = w.items.index_of(&id);
        if (has_item) {
            w.remove(index)
        }else{
            abort EItemNotFound 
        }
    }

    /// Removes and returns all objects from the Wrapper.
    /// Ensures all objects are of type T.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// Returns:
    /// - Vector of all objects of type T from the Wrapper.
    public(package) fun take_all<T:store + key>(w: &mut Wrapper): vector<T> {
        let mut objects = vector[];
        while (w.count() > 0){
            objects.push_back(w.remove<T>(0));
        };
        objects
    }

    /// Adds a single object to the Wrapper. If the Wrapper is empty, sets the kind based on the object's type.
    /// Parameters:
    /// - `w`: Mutable reference to the Wrapper.
    /// - `object`: The object to add to the Wrapper.
    /// Effects:
    /// - The object is added to the Wrapper, and its ID is stored.
    /// Errors:
    /// - `EItemNotSameKind`: If the Wrapper is not empty and the object's type does not match the Wrapper's kind.
    public fun add<T:store + key>(w: &mut Wrapper, object:T) {
        // check the object's kind
        if (w.kind == std::ascii::string(b"")) {
            w.kind = type_name::into_string(type_name::get<T>())
        } else {
            assert!(w.is_same_kind<T>(), EItemNotSameKind)
        };
        // add the object to the Wrapper
        let oid = object::id(&object);
        field::add(&mut w.id, Item{ id: oid }, object);
        w.items.push_back(oid);
    }
    
    /// Creates a new, empty Wrapper.
    /// Parameters:
    /// - `ctx`: Transaction context used for creating the Wrapper.
    /// Returns:
    /// - A new Wrapper with no items and a generic kind.
    public fun new(ctx: &mut TxContext): Wrapper {
        Wrapper {
            id: object::new(ctx),
            items: vector[],
            kind: std::ascii::string(b""),
            alias: std::string::utf8(b""),
            image_url: std::string::utf8(b"data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='1000' height='1000' viewBox='0 0 120 120'%3E %3Cdefs%3E%3Cstyle%3E .st0 %7B fill: %23236D37; %7D .st1 %7B fill: %23C9CF79; %7D .st2 %7B fill: %237C9431; %7D .st3 %7B fill: %23FFFFFF; %7D %3C/style%3E%3Csymbol id='wrapper' viewBox='0 0 120 120'%3E%3Cpath class='st0' d='M83.49,110.3l-49.69-0.57c-2.14-0.02-4.09-1.21-5.1-3.09L5.2,62.84c-0.98-1.83-0.92-4.04,0.15-5.81L31.68,13.6 c1.08-1.77,3.01-2.85,5.08-2.82l49.69,0.57c2.14,0.02,4.09,1.21,5.1,3.09l23.49,43.8c0.98,1.83,0.92,4.04-0.15,5.81l-26.33,43.42 C87.49,109.25,85.56,110.32,83.49,110.3z' /%3E%3Cpath class='st1' d='M46.66,58.52c6.94,0.05,13.4-3.55,17-9.49L82.35,18.2c0.56-0.93-0.1-2.12-1.18-2.13l-37.22-0.46 c-4.79-0.06-9.25,2.42-11.73,6.51L11.59,56.13c-0.56,0.93,0.1,2.12,1.19,2.13L46.66,58.52z' /%3E%3Cpath class='st2' d='M28.64,94.19c2.99,6.11,8.98,10.01,15.77,10.26l34.86,0.62c1.06,0.04,1.82-1.12,1.36-2.08L64.46,71.21 c-2.04-4.23-6.17-6.93-10.85-7.1l-39.58-1.04c-1.06-0.04-1.82,1.13-1.35,2.08L28.64,94.19z' /%3E%3Cpath class='st3' d='M44.02,30.22c-10.62,6.14-16.61,17-16.17,28.16l7.35,0.06c-0.11-8.58,4.41-17.06,12.54-21.76 c4.8-2.77,10.12-3.8,15.18-3.28c1.52,0.16,2.97-0.66,3.57-2.06l0.08-0.18c0.93-2.14-0.44-4.58-2.76-4.89 C57.2,25.39,50.25,26.61,44.02,30.22z' /%3E%3Cpath class='st1' d='M44.47,76.93c0.33,2-1.27,3.68-3.26,3.43l-7.92-0.99l-3.83-0.38c-1.84-0.18-2.68-2.48-1.35-3.68l6.2-5.62 l4.92-5.03c0.91-0.93,2.54-0.41,2.85,0.91l1.73,7.37L44.47,76.93z' /%3E%3Cpath class='st1' d='M28.5,63.45c0.64,2.93,1.75,5.84,3.35,8.63l3.17-3.02L37,67.13c-0.48-1.14-0.85-2.31-1.14-3.49L28.5,63.45z' /%3E%3Cpath class='st1' d='M68.9,79.73c-4.05,1.7-8.33,2.27-12.45,1.82c-1.53-0.17-3,0.65-3.61,2.06l-0.1,0.23 c-0.91,2.1,0.43,4.5,2.7,4.82c5.59,0.78,11.43,0.08,16.88-2.3L68.9,79.73z' /%3E%3Cpath class='st2' d='M74.26,37.09c-0.35-1.99,1.24-3.69,3.24-3.45l8.04,0.65l4.24,0.38c1.84,0.17,2.7,2.46,1.38,3.67l-6.69,5.91 l-5.42,5.65c-0.9,0.94-2.54,0.43-2.86-0.89l-1.25-7.94L74.26,37.09z' /%3E%3Cpath class='st2' d='M84.73,43.84l-2.61,2.75c5.04,10.68,1.33,23.65-8.76,30.48l3.52,6.6c13.95-9.01,18.54-27.44,10.25-42.01 L84.73,43.84z' /%3E%3C/symbol%3E%3Cmask id='text'%3E%3Ctext fill='%23FFFFFF' font-size='12' text-anchor='middle'%3E%3Ctspan x='50%25' y='98%25' font-size='1'%3E{kind}%3C/tspan%3E%3C/text%3E%3C/mask%3E%3C/defs%3E%3Cuse href='%23wrapper' /%3E%3Crect width='120' height='120' fill='url(%23bg)' /%3E %3Crect width='120' height='120' fill='rgba(192,192,192,0.7)' /%3E%3Crect width='120' height='120' fill='rgba(255,0,0,1)' mask='url(%23text)' /%3E%3C/svg%3E"),
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
        assert!(w.count() == 0, EWrapperNotEmpty);
        // delete the Wrapper
        let Wrapper { id, items:_, kind: _, alias:_, image_url:_ } = w;
        id.delete();
    }

    /// Wraps object list into a new Wrapper.
    /// Parameters:
    /// - `object`: The object to wrap.
    /// - `ctx`: Transaction context.
    /// Returns:
    /// - A new Wrapper containing the object.
    public fun wrap<T: store + key>(object:vector<T>, ctx: &mut TxContext):Wrapper{
        // create a new Wrapper
        let mut w = new(ctx);
        let mut object = object;
        // add the object to the Wrapper
        while (object.length() > 0){
            w.add(object.pop_back());
        };
        object.destroy_empty();
        w
    }

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
    public fun shift<T: store + key>(self:&mut Wrapper, w: &mut Wrapper) {
        assert!(self.is_same_kind<T>(), EItemNotSameKind);
        let mut objects = self.take_all<T>();
        while (objects.length() > 0) {
            w.add(objects.pop_back());
        };
        objects.destroy_empty();
    }

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
    public fun merge<T:store + key>(w1: Wrapper, w2: Wrapper, ctx: &mut TxContext): Wrapper{
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
                let mut w = w1;
                let mut self = w2;
                self.shift<T>(&mut w);
                self.destroy_empty();
                w
            } else {
                let mut w = w2;
                let mut self = w1;
                self.shift<T>(&mut w);
                self.destroy_empty();
                w
            }
        } else {
            // create a new Wrapper
            let mut w = new(ctx);
            w.add(w1);
            w.add(w2);
            w
        }
    }

    /// Splits objects from the Wrapper based on the specified count, moving them into a new Wrapper.
    /// If the count is less than or equal to the current count, all objects are moved.
    /// Parameters:
    /// - `w`: Mutable reference to the original Wrapper.
    /// - `count`: Number of items to split into the new Wrapper.
    /// - `ctx`: Transaction context.
    /// Returns:
    /// - A new Wrapper containing the split
    public fun split<T:store + key>(w: &mut Wrapper, count: u64, ctx: &mut TxContext): Wrapper{
        // create a new Wrapper
        let mut w2 = new(ctx);
        if (w.count() <= count) {
            w.shift<T>(&mut w2);
        }else{
            // take the objects from the first Wrapper and add them to the second Wrapper
            while (w2.count() < count){
                w2.add(w.remove<T>(0));
            };
        };
        w2
    }


    /// Splits objects from the Wrapper based on the specified list of indices, moving them into a new Wrapper.
    /// Converts the index list to an ID list before splitting.
    /// Parameters:
    /// - `w`: Mutable reference to the original Wrapper.
    /// - `indexs`: Vector of indices indicating which items to split.
    /// - `ctx`: Transaction context.
    /// Returns:
    /// - A new Wrapper containing the split items.
    /// Errors:
    /// - `EIndexOutOfBounds`: If any specified index is out of bounds.
    public fun split_with_index<T:store + key>(w: &mut Wrapper, indexs: vector<u64>, ctx: &mut TxContext): Wrapper{
        // create a new Wrapper
        let mut w2 = new(ctx);
        // trans index list to id list
        let mut ids = vector[];
        let mut indexs = indexs;
        while (ids.length() < indexs.length()){
            assert!(indexs[indexs.length()-1] < w.count(), EIndexOutOfBounds);
            ids.push_back(w.item(indexs.pop_back()));
        };
        // take the objects from the first Wrapper and add them to the second Wrapper
        while (ids.length() > 0){
            w2.add(w.take<T>(ids.pop_back()));
        };
        w2
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
    public fun split_with_id<T:store + key>(w: &mut Wrapper, ids: vector<ID>, ctx: &mut TxContext): Wrapper{
        // create a new Wrapper
        let mut w2 = new(ctx);
        // take the objects from the first Wrapper and add them to the second Wrapper
        let mut ids = ids;
        while (ids.length() > 0){
            assert!(w.has_item_with_type<T>(ids[ids.length()-1]), EItemNotFoundOrNotSameKind);
            w2.add(w.take<T>(ids.pop_back()));
        };
        w2
    }

    // public fun split_with_amount<T>(w: &mut Wrapper, amount: u64, ctx: &mut TxContext):Wrapper{
    //     // create a new Wrapper
    //     let mut w2 = new(ctx);
    //     // take the objects from the first Wrapper and add them to the second Wrapper
    //     let x:&mut Coin<T> = &mut w[0];
    //     w2.add(x.split(amount, ctx));
    //     w2
    // }
    
    // public fun split<T>(
    //     self: &mut Coin<T>, split_amount: u64, ctx: &mut TxContext
    // ): Coin<T> {
    //     take(&mut self.balance, split_amount, ctx)
    // }

    // public entry fun join_vec<T>(self: &mut Coin<T>, mut coins: vector<Coin<T>>) {
    //     let (mut i, len) = (0, coins.length());
    //     while (i < len) {
    //         let coin = coins.pop_back();
    //         self.join(coin);
    //         i = i + 1
    //     };
    //     // safe because we've drained the vector
    //     coins.destroy_empty()
    // }


    // public fun merge_items(w: &mut Wrapper, ctx: &mut TxContext) {
    //     // 判断Wrapper中对象的类型
    //     if (w.kind == std::ascii::string(b"coin")) {
    //         let new_id = wrapper::coin_strategy::coin_merge(vector::copy(&w.items), ctx);
    //         w.items = vector::singleton(new_id);
    //     }
    //     // 可以在此添加更多类型的合并策略
    // }

    // // 通用拆分函数
    // public fun split_item_by_amount(w: &mut Wrapper, amount: u64, ctx: &mut TxContext) {
    //     // 判断Wrapper中对象的类型
    //     if (w.kind == std::ascii::string(b"coin")) {
    //         let len = vector::length(&w.items);
    //         for i in 0..len {
    //             let id = *vector::borrow(&w.items, i);
    //             let (new_id, remaining_id) = wrapper::coin_strategy::coin_split(id, amount, ctx);

    //             vector::push_back(&mut w.items, new_id);
    //             *vector::borrow_mut(&mut w.items, i) = remaining_id;
    //             return;
    //         }
    //     }
    //     // 可以在此添加更多类型的拆分策略
    //     abort EInvalidAmount;
    // }
}