#[test_only]
module wrapper::wrapper_tests {
    use wrapper::wrapper;
    
    const EItemNotFound: u64 = 0;
    const EIndexOutOfBounds: u64 = 1;
    const EItemNotSameKind: u64 = 2;
    const EItemNotFoundOrNotSameKind: u64 = 3;
    const EWrapperNotEmpty: u64 = 4;

    public struct O has store,key { id: UID,data:u64 }
    public fun Create(ctx:&mut TxContext,data:u64): O {
        O { id: object::new(ctx),data:data }
    }
    public fun Destroy(i:O){
        let O{id,data:_} = i;
        id.delete();
    }

    public struct S has store,key { id: UID,data:vector<u8> }
    public fun CreateS(ctx:&mut TxContext,data:vector<u8>): S {
        S { id: object::new(ctx),data:data }
    }
    public fun DestroyS(i:S){
        let S{id,data:_} = i;
        id.delete();
    }

    #[test]
    /// test if creating a new wrapper is successful
    fun test_new_wrapper() {
        let mut ctx = tx_context::dummy();
        let wrapper = wrapper::new(&mut ctx);
        assert!(wrapper::is_empty(&wrapper), 1);
        wrapper.destroy();
    }

    fun clear_o_wrapper(w:wrapper::Wrapper) {
        let mut dw = w;
        while (dw.count() > 0) {
            let id = dw.item(0);
            let dropobj = dw.take<O>(id);
            dropobj.Destroy();
        };
        dw.destroy();
    }

    fun clear_s_wrapper(w:wrapper::Wrapper) {
        let mut dw = w;
        while (dw.count() > 0) {
            let id = dw.item(0);
            let dropobj = dw.take<S>(id);
            dropobj.DestroyS();
        };
        dw.destroy();
    }

    #[test]
    /// Test creating a new wrapper and basic add/remove operations
    fun test_wrapper_operations() {
        let mut ctx = tx_context::dummy();
        // Test creating a new wrapper
        let mut wrapper = wrapper::new(&mut ctx);
        assert!(wrapper::is_empty(&wrapper), 1);

        // Test adding and removing a single object
        let object = Create(&mut ctx,1);
        wrapper::add(&mut wrapper, object);
        assert!(wrapper::count(&wrapper) == 1, 1);

        let removed = wrapper::remove<O>(&mut wrapper, 0);
        assert!(removed.data == 1, 1);
        removed.Destroy();
        assert!(wrapper::is_empty(&wrapper), 1);

        // Test adding and removing multiple objects of the same type
        let object1 = Create(&mut ctx,0);
        wrapper::add(&mut wrapper, object1);
        let object2 = Create(&mut ctx,1);
        wrapper::add(&mut wrapper, object2);
        assert!(wrapper::count(&wrapper) == 2, 0);

        let removed2 = wrapper::remove<O>(&mut wrapper, 1);
        let removed1 = wrapper::remove<O>(&mut wrapper, 0);
        assert!(removed1.data == 0, 1);
        assert!(removed2.data == 1, 1);
        removed1.Destroy();
        removed2.Destroy();
        assert!(wrapper::is_empty(&wrapper), 1);

        wrapper.destroy();
    }

    #[test, expected_failure(abort_code = 1)]
    /// Test handling out of bounds index
    fun test_index_out_of_bounds() {
        let mut ctx = tx_context::dummy();
        let mut wrapper = wrapper::new(&mut ctx);
        let object = Create(&mut ctx,1);
        let oid = object::id(&object);
        wrapper::add(&mut wrapper, object);

        // Attempt to access an out-of-bounds index
        let id = wrapper::item(&wrapper, 1);
        assert!(id == oid, 1);
        let dropobj = wrapper.take<O>(oid);
        dropobj.Destroy();
        wrapper.destroy();
    }

    #[test, expected_failure(abort_code = 2)]
    /// Test adding different types and handling type errors
    fun test_type_error_handling() {
        let mut ctx = tx_context::dummy();
        let mut wrapper = wrapper::new(&mut ctx);
        let object1 = Create(&mut ctx,0);
        let object2 = CreateS(&mut ctx,b"1");

        wrapper::add(&mut wrapper, object1);
        wrapper::add(&mut wrapper, object2); // Expected to fail

        clear_o_wrapper(wrapper);
    }

