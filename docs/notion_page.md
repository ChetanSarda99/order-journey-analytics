### Building dashboards that show *journeys* (not just charts)

**Tech:** SQL Server (SSMS) · Power BI · Deneb (Vega-Lite) · MCP · Claude · GitHub

**Dataset:** Wide World Importers (WWI) — OLTP + DW

**Theme:** Order Fulfillment SLA + Bottleneck + Journey Explorer

**GitHub:** https://github.com/ChetanSarda99/order-journey-analytics

---

## Why I'm doing this

I work in healthcare, and most performance reporting I've seen is heavy on summaries: totals, averages, trend lines. That stuff is useful — but it doesn't answer the question operations actually cares about:

### Where did the work *wait*, and what caused it?

That's the gap I'm trying to solve with this project.

Also: I wanted a **public, reproducible portfolio project** that still feels like "real operational analytics" (the same thinking you'd use for patient pathways, ED flow, surgical journeys - just without any internal healthcare data).

So I picked a workflow everyone understands:

**Order created → picked → packed → shipped → delivered**

…and built it using an **event log**, which is the core idea behind journey analytics and process mining.

---

## Why WWI (and why this dataset makes sense)

I didn't choose WWI because it's "cool." I chose it because it's practical:

- **It's public** (safe for GitHub + portfolio)
- **It has OLTP + DW** (so I can show how real orgs separate operational systems from analytics)
- **It's complex enough** to look real (warehouses, shipments, customers, dates, status changes)
- **It supports event logs naturally** (orders have stages, timestamps, locations, methods)

This gives me a way to show skills that transfer directly back to healthcare:

- pathway timing
- bottlenecks
- delays
- outliers (P90)
- "case journeys" (Deneb timeline)

---

## The approach

This project is built in layers. I'm intentionally not jumping straight into visuals. I have seen so many people jump into products, without planning and strategy and I say - 'Ah, there goes another dashboard to the digital landfill'

### Layer 1 — Build the event log (foundation) ✅

I model the process as an **event log**: one row per order per event (stage milestone)

This structure is reusable across industries:

- tickets → resolution
- incidents → restore
- hiring pipeline → offer
- patient journey → diagnosis/treatment

**Status:** Event log view created (`wwi.vw_order_event`) + dimension table (`wwi.dim_stage`)

### Layer 2 — Build the semantic model ✅

Once the event log was correct, I built the full analytical layer:

**Order rollup view** — I created `wwi.vw_order_rollup`: one row per order with all stage timestamps pivoted, plus pre-calculated metrics (cycle time, stage durations, SLA flags). This sits alongside the event log as the second fact source. The event log is great for journeys, but terrible for KPIs — you don't want to pivot 4 rows into 1 every time you need a cycle time. So the rollup handles the aggregation-friendly stuff.

**Hybrid model** — The event log stays in DirectQuery (live data for journey visuals), while the rollup uses Import mode with a native SQL query embedded in the M expression. I landed on this after hitting a wall: DirectQuery can't fold native SQL queries. But Import mode actually works better here anyway — MEDIAN and PERCENTILE.INC perform significantly better on imported data than through DirectQuery SQL translation.

**33 DAX measures** — organized into six folders:
- **Core** (4): Total Orders, Delivered, Open, Delivered %
- **SLA** (6): On-Time %, Breach %, Late Orders, Cumulative Late % (for Pareto), conditional scatter color
- **Cycle Time** (3): Median, P90, Average
- **Stage Duration** (8): Median + P90 for each of the 3 stage transitions, plus SWITCH measures that respond to a disconnected `StageTransition` table
- **Period Comparison** (8): Prior month versions + MoM deltas + label measures with arrow indicators
- **Journey** (4): Event Count + single-order context measures for sidebar cards

**Date table** — `dim_calendar` with fiscal columns, month-year sort, day-of-week sort.

**StageTransition table** — A disconnected calculated table (3 rows: Created→Picked, Picked→Invoiced, Invoiced→Delivered) that powers the stage duration bar charts via SWITCH measures. No relationships needed — it's a slicer-only table.

**Status:** Semantic model complete. All 33 measures validated via DAX queries. TMDL snapshots versioned locally.

### Layer 3 — Build report pages 🔄 IN PROGRESS

Now I'm building 5 report pages, and here's the interesting part — I'm doing it programmatically.

Power BI recently introduced the **PBIR (Enhanced Report Format)**, which exposes every page, visual, bookmark as individual JSON files with public schemas. Instead of drag-and-drop, I can write page and visual definitions as JSON and Power BI Desktop loads them.

This means the report layout is version-controlled, reproducible, and scriptable — exactly the kind of engineering rigor this project is about.

Detailed visual specs are already written (`docs/page_visual_specs.md` — 1,075 lines of exact positions, field bindings, colors, formatting rules for all 5 pages).

---

## The 5 report pages

### **Page 1 — Control Tower (Executive)**

**Goal:** Are we okay? What changed? Where should we focus?

- 4 KPI cards (Total Orders, On-Time %, Median Cycle, P90 Cycle) with MoM deltas
- On-Time % trend line over time
- Orders by delivery method (on-time vs late)
- "Red Alert" table: worst-performing lanes by SLA breach rate
- Global slicer bar: Year, Quarter, Month, Delivery Method, State

### **Page 2 — Bottleneck Finder (Operations)**

**Goal:** Where is delay happening in the workflow?

- Horizontal bar chart: median stage duration by transition
- Scatter plot: volume vs median delay by stage x delivery method (quadrant analysis)
- Heatmap: SLA breach % by stage x delivery method
- P90 vs Median comparison bars (shows where variance is worst)

### **Page 3 — Journey Explorer (Deneb)**

**Goal:** Show one order's journey end-to-end.

- Customer + OrderID slicers
- Deneb Vega-Lite timeline (connected dot chart with Pre-Ship / In-Transit bands)
- Sidebar cards: selected order's stage, delivery method, cycle time, on-time status

### **Page 4 — Root Cause Lab (Analyst)**

**Goal:** Why are we late?

- Pareto chart: top contributors to late deliveries
- Decomposition tree / Key Influencers: what drives SLA breaches?
- Detail drill-through table: OrderID, Customer, City, Method, Cycle Time, On-Time flag

### **Page 5 — Show Your Work**

**Goal:** Prove engineering + governance

- Data dictionary, metric definitions, business rules
- SQL snippets showing how the event log was built
- Data lineage diagram (OLTP → event log → rollup → Power BI)
- GitHub link, tech stack

---

## WWI dataset setup workflow

[Release Wide World Importers sample database v1.0 · microsoft/sql-server-samples · GitHub](https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0)

[Wide World Importers - Sample Database for SQL - SQL Server | Microsoft Learn](https://learn.microsoft.com/en-us/sql/samples/wide-world-importers-what-is?view=sql-server-ver17)

[WideWorldImportersDW](https://dataedo.com/samples/html/WideWorldImportersDW/doc/WideWorldImportersDW_6/home.html)

[WideWorldImporters](https://dataedo.com/samples/html/WideWorldImporters/doc/WideWorldImporters_5/home.html)

---

## OLTP vs DW (why I need both)

WWI comes with two "worlds":

### **OLTP = operational truth**

- detailed events
- timestamps/status changes
- best source for *journeys* (timeline view)

### **DW = analytics convenience**

- reporting-friendly structure
- great for slices/aggregates (trend charts, breakdowns, KPI pages)

**How I use them**

- **Journey Explorer (Deneb)** is powered by **OLTP-derived event log**
- **KPI + performance pages** pull from the **order rollup** (pivoted from OLTP, imported into Power BI)

This mirrors reality: journeys come from operational systems, KPIs often come from curated rollups.

---

## Dataset setup (what I did)

Here's exactly how I got the data working locally:

### Step 1 — Download WWI sample ✅

I used the official Microsoft sample release + docs (links in repo/notes).

### Step 2 — Import into SQL Server (SSMS) ✅

Because I'm using SQL Server Express locally, I imported the **BACPAC** files (instead of restoring .bak).

In SSMS:

1. Connect to `.\SQLEXPRESS`
2. Right-click **Databases**
3. **Import Data-tier Application**
4. Select:
    - `WideWorldImporters` (OLTP)
    - `WideWorldImportersDW` (DW)
5. Confirm both databases appear and can be queried

### Step 3 — Create my analytics database ✅

I created a separate workspace DB:

- `wwi_analytics`

### Step 4 — Create my curated schema + objects ✅

Inside `wwi_analytics` I created:

- schema: `wwi`
- `wwi.dim_stage` (canonical stage list + sort order)
- `wwi.vw_order_event` (event log — one row per order per milestone)
- `wwi.vw_order_rollup` (one row per order with pivoted timestamps + pre-calculated metrics)

### Step 5 — Connect Power BI ✅

- Power BI → Get Data → SQL Server
- Server: `DESKTOP-...\SQLEXPRESS`
- Database: `wwi_analytics`
- Event log: DirectQuery (live journey data)
- Rollup: Import with native SQL query (for MEDIAN/PERCENTILE performance)

---

## The semantic model (what's in Power BI)

### Tables (5)

| Table | Mode | Purpose |
|---|---|---|
| `wwi vw_order_event` | DirectQuery | Event log — 1 row per order per stage |
| `wwi vw_order_rollup` | Import | Rollup — 1 row per order, pre-calculated metrics |
| `wwi dim_stage` | Import | Stage dimension (4 stages) |
| `dim_calendar` | Calculated/Import | Date table with fiscal, month-year sort |
| `StageTransition` | Calculated (DAX) | Disconnected table for stage duration bar charts |

### Relationships (3)

- `vw_order_event[Stage]` → `dim_stage[stage_name]` (many:1)
- `vw_order_event[EventTS]` → `dim_calendar[Date]` (many:1)
- `vw_order_rollup[CreatedDate]` → `dim_calendar[Date]` (many:1)

### Measures (33)

See `docs/metric_definitions.md` for the full list with logic and formats.

---

## Claude + MCP (how I built this)

I used **Claude Code with MCP (Model Context Protocol)** as a build assistant so the project isn't "just a dashboard" — it's a repeatable workflow with version-controlled SQL + documentation.

**What MCP gave me**

- Claude can create/update files in my local repo (SQL scripts, metric definitions, Deneb specs, visual specs).
- Claude can review diffs and help structure commits, so changes are traceable.
- **Power BI Modeling MCP** lets Claude directly interact with my Power BI model — creating tables, measures, relationships, running DAX validation queries, and exporting TMDL snapshots. No manual clicking required for model building.

**MCP servers used**

- **Power BI Modeling MCP** (connects to local Power BI Desktop via localhost port)

**What was automated vs manual**

| Automated (Claude + MCP) | Manual (me in PBI Desktop) |
|---|---|
| All 33 DAX measures (batch create) | Power BI Desktop open/save |
| Table creation (rollup, StageTransition) | Enable PBIR preview feature |
| Relationships | Save as PBIP project |
| Column metadata (sort-by, hide, descriptions) | Visual spot-checking |
| TMDL version snapshots | |
| DAX validation queries | |
| Deneb Vega-Lite spec | |
| Page visual specifications (1,075 lines) | |
| SQL rollup view | |

**Why this matters**

Most BI portfolios show final visuals. This approach shows how I work end-to-end:

- define a canonical event-log
- implement it in SQL
- document business rules + metrics
- build the semantic model programmatically
- version-control the model definition (TMDL)
- ship a Power BI report that explains "where the work waited," not just totals

---

## Learnings and things I ran into

These are real things I hit during this build. Documenting them because they're the kind of stuff that doesn't show up in tutorials.

### DirectQuery vs Import — it's not just a preference

I originally tried to put everything in DirectQuery because "live data" sounds better. But native SQL queries embedded in Power BI's M expression (the `Sql.Database(..., [Query="..."])` pattern) don't fold in DirectQuery mode. Power BI throws "Unable to convert M query into native source query." The fix was Import mode for the rollup table — which actually turned out better because MEDIAN and PERCENTILE.INC perform significantly better on imported data anyway.

**Takeaway:** Hybrid models (some tables DirectQuery, some Import) aren't a compromise. They're often the right architecture.

### TMDL is only half the story

TMDL (Tabular Model Definition Language) covers the semantic model: tables, measures, relationships, data sources. It does NOT cover report pages, visuals, or formatting. That's a separate layer. I spent time thinking TMDL could handle everything before realizing the split.

**The answer:** PBIR (Power BI Enhanced Report Format) covers the report layer. Together, TMDL + PBIR = full version control of a Power BI project.

### Power BI MCP gotchas

- Data types are case-sensitive: `Int64`, `String`, `DateTime` — not `int64`
- Deleting tables requires `shouldCascadeDelete: true` explicitly
- Calculated tables (like `StageTransition`) auto-derive their columns from the DAX expression — don't try to specify columns in the create definition
- The MCP handles the semantic model only. Report pages and visuals are a completely separate layer that MCP can't touch.

### The disconnect table pattern is underrated

For stage duration bar charts, I couldn't just put "stage transition" on an axis — the transitions are separate measures (Median Created-to-Picked, Median Picked-to-Invoiced, etc.), not a single column. The solution: a tiny calculated table (`StageTransition`) with 3 rows and a SWITCH measure that returns the right value based on which row is selected. No relationships needed. It's a clean pattern that keeps the model simple.

### PBIR — programmatic report building

This was the biggest discovery. Power BI's PBIR format (preview) exposes every page, visual, and bookmark as individual JSON files with publicly documented schemas. Each visual has a `visual.json` with position, size, field bindings, formatting. You can create pages by writing JSON files, and Power BI Desktop validates and loads them on open.

This means: the entire report — not just the model — can be version-controlled, diffed, and scripted. For a portfolio project about engineering rigor, this is the move.

**Schemas:** https://github.com/microsoft/json-schemas/tree/main/fabric/item/report/definition

---

## Metrics

- **Cycle time:** start milestone → delivered (or last known milestone)
- **Stage time:** time between adjacent milestones
- **Median cycle time**
- **P90 cycle time**
- **SLA breach %:** delivered after expected date
- **On-time %:** delivered on or before expected date
- **MoM deltas:** period-over-period comparison (orders, on-time %, cycle time)

---

## GitHub Repository Setup ✅

**Repository:** https://github.com/ChetanSarda99/order-journey-analytics

**What's in the repo:**
- SQL scripts for schema, views, and metrics
- Comprehensive documentation (data dictionary, metric definitions, business rules, visual specs)
- Deneb Vega-Lite spec for journey timeline
- README with project overview, tech stack, and getting started guide
- MIT License
- .gitignore configured (Power BI files excluded, TMDL snapshots local-only)

**Version control strategy:**
- SQL scripts and documentation are version controlled
- Power BI .pbix files are excluded via .gitignore
- TMDL semantic model snapshots are kept locally (`.tmdl_versions/`) for rollback
- Once PBIR is enabled, report pages will also be version-controlled as JSON
- Git commits organized with clear, descriptive messages

---

## Project Status: Layer 2 Complete, Starting Layer 3

- ✅ Dataset imported and configured
- ✅ Event log SQL layer built (`wwi.vw_order_event`)
- ✅ Order rollup SQL layer built (`wwi.vw_order_rollup`)
- ✅ GitHub repository created and documented
- ✅ Power BI connected (hybrid DirectQuery + Import)
- ✅ Semantic model complete (5 tables, 3 relationships, 33 measures)
- ✅ TMDL versioning set up (3 snapshots: baseline, measures-rollup, supporting-measures)
- ✅ Deneb Vega-Lite spec written (6-layer connected dot timeline)
- ✅ Page visual specifications written (1,075 lines, all 5 pages)
- 🔄 Converting to PBIP + PBIR for programmatic page building
- 📋 Build report pages (write visual JSON definitions)
- 📋 Screenshots and portfolio polish
