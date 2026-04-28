# Order Journey Analytics

## Project Context
Event-log analytics project using WWI (Wide World Importers) dataset.
Power BI + SQL Server + Deneb + MCP. Portfolio project demonstrating journey analytics.

## Architecture
- **Event log** (`wwi.vw_order_event`): DirectQuery — 1 row per order per stage milestone
- **Order rollup** (`wwi.vw_order_rollup`): Import mode — 1 row per order, pre-calculated metrics
- **Hybrid model**: DirectQuery for live journey data, Import for KPI aggregation (MEDIAN/PERCENTILE need Import)
- **StageTransition**: Disconnected DAX calculated table for stage duration SWITCH measures

## Power BI MCP
- Exe: `C:\Users\Chetan\.vscode\extensions\analysis-services.powerbi-modeling-mcp-0.1.9-win32-x64\server\powerbi-modeling-mcp.exe`
- Config: `.mcp.json` at project root (no `type` field — Claude Code format)
- Connect: `ListLocalInstances` → `Connect` with `localhost:<port>`
- Handles: semantic model only (tables, measures, relationships, TMDL export)
- Does NOT handle: report pages, visuals, formatting (that's the PBIR layer)

## SQL Server
- Server: `DESKTOP-TNE86KL\SQLEXPRESS`
- Database: `wwi_analytics`, Schema: `wwi`
- No SQL Server MCP — use PBI native query or SSMS

## Key Gotchas
- PBI MCP data types are case-sensitive: `Int64`, `String`, `DateTime`
- `table_operations` Delete needs `shouldCascadeDelete: true`
- Calculated tables: do NOT specify `columns` — they auto-derive from DAX expression
- DirectQuery can't fold native SQL queries in M expressions — use Import mode
- `.mcp.json` for Claude Code: no `type: stdio` field (differs from Claude Desktop format)

## TMDL Versioning
- Snapshots at `.tmdl_versions/` (git-ignored, local only)
- Convention: `YYYY-MM-DD_description/`
- Current snapshots: baseline, measures-rollup, supporting-measures

## PBIR (Active — already enabled)
- PBIP saved at `powerbi/wwi_order_jounrney_analytics.pbip`
- Report definition: `powerbi/wwi_order_jounrney_analytics.Report/definition/`
- Semantic model TMDL: `powerbi/wwi_order_jounrney_analytics.SemanticModel/definition/`
- Schema versions: visual `2.5.0`, page `2.0.0`, report `3.1.0`
- Schemas: https://github.com/microsoft/json-schemas/tree/main/fabric/item/report/definition
- Each visual = `visual.json` with position, query (field projections), objects (formatting)
- Each page = folder with `page.json` + `visuals/` subfolder
- Deneb custom visual ID: `deneb7E15AEF80B9E4D4F8E12924291ECE89A`
- Field reference pattern: `{"Column": {"Expression": {"SourceRef": {"Entity": "table name"}}, "Property": "column name"}}`
- Measure reference pattern: `{"Measure": {"Expression": {"SourceRef": {"Entity": "table name"}}, "Property": "measure name"}}`
- Slicer bar bg pattern: `basicShape` visual at Y=0, Z=-100, H=50, W=1280, fill `#1B2A4A` — one per page
- Slicer object pattern: `header.fontColor = #FFFFFF`, `background.show = false` for slicers on dark bar

## Files
- SQL: `sql/00_setup/`, `sql/01_views/`, `sql/02_metrics/`
- Docs: `docs/` (metric_definitions, business_rules, data_dictionary, page_visual_specs, notion_page)
- Deneb: `deneb/journey_explorer_spec.json` (source of truth; also embedded in denebTimeline/visual.json)
- Visual specs: `docs/page_visual_specs.md`
- Theme: `powerbi/themes/order-journey-modern.json` (mirrors `StaticResources/RegisteredResources/`)

## Current State (Session 6 — 2026-02-21)
- 5 PBIR pages built: ControlTower, BottleneckFinder, JourneyExplorer, RootCauseLab, DataDictionary
- Navy slicer bar (`slicerBarBg`) added to all 4 active pages; 17 slicers have white header text
- Deneb spec rebuilt: DaysFromStart normalization, IsOnTime coloring, 1-day SLA reference line
- Remaining: Key Influencers Analyze field, scatter plot breakdown, conditional formatting, git push

## Vault Links

[[README]] · [[.mcp.json]]

**Docs:** [[docs/metric_definitions|Metric Definitions]] · [[docs/business_rules|Business Rules]] · [[docs/data_dictionary|Data Dictionary]] · [[docs/page_visual_specs|Visual Specs]]

**Power BI:** [[powerbi/wwi_order_jounrney_analytics.pbip|pbip]] · [[deneb/journey_explorer_spec.json|Deneb spec]]

## Shared Resources
- **Shared scripts/modules:** `~/Projects/shared/` (image gen, Telegram, orchestration)
- **Notion guide:** `~/Projects/shared/NOTION-GUIDE.md` (DB IDs, routing rules, triage protocol)
- **Cross-instance state:** `~/Projects/shared/shared-state/claude-activity/` (activity log, project status, decisions)
- **Read activity log + project status at session start. Update after significant work.**
