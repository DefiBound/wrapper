/// Module: wrapper
/// Provides functionality for managing a collection of objects within a "Wrapper".
/// This module includes functionalities to wrap, unwrap, merge, split, and manage items in a Wrapper.
/// It handles different kinds of objects and ensures that operations are type-safe.
module wrapper::wrapper {
    use sui::dynamic_object_field as field;
    use sui::display;
    use sui::package;
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
        let display = display::new<Wrapper>(&publisher,ctx);
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
    public fun set_alias(w: &mut Wrapper, alias: std::string::String) {
        w.alias = alias;
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
    public fun take_all<T:store + key>(w: &mut Wrapper): vector<T> {
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
        }
    }

    /// Destroys the Wrapper, ensuring it is empty before deletion.
    /// Parameters:
    /// - `w`: The Wrapper to destroy.
    /// Effects:
    /// - The Wrapper and its identifier are deleted.
    /// Errors:
    /// - `EWrapperNotEmpty`: If the Wrapper is not empty at the time of destruction.
    public fun destroy(w: Wrapper) {
        // remove all items from the Wrapper
        assert!(w.count() == 0, EWrapperNotEmpty);
        // delete the Wrapper
        let Wrapper { id, items:_, kind: _, alias:_ } = w;
        id.delete();
    }

    /// Wraps a single object into a new Wrapper.
    /// Parameters:
    /// - `object`: The object to wrap.
    /// - `ctx`: Transaction context.
    /// Returns:
    /// - A new Wrapper containing the object.
    public fun wrap<T: store + key>(object:T, ctx: &mut TxContext):Wrapper{
        // create a new Wrapper
        let mut w = new(ctx);
        // add the object to the Wrapper
        w.add(object);
        w
    }

    /// Unwraps all objects from the Wrapper, ensuring all are of type T, then destroys the Wrapper.
    /// Parameters:
    /// - `self`: The Wrapper to unwrap.
    /// Returns:
    /// - Vector of all objects of type T from the Wrapper.
    /// Errors:
    /// - `EItemNotSameKind`: If any contained item is not of type T.
    public fun unwrap<T:store + key>(self: Wrapper):vector<T> {
        assert!(self.is_same_kind<T>(), EItemNotSameKind);
        let mut w = self;
        // unwrap all objects from the Wrapper
        let objects = w.take_all<T>();
        // destroy the Wrapper
        w.destroy();
        objects
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
            w1.destroy();
            w2
        } else if (w2.is_empty()) {
            w2.destroy();
            w1
        } else if (w1.kind == w2.kind && w2.kind == kind) {
            // check the count of the two Wrappers
            if (w1.count() > w2.count()) {
                let mut w = w1;
                let mut self = w2;
                self.shift<T>(&mut w);
                self.destroy();
                w
            } else {
                let mut w = w2;
                let mut self = w1;
                self.shift<T>(&mut w);
                self.destroy();
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
}