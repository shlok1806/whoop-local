# decode/ — Phases 2–4: protocol decode + metrics

**Python (`bleak`).** Subscribe to the band's data characteristic, decode packets, then derive
metrics. Order: live HR (Phase 2, easiest to validate) → RR intervals → flash backfill (Phase 3)
→ metrics (Phase 4).

## Rules
- **Decode defensively.** Sensor packets can be partial; flash backfill can stall. Model every
  field as optional/fallible — never assume a field is present.
- **Metrics are labeled approximations, not WHOOP's scores.** RMSSD-from-RR-intervals for HRV is
  the one genuinely standard metric. Strain (HR time-in-zone) and recovery (morning baseline) are
  *our* textbook substitutes — label them as such wherever they surface.
- Flash backfill (Phase 3) likely uses sequence numbers we must ack to advance pagination.
  Document the framing/ack scheme in `docs/` as you reverse it.

Update this file when a new packet-decoding convention or a metric-computation decision lands.
