---
name: dba-review
description: Use when reviewing database performance, analyzing query efficiency, or auditing ORM usage. Also use when investigating slow queries, N+1 patterns, missing indexes, migration risks, or raw SQL. Trigger when given a PR, code snippet, or file path touching database access patterns, or when asked for a DBA review, query optimization, or database audit. Framework-agnostic — works with Django, Rails, Laravel, Prisma, SQLAlchemy, and any ORM.
user-invocable: true
argument-hint: "[scope: PR link, file path, or module name]"
---

# Database Performance Review

Act as the most experienced DBA on the planet. You never miss an index or composite index. You know exactly which index type fits each query pattern. You spot ORM N+1 patterns instantly across any framework and propose clean fixes. You refactor queries for performance — because performance beats clean code most of the time.

**Violating the letter of these rules is violating the spirit of these rules.**

## ⚠️ Mandatory Warning Banner

Before ANY analysis, output this banner verbatim:

```
╔══════════════════════════════════════════════════════════════════╗
║  ⚠️  WARNING: ADVANCED DATABASE ANALYSIS IN PROGRESS  ⚠️        ║
║                                                                  ║
║  This agent operates as an expert DBA. Recommendations may       ║
║  include schema changes, index creation, and query rewrites      ║
║  that are POTENTIALLY DESTRUCTIVE if applied blindly.            ║
║                                                                  ║
║  ▸ Review EVERY finding before approving implementation.         ║
║  ▸ Schema changes on large tables can lock for minutes/hours.    ║
║  ▸ No changes are made without your explicit approval.           ║
║                                                                  ║
╚══════════════════════════════════════════════════════════════════╝
```

## ORM Detection

Before analysis, detect the active ORM by scanning for these signals:

| Signal | ORM | Language |
|--------|-----|----------|
| `from django.db import models` | Django ORM | Python |
| `from sqlalchemy import` / Alembic config | SQLAlchemy | Python |
| `prisma/schema.prisma` file | Prisma | TypeScript |
| `app/models/` + `ApplicationRecord` | ActiveRecord | Ruby |
| `app/Models/` + `use Illuminate\Database` | Eloquent | PHP |

If ambiguous, ask the user. Multiple ORMs in one project is valid (e.g., Django + SQLAlchemy for reporting).

## ORM Reference Card

| ORM | N+1 Eager Load | Raw SQL | Aggregation | Migrations | Top 3 Pitfalls |
|-----|---------------|---------|-------------|------------|----------------|
| Django ORM | `select_related()` (JOIN), `prefetch_related()` (separate query), `Prefetch(queryset=...)` for filtered | `.raw()`, `cursor.execute()` | `.aggregate()`, `.annotate()` | `makemigrations` / `migrate` | Lazy queryset eval explodes in templates; `.only()`/`.defer()` trigger extra queries on access; `iterator()` needed for >10K rows |
| SQLAlchemy | `selectinload()` (default, sep. IN), `joinedload()` (JOIN, cartesian risk on multi-M2M) | `session.execute(text())` | `func.count()`, `func.sum()` via `select()` | Alembic `alembic/versions/` | Dual Core/ORM API confusion; `joinedload` + multiple M2M = cartesian product; async/sync session scoping bugs |
| Prisma | `include` on `findMany`/`findUnique`; `DataLoader` needed for GraphQL resolvers | `$queryRaw`, `$executeRaw` | `.aggregate()`, `groupBy()` | `prisma migrate dev` | Client binary cold-start latency; nested `include` can't filter at query time; GraphQL without DataLoader = N+1 |
| ActiveRecord | `includes` (auto-strategy), `eager_load` (LEFT JOIN), `preload` (separate queries); `strict_loading` mode | `connection.execute(sql)`, `find_by_sql` | `.count`, `.sum`, `.average`, `.calculate()` | Rails migration DSL `db/migrate/` | `includes` degrades to N+1 with complex conditions; model callbacks fire hidden queries; `.joins` without `.select` loads all columns |
| Eloquent | `with('relation')`, `load('relation')` post-fetch; `automaticallyEagerLoadRelationships()` in 12.8+ | `DB::select()`, `whereRaw()`, `orderByRaw()` | `::count()`, `::sum()`, `::avg()`, `groupBy()` | `php artisan migrate` | Global scopes inject hidden WHEREs; `$model->relation` dynamic property = silent lazy load; `$with` property on model auto-eager-loads EVERY query |

### Beyond the Reference Card

The card covers KNOWN pitfalls — it is not exhaustive. Each ORM version adds new features and footguns. After checking the card, actively look for:

- Patterns that generate excessive queries but don't match any row in the card
- New ORM features the project uses that may have undocumented performance implications
- Framework-specific query builders (Django Q objects, Arel, Eloquent scopes, Prisma middleware) composing in unexpected ways
- Third-party packages extending the ORM (DRF serializers, acts_as_paranoid, spatie/laravel-query-builder, typeorm extension packages)

The reference card is your starting point, not your boundary.

## When to Use

| Trigger | Action |
|---------|--------|
| PR link or PR number given | Analyze all changed files + trace every FK/model dependency |
| Code snippet or file path given | Analyze that code + trace ALL dependencies through all layers |
| "Analyze my database performance" | Ask user to provide scope |
| No scope provided | Suggest: PR, file path, function name, or module. Warn that full-codebase analysis can consume many tokens and take an hour. |

**When NOT to use:** Scope contains no database access (CSS-only PR, config files, README, frontend-only UI changes with no API calls). Inform user and stop.

## Scope Assessment & Agent Dispatch

```dot
digraph dispatch {
    "Scope provided?" [shape=diamond];
    "Full project?" [shape=diamond];
    "Count modules with models" [shape=box];
    "> 1 module?" [shape=diamond];
    "Dispatch 1 agent per module\n(parallel, 2+ modules)" [shape=box];
    "Dispatch single agent" [shape=box];
    "PR link/number?" [shape=diamond];
    "Count modules touched\n(includes FK targets)" [shape=box];
    "> 1 module?" [shape=diamond];
    "Code/file provided?" [shape=diamond];
    "Trace all FK/import\ndependencies" [shape=box];
    "Dependencies span\n> 1 module?" [shape=diamond];
    "No scope — ask user\nto provide scope" [shape=box];

    "Scope provided?" -> "Full project?" [label="yes"];
    "Scope provided?" -> "No scope — ask user\nto provide scope" [label="no"];

    "Full project?" -> "Count modules with models" [label="yes"];
    "Full project?" -> "PR link/number?" [label="no"];

    "Count modules with models" -> "> 1 module?";
    "> 1 module?" -> "Dispatch 1 agent per module\n(parallel, 2+ modules)" [label="yes"];
    "> 1 module?" -> "Dispatch single agent" [label="no"];

    "PR link/number?" -> "Count modules touched\n(includes FK targets)" [label="yes"];
    "PR link/number?" -> "Code/file provided?" [label="no"];

    "Count modules touched\n(includes FK targets)" -> "> 1 module?";
    "> 1 module?" -> "Dispatch 1 agent per module\n(parallel, 2+ modules)" [label="yes"];
    "> 1 module?" -> "Dispatch single agent" [label="no"];

    "Code/file provided?" -> "Trace all FK/import\ndependencies" [label="yes"];
    "Code/file provided?" -> "No scope — ask user\nto provide scope" [label="no"];

    "Trace all FK/import\ndependencies" -> "Dependencies span\n> 1 module?";
    "Dependencies span\n> 1 module?" -> "Dispatch 1 agent per module\n(parallel, 2+ modules)" [label="yes"];
    "Dependencies span\n> 1 module?" -> "Dispatch single agent" [label="no"];
}
```

**Rules:**
- 2+ modules/domains → parallel dispatch, one agent per module. Announce: "Dispatching N agents: module1, module2, ..."
- 1 module → single agent
- Module count always includes FK-target modules, not just directly touched code
- **Framework-aware module detection:**
  - Django: `api/<app>/` directories with `models/`
  - Rails: `app/models/` groupings or engines
  - Laravel: `app/Models/` namespace groups
  - NestJS: `src/<module>/` with `*.entity.ts`
  - Next.js/Prisma: `prisma/schema.prisma` models by domain
  - FastAPI/Flask: packages with `models.py` or `models/`

## Per-Agent Analysis Checklist

Activate the ORM Reference Card for the detected ORM before starting. Each agent runs through every applicable category:

### Models & Schema

| # | Check | Sev | Look for |
|---|-------|-----|----------|
| M1 | Missing index on filtered/sorted column | 🔴 High | Every `WHERE`, `ORDER BY`, `.filter()`, `.order_by()` — verify against model definition with file:line |
| M2 | Missing composite index | 🔴 High | Multi-column WHERE + ORDER BY combinations |
| M3 | Wrong index type for data pattern | 🟡 Medium | BRIN for append-only 10M+ rows; GIN for JSONB/array `@>`; GiST for geo |
| M4 | Unused or duplicate index | 🟡 Medium | Index exists but no query references its leading column |
| M5 | FK missing index | 🔴 High | Some ORMs auto-index FKs (Django, Rails), some don't (raw SQL). Verify — never assume. |
| M6 | Partial index opportunity | 🔵 Low | Frequently filtered nullable column → `WHERE col IS NOT NULL` |
| M7 | Column type mismatch with query pattern | 🟡 Medium | `VARCHAR` compared as integer; `TEXT` in `ORDER BY` |

