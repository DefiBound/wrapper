/// Module: template
module tokenization::T_6ee7597e7344c205d78979d8052dfae85b2ae01bee40a0abb287d33cdcacc204 {
    use sui::url;
    use sui::address;
    use sui::coin::{Self, Coin, TreasuryCap};

    use wrapper::tokenized::{Self as wt,WrapperTokenized};

    public struct T_6EE7597E7344C205D78979D8052DFAE85B2AE01BEE40A0ABB287D33CDCACC204 has drop {}

    const LOCKED_OBJECT: vector<u8> = b"6ee7597e7344c205d78979d8052dfae85b2ae01bee40a0abb287d33cdcacc204";
    const TOTAL_SUPPLY: u64 = 100000000000000;
    const DECIMALS: u8 = 6;

    const SYMBOL: vector<u8> = b"Wrapper Tokenized Symbol";
    const NAME: vector<u8> = b"Wrapper Tokenized Name";
    const DESCRIPTION: vector<u8> = b"Wrapper Tokenized Description";
    const ICON_URL: vector<u8> = b"https://th.bing.com/th/id/OIP.KIbQVW995sdomP7hAushQgHaHa";


    fun init(otw: T_6EE7597E7344C205D78979D8052DFAE85B2AE01BEE40A0ABB287D33CDCACC204, ctx: &mut TxContext) {
        let icon_url = if (ICON_URL == b"") {
            option::none()
        } else {
            option::some(url::new_unsafe_from_bytes(ICON_URL))
        };

        wt::register<T_6EE7597E7344C205D78979D8052DFAE85B2AE01BEE40A0ABB287D33CDCACC204>(
            otw,
            DECIMALS,
            SYMBOL,
            NAME,
            DESCRIPTION,
            icon_url,
            address::from_ascii_bytes(&LOCKED_OBJECT),
            ctx
        );
    }
}
