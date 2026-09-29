"""The model behind `sdlc.py view`: the project's records, read now, joined by work item ID.

Read-only. It parses the formats the kit's own templates define -- backlog tables by
header name, worklog entries by `## ID — title` heading or the compact Tier 3 line,
plans, reviews, defects and postmortems by file name -- and writes one self-contained page
to .ai-sdlc/view/index.html, which git ignores. Nothing it cannot read is dropped: it is
listed under "unread" so the page can say so.

Called by sdlc.py, which passes itself in as `rt` so the two share one set of parsers.
This file must never contain two opening braces in a row (see sdlc.py).
"""

import datetime
import json
import os
import re
import webbrowser

# Backlog statuses, in the order the board shows them, and the column each belongs to.
COLUMNS = (("Now", ("In progress", "In review")), ("Next", ("Ready",)),
           ("Blocked", ("Blocked",)), ("Parked", ("Parked",)), ("Later", ("Deferred",)),
           ("Done", ("Done",)), ("Dropped", ("Dropped",)))
STEPS = ("Frame", "Plan", "Design review", "Build", "Verify", "Ship review", "Log", "Close")
RECORD_DIRS = ("plans", "reviews", "defects", "postmortems", "adr")
MAX_DOC_CHARS = 400000
MAX_COMMITS = 3000


def plain(cell):
    """A table cell without the markdown a human reads past."""
    cell = re.sub(r"_\([^)]*\)_", "", cell or "")
    cell = re.sub(r"\*\*|__|`|~~", "", cell)
    return cell.strip()


def column_of(status):
    for name, statuses in COLUMNS:
        if status in statuses:
            return name
    return "Other"


def headings(text):
    out, fence = [], False
    for n, line in enumerate(text.splitlines()):
        if line.startswith("```"):
            fence = not fence
        if fence:
            continue
        m = re.match(r"^(#{1,4})\s+(.*\S)\s*$", line)
        if m:
            out.append({"level": len(m.group(1)), "text": m.group(2), "line": n})
    return out


# ---------------------------------------------------------------- backlog

def backlog_tables(text):
    """Every table under a `## ` section whose header has ID and Status columns."""
    rows, section, header = [], "", None
    for n, line in enumerate(text.splitlines()):
        if line.startswith("## "):
            section, header = line[3:].strip(), None
            continue
        cells = None
        body = line.strip()
        if body.startswith("|") and body.endswith("|"):
            cells = [c.strip().replace("\\|", "|")
                     for c in re.split(r"(?<!\\)\|", body[1:-1])]
        if cells is None:
            header = None
            continue
        if header is None:
            names = [plain(c) for c in cells]
            header = names if "ID" in names and "Status" in names else False
            continue
        if header is False or set("".join(cells)) <= set("-: "):
            continue
        rows.append((section, n + 1, dict(zip(header, cells))))
    return rows


def epics(text, ids):
    """An optional `| Epic | Items | ... |` table. The kit does not require one."""
    out, header = [], None
    for line in text.splitlines():
        body = line.strip()
        if not (body.startswith("|") and body.endswith("|")):
            header = None
            continue
        cells = [c.strip() for c in re.split(r"(?<!\\)\|", body[1:-1])]
        if header is None:
            names = [plain(c) for c in cells]
            header = names if "Epic" in names and "Items" in names else False
            continue
        if header is False or set("".join(cells)) <= set("-: "):
            continue
        row = dict(zip(header, cells))
        members = [i for i in ids.findall(row.get("Items", ""))]
        extra = dict((k, plain(v)) for k, v in row.items() if k not in ("Epic", "Items"))
        out.append({"name": plain(row.get("Epic", "")), "items": members, "extra": extra})
    return out


# ---------------------------------------------------------------- worklog

