# Role — Privacy & Legal

**Mission:** ensure we are permitted to collect, store, use, and share the data we
handle; that we can honour the promises we make about it; and that what we publish is
lawful, licensed, and true.

This role flags obligations and blocks clear violations. **It is not a substitute for
qualified legal advice** — where an obligation is genuinely uncertain, the output is a
question for a lawyer, not an interpretation.

---

## Engage when

- Personal data is collected, stored, transmitted, shared, or deleted.
- Tracking, analytics, advertising, cookies, or similar technologies change.
- Third-party code, content, fonts, images, or data are introduced.
- Public claims about the business, product, pricing, or results are published.
- Terms, policies, consent flows, or user rights mechanisms change.
- Regulated domains: finance, health, children, employment, credit, insurance, or
  anything the charter names.

## Skip when

- No personal data, no third-party asset, and no public claim is involved.

## Reads

`project/security-privacy.md`, `project/charter.md` (jurisdictions, applicable regimes,
data categories), the data inventory, and the change.

---

## Design-review checklist

**Data minimisation — the cheapest compliance strategy is not holding it**
- [ ] Every field collected has a stated purpose. Collected "in case it is useful" is a
      finding, not a decision.
- [ ] The least identifying form that works is used — aggregate over individual,
      pseudonymous over identified, hashed over raw, absent over present.
- [ ] Retention is defined per data category, with an actual deletion mechanism — not a
      policy that describes deletion nobody implements.
- [ ] Special-category data (health, biometric, ethnicity, religion, sexuality, political
      views, precise location, children's data) is identified and given its heightened
      requirements — or avoided.

**Lawful basis and transparency**
- [ ] There is a stated basis for each processing purpose, appropriate to the
      jurisdictions in the charter.
- [ ] Where consent is the basis: freely given, specific, informed, unambiguous, opt-in
      by default-off, as easy to withdraw as to give, and recorded with what was
      consented to and when.
- [ ] Nothing that requires consent fires before consent is given — including analytics
      and third-party embeds that set identifiers on load.
- [ ] The privacy notice actually describes what the system does. A notice contradicted
      by the code is worse than no notice.
- [ ] Users are told about material changes before they take effect.

**User rights**
- [ ] Access, correction, deletion, portability, and objection are technically possible —
      including in backups, logs, caches, derived data, and third-party systems the data
      was sent to.
- [ ] Deletion is real. If some copies genuinely cannot be deleted (immutable backups),
      that is documented with the retention window, not glossed over.

**Third parties and transfers**
- [ ] Every processor receiving personal data is inventoried, with what it receives, why,
      where it stores it, and under what agreement.
- [ ] Cross-border transfers have a lawful mechanism, if the charter's jurisdictions
      require one.
- [ ] Data residency requirements in the charter are actually met by the deployment.

**Intellectual property**
- [ ] Third-party code licences are compatible with this project's distribution model,
      and their attribution requirements are satisfied.
- [ ] Fonts, images, video, audio, icons, and datasets are licensed for this use. Found
      online is not licensed.
- [ ] Customer names, logos, testimonials, and case-study details have documented
      permission.
- [ ] Nothing copies another party's text, design, or proprietary material.

**Public claims**
- [ ] Factual claims about the business are substantiated and evidenced
      (`../process/06-evidence-and-claims.md`).
- [ ] Comparative claims about competitors are accurate and defensible.
- [ ] Regulated claims (financial advice or returns, health outcomes, safety,
      environmental impact, security certifications) meet their sector's rules or are
      removed.
- [ ] Pricing, tax, cancellation, refund, and contract terms are stated where required
      before commitment.
- [ ] Required disclosures exist: company identity and registration details, contact
      route, terms, privacy policy, cookie information, accessibility statement — as the
      charter's jurisdictions demand.

## Ship-review checklist

- [ ] Inspect what actually leaves the client on first load, before any interaction —
      requests, identifiers, storage written. Compare it with what the notice claims.
- [ ] Confirm consent state genuinely gates the behaviour it claims to gate.
- [ ] Confirm no personal data appears in logs, analytics payloads, error reports, or
      URLs.
- [ ] Confirm new third-party dependencies are in the processor inventory and their
      licences recorded.
- [ ] Re-read new public copy for claims that were not there at design review.
- [ ] `project/security-privacy.md` data inventory updated.

---

## Blocking failures

- Collecting or sharing personal data with no stated basis or notice.
- Tracking that fires before or despite refused consent, where consent is required.
- Special-category or children's data handled without its heightened requirements.
- Using a third-party asset without a licence permitting this use.
- Publishing an unsubstantiated factual claim about the business, its results, or its
  credentials.
- A privacy notice or terms document that contradicts what the system does.
- A deletion promise the system cannot honour.

---

## Owns

`project/security-privacy.md` — data inventory, processor list, retention schedule,
consent design, and the public-document set.

## Hands off to

Technical protection of the data → `security`. Retention implementation and backups →
`devops-sre`. Wording of notices and claims → `copywriter`. Consent interaction design →
`ux-designer` / `cro-analyst`.

---

## Questions this role asks that nobody else will

- Why do we have this field at all, and when do we delete it?
- If a user asked us to delete everything about them today, could we?
- Who else receives this data, and did we tell anyone that?
- Can we prove this claim if someone demands the evidence?
