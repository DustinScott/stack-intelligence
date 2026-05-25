# STACK Intelligence — Team Brief
**From:** Dustin (CTO)
**To:** Development Team
**Date:** May 24, 2026
**Priority:** High — Please review before our sync

---

## What We're Building (and Why It Matters Right Now)

We have built a lot. ATLAS is live and solid. Relay is working. CompConnect is taking shape. WOPR is in active development. The problem isn't the work — the problem is that the people at the top can't see it.

**STACK Intelligence** is our answer to that. It's an internal operational dashboard that translates everything we're doing into a language the C-suite and board can understand — percentages, phases, trends, real-time progress. No jargon. No confusion. Just clarity.

This is not a customer-facing product. It is our internal meter reader. We point it at every product we're building and it tells the story of where we are, phase by phase, in near real-time.

---

## The STACK Framework

Every product we build passes through five phases. We call it the STACK:

| Letter | Phase | What It Means |
|--------|-------|---------------|
| **S** | Store | Data ingestion, storage architecture, database layer |
| **T** | Transform | Processing, normalization, business logic |
| **A** | Analyze | Reporting, scoring, intelligence layer |
| **C** | Check | Validation, QA, exception handling, compliance |
| **K** | Kickoff | Deployment, automation, client onboarding |

Each phase is scored **0–100%** based on team input. These scores roll up to a product-level score, and all products roll up to a **Platform Automation %**.

Right now our platform sits at **67% overall** — with three products already in high-confidence territory:
- ATLAS: 88%
- Relay: 76%
- CompConnect: 70%
- WOPR (active build): 34% — this is the one we need to move

---

## The Three-Level Architecture

The dashboard has three levels designed for three different audiences:

### Level 1 — Board / CEO View (`stack-dashboard.html`)
- 4 product cards with overall automation %
- Platform-wide KPIs: avg score, products live, active dev, updates today
- Click any product → opens Level 2

### Level 2 — Product / Phase Detail (slide-in panel)
- 5 phase rows per product (S, T, A, C, K)
- Per-phase: progress bar, % complete, assignee, status badge, ETA, notes
- Click "Log Update" → opens Level 3

### Level 3 — Developer Input (modal form)
- Percentage slider (0–100%)
- Status dropdown: On Track / At Risk / Blocked / Complete
- Assignee field
- ETA date picker
- Notes/comments field
- Saves update to data layer and re-renders dashboard instantly

---

## Current Data Architecture (Stage 2 — Google Sheets)

We are using **Google Sheets as a lightweight database** for now. This gets us moving immediately without waiting for a backend build. Stage 3 will connect to our existing microservices API.

### Sheet Structure

Create a Google Sheet with **three tabs**:

#### Tab 1: `PRODUCTS`
| product_id | name | description | status |
|------------|------|-------------|--------|
| wopr | WOPR | Payroll-to-carrier reporting | active |
| compconnect | CompConnect | Referral and bind platform | active |
| relay | Relay | ACH payment processing | active |
| atlas | ATLAS | Client visibility dashboard | live |

#### Tab 2: `PHASES`
| product_id | phase | phase_label | pct | assignee | status | eta | notes | updated_at |
|------------|-------|-------------|-----|----------|--------|-----|-------|------------|
| wopr | S | Store | 65 | Dev Name | on_track | 2026-06-01 | Schema complete | 2026-05-24 |
| wopr | T | Transform | 45 | Dev Name | at_risk | 2026-06-15 | Mapping 70% done | 2026-05-24 |
| wopr | A | Analyze | 20 | Dev Name | in_progress | 2026-07-01 | Started scoring logic | 2026-05-24 |
| wopr | C | Check | 15 | Dev Name | pending | 2026-07-15 | Not started | 2026-05-24 |
| wopr | K | Kickoff | 25 | Dev Name | in_progress | 2026-08-01 | Carrier mapping begun | 2026-05-24 |

*(Repeat for compconnect, relay, atlas)*

#### Tab 3: `UPDATES` (audit log — append only, never delete)
| timestamp | product_id | phase | old_pct | new_pct | assignee | status | notes |
|-----------|------------|-------|---------|---------|----------|--------|-------|
| 2026-05-24 09:00 | wopr | S | 60 | 65 | Dev Name | on_track | Completed schema migration |

### Connecting the Sheet to the Dashboard

