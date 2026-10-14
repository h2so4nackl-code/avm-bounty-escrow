# Candidate SDK integration

Keep the existing standard examples unchanged. Add the two contracts as separate
fixtures and retain the native regression suite and stand journey. A compact
integration can preserve this repository as a pinned test dependency; alternatively
copy `contracts/` and `tests/` into new SDK example directories and adjust only the
SDK dependency paths and script fixture paths.

Suggested SDK release gate:

1. Build both new contracts with the official `avm-contract-build`.
2. Validate canonical method/event IDs.
3. Run the existing SDK gates unchanged.
4. Run `scripts/e2e.py --sdk <packaged SDK root>`.
5. Require exact accounting/state assertions and matching journal replay roots.

The escrow test exercises a practical state machine beyond fixed forwarding:
work revisions, signer authority, funding isolation, asynchronous payment and
refund failure handling, replay protection, and logical-time boundaries.

## Submission description

AVM Bounty Escrow is a Rust milestone-payment reference contract with a bound
accepting/rejecting receiver fixture. It demonstrates exact-hash client approvals,
asynchronous payout settlement, principal refunds on failed delivery, and expiry
refunds that preserve approved work. The repository includes 35 native regression
tests, pinned SDK source, reproducible AVM artifacts, an actual local-stand journey,
and matching journal replay evidence. It is proposed as an SDK test-suite example,
with its limits and runtime trust assumptions documented. No mainnet deployment
or third-party audit is claimed.

## SDK 0.2.0

See [the standalone compatibility result](SDK-020.md). In-tree integration must
use the current SDK path dependency and reviewed lock, without RUSTC_WRAPPER.
The existing upstream integration PR is #9. Its approval and validation
are separate from these standalone checks.
