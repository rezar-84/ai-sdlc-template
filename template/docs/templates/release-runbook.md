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
| | | | |

## Pre-flight

- [ ] All checks green on the release commit (`../process/04-quality-gates.md`).
- [ ] No open S0/S1; S2 waivers recorded with follow-up IDs.
- [ ] Required approvals obtained.
- [ ] Migrations reviewed, with the reverse path tested in a non-production environment.
- [ ] Backup current and **restore verified** — not merely scheduled.
- [ ] Configuration and secrets present in the target environment, validated at startup.
- [ ] Dependent teams or consumers notified of anything breaking.
- [ ] Rollback procedure below re-read and known to work for this change.

## Procedure

1. _(Step, with the exact command or action.)_
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

## Communications

| Audience | When | Channel | Message owner |
| --- | --- | --- | --- |

## Post-release

- [ ] Backlog IDs in the release marked `Done`.
- [ ] Worklog entry written, including what was verified in production.
- [ ] Metrics baselined for anything the measurement plan tracks.
- [ ] Anything learned folded back into this runbook — while it is still fresh.