    #[test]
    /// Test adding different types and handling type errors
    fun test_not_same_type_tow_wrapper_handling() {
        use std::debug;
        let mut ctx = tx_context::dummy();
        let mut wrapper1 = wrapper::new(&mut ctx);
        let mut wrapper2 = wrapper::new(&mut ctx);
        let object1 = Create(&mut ctx,0);
        let object2 = CreateS(&mut ctx,b"1");

        wrapper::add(&mut wrapper1, object1);
        wrapper::add(&mut wrapper2, object2);

        assert!(wrapper::count(&wrapper1) == 1, 0);
        assert!(wrapper::count(&wrapper2) == 1, 0);

        // Test merging wrappers with different types
        let mut w = wrapper::merge<O>(wrapper1, wrapper2, &mut ctx);
        assert!(wrapper::count(&w) == 2, 0);
        debug::print(&w.kind());

        // Test borrowing an item from a wrapper with different type
        let x:&mut wrapper::Wrapper = &mut w[0];
        debug::print(&x.count());
        debug::print(&x.kind());
        x.add(Create(&mut ctx,11));
        debug::print(&x.count());
        debug::print(&x.kind());

        // Test borrowing an item from a wrapper with different type
        let x:&wrapper::Wrapper = &w[1];
        debug::print(&x.count());
        debug::print(&x.kind());


        assert!(w.kind() == std::ascii::string(b"0000000000000000000000000000000000000000000000000000000000000000::wrapper::Wrapper"), 0);
        let mut o = w.unwrap();
        
        clear_s_wrapper(o.remove(1));
        clear_o_wrapper(o.remove(0));
        o.destroy_empty();

    }

    #[test]
    /// Test object transfer and merge operations
    fun test_transfer_and_merge_operations() {
        let mut ctx = tx_context::dummy();
        let mut source_wrapper = wrapper::new(&mut ctx);
        let mut dest_wrapper = wrapper::new(&mut ctx);
        let object = Create(&mut ctx,0);

        // Test transferring objects between wrappers
        wrapper::add(&mut source_wrapper, object);
        wrapper::shift<O>(&mut source_wrapper, &mut dest_wrapper);
        assert!(wrapper::is_empty(&source_wrapper), EWrapperNotEmpty);
        source_wrapper.destroy();
        assert!(wrapper::count(&dest_wrapper) == 1, 0);

        let dropobj = dest_wrapper.remove<O>(0);
        dropobj.Destroy();
        dest_wrapper.destroy();

        // Test merging wrappers
        let mut wrapper1 = wrapper::new(&mut ctx);
        let mut wrapper2 = wrapper::new(&mut ctx);
        let object1 = Create(&mut ctx,1);
        let object2 = Create(&mut ctx,2);

        wrapper::add(&mut wrapper1, object1);
        wrapper::add(&mut wrapper2, object2);
        let merged_wrapper = wrapper::merge<O>(wrapper1, wrapper2, &mut ctx);
        assert!(wrapper::count(&merged_wrapper) == 2, 0);
        
        clear_o_wrapper(merged_wrapper);
    }

    #[test]
    /// Test splitting wrappers
    fun test_split_operations() {
        let mut ctx = tx_context::dummy();
        let mut wrapper = wrapper::new(&mut ctx);
        let mut objects = vector[Create(&mut ctx,1), Create(&mut ctx,2), Create(&mut ctx,3), Create(&mut ctx,4)];
        let count = objects.length();

        // Add all objects and then split by index
        while (wrapper::count(&wrapper) < count) {
            wrapper::add(&mut wrapper, objects.remove(0));
        };
        objects.destroy_empty();

        let indices = vector[1];
        let new_wrapper = wrapper::split_with_index<O>(&mut wrapper, indices, &mut ctx);
        assert!(wrapper::count(&new_wrapper) == 1, 0);
        assert!(wrapper::count(&wrapper) == count - 1, 0);

        clear_o_wrapper(new_wrapper);


        // Test edge case of splitting with an empty index list
        let empty_wrapper = wrapper::split<O>(&mut wrapper, count + 1, &mut ctx);
        assert!(wrapper::is_empty(&wrapper), 1);
        assert!(wrapper::count(&empty_wrapper) == count - 1, 0);

        clear_o_wrapper(wrapper);
        clear_o_wrapper(empty_wrapper);
    }


    #[test, expected_failure(abort_code = 1)]
    /// test if splitting an empty wrapper fails
    fun test_operate_on_empty_wrapper() {
        let mut ctx = tx_context::dummy();
        let mut wrapper = wrapper::new(&mut ctx);
        // try to remove an item from an empty wrapper
        let obj = wrapper::remove<O>(&mut wrapper, 0);
        obj.Destroy();
        wrapper.destroy();
    }

    /// test ctx1 create and ctx2 use
    #[test]
    fun test_ctx1_create_ctx2_use() {
        let mut ctx1 = tx_context::dummy();
        let mut ctx2 = tx_context::dummy();
        let mut wrapper = wrapper::new(&mut ctx1);
        let object = Create(&mut ctx1,0);
        let id = object::id(&object);
        wrapper::add(&mut wrapper, object);

        
        let obj = wrapper::remove<O>(&mut wrapper, 0);
        assert!(obj.data == 0, 1);
        obj.Destroy();
        wrapper.destroy();
    }
}
