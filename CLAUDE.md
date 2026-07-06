# whoop-local

A local-first client for reading data **directly off a WHOOP 5.0 band over Bluetooth LE** —
no phone, no cloud, no subscription dependency. We read our own hardware, decode the raw
protocol, and compute metrics on-device.

This is **Path A**: talk BLE to the band directly. We are explicitly *not* impersonating the
phone to WHOOP's cloud (that path violates their API terms and risks the account). We read the
device we own, for interoperability.

---

## Why this exists

WHOOP has no desktop presence and the phone is a mandatory middleman for sync. This project
cuts the phone out: the Mac connects to the band over BLE, streams live data, backfills
historical data from the band's flash buffer, and stores everything locally. As a bonus, direct
BLE gives us **live heart rate** — something the official cloud API cannot provide.

## Hardware

- Band: **WHOOP 5.0** (confirmed). Note: community reverse-engineering coverage is strongest
  for the 4.0. The 5.0 may differ in characteristic UUIDs, packet framing, or command opcodes,
  so treat all 4.0-derived protocol notes as a *starting hypothesis to verify*, not gospel.
- Host: macOS (has Bluetooth; we use the OS BLE stack via each language's binding).

## Language strategy (two phases, deliberate)

- **Decode phase → Python + `bleak`.** Fast REPL loop for reverse-engineering: connect, subscribe,
  print bytes, poke the band, watch what changes. Most of this code is disposable.
- **Production phase → Rust + `btleplug` + `tokio`.** This is what OpenWhoop uses, so we get a
  protocol reference in the same ecosystem. Rust forces real modeling of the binary protocol
  (enums for packet kinds, typed structs, real error handling) and is the strongest resume flex.

## Prerequisites / setup

```bash
# Python decode env
python3 -m venv .venv && source .venv/bin/activate
pip install bleak

# Rust (later)
# rustup + cargo; deps: btleplug, tokio, rusqlite
```

---

## Critical gotchas (read before touching the band)

1. **One BLE connection at a time.** The band's phone app will fight our script for the
   connection. Before any session: unpair the band from the WHOOP phone app, OR put the phone
   in airplane mode. Otherwise you'll get flaky connects and dropped notifications.
2. **5.0 ≠ 4.0.** Verify every UUID and packet format against *our* device in Phase 0 before
   trusting any external protocol notes.
3. **Model everything as optional / fallible.** Sensor packets can be partial; flash backfill can
   stall. Decode defensively, never assume a field is present.
4. **Metrics are approximations.** Strain and recovery are WHOOP-proprietary and closed. We
   compute textbook substitutes (RMSSD for HRV, HR-time-in-zone for strain, morning-baseline for
   recovery) and must label them clearly as *our* numbers, not WHOOP's scores. HRV (RMSSD from
   RR intervals) is the one that's genuinely standard.

---

## Phases

### Phase 0 — Recon  *(Python, ~1 evening)*  → `recon/`
Scan, connect, enumerate every GATT service + characteristic (UUIDs + properties:
notify/read/write). Dump to a file. **Goal:** know exactly what the 5.0 exposes before decoding.
Deliverable: `docs/gatt_map_5.0.md`.

### Phase 1 — Cross-reference protocol  *(reading, ~1 evening)*  → `docs/`
Map OpenWhoop's documented UUIDs/packet formats onto what Phase 0 found. Identify: the **command**
characteristic (we write requests), the **data** characteristic (band notifies us), and the
**framing** (packet start/end, length fields, CRC). Stand on their map, verify against our device.

### Phase 2 — Live stream  *(Python, ~1 weekend)*  → `decode/`
Subscribe to the data characteristic, decode live packets. **Heart rate first** — easiest to
validate (compare to the band's own display or a chest strap). Then RR intervals if exposed.
Milestone: real-time HR off our own strap, no phone, no cloud.

### Phase 3 — Historical backfill  *(Python, the hard part)*  → `decode/`
The band buffers data in flash when disconnected — this is how the phone "catches up." Send the
buffer-request command, decode the historical stream. Trickiest part: pagination/ack of a flash
dump, likely sequence numbers we must ack to advance. Success = we've replicated the real sync.

### Phase 4 — Metrics  *(either language)*  → `decode/` or `daemon/`
Raw sensor data → derived metrics. RMSSD for HRV (standard, documented). Strain/recovery as
labeled approximations. Optionally a small modeling sub-project.

### Phase 5 — Rust daemon + frontend  → `daemon/`
Reimplement the understood protocol in Rust/`btleplug`: background daemon connects on proximity,
streams live, backfills on reconnect, writes to local SQLite. Thin frontend reads SQLite —
either reuse a SwiftUI `MenuBarExtra`, or go Rust-native tray via `tao`/`tray-icon`.

---

## Current status

- [x] Project scaffold + plan
- [ ] Phase 0 — recon script + GATT map
- [ ] Phase 1 — protocol cross-reference
- [ ] Phase 2 — live HR
- [ ] Phase 3 — flash backfill
- [ ] Phase 4 — metrics
- [ ] Phase 5 — Rust daemon + menu bar

**Next action:** write and run the Phase 0 recon script (`recon/enumerate.py`) to dump the
5.0's GATT services and characteristics.

## Layout

```
whoop-local/
├── CLAUDE.md        # this file
├── recon/           # Phase 0: GATT enumeration (Python, disposable)
├── decode/          # Phases 2–4: protocol decode + metrics (Python)
├── daemon/          # Phase 5: Rust production daemon
└── docs/            # GATT map, protocol notes, decode findings
```

## Living documentation

This project uses per-folder `CLAUDE.md` files (`recon/`, `decode/`, `daemon/`, `docs/`). After
any session where you introduce a new module, dependency, or convention, update the `CLAUDE.md`
**closest** to where the change lives — not this root file unless the change is project-wide.
Write only what a future agent could not derive from reading the code: rules, boundaries,
ownership decisions, non-obvious tradeoffs. Not file inventories (they go stale) and not what the
code plainly does.

## Open-source hygiene — no personal info in tracked files

This ships as a **public** repo. Nothing committed may contain personal or device-identifying
information. The rule is to keep the tree clean at the source, not to scrub it later:

- **Paths:** repo-relative only (`recon/enumerate.py`), never absolute home paths.
- **No** email addresses, machine names, or usernames in code, docs, or CLAUDE.md files.
- **The band's BLE identifier** (MAC/UUID) is personal — never hardcode it. Read it from a
  gitignored config or env var and pass it in.
- **Captured biometric data** (HR/HRV logs, flash dumps) never gets committed — it lives in
  gitignored dirs (`raw_captures/`, etc.).

A `scripts/check-leaks.sh` pre-commit hook blocks commits that violate this. Install it per clone
with `ln -sf ../../scripts/check-leaks.sh .git/hooks/pre-commit` (git does not share hooks).

Two remotes, identical clean tree: `origin` (private dev) and `public` (open source). Publish with
`git push public main`. There is deliberately **no** dev→public scrubbing step — if the guardrails
hold, both repos get the same commits.

## Legal / ethical footing

Reading data off hardware we own, for personal interoperability (cf. 17 U.S.C. §1201(f)). We do
**not** access WHOOP's cloud via undocumented/private endpoints, spoof the official app's identity,
or mask our client to their servers. Direct-band-only.
