# Migration Plan: STM32 CryptoWallet -> Yocto (NanoPI NEO v1.2)

This document maps the legacy MCU implementation to the new Linux/Yocto platform and defines a staged migration path with low risk.

## Scope

- Legacy source baseline: `legacy-stm32-cryptowallet`
- New target: NanoPI NEO v1.2 (Allwinner H3), Yocto image `cryptowallet-image`
- Goal: preserve wallet security model and core signing behavior while replacing MCU-specific runtime and peripherals with Linux equivalents

## Architecture Mapping

| Legacy STM32 block | New Yocto/Linux block | Notes |
|---|---|---|
| FreeRTOS tasks (`task_sign`, service loops) | `systemd` services + user-space daemons | Split by responsibility: signer, API, diagnostics |
| LwIP HTTP server | Linux HTTP API service (e.g. Rust/Go/Python) behind localhost/lan bind policy | Add auth/TLS strategy from day one |
| WebUSB firmware endpoint | Linux USB gadget/daemon or API bridge (optional phase) | Not required for first MVP |
| UART CWUP diagnostics | Linux serial diagnostics service / CLI tool | Keep command vocabulary for compatibility where practical |
| `trezor-crypto` usage in firmware | Same crypto lib in user-space or audited alternative | Keep deterministic test vectors |
| Seed hook (`get_wallet_seed`) | Secure storage backend (file+encryption, TPM/SE, HSM-like peripheral) | No plain seed in filesystem |
| Bootloader + firmware signing split | U-Boot/boot chain + signed update artifact policy | Define trust boundaries in docs early |
| HIL python scripts | Host integration tests against Linux service endpoints | Reuse scripts where protocol remains compatible |

## Migration Stages

## Stage 0 - Foundation (done in this repository)

- Yocto project skeleton and custom layer (`meta-cryptowallet`)
- `cryptowallet-image` recipe
- Placeholder `cryptowallet` package recipe

## Stage 1 - Service skeleton on Linux

- Replace placeholder recipe with real application package
- Install `cryptowalletd` binary/script and `systemd` unit
- Expose health endpoint (`/health`) and version endpoint (`/version`)
- Add structured logs for CI checks

Deliverable: bootable image where `systemctl status cryptowalletd` is healthy.

## Stage 2 - Crypto signing parity

- Port signing flow from `task_sign` semantics
- Reproduce deterministic signing tests from legacy vectors
- Enforce memory hygiene (short-lived buffers, explicit zeroization where available)
- Disable secret material in logs and diagnostics

Deliverable: signature outputs match agreed test vectors.

## Stage 3 - API and transport compatibility

- Implement HTTP API replacing MCU LwIP endpoints
- Optionally provide compatibility shim for legacy host tools
- Define auth model (token/mTLS/localhost-only for first cut)
- Reassess CWUP needs: keep only diagnostics commands if still useful

Deliverable: host tools can perform sign/status flows on Linux target.

## Stage 4 - Storage hardening

- Implement production seed backend
- Device binding strategy (UID/hardware-backed key + user secret/PIN)
- Backup/restore and provisioning workflow
- Add threat-model document for operational usage

Deliverable: no plaintext seed at rest; documented recovery/provisioning.

## Stage 5 - Update and release pipeline

- Signed update artifact policy (RAUC/swupdate/OSTree)
- CI: reproducible build checks and smoke tests
- Release metadata (SBOM/checksums/signatures)

Deliverable: deterministic build + secure update path.

## Backlog candidates

- WebUSB parity layer
- OLED/local UI support on Linux target
- Remote attestation/reporting
- Expanded fuzz and fault-injection tests

## Definition of Done for first Yocto MVP

- `bitbake cryptowallet-image` passes in CI
- Image boots on NanoPI NEO v1.2
- `cryptowalletd` starts automatically
- Health/version endpoints respond
- Signing test vector suite passes on target