def worklog_entries(text, source, id_re):
    """Full entries (`## ID — title` with `### ` subsections) and compact Tier 3 lines
    (`- YYYY-MM-DD · ID · request · ...`)."""
    entries, current, sub = [], None, None
    for n, line in enumerate(text.splitlines()):
        if line.startswith("## "):
            m = re.match(r"^##\s+(%s)\s+[—-]+\s*(.*)$" % id_re.pattern, line)
            current = None
            if m:
                current = {"id": m.group(1), "title": m.group(2).strip(), "source": source,
                           "line": n + 1, "date": "", "status": "", "sections": {},
                           "compact": False}
                entries.append(current)
                sub = "_head"
            continue
        compact = re.match(r"^- (\d{4}-\d{2}-\d{2}) · (%s) · (.*)$" % id_re.pattern, line)
        if compact:
            current, sub = None, None
            parts = [p.strip() for p in compact.group(3).split(" · ")]
            entries.append({"id": compact.group(2), "title": parts[0], "source": source,
                            "line": n + 1, "date": compact.group(1), "status": "Done",
                            "sections": {"Summary": " · ".join(parts[1:])},
                            "compact": True})
            continue
        if current is None:
            continue
        if line.startswith("### "):
            sub = line[4:].strip()
            current["sections"][sub] = ""
            continue
        if sub == "_head":
            m = re.search(r"\*\*Date:\*\*\s*(\d{4}-\d{2}-\d{2})", line)
            if m:
                current["date"] = m.group(1)
            m = re.search(r"\*\*Status:\*\*\s*([A-Za-z]+)", line)
            if m:
                current["status"] = m.group(1)
            continue
        if sub:
            current["sections"][sub] += line + "\n"
    for entry in entries:
        entry["sections"] = dict((k, v.strip()) for k, v in entry["sections"].items())
    return entries


# ---------------------------------------------------------------- model

