# Database Performance Analysis — `<scope>` — `<date>`

## Executive Summary

≤5 sentences. What was analyzed, overall health assessment, single biggest win.

## Findings Deep-Dive

Each finding follows this template:

### Finding #N — `<LEVEL EMOJI>` `<Title>`

| Dimension | Assessment |
|-----------|------------|
| **The Gap** | What's happening now vs what should happen (concrete, with file:line) |
| **Impact** | Real-world effect — latency added, rows scanned, lock duration, user-visible consequence |
| **Root Cause** | Why it's happening — missing index, ORM misuse, schema design flaw |
| **Fix** | Exact code change proposed (ORM, raw SQL, or migration snippet) |
| **Gain** | Quantified where possible — "reduces query from 850ms to ~5ms", "eliminates 40 DB round-trips per page load" |
| **Risk** | What could go wrong — index bloat on write-heavy table, lock during creation, regression potential |
| **Trade-off** | Write performance cost of new index, increased storage, ORM readability vs raw SQL speed |
| **Rollback** | How to undo — `DROP INDEX CONCURRENTLY`, revert commit, or reverse migration |

## Index Summary

| # | Table | Columns | Type | Size Est. | Priority |
|---|-------|---------|------|-----------|----------|
| 1 | `table` | `col1, col2` | B-tree | ~X MB | 🔴 High |

## Migration Plan

If schema changes are proposed:

- Order of operations (which index/migration first, why)
- Downtime estimate per operation
- Safe execution commands (`CREATE INDEX CONCURRENTLY`, lock-free alternatives)

## What We're NOT Changing

Findings the DBA considered but rejected, and why — so the reader understands the judgment calls behind each decision.
