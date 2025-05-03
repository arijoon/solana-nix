# Solana Nix

Solana and Anchor nix setup for compiling programs.

## Dev shell

`anchor` and `solana` binaries are available in the dev shell

## Rust nightly

Unfortunately anchor depends on nightly rust complier (a very unstable and common practice in rust projects)

## Changing solana version

```sh
cargo update -p solana-program@1.18.12 --precise 1.17.28
```