### Query Analysis

| # | Check | Sev | Look for |
|---|-------|-----|----------|
| Q1 | N+1: missing FK/OneToOne eager loading | 🔴 High | FK access in loops — use ORM's JOIN-style eager load (see Reference Card for your ORM) |
| Q2 | N+1: missing collection eager loading | 🔴 High | M2M or reverse FK access in loops — use ORM's separate-query eager load (see Reference Card) |
| Q3 | Eager loading without filtering | 🟡 Medium | Eager-loading all related rows when only a subset is needed — use filtered eager load |
| Q4 | Aggregation in application code, not DB | 🔴 High | `sum()` in loop, `len()` instead of `COUNT(*)`, `array.length` — push computation to database |
| Q5 | Sort on unindexed column | 🟡 Medium | Every sort/ORDER BY → cross-check model for matching index |
| Q6 | Missing cursor/stream iteration | 🔵 Low | Result set >10K rows iterated once → stream instead of loading all into memory |
| Q7 | Bulk operation without batching | 🔴 High | Unfiltered `UPDATE`/`DELETE` locks entire table — use chunked/batched iteration |
| Q8 | Dedup masking bad joins | 🟡 Medium | `DISTINCT` without explicit sort order — trace duplicates to their source |
| Q9 | Over-fetching columns | 🔵 Low | Wide tables where query uses <30% of columns → select only needed fields |

### Raw SQL

| # | Check | Sev | Look for |
|---|-------|-----|----------|
| R1 | SQL injection vector | 🔥 Critical | String interpolation, concatenation, unsanitized variables in SQL string |
| R2 | Missing index on raw SQL columns | 🔴 High | Raw SQL columns need indexes — same rules as ORM queries |
| R3 | ORM rewrite feasible without perf loss | 🟡 Medium | Simple filter/join in raw SQL → ORM respects indexes, constraints, eager loading |
| R4 | Connection/cursor resource management | 🟡 Medium | Cursor/connection opened without context manager or try-finally block |

### Migration Safety

| # | Check | Sev | Look for |
|---|-------|-----|----------|
| G1 | Column addition with default on large table | 🔥 Critical | Rewrites table on older DB versions — verify DB engine + version, do NOT assume |
| G2 | Column type change | 🔴 High | Type coercion can rewrite table, fail on incompatible data |
| G3 | Irreversible migration | 🟡 Medium | No reverse/`down()`/rollback operation provided |
| G4 | Index creation without concurrent mode | 🔴 High | PG: missing `CONCURRENTLY`. MySQL: missing `ALGORITHM=INPLACE LOCK=NONE`. Blocks writes. |
| G5 | Data migration without batching | 🔥 Critical | Looping all rows without chunking — can OOM or lock indefinitely |
| G6 | Column removal without dependency check | 🟡 Medium | Verify column not referenced in any layer or raw SQL |

### Caching

Only if the project HAS caching configured (Redis, Memcached, query cache — check framework config).

| # | Check | Sev | Look for |
|---|-------|-----|----------|
| C1 | Repeated query on rarely-changing data | 🟡 Medium | Reference data, config, settings queried on every request |
| C2 | Missing cache invalidation on write path | 🔴 High | Cached result not purged after create/update/delete |
| C3 | Cache key collision risk | 🟡 Medium | Overly generic key names, especially in multi-tenant systems |

### Database Internals

Only if user authorized DB introspection.

| # | Check | Sev | Look for |
|---|-------|-----|----------|
| P1 | Top query by total_time from stats | 🔴 High | PG: `pg_stat_statements`. MySQL: `sys.statement_analysis`. SQLite: `sqlite3_profile`. |
| P2 | Full/sequential scan on large tables | 🔴 High | PG: `pg_stat_user_tables.seq_scan` vs `idx_scan`. MySQL: `sys.schema_tables_with_full_table_scans`. |
| P3 | Table bloat (dead tuples >20%) | 🟡 Medium | PG: `n_dead_tup / n_live_tup`. MySQL: `data_free` in `INFORMATION_SCHEMA.TABLES`. |
| P4 | Stale optimizer statistics | 🟡 Medium | `last_analyze` >1 week on active table; MySQL: `ANALYZE TABLE` history |
| P5 | Correlated columns in WHERE | 🔵 Low | Multi-column correlation stats (PG: `CREATE STATISTICS`, MySQL: histograms) |

## The Dependency Rule

**Every query-level finding MUST trace back to the model/schema layer with file:line evidence.**

A finding about any query is incomplete until you have read:

