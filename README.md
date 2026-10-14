# AVM Bounty Escrow

A Rust AVM reference contract for milestone bounties, with authenticated approvals,
asynchronous payment settlement, expired-balance refunds, and a real local-stand
regression journey. Designed as a useful candidate for the `gosh-sh/avm-sdk` test
suite. This is a tested SDK example, not an audited financial product.

## SDK 0.2.0 compatibility

Verified on 14 October 2026 with the published SDK 0.2.0 bundle and its guest SDK
0.1.1: **35 application + 13 SDK = 48 native tests**, all contract builds and
lints, and the actual AVM journey/replay passed. [Migration and provenance](docs/SDK-020.md)
record the exact tools, profile and limitations. [GitHub Actions](https://github.com/h2so4nackl-code/avm-bounty-escrow/actions)
provides the current hosted result. The application contract logic is unchanged.

## What it demonstrates

- The client funds the complete bounty once, using `value_main`.
- The worker submits a delivery hash for an individual milestone.
- The client approves that exact hash, preventing a revised submission from
  silently replacing the delivery they intended to approve.
- Either party may trigger payment of an approved milestone. The fixed recipient
  cannot be changed by the caller.
- Payment enters a pending state. A successful native callback settles it; an
  unsuccessful callback must return the exact principal before the state unlocks.
- At or after the deadline, the client may request a refund of **unapproved**
  milestones. Approved work remains payable after the deadline.
- Receipt hashes remain in bounded persistent state so an old callback cannot
  settle a later attempt. Ordinary internal messages cannot act as callbacks.
- Canonical events expose funded, paid, refunded, and pending amounts.

The companion receiver accepts payments only from its bound escrow, echoes an
acknowledgment, detects repeated successful attempts, and can deliberately reject
delivery. It is a test fixture, not a general-purpose wallet.

## Verified result

### Local validation

Current local validation on SDK 0.2.0, 14 October 2026:

| Check | Result |
| --- | --- |
| Project native regression tests | 35 passed |
| Unmodified vendored SDK tests | 13 passed |
| Generated action sequence coverage | 100 sequences × 80 actions inside one regression test |
| Official reproducible builder | Both contract artifact triples produced |
| Native and WASM Clippy | No warnings under `-D warnings` |
| WASM surface | Required exports present; zero host imports |
| Actual AVM E2E | Failed payment → refund → retry; failed expiry refund → retry; late approved payment |
| Rejected AVM operations | Duplicate funding/payment/refund, unauthorized submission, premature refund, late submission |
| Final accounting | 1,000 deposited = 700 paid + 300 refunded; no transfer pending |
| Journal replay | Account root, registry root, accepted-input count, and cumulative fees match |

See [`evidence/`](evidence/). Failed contract calls are checked by their canonical
`ACMO` status and state, not merely by the stand command's outer `status: ok`.
The main-value amounts above are synthetic local test units. They do not establish
a denomination or live NACKL balance. Execution SHELL is accounted separately.

### GitHub Actions

The GitHub-hosted [AVM escrow checks run 38196158944](https://github.com/h2so4nackl-code/avm-bounty-escrow/actions/runs/38196158944)
completed successfully on 12 October 2026 at 02:32 UTC for commit
[`054300d719445a0f3c1229f63e033cc59a8c0d80`](https://github.com/h2so4nackl-code/avm-bounty-escrow/commit/054300d719445a0f3c1229f63e033cc59a8c0d80).
The `verify` job installed the pinned Rust toolchain, downloaded and verified the
pinned AVM runtime, and ran `bash scripts/check.sh`. Its logs confirm 35 project
regression tests and 12 SDK tests passed, contract builds and lint checks passed,
and the actual local AVM stand journey and WASM artifact checks passed.

This hosted execution is separate from the historical local results and files in
[`evidence/`](evidence/) above. It does not establish an independent security audit,
mainnet deployment, or production use.

## Run it

Requirements: Linux x86-64-v3, glibc >=2.39 (Windows: WSL2), Rust/Cargo 1.93.0, Python >=3.11, curl and sha256sum.
No crates.io dependencies are needed; the SDK source is vendored.

```bash
rustup toolchain install 1.93.0 --profile minimal --component rustfmt --component clippy
rustup target add wasm32-unknown-unknown --toolchain 1.93.0
bash scripts/install_runtime.sh
bash scripts/check.sh
```

With an existing verified SDK installation:

```bash
bash scripts/check.sh /absolute/path/to/avm-sdk-linux-x86_64
```

`install_runtime.sh` downloads one pinned official Linux release, verifies its
published SHA-256, and verifies all files against its `SHA256SUMS` manifest.
`check.sh` runs native tests and lint, builds each contract twice using the
official builder's reproducibility check, validates ABI IDs, lints the WASM
targets, executes the real stand journey, and checks the WASM export surface.
The demo uses a fresh temporary state and no real funds or external endpoints.

For native tests only:

```bash
cargo test --workspace --offline
```

## SDK versions

- Vendored `avm-contract-sdk`: `gosh-sh/avm-sdk`
  commit `0748f4f0767a26da8bc363bcb6b5585539d6970e`.
- Published builder/stand release:
  `avm-dev-06e96ef71006-sdk-0748f4f0767a`.
- Runtime source revision recorded by that release:
  `06e96ef71006cca020575cbf35e6b82cc82a324e`.
- Release SDK revision: `0748f4f0767a26da8bc363bcb6b5585539d6970e`.

Vendored guest source matches the published bundle SDK revision. The included
E2E evidence uses the shipped SDK 0.2.0 runtime and profile in a fresh stand. [`PROVENANCE.json`](PROVENANCE.json) records the pins.

## Layout

```text
contracts/escrow/       Main contract, canonical ABI and generated IDs
contracts/receiver/     Bound accepting/rejecting receiver fixture
tests/tests/           Native contract regression tests
vendor/                Pinned SDK source and its MIT license
scripts/               Verified setup, checks, real stand E2E, artifact checks
evidence/              Actual local test/build/replay outputs
docs/SPEC.md           Wire layout, accounting, authority, and limitations
docs/SDK-INTEGRATION.md Suggested upstream test-suite integration
```

The ZIP also includes prebuilt `contracts/*/target/avm/contract.{wasm,acab,descriptor}`.
Those build directories are ignored by Git; source reproduction is authoritative.

## Limits

- One bounty per escrow, at most 8 milestones and 64 total outbound attempts.
  Every dispatch counts, including failed attempts. After that bound, further
  outbound transfers are refused and unresolved principal can remain locked.
- A native callback that never arrives leaves the transfer pending. There is
  deliberately no timeout unlock that could permit a second payment after a
  late successful first delivery.
- `value_main` is the only principal asset. SHELL (`extra` currency ID 2) funds
  execution separately. The example does not implement NACKL token integration,
  refunds of unused operating SHELL, arbitration, or production wallet adapters.
- Receiver addresses and authorities are fixed by initialization. The example
  has no administrative sweep or upgrade entrypoint.
- Expiry is checked when an operation executes; a transaction must request the
  refund. The contract does not execute on its own when time passes.
- Delivery hashes record references, not proof that work is correct. The client
  remains responsible for approving the work.
- Callback authenticity depends on the AVM runtime admitting native callbacks
  and forbidding ordinary callers from injecting VM-owned queue messages.
- No mainnet deployment, third-party security audit, production use, or reward
  eligibility decision is claimed. GitHub-hosted validation is recorded above.

## Official references

- [SDK repository](https://github.com/gosh-sh/avm-sdk)
- [Pinned source](https://github.com/gosh-sh/avm-sdk/tree/0748f4f0767a26da8bc363bcb6b5585539d6970e)
- [Published runtime release](https://github.com/gosh-sh/avm-sdk/releases/tag/avm-dev-06e96ef71006-sdk-0748f4f0767a)
- [Examples](https://github.com/gosh-sh/avm-sdk/blob/0748f4f0767a26da8bc363bcb6b5585539d6970e/examples/README.md)
- [FUEL and SHELL](https://github.com/gosh-sh/avm-sdk/blob/0748f4f0767a26da8bc363bcb6b5585539d6970e/docs/fuel-and-fees.md)

MIT licensed. The vendored SDK retains its upstream license.
