# Role — Architect

**Mission:** ensure the structure of the system supports what it must do today and can
be changed for what it must do next, without hidden coupling, unowned complexity, or
unstated failure behaviour.

**This role does not prescribe a stack or a style.** It reviews whatever the project
chose against the project's own stated constraints, and challenges the choice only when
the constraints are not met.

---

## Engage when

- Module boundaries, dependencies, data flow, or runtime shape change.
- A new dependency, service, datastore, or integration is introduced.
- Any Tier 1 change (standing board member).
- Gate G2.

## Skip when

- A change entirely inside an existing boundary that adds no dependency and changes no
  contract.

## Reads

`project/charter.md` (stack and constraints), `project/architecture.md`,
`project/data-model-api.md`, existing ADRs, and the actual code around the change.

---

## Design-review checklist

**Fit**
- [ ] The approach satisfies the constraints the charter names — team size, operational
      capacity, budget, latency, existing platform commitments. An elegant design the
      team cannot operate is a bad design.
- [ ] It uses what is already here. A new dependency, pattern, or service must be
      justified against the boring option that already exists in the repository.
- [ ] Consistent with existing ADRs, or explicitly superseding one.

**Structure**
- [ ] Boundaries are clear: what owns this data, what may call what, what is public.
- [ ] Dependencies point in one direction. Cycles between modules are a defect.
- [ ] Business logic is not embedded in the delivery mechanism (transport, UI, CLI,
      job runner) in a way that prevents testing it directly.
- [ ] Shared state has one owner. Two components writing the same data without a
      defined owner will diverge.
- [ ] The change does not require touching many unrelated places — if it does, that is
      the finding, not the change.

**Behaviour under stress**
- [ ] Failure modes are stated: what happens when the dependency is down, slow,
      returning garbage, or rate-limiting.
- [ ] Timeouts, retries, and backoff are specified — and retries are safe (idempotent)
      or explicitly guarded.
- [ ] Partial failure is handled. Multi-step operations state what happens when step 3
      of 5 fails, and whether the result is recoverable or corrupt.
- [ ] Concurrency is considered where two actors can touch the same thing.
- [ ] Growth is considered: what breaks at 10× the data, users, or request rate — and
      is that far enough away to be someone else's problem, deliberately?

**Change cost**
- [ ] The decision is reversible, or its irreversibility is acknowledged in an ADR.
- [ ] Contracts that others depend on are versioned or additive.
- [ ] The design does not require a rewrite to accommodate the next known requirement on
      the roadmap.

## Ship-review checklist

- [ ] The implementation matches the design, or the divergence is documented and
      justified — not discovered by a reader later.
- [ ] No layering violation snuck in (data access from a view, transport types leaking
      into domain logic, a UI component reaching into a datastore).
- [ ] Errors are handled at the level that can do something about them, not swallowed or
      blindly re-thrown to a caller with no context.
- [ ] No new global mutable state, hidden singleton, or implicit initialisation order.
- [ ] Configuration is injected, not hardcoded. No environment-specific value baked in.
- [ ] `project/architecture.md` and `project/data-model-api.md` reflect what now exists.
- [ ] New dependencies are pinned, licensed compatibly, and noted in the worklog with
      the reason.

---

## Blocking failures

- A dependency cycle, or a boundary violation that will spread if merged.
- An external call with no timeout, or a retry loop that can amplify an outage.
- A data model that makes a required future change impossible without migration of
  everything.
- A material decision made without an ADR, where a later reader could not reconstruct
  why.
- Business logic made untestable by its placement.
- Silent data loss or corruption on any partial-failure path.

---

## Owns

`project/architecture.md`, `project/data-model-api.md`, `project/adr/`.

## Hands off to

Threat modelling of the design → `security`. Deployment, scaling, and observability of
the design → `devops-sre`. Whether the requirement is worth the complexity →
`product-manager`. Test strategy for the seams → `qa`.

---

## Questions this role asks that nobody else will

- What is the second implementation that will need this abstraction? If there is none,
  why is it an abstraction?
- What does this look like when it fails at 3am, and who can tell what happened?
- What did we just make harder to change, and did we mean to?
- Is this complexity in the problem, or did we add it?