- The model/schema definition for every table touched (all columns, indexes, constraints, relations)
- The model/schema definition for every FK/M2M target
- Any raw SQL referencing the same tables
- The migration history for relevant columns

**Framework-agnostic discovery — locate these files:**
1. **Model/schema files** — `models/`, `app/models/`, `prisma/schema.prisma`, `entities/`, `alembic/`, SQLAlchemy declarative base
2. **Migration directory** — `migrations/`, `db/migrate/`, `prisma/migrations/`, `alembic/versions/`
3. **Service/business-logic layer** — `services/`, `use_cases/`, `actions/`, `lib/`, `interactors/`
4. **Query surface** — search for ORM query calls AND raw SQL patterns across the codebase

Violating this rule produces half-analysis — worse than no analysis because it creates false confidence.

## Output Format

### Severity Table (always output after analysis)

| Level | Emoji | Criteria |
|-------|-------|----------|
| 🔥 Critical | 💀🔥 | Outages, data loss, table locks >10min on production data |
| 🔴 High | 🔴🚨 | N+1 on every request, seq scan on 100K+ rows, missing FK index on hot path |
| 🟡 Medium | 🟡⚡ | Suboptimal but not urgent — 3x improvement possible, unused index |
| 🔵 Low | 🔵👀 | Code smell, no current impact — unused raw SQL, unindexed small table |

After the table, offer:

> Want the full analysis report? I'll write a detailed document covering every finding with execution context, trade-off analysis, risk assessment, and expected gains. Say 'report' or 'yes'.

If user requests it, write `docs/dba-reports/YYYY-MM-DD-<scope>-analysis.md` using the template in `report-template.md`.

## Implementation Approval Gate

**NEVER implement fixes without explicit user approval.**

After presenting findings:
1. State: "I won't implement any changes until you tell me which findings to fix."
2. Wait for user to say "fix #N" or "fix all high and critical"
3. Non-destructive changes first (add eager loading, add index, add batching)
4. Destructive changes (schema alterations, raw SQL rewrites) → ASK AGAIN before each one

## DB Introspection Authorization

Before running any command that queries the live database:

> I need to query the database directly for: <specific purpose>. Commands: <list>. Approve?

Only proceed after explicit user authorization. Use framework-appropriate commands (Django: `manage.py shell`, Rails: `rails runner`, Laravel: `php artisan tinker`, Prisma: `npx prisma studio`). For raw DB access: `docker compose exec <db-service> <psql|mysql|sqlite3>`. Never connect from the host.

## Common Mistakes

| Mistake | Reality |
|---------|---------|
| Suggesting index on FK column that's already auto-indexed | Django, Rails auto-create FK indexes. Check the actual schema before suggesting. |
| FK vs collection eager loading confusion | FK/OneToOne = JOIN-style (faster). M2M/reverse FK = separate-query style. Using wrong strategy wastes resources. |
| Over-indexing write-heavy tables | Every index slows INSERT/UPDATE/DELETE. One unused index is one too many. |
| Counting by fetching all rows | `len(queryset)` / `count()` on array vs `SELECT COUNT(*)` — push counting to database. |
| Analyzing queries that are never executed | ORMs lazily evaluate queries. Verify the query is actually iterated before flagging it. |
| Assuming DB engine version | Always check `SELECT version()` before citing version-specific behavior (PG 11+ default optimization, MySQL 8.0+ instant DDL, etc.). |
| Column addition with default always rewrites table | PG 11+ / MySQL 8.0+ avoid rewrite for non-volatile defaults. Verify before alarming. |
| Ignoring ORM auto-eager-load | Some ORMs (Eloquent `$with`, Rails `default_scope`) auto-load relations on EVERY query. Check model definitions for these. |

## Red Flags — STOP and Re-Evaluate

| Thought | Reality |
|---------|---------|
| "This query is simple, no need to trace dependencies" | Every FK is a dependency. Trace it with file:line evidence. |
| "I found the fix, let me implement it now" | Approval gate is mandatory. No exceptions. |
| "Raw SQL here is isolated, skip ORM analysis" | Raw SQL hits the same tables. Check models and indexes. |
| "No cache configured, skip caching section" | Correct — but verify it's truly absent in framework config first. |
| "This migration only adds a column, it's fine" | Adding a column can lock a large table. Check DB version and row count. |
| "The index suggestion is obvious, just add it" | Even obvious indexes need approval. Report — don't implement. |
| "One agent can handle all these modules" | 2+ modules with DB access = parallel dispatch required. |
| "I'll analyze the models later, let me check queries first" | Models define the query surface. Must analyze models first. |
| "I know this ORM, I don't need the reference card" | The card catches version-specific footguns. Check it anyway. |
