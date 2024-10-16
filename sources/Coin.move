module lending_addr::mega_coin {
    use std::debug::print;
    use std::signer;
    use std::string;
    use aptos_framework::coin::{Coin, Self, MintCapability, BurnCapability};

    const BASE: u64 = 1000000;
    const INITIAL_SUPPLY: u64 = 1000000000000000; // 1 billion

    friend lending_addr::lending_pool;
    friend lending_addr::lending_pool_test;
    friend lending_addr::exchange;

    struct MegaAPT {}
    
    struct MockAPT {}

    struct CoinCapability<phantom CoinType> has key {
        coin: Coin<CoinType>,
        mint_cap: MintCapability<CoinType>,
        burn_cap: BurnCapability<CoinType>,
    }
    
    public fun initialize(owner: &signer) {
        let (apt_burn, apt_freeze, apt_mint) = coin::initialize<MockAPT>(owner, string::utf8(b"Aptos Token"), string::utf8(b"APT"), 6, true);
        let apt_coin = coin::mint<MockAPT>(INITIAL_SUPPLY, &apt_mint);
        move_to(owner, CoinCapability<MockAPT>{
            coin: apt_coin,
            mint_cap: apt_mint,
            burn_cap: apt_burn,
        });
        coin::destroy_freeze_cap<MockAPT>(apt_freeze);

        let (mega_apt_burn, mega_apt_freeze, mega_apt_mint) = coin::initialize<MegaAPT>(owner, string::utf8(b"Megaloandon APT"), string::utf8(b"mAPT"), 6, true);
        let mega_apt_coin = coin::mint<MegaAPT>(INITIAL_SUPPLY, &mega_apt_mint);
        move_to(owner, CoinCapability<MegaAPT> {
            coin: mega_apt_coin,
            mint_cap: mega_apt_mint,
            burn_cap: mega_apt_burn,
        });
        coin::destroy_freeze_cap<MegaAPT>(mega_apt_freeze);
    }

    public entry fun mint<CoinType>(sender: &signer, amount: u64) acquires CoinCapability {
        register(sender);
        let coin_cap = borrow_global_mut<CoinCapability<CoinType>>(@lending_addr);
        let coin = coin::extract(&mut coin_cap.coin, amount);
        coin::deposit<CoinType>(signer::address_of(sender), coin);
    }

    public entry fun withdraw<CoinType>(sender: &signer, amount: u64) acquires CoinCapability {
        let coin = coin::withdraw<CoinType>(sender, amount);
        let coin_reserve = &mut borrow_global_mut<CoinCapability<CoinType>>(@lending_addr).coin;
        coin::merge(coin_reserve, coin);
    }

    public entry fun transfer<CoinType>(sender: &signer, receiver: address, amount: u64) {
        let coin = coin::withdraw<CoinType>(sender, amount);
        coin::deposit<CoinType>(receiver, coin);
    }

    #[view]
    public fun get_balance<CoinType>(sender_addr: address): u64 {
        if(coin::is_account_registered<MockAPT>(sender_addr) == false) {
            return 0
        };
        coin::balance<CoinType>(sender_addr)
    }

    public entry fun register(sender: &signer) {
        if(coin::is_account_registered<MockAPT>(signer::address_of(sender)) == false) {
            coin::register<MockAPT>(sender);
        };

        if(coin::is_account_registered<MegaAPT>(signer::address_of(sender)) == false) {
            coin::register<MegaAPT>(sender);
        };
    }

}