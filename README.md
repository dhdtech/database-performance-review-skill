# Database Performance Review

An AI skill that does what a senior DBA does: scans your queries, spots trouble before it hits production, tells you what to fix. Django, Rails, Laravel, Prisma, SQLAlchemy — it auto-detects your ORM and knows its quirks.

## What it catches

- N+1 queries hiding in loops
- Missing indexes on columns you filter and sort by
- Migrations that will lock your biggest table for 20 minutes
- Raw SQL with injection vectors
- Aggregation happening in app code when the database should do it

## Supported ORMs

| ORM | Language |
|-----|----------|
| Django ORM | Python |
| SQLAlchemy | Python |
| Prisma | TypeScript |
| ActiveRecord | Ruby |
| Eloquent | PHP |

Running more than one? Django + SQLAlchemy for reporting? The skill handles that.

## Install

### Option A: Quick install (recommended)

```bash
curl -sSL https://raw.githubusercontent.com/dhdtech/dba-review/main/install.sh | bash
```

The script detects which CLIs you have and asks which ones to install to. Pick one, pick a few, or grab them all.

### Option B: Manual install

**Claude Code** — personal skills live at `~/.claude/skills/<name>/SKILL.md`:

```bash
git clone https://github.com/dhdtech/dba-review.git \
  ~/.claude/skills/dba-review
```

**Copilot CLI** — personal skills live at `~/.copilot/skills/<name>/SKILL.md`:

```bash
git clone https://github.com/dhdtech/dba-review.git \
  ~/.copilot/skills/dba-review
```

> If you have `gh` 2.74+, you can also run: `gh skill install dhdtech/dba-review`

**Gemini CLI** — personal skills live at `~/.gemini/skills/<name>/SKILL.md`:

```bash
git clone https://github.com/dhdtech/dba-review.git \
  ~/.gemini/skills/dba-review
```

**Codex (OpenAI)** — personal skills live at `~/.codex/skills/<name>/SKILL.md`:

```bash
git clone https://github.com/dhdtech/dba-review.git \
  ~/.codex/skills/dba-review
```

## Use

The skill activates whenever database performance is relevant to what you're asking. Examples:

> "Review PR #712 for database issues."
> "This endpoint is slow — check the queries."
> "Look at this migration before we deploy."

Or invoke it directly:

| Platform | Invocation |
|----------|-----------|
| Claude Code | `/dba-review` |
| Copilot CLI | `/dba-review` |
| Gemini CLI | `/dba-review` |
| **Codex (OpenAI)** | **`$dba-review`** |

> [!IMPORTANT]
> **Codex users — use `$dba-review`, not `/dba-review`.**
> Codex reserves `/` slash commands for curated-registry plugins. Directory-installed skills use `$` (dollar sign) invocation instead. Same skill, different prefix. Type `$dba-review` and hit enter.

## What you get

It traces every foreign key, reads your model definitions, checks your indexes, and walks your query paths. Then you get a ranked list — Critical down to Low — with file:line references and specific fixes. Nothing changes without your approval, and it never touches your database without asking first.

## Files

| File | Purpose |
|------|---------|
| `SKILL.md` | The skill: detection rules, checklists, ORM reference card |
| `report-template.md` | Template for full written DBA reports |
| `install.sh` | Multi-platform installer — auto-detects your tools |

## License

MIT. Use it, fork it, ship it in your product. No credit needed.

---

> **⚠️ After installing: close and reopen your CLI tool.**
>
> Claude Code picks up new skill directories only at session start. Copilot CLI needs `/skills reload`. Gemini CLI needs a restart. If the skill doesn't appear, a fresh session always fixes it.

---

<p align="center">
  <strong>Something broken? Something missing?</strong><br>
  <a href="https://github.com/dhdtech/dba-review/issues">Open an issue</a>.
  Bugs, feature ideas, an ORM you want supported — all fair game.
</p>
