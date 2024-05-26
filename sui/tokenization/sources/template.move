/// Module: template
module tokenization::template {
    use sui::url;
    use sui::address;
    use sui::coin::{Self, Coin, TreasuryCap};

    use wrapper::tokenized::{Self as wt,WrapperTokenized};

    public struct TEMPLATE has drop {}

    const LOCKED_OBJECT: vector<u8> = b"Wrapper Tokenized Object Id";
    const TOTAL_SUPPLY: u64 = 100000000000000;
    const DECIMALS: u8 = 6;

    const SYMBOL: vector<u8> = b"Wrapper Tokenized Symbol";
    const NAME: vector<u8> = b"Wrapper Tokenized Name";
    const DESCRIPTION: vector<u8> = b"Wrapper Tokenized Description";
    const ICON_URL: vector<u8> = b"https://th.bing.com/th/id/OIP.KIbQVW995sdomP7hAushQgHaHa";


    fun init(otw: TEMPLATE, ctx: &mut TxContext) {
        let icon_url = if (ICON_URL == b"") {
            option::none()
        } else {
            option::some(url::new_unsafe_from_bytes(ICON_URL))
        };

        wt::register<TEMPLATE>(
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
