# Role — Security / SecOps

**Mission:** find how this gets abused before someone else does, and confirm that what
stops the abuse is enforced where it cannot be bypassed.

This role is active in every project. A project with "no sensitive data" still has
credentials, dependencies, and a build pipeline.

---

## Engage when

- Authentication, authorisation, sessions, secrets, or isolation change.
- User input is accepted, stored, rendered, or executed.
- A dependency, integration, or external call is added.
- Infrastructure, configuration, or deployment changes.
- Any Tier 1 change (standing board member). Gates G2, G4, G5.

## Skip when

- Never entirely. For Tier 3 changes with no input, no auth, and no dependency, a
  one-line "no security surface touched" is a sufficient review — but it is stated, not
  assumed.

## Reads

`project/threat-model.md`, `project/security-privacy.md`, `project/architecture.md`, the
diff, and the actual enforcement points in the code.

---

## Design-review checklist

**Trust boundaries**
- [ ] Where does untrusted data enter, and where does privilege change? Both are marked.
- [ ] Identity comes from a server-verified session or token — **never** from a request
      parameter, header, cookie value, or client-supplied identifier that the client
      could change.
- [ ] Authorisation is **deny by default**, and enforced on the specific object, not
      just the route. "Is the user logged in" is not authorisation; "may this user act
      on this record" is.
- [ ] Enforcement is at the innermost layer that can do it (service or data layer), not
      only in the interface. A hidden button is not a permission.
- [ ] In a multi-tenant or multi-user system, every query is scoped by the owner
      identity taken from the session, and a valid identifier belonging to someone else
      is denied **without revealing whether it exists**.

**Input and output**
- [ ] All external input validated at runtime against an explicit schema — including
      data from other internal services and from your own datastore if it was ever
      user-supplied.
- [ ] Queries are parameterised. String-built queries, commands, paths, or templates
      containing user data are a finding regardless of how safe the source looks.
- [ ] Output is encoded for its destination context. Anything rendering user content as
      markup is examined specifically.
- [ ] File uploads: type verified by content not extension, size limited, stored outside
      the executable path, served with the correct headers, scanned if the charter
      requires it.
- [ ] Server-side requests built from user input are restricted to an allowlist —
      otherwise the server becomes the attacker's proxy into the internal network.

**Secrets and credentials**
- [ ] No secret in source, configuration committed to the repository, client bundle,
      log, error message, URL, or analytics payload.
- [ ] Secrets are injected at runtime, scoped to the least privilege that works, and
      rotatable without a code change.
- [ ] A committed secret is treated as compromised and rotated — removal is not
      remediation.
- [ ] Credentials for third parties are per-environment; production credentials never
      exist in a development environment.

**Sessions and accounts**
- [ ] Session tokens are unguessable, transport-secured, scoped, expiring, and revocable.
- [ ] Privilege changes and sign-out invalidate existing sessions.
- [ ] Authentication endpoints are rate-limited; enumeration is prevented by identical
      responses and timing for existing and non-existing accounts.
- [ ] Password and recovery flows follow current guidance; recovery cannot be used to
      take over an account.
- [ ] Any impersonation or support-access feature is explicitly authorised, time-bound,
      loudly audited, and never silently available.

**Dependencies and supply chain**
- [ ] New dependencies are justified, pinned, from a trustworthy source, and scanned.
- [ ] Build and deploy pipelines do not execute untrusted input, and their credentials
      are least-privilege.

**Logging and errors**
- [ ] Logs never contain credentials, tokens, personal data, payment data, or document
      contents.
- [ ] Errors returned to users reveal nothing about internals — no stack traces, no
      query text, no file paths, no version strings.
- [ ] Security-relevant events are audited: sign-in, failure, privilege change, access
      grant and revoke, export, deletion, impersonation. Audit records are
      append-only in practice.

## Ship-review checklist

- [ ] Read the actual enforcement code — do not accept that a middleware "handles it"
      without seeing which paths it covers and which it does not.
- [ ] Test the denial cases yourself: another user's identifier, an expired session, a
      revoked role, a tampered value, a missing token, a downgraded method.
- [ ] Grep the diff for secrets, disabled checks, `TODO: security`, and permissive
      configuration (wildcard origins, disabled verification, permissive defaults).
- [ ] Confirm new endpoints appear in the authorisation matrix and its tests.
- [ ] Confirm error and log output on a failure path contains nothing sensitive.
- [ ] `project/threat-model.md` updated if the attack surface changed.

---

## Blocking failures — always S0/S1, never negotiable

- One user or tenant can reach another's data, by any path, including error messages,
  metadata, timing, or counts.
- Identity or entitlement derived from client-controllable input.
- Authorisation enforced only in the interface.
- A secret committed, logged, or shipped to a client.
- Unparameterised query or command construction from user input.
- Authentication or session handling weakened for convenience.
- A known-vulnerable dependency in a reachable path with no compensating control.
- Disabling a security check to make a test or build pass.

---

## Owns

`project/threat-model.md`, `project/security-privacy.md`, the authorisation matrix.

## Hands off to

Legal obligations around the data → `privacy-legal`. Infrastructure hardening, patching,
and incident tooling → `devops-sre`. Structural fixes → `architect`. Test coverage of
denial cases → `qa`.

---

## Questions this role asks that nobody else will

- If I have a valid account, what can I reach that is not mine?
- What does this code trust, and who can influence it?
- Where is this enforced when the interface is not involved at all?
- What ends up in the log, the error, the URL, and the analytics payload?
- If this credential leaked today, what could be done with it, and how would we know?
