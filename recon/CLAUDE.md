# recon/ — Phase 0: GATT enumeration

**Disposable Python.** Scripts here connect to the band over BLE (`bleak`) and dump every GATT
service + characteristic — UUIDs and properties (notify/read/write). Goal: know exactly what the
5.0 exposes before decoding anything. Output goes to `docs/gatt_map_5.0.md`, not here.

This code is throwaway — do not build abstractions. One connect-and-dump script is enough.

## Rules
- **One BLE connection at a time.** Unpair the band from the WHOOP app or airplane-mode the phone
  first, or connects will be flaky.
- Treat 4.0-derived protocol notes as a hypothesis to verify against *our* 5.0, never as fact.

Update this file only if a non-obvious recon convention emerges (e.g. a required scan filter or a
pairing dance the band needs).
