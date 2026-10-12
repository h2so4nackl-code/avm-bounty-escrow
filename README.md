# AVM Bounty Escrow

A Rust AVM reference contract for milestone bounties, with authenticated approvals,
asynchronous payment settlement, expired-balance refunds, and a real local-stand
regression journey. Designed as a useful candidate for the `gosh-sh/avm-sdk` test
suite. This is a tested SDK example, not an audited financial product.

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

Local validation on 12 October 2026:

| Check | Result |
| --- | --- |
| Project native regression tests | 35 passed |
| Unmodified vendored SDK tests | 12 passed |
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

## Run it

Requirements: Linux x86-64 (Windows: WSL2), Rustup, Python 3, curl, tar, sha256sum.
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
  commit `72ee42dbf923f081bf29b4a1a1b6ea012b6af54f`.
- Published builder/stand release:
  `avm-dev-335a0f09fdbc-sdk-0cbca40fad9a`.
- Runtime source revision recorded by that release:
  `335a0f09fdbc98eb7a1056c0f6b84cd4f39d889e`.
- Release SDK revision: `0cbca40fad9a8f11863197cbcbaf6208651752b9`.

The source SDK and published runtime are different revisions. The included E2E
evidence validates this exact combination; it does not claim compatibility with
an unpublished runtime. [`PROVENANCE.json`](PROVENANCE.json) records the pins.

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
- No mainnet deployment, third-party security audit, reward eligibility decision,
  or GitHub-hosted CI run is claimed. A CI workflow is included for publication.

## Official references

- [SDK repository](https://github.com/gosh-sh/avm-sdk)
- [Pinned source](https://github.com/gosh-sh/avm-sdk/tree/72ee42dbf923f081bf29b4a1a1b6ea012b6af54f)
- [Published runtime release](https://github.com/gosh-sh/avm-sdk/releases/tag/avm-dev-335a0f09fdbc-sdk-0cbca40fad9a)
- [Examples](https://github.com/gosh-sh/avm-sdk/blob/72ee42dbf923f081bf29b4a1a1b6ea012b6af54f/examples/README.md)
- [FUEL and SHELL](https://github.com/gosh-sh/avm-sdk/blob/72ee42dbf923f081bf29b4a1a1b6ea012b6af54f/docs/fuel-and-fees.md)

MIT licensed. The vendored SDK retains its upstream license.