def build(rt, project):
    prefix = project.prefix
    docs_root = os.path.join(project.docs, "project")
    id_re = re.compile(r"%s-[0-9]+" % re.escape(prefix)) if prefix else re.compile(r"(?!x)x")
    model = {
        "generated": datetime.datetime.now().strftime("%Y-%m-%d %H:%M"),
        "project": plain(rt.labelled(project.charter, "Project") or "") or
                   os.path.basename(project.root),
        "prefix": prefix, "docs_dir": project.docs,
        "git_head": project.git("rev-parse", "--short", "HEAD").strip(),
        "columns": [c for c, _ in COLUMNS] + ["Other"], "steps": list(STEPS),
        "items": {}, "order": [], "epics": [], "worklog": [], "docs": [], "unread": [],
        "alerts": [],
    }
    if not prefix:
        model["unread"].append({"path": project.charter_path,
                                "reason": "no work item prefix in the charter, so no ID "
                                          "can be recognised"})

    # Backlog rows.
    backlog_rel = os.path.join(docs_root, "backlog.md")
    backlog = rt.read(project.path(backlog_rel))
    rows = backlog_tables(backlog)
    for section, line, row in rows:
        raw_id = plain(row.get("ID", ""))
        if not id_re.fullmatch(raw_id):
            if raw_id and not raw_id.startswith("_("):
                model["unread"].append({"path": "%s:%d" % (backlog_rel, line),
                                        "reason": "ID %r is not %s-###" % (raw_id, prefix)})
            continue
        status = plain(row.get("Status", ""))
        known = ("ID", "Task", "Tier", "Owner role", "Depends on", "Status")
        item = model["items"].setdefault(raw_id, {"id": raw_id})
        item.update({
            "title": plain(row.get("Task", "")), "tier": plain(row.get("Tier", "")),
            "owner": plain(row.get("Owner role", "")),
            "depends": id_re.findall(row.get("Depends on", "")),
            "depends_text": plain(row.get("Depends on", "")),
            "status": status, "column": column_of(status), "section": section,
            "row": "%s:%d" % (backlog_rel, line),
            "extra": dict((k, plain(v)) for k, v in row.items() if k not in known and v),
        })
        if raw_id not in model["order"]:
            model["order"].append(raw_id)
    model["epics"] = epics(backlog, id_re)

    # Worklog, active then archive.
    sources = [os.path.join(docs_root, "worklog.md")]
    archive = project.path(os.path.join(docs_root, "worklog-archive"))
    if os.path.isdir(archive):
        sources += [os.path.join(docs_root, "worklog-archive", n)
                    for n in sorted(os.listdir(archive)) if n.endswith(".md")]
    for rel in sources:
        model["worklog"].extend(worklog_entries(rt.read(project.path(rel)), rel, id_re))

    # Every markdown record under project/, plus the contract and the card.
    doc_paths = ["AGENTS.md", os.path.join(project.docs, "CARD.md")]
    for base, _, files in sorted(os.walk(project.path(docs_root))):
        for name in sorted(files):
            if name.endswith(".md"):
                doc_paths.append(os.path.relpath(os.path.join(base, name), project.root))
    for rel in doc_paths:
        text = rt.read(project.path(rel))
        if not text:
            continue
        kind = "record"
        parts = rel.replace(os.sep, "/").split("/")
        for d in RECORD_DIRS:
            if d in parts[:-1]:
                kind = d
        if parts[-1] == "README.md" and kind in RECORD_DIRS:
            kind = "index"
        if "worklog-archive" in parts:
            kind = "archive"
        truncated = len(text) > MAX_DOC_CHARS
        meta = rt.frontmatter(text)
        doc = {"path": rel.replace(os.sep, "/"), "kind": kind,
               "title": next((h["text"] for h in headings(text) if h["level"] == 1),
                             parts[-1]),
               "meta": meta, "headings": headings(text),
               "mentions": sorted(set(id_re.findall(text))),
               "text": text[:MAX_DOC_CHARS], "truncated": truncated}
        m = re.match(r"^(%s)(?:-(design|ship))?" % id_re.pattern, parts[-1])
        doc["owner_id"] = m.group(1) if m and kind in RECORD_DIRS else ""
        doc["stage"] = (m.group(2) or "") if m else ""
        model["docs"].append(doc)

    # Commits that name an ID.
    log = project.git("log", "-n", str(MAX_COMMITS), "--date=short",
                      "--format=%h%x1f%ad%x1f%s")
    commits = {}
    for line in log.splitlines():
        parts = line.split("\x1f")
        if len(parts) != 3:
            continue
        for found in set(id_re.findall(parts[2])):
            commits.setdefault(found, []).append({"sha": parts[0], "date": parts[1],
                                                  "subject": parts[2]})

    # Join everything onto the items. An ID seen only in the records still gets a node.
    def item(i):
        if i not in model["items"]:
            model["items"][i] = {"id": i, "title": "", "status": "", "column": "Other",
                                 "orphan": True, "depends": [], "extra": {}}
            model["order"].append(i)
        return model["items"][i]
    for n, entry in enumerate(model["worklog"]):
        it = item(entry["id"])
        it.setdefault("worklog", []).append(n)
        if not it.get("title"):
            it["title"] = entry["title"]
    for n, doc in enumerate(model["docs"]):
        if doc["owner_id"]:
            item(doc["owner_id"]).setdefault("records", []).append(n)
        for mention in doc["mentions"]:
            if mention in model["items"] and mention != doc["owner_id"]:
                model["items"][mention].setdefault("mentioned_in", []).append(n)
    for i, found in commits.items():
        if i in model["items"]:
            model["items"][i]["commits"] = found[:50]
    for it in model["items"].values():
        for dep in it.get("depends", []):
            if dep in model["items"]:
                model["items"][dep].setdefault("dependents", []).append(it["id"])
        it["steps"] = lifecycle(it, model)

    model["metrics"] = metrics(rt, project, model)

    # The mechanical doctor findings are the home page's alerts.
    try:
        model["alerts"] = rt.doctor(project)
    except Exception as exc:  # the view must open even when a check breaks
        model["alerts"] = [{"level": "warn", "check": "view", "where": "",
                            "message": "doctor could not run: %s" % exc}]
    return model


