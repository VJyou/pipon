# Deployments

## devnet (2026-10-04)
| Item | Value |
|---|---|
| Program `zk_gate` | [`AsTtCWikB8EtHo3fophwB5EhVLY3FwwyuVFjLai86ZDK`](https://explorer.solana.com/address/AsTtCWikB8EtHo3fophwB5EhVLY3FwwyuVFjLai86ZDK?cluster=devnet) |
| Upgrade authority | `7LQSbKRwxW7argJ4mUcLyRsPvq8yuzfzvxVr8aightAR` (keypair kept outside the repository) |
| Gate (scope 1, age 20+, Tokyo) | `F8QEE9cre8L1b3c51jH7S6YhbLk8PQpCb4uQruxwrZF1` |
| Gate (scope 2, age 20+, all prefectures, J-LIS signca02/03) — real cards, 2026-10-07 | [`8beNW6KmpQuRvqz4THZQnaigbKNr7SqUf9ga15MhXavx`](https://explorer.solana.com/address/8beNW6KmpQuRvqz4THZQnaigbKNr7SqUf9ga15MhXavx?cluster=devnet) ([tx](https://explorer.solana.com/tx/3yQ3ysGdDqT9jUYiiyBtdnZSBEo1TkHmVY2NRTzksJJoDhNmDyRn38dX48HxZ6XxKcxE9sXghKpKJQW3jLp2em9K?cluster=devnet)), created by `sdk/scripts/create-jlis-gate.cjs` |
| Gate (scope 3, same policy as scope 2) — real-card **tests**, 2026-10-07 | [`ENejhjnskVR71rJEze66GkKprtXtNvQPVqVBxvuP8wFT`](https://explorer.solana.com/address/ENejhjnskVR71rJEze66GkKprtXtNvQPVqVBxvuP8wFT?cluster=devnet) ([tx](https://explorer.solana.com/tx/gEzkBcFvhtDZ3tJhky6JnmuzLn2J6EmSaLz67i7GYnWkgsw8e3NyCaBXDE7Ax4YnRyEaTKC8kT8HQXAsR8RUmtm?cluster=devnet)), `SCOPE=3` with the same script; keeps scope 2 unclaimed for the demo video |
| Gate (scope 4, same policy as scope 2, named "p!pon Japan 20+") — **demo video**, 2026-10-07 | [`75HaiJKZAPN2wAvuEevwBQ1itYBgxkKAsUqueS3DPNb8`](https://explorer.solana.com/address/75HaiJKZAPN2wAvuEevwBQ1itYBgxkKAsUqueS3DPNb8?cluster=devnet) ([tx](https://explorer.solana.com/tx/5Dcx3Zdyae9TZZVzudt7EQA4HpCxu6MDQjSfZZRzNCUhEEHf1v19yhFRHM4M79XxQGhe2h4a76RvFhiBXfwpqYJX?cluster=devnet)); replaces scope 2 in the demo's gate menu after the rename to p!pon |
| First real-card claim (2026-10-07) | [tx](https://explorer.solana.com/tx/c623tnmBNeQB8FyA16Nb5dDXWjy5QyoVpd86iLwC48KNXjQcZHbVhK7KSZdqEuEVaUjktQHjNbNeKpWbTvszYv7?cluster=devnet) / [asset](https://explorer.solana.com/address/9c531gADhvaa8upLBGnvG4ftdvjMmzZwDednfnm2RpCU?cluster=devnet) — scope 3, holder's own My Number Card in a USB reader via `zkcred-mac`, web demo relay |
| First claim | [tx](https://explorer.solana.com/tx/3LXGmNw29yR1oXRJEQrhtztvhru3i24CRaEAhRDV7QT2KcAq7kukWsosqf1A9D9DEman63Pw6t2bxxbPVLhf8uBz?cluster=devnet) / [asset](https://explorer.solana.com/address/D5bdYoccxc6ncooQLxG3uVoVFyDx9qjkg6p76XCXezHT?cluster=devnet) (143,945 CU) |
| First claim from the iOS app (2026-10-06) | [tx](https://explorer.solana.com/tx/617ZAmfRPYySZSEuaN6YiNaebJk16x3XyR6HzVMLFZdWWqqnJ5hWnnqwkTDWtATqs5THu3PXZ3rtChxvjCXkBrwk?cluster=devnet) / [asset](https://explorer.solana.com/address/FX7sdkS7g5JsrhTmKWC2nU2ioaiUmbXQYdWkVRVij6gA?cluster=devnet) — iOS simulator, dummy card `tokyo30`, via the web demo relay |

Notes:
- The scope-1 gate trusts only the **dummy CA** (`circuits/build/dummy-ca.pem`, not committed). If that key is lost, new
  proofs for scope 1 are impossible → create a gate with a new scope.
- The scope-2 gate trusts the J-LIS signing CAs (signca02/03) by their `caKeyHash` (`docs/research/rsa-spike.md`); signca01
  expired on 2025-10-19. Dummy-card proofs are rejected there (`Untrusted CA`). Gates cannot be changed after creation.
- Re-run the demo: `circuits/scripts/make-claim.sh <wallet> out.json` → `cd sdk && WALLET_KEYPAIR=... CLAIM=out.json npm run demo:devnet`
