---
status: draft
owner: devops-sre
last-reviewed: YYYY-MM-DD
---

# Release runbook — {{PROJECT_NAME}}

> Written so that someone who did not build the change can execute it, and so that
> someone woken at 3am can reverse it. If a step needs knowledge that is only in
> somebody's head, that is the finding.

## Environments

Purpose, source branch, and who may deploy are declared in `charter.md` → Environments.
Add only the deploy-time specifics here:

| Environment | URL / target | Deploy command or pipeline | Smoke check after deploy |
| --- | --- | --- | --- |
| local | `http://localhost:PORT` | `docker compose up -d` / dev server | Local smoke script / unit test suite |
| staging / preview | `https://staging.example.com` | CI/CD on push to branch/PR | Automated E2E & integration suite |
| production | `https://example.com` | Protected pipeline / Dokploy webhook | Production smoke checks below |
| backup / dr | Storage bucket / standby node | Scheduled snapshot cron / replication sync | Periodic restore verification script |

### Promotion path

All changes must follow the standard progression:
`local` (developer verification) ➔ `staging` (automated CI/CD & integration checks) ➔ `production` (guarded deployment).
Direct pushes or untested jumps to production are prohibited.

### Dokploy / Self-hosted PaaS deployment

When deploying via Dokploy or containerized PaaS:
- [ ] **Persistent volumes:** State/upload directories and database storage must bind to persistent named volumes or host mounts. Verify data persists across container redeployments.
- [ ] **Traefik routing & SSL:** Router rules (`traefik.http.routers.<app>.rule=Host(...)`) and TLS certresolvers (`traefik.http.routers.<app>.tls.certresolver=letsencrypt`) are configured. Test HTTP-to-HTTPS redirect.
- [ ] **Zero-downtime rolling deploys:** Health check probe (`HEALTHCHECK` in Dockerfile or Dokploy container healthcheck) must return HTTP 200 before Traefik shifts live traffic to the newly spawned container.
- [ ] **Environment variables & secrets:** App secrets injected via Dokploy dashboard / `.env` secrets store; never baked into Docker images or committed to Git.

## Pre-flight

- [ ] All checks green on the release commit (`../process/04-quality-gates.md`).
- [ ] No open S0/S1; S2 waivers recorded with follow-up IDs.
- [ ] Required approvals obtained.
- [ ] Migrations reviewed, with the reverse path tested in a non-production environment.
- [ ] Backup current and **restore verified** — not merely scheduled (see Backup & restore procedure below).
- [ ] Configuration and secrets present in the target environment, validated at startup.
- [ ] Dependent teams or consumers notified of anything breaking.
- [ ] Rollback procedure below re-read and known to work for this change.

## Procedure

1. _(Step, with the exact command or action — e.g. trigger Dokploy webhook or run CI/CD deployment pipeline.)_
2. _(Migration order relative to the deploy — state whether it runs before, during, or
   after, and whether old code can run against the new schema.)_
3. _(Deploy.)_
4. _(Post-deploy steps: CDN cache purge for Cloudflare/CloudFront, index rebuild, feature flag, warm-up.)_

State the expected duration and what "still normal" looks like at each step.

## Smoke checks

The minimum set proving the release is alive. Run every time; automate where possible.

- [ ] _(Critical journey 1 — completes end to end.)_
- [ ] _(Critical journey 2.)_
- [ ] _(Authentication works, and denial still denies.)_
- [ ] _(A representative write reaches the datastore and is readable back.)_
- [ ] _(SSL / TLS certificate is valid, expiration healthy, HTTPS redirect verified without redirect loops.)_
- [ ] _(Search Console verification tag/file and Analytics/GTM container IDs present and functional.)_
- [ ] _(Health, error rate, and latency within normal range.)_

## Monitoring window

- Watch for: _(duration)_
- Signals: _(error rate, latency, queue depth, specific business metric)_
- **Rollback trigger:** _(the specific, pre-agreed threshold — decided now, not during
  the incident, when the temptation is always to wait one more minute.)_

## Rollback

1. _(Exact steps.)_
2. _(Data implications — what happens to records written by the new version, and whether
   the old version can read them.)_
3. _(Who to tell.)_

**Last executed:** _(date, environment. If this says "never", the rollback is a theory.)_

## Backup & restore procedure

> An untested backup is an assumption, not a recovery plan. Restore drills must be executed
> periodically in an isolated/staging environment to verify data integrity.

- [ ] **Snapshot creation:** Backup datastores (database dump, object store snapshot, state volumes) prior to release.
- [ ] **Storage replication:** Verify snapshot is pushed to an offsite or secondary durable bucket (e.g. S3, R2, GCS, separate storage node).
- [ ] **Restore command:** `_(Exact command or script to restore snapshot into a fresh environment)_`
- [ ] **Data integrity verification:**
  - Check record counts and checksums against pre-backup baseline.
  - Verify relational integrity and constraints.
  - Test application boot and primary query against restored database.
- **Last restore drill executed:** _(date, target environment, recovery time achieved)_

## Communications

| Audience | When | Channel | Message owner |
| --- | --- | --- | --- |

## Post-release

- [ ] Backlog IDs in the release marked `Done`.
- [ ] Worklog entry written, including what was verified in production.
- [ ] Metrics baselined for anything the measurement plan tracks.
- [ ] Anything learned folded back into this runbook — while it is still fresh.