def lifecycle(it, model):
    """Frame -> Close, each step done / missing / n/a, from which records exist."""
    records = [model["docs"][n] for n in it.get("records", [])]
    kinds = set((d["kind"], d["stage"]) for d in records)
    entries = [model["worklog"][n] for n in it.get("worklog", [])]
    tier = it.get("tier", "")
    verified = any(any(re.search(r"verif", name, re.I) for name in e["sections"])
                   or "verified:" in e["sections"].get("Summary", "") for e in entries)
    done = it.get("column") == "Done"
    started = it.get("column") in ("Now", "Done")  # before work starts, nothing is owed yet

    def need(present, required=True):
        return "done" if present else ("missing" if required else "n/a")
    return {
        "Frame": need(bool(it.get("row"))),
        "Plan": need(("plans", "") in kinds, tier == "1" and started),
        "Design review": need(("reviews", "design") in kinds, tier == "1" and started),
        "Build": need(bool(it.get("commits")), done),
        "Verify": need(verified, done),
        "Ship review": need(("reviews", "ship") in kinds, tier == "1" and done),
        "Log": need(bool(entries), done),
        "Close": need(done, False) if not done else "done",
    }


# ---------------------------------------------------------------- metrics

def _date(value):
    m = re.search(r"(\d{4})-(\d{2})-(\d{2})", value or "")
    return datetime.date(int(m.group(1)), int(m.group(2)), int(m.group(3))) if m else None


def _median(values):
    values = sorted(values)
    if not values:
        return None
    mid = len(values) // 2
    return values[mid] if len(values) % 2 else (values[mid - 1] + values[mid]) / 2.0


