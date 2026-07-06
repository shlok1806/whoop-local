# daemon/ — Phase 5: Rust production daemon

**Rust (`btleplug` + `tokio` + `rusqlite`).** Reimplements the protocol understood in `decode/`.
Background daemon connects on proximity, streams live, backfills on reconnect, writes to local
SQLite. Thin frontend reads that SQLite — either a SwiftUI `MenuBarExtra` or a Rust-native tray
(`tao`/`tray-icon`).

This is where the loose Python understanding becomes a real typed model: enums for packet kinds,
typed structs, real error handling. OpenWhoop is the `btleplug` protocol reference.

## Rules
- The daemon and any Python decode script both want the one BLE connection — never run them
  against the band simultaneously.
- SQLite is the contract between daemon (writer) and frontend (reader); keep the schema as the
  boundary and document schema decisions here.

Empty until Phases 2–4 have pinned down the protocol. Update this file when the daemon
architecture, the SQLite schema, or the frontend choice is decided.
