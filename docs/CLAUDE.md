# docs/ — GATT map, protocol notes, decode findings

**Prose, not code.** The shared knowledge base every phase reads from and writes to.

## What lives here
- `gatt_map_5.0.md` — Phase 0 output: the 5.0's services + characteristics (UUIDs, properties).
- Protocol notes — Phase 1 onward: the command characteristic (we write), the data
  characteristic (band notifies), packet framing (start/end, length, CRC), backfill ack scheme.

## Rules
- This is the source of truth for the protocol as verified against *our* 5.0. When band behavior
  contradicts an external (4.0) note, record what the 5.0 actually does and mark the external note
  as superseded.
- Findings here are the spec `daemon/` implements in Rust — keep them precise enough to code from.

Update whenever a UUID, packet format, or framing detail is confirmed or corrected.
