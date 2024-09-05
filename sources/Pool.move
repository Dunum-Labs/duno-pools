////////////////////////////
//  2024 by Dunum Labs.   //
////////////////////////////

module Std::DunoLiquidityPool {
	use std::signer;
	use aptos_framework::coin;
	use aptos_framework::aptos_coin;
	use Std::Duno;

	struct LiquidityPool has key {
		reserve_dno: u64,
		reserve_apt: u64,
		total_liquidity: u64,
		lp_token_supply: u64,
	}

	public entry fun initialize(account: &signer) {
		let pool = LiquidityPool {
			reserve_dno: 0,
			reserve_apt: 0,
			total_liquidity: 0,
			lp_token_supply: 0,
		};
		move_to(account, pool);
	}

	public entry fun add_liquidity(account: &signer, amount_dno: u64, amount_apt: u64) acquires LiquidityPool {
		let pool = borrow_global_mut<LiquidityPool>(@Std);

		let dno_coins = coin::withdraw<Duno::Duno>(account, amount_dno);
		coin::deposit<Duno::Duno>(@Std, dno_coins);

		let apt_coins = coin::withdraw<aptos_coin::AptosCoin>(account, amount_apt);
		coin::deposit<aptos_coin::AptosCoin>(@Std, apt_coins);

		pool.reserve_dno = pool.reserve_dno + amount_dno;
		pool.reserve_apt = pool.reserve_apt + amount_apt;

		let liquidity_minted = calculate_liquidity_tokens(amount_dno, amount_apt);
		pool.lp_token_supply = pool.lp_token_supply + liquidity_minted;

	}

	fun calculate_liquidity_tokens(amount_dno: u64, amount_apt: u64): u64 {
		(amount_dno + amount_apt) / 2
	}

	public entry fun remove_liquidity(account: &signer, liquidity_tokens: u64) acquires LiquidityPool {
		let pool = borrow_global_mut<LiquidityPool>(signer::address_of(account));

		let dno_amount = pool.reserve_dno * liquidity_tokens / pool.lp_token_supply;
		let apt_amount = pool.reserve_apt * liquidity_tokens / pool.lp_token_supply;

		pool.reserve_dno = pool.reserve_dno - dno_amount;
		pool.reserve_apt = pool.reserve_apt - apt_amount;
		pool.lp_token_supply = pool.lp_token_supply - liquidity_tokens;

		let dno_coins = coin::withdraw<Duno::Duno>(account, dno_amount);
		coin::deposit<Duno::Duno>(signer::address_of(account), dno_coins);

		let apt_coins = coin::withdraw<aptos_coin::AptosCoin>(account, apt_amount);
		coin::deposit<aptos_coin::AptosCoin>(signer::address_of(account), apt_coins);

	}

	public entry fun swap_dno_to_apt(account: &signer, amount_dno: u64) acquires LiquidityPool {
		let pool = borrow_global_mut<LiquidityPool>(signer::address_of(account));

		let amount_apt = calculate_swap_amount(pool.reserve_dno, pool.reserve_apt, amount_dno);

		pool.reserve_dno = pool.reserve_dno + amount_dno;
		pool.reserve_apt = pool.reserve_apt - amount_apt;

		let dno_coins = coin::withdraw<Duno::Duno>(account, amount_dno);
		coin::deposit<Duno::Duno>(signer::address_of(account), dno_coins);

		let apt_coins = coin::withdraw<aptos_coin::AptosCoin>(account, amount_apt);
		coin::deposit<aptos_coin::AptosCoin>(signer::address_of(account), apt_coins);


	}

	fun calculate_swap_amount(reserve_in: u64, reserve_out: u64, amount_in: u64): u64 {
		let amount_out = (reserve_out * amount_in) / (reserve_in + amount_in);
		amount_out
	}
}