/// Module: entry
module wrapper::entry {
    use wrapper::wrapper::{Self,Wrapper};
    use sui::transfer;

    public entry fun empty(ctx: &mut TxContext) {
        transfer::public_transfer(wrapper::new(ctx),ctx.sender());
    }

    // display.add(b"name".to_string(), b"Capy {name}".to_string());
    // display.add(b"link".to_string(), b"https://capy.art/capy/{id}".to_string());
    // display.add(b"image".to_string(), b"https://api.capy.art/capy/{id}/svg".to_string());
    // display.add(b"description".to_string(), b"A Lovely Capy".to_string());

    public entry fun wrap<T: store + key>(object:vector<T>, ctx: &mut TxContext){
        transfer::public_transfer(wrapper::wrap(object, ctx), ctx.sender());
    }


    public entry fun test(mut object:vector<u8>, ctx: &mut TxContext){
        while (object.length() >0){
            object.pop_back();
        };
        object.destroy_empty();
    }

}