def metrics(rt, project, model, today=None):
    """Process measures computed only from what the records and git already hold. Each is
    labelled leading (moves early) or lagging (confirms later), and says what it is from."""
    today = today or datetime.date.today()
    items = model["items"].values()
    out = []

    def add(name, kind, value, basis):
        out.append({"name": name, "kind": kind, "value": value, "basis": basis})

    def first_commit(it):
        dates = [_date(c["date"]) for c in it.get("commits", [])]
        dates = [d for d in dates if d]
        return min(dates) if dates else None

    now = [it for it in items if it.get("column") == "Now"]
    ages = [(today - first_commit(it)).days for it in now if first_commit(it)]
    add("Work in progress", "leading", "%d items, oldest %s" % (
        len(now), "%d days" % max(ages) if ages else "unknown"),
        "Now rows; age from each item's first commit")

    waiting = [it for it in items if it.get("column") in ("Blocked", "Parked")]
    waits = [(today - _date(it["extra"].get("Since"))).days for it in waiting
             if _date(it.get("extra", {}).get("Since"))]
    add("Waiting on a human", "leading", "%d items, oldest %s" % (
        len(waiting), "%d days" % max(waits) if waits else "unknown"),
        "Blocked and Parked rows, their Since cell")

    runs = []
    folder = project.path(os.path.join(".ai-sdlc", "evidence"))
    if os.path.isdir(folder):
        for name in sorted(os.listdir(folder)):
            try:
                with open(os.path.join(folder, name, "summary.json"), encoding="utf-8") as h:
                    runs.append(json.load(h))
            except (IOError, OSError, ValueError):
                continue
    ran = [r for r in runs if any(e["result"].startswith("Verified") for e in r["stages"])]
    passed = [r for r in ran if not any(e["result"].startswith("Verified: fail")
                                        for e in r["stages"])]
    add("Verify pass rate", "leading",
        "%d of %d runs (%d%%)" % (len(passed), len(ran), 100 * len(passed) // len(ran))
        if ran else "no runs recorded", "sdlc.py verify evidence under .ai-sdlc/evidence/")

    done = [it for it in items if it.get("column") == "Done"]
    recent = [it for it in done if _date(it.get("extra", {}).get("Completed"))
              and (today - _date(it["extra"]["Completed"])).days <= 28]
    add("Throughput", "lagging", "%d items in the last 4 weeks" % len(recent),
        "Done rows, their Completed cell")

    leads = []
    for it in done:
        start, end = first_commit(it), _date(it.get("extra", {}).get("Completed"))
        if start and end and end >= start:
            leads.append((end - start).days)
    lead = _median(leads)
    add("Lead time", "lagging", "median %s days over %d items" % (lead, len(leads))
        if lead is not None else "unknown", "first commit naming the item to its Completed date")

    gaps = [it["id"] for it in done
            if any(v == "missing" for v in it.get("steps", {}).values())]
    add("Done with a lifecycle gap", "lagging", "%d of %d" % (len(gaps), len(done)) +
        (": " + ", ".join(gaps[:8]) + (" …" if len(gaps) > 8 else "") if gaps else ""),
        "Done items missing a plan, review, commit or worklog entry their tier requires")

    revised = 0
    for it in items:
        plan = next((model["docs"][n] for n in it.get("records", [])
                     if model["docs"][n]["kind"] == "plans"), None)
        start = first_commit(it)
        if not plan or not start:
            continue
        log = project.git("log", "--date=short", "--format=%ad", "--", plan["path"])
        if any(_date(d) and _date(d) > start for d in log.split()):
            revised += 1
    add("Plans updated after build started", "lagging", str(revised),
        "plan files changed after the item's first commit: deviations that were recorded")
    return out


# ---------------------------------------------------------------- page

def render(model, template):
    data = json.dumps(model, ensure_ascii=False, separators=(",", ":"))
    # Safe inside <script>: nothing can close the tag or start a comment.
    data = (data.replace("<", "\\u003c").replace(">", "\\u003e")
            .replace("\u2028", "\\u2028").replace("\u2029", "\\u2029"))
    return template.replace("/*NUHUT_MODEL*/null", data, 1)


def print_metrics(rt, project, opts):
    model = build(rt, project)
    if getattr(opts, "json", False):
        print(json.dumps(model["metrics"], indent=2))
        return 0
    width = max(len(m["name"]) for m in model["metrics"])
    for m in model["metrics"]:
        print("%-7s  %-*s  %s" % (m["kind"], width, m["name"], m["value"]))
        print("         %-*s  from: %s" % (width, "", m["basis"]))
    return 0


def run(rt, project, opts):
    here = os.path.dirname(os.path.abspath(__file__))
    template = rt.read(os.path.join(here, "view.html"))
    if not template:
        raise SystemExit("view.html is missing next to view.py; re-run the installer "
                         "with --upgrade")
    model = build(rt, project)
    out_dir = project.path(os.path.join(".ai-sdlc", "view"))
    if not os.path.isdir(out_dir):
        os.makedirs(out_dir)
    ignore = os.path.join(out_dir, ".gitignore")
    if not os.path.exists(ignore):
        # The page copies the records' contents; it is a view, not a record.
        with open(ignore, "w", encoding="utf-8") as handle:
            handle.write("*\n")
    out = os.path.join(out_dir, "index.html")
    with open(out, "w", encoding="utf-8") as handle:
        handle.write(render(model, template))
    if getattr(opts, "json", False):
        print(json.dumps(model, indent=2, ensure_ascii=False))
        return 0
    counts = {}
    for it in model["items"].values():
        counts[it["column"]] = counts.get(it["column"], 0) + 1
    print("view: %d items (%s), %d worklog entries, %d documents%s"
          % (len(model["items"]),
             ", ".join("%s %d" % (c, counts[c]) for c in model["columns"] if c in counts),
             len(model["worklog"]), len(model["docs"]),
             ", %d unread" % len(model["unread"]) if model["unread"] else ""))
    print("wrote %s" % os.path.relpath(out, project.root))
    if not getattr(opts, "no_open", False):
        webbrowser.open("file://" + out)
    return 0
