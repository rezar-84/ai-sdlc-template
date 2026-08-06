# Architecture Decision Records

One file per durable decision: `NNNN-short-slug.md`, from `../../templates/adr.md`.

## When to write one

Write an ADR when the decision is **expensive to reverse**, or when a future reader would
otherwise have to reverse-engineer the reasoning from the code.

Typically: stack, storage, and hosting choices · authentication and authorisation model ·
tenancy or isolation model · the shape of an interface others depend on · a significant
new dependency · a data model others will build on · **anything chosen against the
obvious option**.

Not: naming, formatting, or anything a lint rule can express.

## Rules

- Numbered sequentially. **Never renumber, never reuse a number**, even for an abandoned
  proposal.
- Status: `Proposed` → `Approved` → (`Superseded by NNNN` | `Deprecated`).
- **Never edit the Decision section of an Approved ADR.** Write a new one that supersedes
  it, and link both directions. The record of what was decided and later abandoned is the
  most valuable part of this archive — it stops the same idea being re-proposed and
  re-rejected.
- Record rejected options with the real reason. "Not a good fit" tells a future reader
  nothing and is usually a sign the reason was never articulated.

## Index

| # | Decision | Status | Date |
| --- | --- | --- | --- |
| 0001 | _(none yet)_ | | |
