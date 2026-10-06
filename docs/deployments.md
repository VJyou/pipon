# Deployments

## devnet (2026-10-04)
| Item | Value |
|---|---|
| Program `zk_gate` | [`AsTtCWikB8EtHo3fophwB5EhVLY3FwwyuVFjLai86ZDK`](https://explorer.solana.com/address/AsTtCWikB8EtHo3fophwB5EhVLY3FwwyuVFjLai86ZDK?cluster=devnet) |
| Upgrade authority | `7LQSbKRwxW7argJ4mUcLyRsPvq8yuzfzvxVr8aightAR` (keypair kept outside the repository) |
| Gate (scope 1, age 20+, Tokyo) | `F8QEE9cre8L1b3c51jH7S6YhbLk8PQpCb4uQruxwrZF1` |
| Gate (scope 2, age 20+, all prefectures, J-LIS signca02/03) — real cards, 2026-10-07 | [`8beNW6KmpQuRvqz4THZQnaigbKNr7SqUf9ga15MhXavx`](https://explorer.solana.com/address/8beNW6KmpQuRvqz4THZQnaigbKNr7SqUf9ga15MhXavx?cluster=devnet) ([tx](https://explorer.solana.com/tx/3yQ3ysGdDqT9jUYiiyBtdnZSBEo1TkHmVY2NRTzksJJoDhNmDyRn38dX48HxZ6XxKcxE9sXghKpKJQW3jLp2em9K?cluster=devnet)), created by `sdk/scripts/create-jlis-gate.cjs` |
| First claim | [tx](https://explorer.solana.com/tx/3LXGmNw29yR1oXRJEQrhtztvhru3i24CRaEAhRDV7QT2KcAq7kukWsosqf1A9D9DEman63Pw6t2bxxbPVLhf8uBz?cluster=devnet) / [asset](https://explorer.solana.com/address/D5bdYoccxc6ncooQLxG3uVoVFyDx9qjkg6p76XCXezHT?cluster=devnet) (143,945 CU) |
| First claim from the iOS app (2026-10-06) | [tx](https://explorer.solana.com/tx/617ZAmfRPYySZSEuaN6YiNaebJk16x3XyR6HzVMLFZdWWqqnJ5hWnnqwkTDWtATqs5THu3PXZ3rtChxvjCXkBrwk?cluster=devnet) / [asset](https://explorer.solana.com/address/FX7sdkS7g5JsrhTmKWC2nU2ioaiUmbXQYdWkVRVij6gA?cluster=devnet) — iOS simulator, dummy card `tokyo30`, via the web demo relay |

Notes:
- The scope-1 gate trusts only the **dummy CA** (`circuits/build/dummy-ca.pem`, not committed). If that key is lost, new
  proofs for scope 1 are impossible → create a gate with a new scope.
- The scope-2 gate trusts the J-LIS signing CAs (signca02/03) by their `caKeyHash` (`docs/research/rsa-spike.md`); signca01
  expired on 2025-10-19. Dummy-card proofs are rejected there (`Untrusted CA`). Gates cannot be changed after creation.
- Re-run the demo: `circuits/scripts/make-claim.sh <wallet> out.json` → `cd sdk && WALLET_KEYPAIR=... CLAIM=out.json npm run demo:devnet`
