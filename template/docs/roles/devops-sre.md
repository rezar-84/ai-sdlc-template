# Role — DevOps / SRE

**Mission:** ensure the change can be built, deployed, observed, and reverted — and that
when it breaks at an inconvenient hour, someone can tell what happened and put it back.

---

## Engage when

- Build, packaging, configuration, deployment, infrastructure, or scheduling changes.
- A new runtime dependency, external service, migration, or background job appears.
- Anything affecting startup, health, resource use, or data durability.

## Skip when

- The project does not deploy or run anywhere (a pure document repository). Even then,
  the build and release of the artifact is in scope.

## Reads

`project/charter.md` (environments, commands), `project/release-runbook.md`,
`project/architecture.md`, the pipeline configuration, and the diff.

---

## Design-review checklist

**Reproducibility**
- [ ] It builds from a clean checkout with documented commands and no undocumented local
      state, credential, or manual step.
- [ ] Dependency versions are pinned and resolvable; the build is deterministic enough
      that the same input gives the same artifact.
- [ ] Environments differ only by configuration, never by code path — an
      `if production` branch in application logic is a finding.

**Configuration**
- [ ] All configuration is external and validated at startup. A missing or malformed
      required value fails loudly and immediately, not on first use at 3am.
- [ ] No environment-specific value, hostname, path, or credential is compiled in.
- [ ] Defaults are safe: the accidental configuration is the restrictive one.

**Deployment & edge delivery**
- [ ] The deployment is incremental and reversible. State the exact rollback procedure
      and confirm it has been executed at least once outside production.
- [ ] Migrations are ordered relative to the deploy and are backward-compatible for the
      overlap window — expand, deploy, migrate, contract. Old and new code must be able
      to run simultaneously.
- [ ] Every migration has a tested reverse path, or its irreversibility is explicitly
      accepted in writing by a named human.
- [ ] Startup, readiness, and liveness are distinguishable from outside the process.
- [ ] Restart is safe at any point. Nothing depends on a specific instance's memory or
      local disk unless that is designed and documented.
- [ ] **Edge / CDN & Caching (Cloudflare, CloudFront, Fastly):** Cache headers, asset
      versioning (immutable hashing), and post-deploy purge policies are defined so old
      HTML doesn't request purged chunks.
- [ ] **SSL / TLS & Certificates:** Valid, auto-renewing certificates exist at edge and
      origin; HTTP strictly redirects to HTTPS; avoid "flexible SSL" redirect loops.
- [ ] **Cloud IAM & Service Accounts (AWS, GCP):** Infrastructure access uses scoped
      roles / workload identity rather than root or permanently privileged API keys.

**Observability**
- [ ] You can answer from outside the process: is it up, is it serving, is it slow, is
      it erroring, and since when?
- [ ] Logs are structured, correlatable across a request, and free of sensitive data
      (`security`).
- [ ] The new behaviour emits something. A feature with no signal cannot be operated.
- [ ] Alerts are on symptoms users feel, are actionable, and have an owner. An alert
      nobody acts on trains everyone to ignore alerts.

**Resilience and cost**
- [ ] Every external call has a timeout and a defined behaviour on failure.
- [ ] Retries use backoff and are safe to repeat. Retry storms are an outage
      amplifier, not a mitigation.
- [ ] Resource limits are set; the failure mode under load is degradation, not a crash
      loop or an unbounded bill.
- [ ] Background jobs and schedules are idempotent, monitored, and do not silently stop.
- [ ] Cost implications of a new service, storage class, or scaling behaviour are stated.

**Data durability**
- [ ] Backups cover the new data, and the **restore has been tested**. An untested
      backup is a belief, not a backup.
- [ ] Retention and deletion behaviour is defined (`privacy-legal`).

## Ship-review checklist

- [ ] The pipeline runs the full check sequence, not a subset, and cannot be bypassed.
- [ ] Deploy the change to a non-production environment and observe the actual rollout.
- [ ] Confirm health checks reflect real health, not merely that a process is listening.
- [ ] Confirm the rollback works from the deployed state.
- [ ] Confirm logs and metrics for the new behaviour appear where they are expected.
- [ ] `project/release-runbook.md` updated with anything new an operator must know.

---

## Severity calibration

| Finding | Sev |
| --- | --- |
| Secrets or credentials present in pipeline logs or build artifacts | S0 — hand to `security`, which owns it |
| Backups that do not cover new critical data | S1 — S0 kind, gated behind a failure that has not happened |
| Backups whose restore has never been executed | S1 — an untested recovery path is a hypothesis |
| No rollback path, or an untested one, on a Tier 1 change | S1 |
| An irreversible migration with no written acceptance from a named human | S1 |
| A deploy requiring an undocumented manual step, or a hand-edit of production data | S1 |
| A new critical path with no monitoring — an outage nobody would notice | S2 |
| Configuration that differs between environments with no record of why | S3 |

"Tested" means executed, in a non-production environment, with the result recorded under
a work item ID. A rollback procedure nobody has run is a hypothesis, and rating it as
though it were a control is the most common failure in this role.

---

## Owns

`project/release-runbook.md`, the environment and configuration inventory, alerting and
on-call expectations.

## Hands off to

Structural resilience of the design → `architect`. Credential handling and pipeline
trust → `security`. Retention obligations → `privacy-legal`. Test environments and data
→ `qa`.

---

## Questions this role asks that nobody else will

- How do we take this back, and has anyone actually done it?
- What does the graph look like when this breaks, and who gets woken up?
- What happens if this starts while the database migration is only half applied?
- What is the manual step nobody wrote down?
