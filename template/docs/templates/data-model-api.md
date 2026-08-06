---
status: draft
owner: architect
last-reviewed: YYYY-MM-DD
---

# Data model & interfaces — {{PROJECT_NAME}}

## Entities

| Entity | Represents | Owned by | Lifecycle | Personal data? |
| --- | --- | --- | --- | --- |
| | | _(component)_ | _(created / updated / deleted by what)_ | _(yes → privacy-legal)_ |

For each entity, state:

- **Fields** and their constraints — required, unique, bounded, validated how.
- **Relationships** and their cardinality, plus what happens on delete (cascade,
  restrict, orphan — pick deliberately, do not inherit the default).
- **Ownership** — which user, account, or tenant this record belongs to, and how that is
  established. This is the field every authorisation check will scope by.
- **Retention** — how long it lives and what deletes it.

## Invariants

_(Things that must always be true, and where they are enforced. An invariant enforced
only in application code will eventually be violated by a migration, a script, or a
second code path. State where the real guard is.)_

## Migrations

- Naming and ordering convention.
- Backward compatibility rule: _(expand → deploy → migrate → contract)_
- Reverse path requirement: _(every migration, or explicitly accepted exceptions)_
- Where seed and fixture data live, and how they differ from production.

## Interfaces

For each API, event, or contract others depend on:

| Operation | Purpose | Auth required | Idempotent | Consumers |
| --- | --- | --- | --- | --- |
| | | | | |

Per operation, specify:

- **Input** — schema, validation rules, size limits.
- **Output** — success shape, and the shape of each error.
- **Errors** — the full set, with what a caller should do about each.
- **Authorisation** — not "authenticated", but *which* actor may act on *which* object.
- **Idempotency** — for anything that can be retried, how repetition is made safe.
- **Rate limits / quotas.**

## Versioning & compatibility

_(How a breaking change is made without breaking consumers, and how consumers are told.
A contract with no versioning story will be broken by accident.)_

## Authorisation matrix

The reference for both implementation and tests. Every row needs a test
(`../roles/security.md`, `../roles/qa.md`).

| Actor | Resource | Create | Read | Update | Delete | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| | | | | | | |

Include the denial rows explicitly: another owner's record, a revoked actor, an expired
session. A matrix that lists only what is allowed cannot be tested for what is forbidden.