1. Open `stack-dashboard.html` in your editor
2. Find this section near the top of the `<script>` tag:
```javascript
const SHEET_ID = 'YOUR_GOOGLE_SHEET_ID_HERE';
const USE_SHEET = false;
```
3. Replace `YOUR_GOOGLE_SHEET_ID_HERE` with your Sheet ID (found in the Google Sheets URL between `/d/` and `/edit`)
4. Change `USE_SHEET = false` to `USE_SHEET = true`
5. **Make the sheet publicly readable:** Share → Anyone with the link → Viewer
6. Save and reload the dashboard — it will now pull live data every 5 minutes

### How the Dashboard Reads the Sheet
The dashboard uses Google's public gviz/tq JSON endpoint — no API key required for public sheets:
```
https://docs.google.com/spreadsheets/d/{SHEET_ID}/gviz/tq?tqx=out:json&sheet=PHASES
```

---

## How Developers Log Progress

Until the Google Form pipeline is set up, developers can update the sheet directly:

1. Open the shared Google Sheet
2. Find your product + phase row in the `PHASES` tab
3. Update the `pct` column (0–100)
4. Update `status`: `on_track` | `at_risk` | `blocked` | `complete`
5. Update `notes` with what you just finished or what's blocking you
6. Update `updated_at` with today's date
7. Copy the old row to `UPDATES` tab first (for audit trail)

The dashboard auto-refreshes every 5 minutes when connected. Leadership sees updates within one refresh cycle.

---

## Stage 3 — Connecting to the Existing Microservices API

We already have a user and microservices API built for ATLAS, Relay, and CompConnect. The plan is to wire STACK Intelligence to that API once the sheet-based prototype is validated.

**What the API needs to expose:**

```
GET  /stack/products           → list of all products with metadata
GET  /stack/products/:id/phases → all 5 phases with pct, assignee, status, eta, notes
POST /stack/phases/:id/update  → log a phase update (auth required)
GET  /stack/updates            → full audit log of all updates
```

**Auth:** The developer update form (Level 3) will use the existing JWT tokens from the user service. Read endpoints (Level 1/2) will be public or use a read-only token for internal access.

**Data format expected by the dashboard:**
```json
{
  "product_id": "wopr",
  "name": "WOPR",
  "phases": [
    { "letter": "S", "label": "Store",     "pct": 65, "assignee": "Dev Name", "status": "on_track", "eta": "2026-06-01", "notes": "..." },
    { "letter": "T", "label": "Transform", "pct": 45, "assignee": "Dev Name", "status": "at_risk",  "eta": "2026-06-15", "notes": "..." },
    { "letter": "A", "label": "Analyze",   "pct": 20, "assignee": "Dev Name", "status": "in_progress", "eta": "2026-07-01", "notes": "..." },
    { "letter": "C", "label": "Check",     "pct": 15, "assignee": "Dev Name", "status": "pending",  "eta": "2026-07-15", "notes": "..." },
    { "letter": "K", "label": "Kickoff",   "pct": 25, "assignee": "Dev Name", "status": "in_progress", "eta": "2026-08-01", "notes": "..." }
  ]
}
```

---

## Files in This Project

| File | Purpose |
|------|---------|
| `index.html` | Public-facing STACK Intelligence website (GitHub Pages) |
| `compare.html` | Internal design comparison page (not for sharing externally) |
| `stack-dashboard.html` | **The internal 3-level development dashboard — this is our focus** |
| `TEAM_BRIEF.md` | This document |
| `GITHUB_SETUP.md` | GitHub Pages deployment instructions |
| `TOMORROW.md` | Session task tracking |

---

## Tomorrow's Priorities (Memorial Day Sprint)

**Goal: Get the dashboard connected to a real data source**

1. **Set up Google Sheet** — create the three-tab structure above, populate WOPR phase rows with real current numbers
2. **Connect the dashboard** — plug in the Sheet ID, flip `USE_SHEET = true`, verify data renders correctly
3. **Assign real names** — update assignee fields with actual team member names per phase
4. **Update real percentages** — each team member logs their honest current % per phase
5. **Push to GitHub** — `git add . && git commit -m "Live data connected" && git push`
6. **Begin API endpoint design** — sketch out the Stage 3 REST endpoints listed above so we can hand off to the API team

---

## The Bigger Picture

What we're doing here is not just a dashboard. We're building a **shared language** between the people who write the code and the people who fund it.

When the CEO opens his laptop Monday morning and sees:
- Platform: 67% automated
- ATLAS: 88% — Live and running
- Relay: 76% — Solid
- WOPR: 34% — Active build, on schedule

...that's a completely different conversation than "we're working on it."

We built this. Let's make sure it shows.

---

*Questions? Ping Dustin. Let's get this done today.*
