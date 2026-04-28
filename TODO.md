# Order Journey Analytics — Open Issues

## Critical (blocking visuals)

*(None — Key Influencers Analyze field is correctly wired to `SLA Breach %` with CustomerCategoryName, StateProvinceName, FurthestStage as Explain by fields.)*

## Theme & Visual Polish

- [ ] **Theme auto-apply**: Custom theme is wired via PBIR RegisteredResources and file is present at `StaticResources/RegisteredResources/order-journey-modern.json`. If charts still show default blue after reopening PBI, go to View > Themes > Browse > select `powerbi/themes/order-journey-modern.json` to force-apply.
- [ ] **Slicer labels truncated**: "CustomerCategor..." / "StateProvinceNa..." — widen slicers or shorten display names in SQL view aliases.
- [ ] **Scatter plot (BottleneckFinder)**: `StateProvinceName` is wired to `Details` (which should produce multiple dots). If still showing single dot in PBI, add `CustomerCategoryName` to `Legend` well instead and compare.
- [ ] **Conditional formatting** *(PBI Desktop only — PBIR FillRule schema is undocumented, hand-writing risks breaking visuals)*: In PBI Desktop, right-click each measure > Conditional formatting > Font color:
  - `On-Time %` card: static teal already set (`#2E8B8B`); dynamic rule for < 90% threshold if desired
  - `Open Orders` card: static coral already set (`#E07A5F`); good as-is for WWI dataset
  - `Median Cycle Days` card: optional — lower is better (inverted scale)
  - `SLA Breach %` in matrixBreachHeatmap: gradient white → coral `#E07A5F`
- [ ] **Control Tower MoM labels**: "+0.0 pp" is correct when no month filter is active (all-time vs all-time). Works correctly with month filter applied.
- [ ] **DataDictionary page**: Verify text blocks render correctly with metric definitions and business rules content.

## Data Model

- [ ] **Rollup table refresh**: Confirm Import table shows correct double-precision CycleTimeDays (spot check: should see values like 2.33, 2.38).
- [ ] **dim_calendar sort columns**: Verify `month_year` sorted by `month_number`, `day_of_week` by `day_of_week_number` in PBI column properties.
- [ ] **Date table marking**: Confirm `dim_calendar` is marked as Date Table in PBI (Model view > right-click table).

## DevOps

- [ ] **Notion page update**: MCP token expired — re-authenticate and sync project status to Notion page `2f81d7ee-04a1-805a-beae-ed65ae5ad0e8`.
- [x] **GitHub push**: Sessions 5, 6, 7 pushed. Remote is up to date (c4b38c1).

---

## Completed ✓

- [x] SQL views v3.1 executed: CustomerCategoryName + DeliveryMethodName backward-compat aliases, fractional CycleTimeDays, IsOnTime NULL for open orders
- [x] 33 DAX measures verified: Core (4), SLA (6), Cycle Time (3), Stage Duration (8), Period Comparison (8), Journey (4)
- [x] 5 PBIR pages created: ControlTower, BottleneckFinder, JourneyExplorer, RootCauseLab, DataDictionary
- [x] Custom theme wired in PBIR RegisteredResources (order-journey-modern.json)
- [x] BOM stripped from 49 PBIR files; visualContainerObjects removed from 11 files
- [x] Navy slicer bar background shape added to all 4 non-dictionary pages (slicerBarBg, #1B2A4A, 1280×50)
- [x] All 17 slicer visuals updated: white header text on dark bar; transparent slicer background
- [x] Deneb: CustomerCategoryName removed from query (was causing DirectQuery cache error)
- [x] Deneb: IsOnTime added to query (8 fields total)
- [x] Deneb: Spec rebuilt — normalized DaysFromStart Y-axis, IsOnTime coloring (teal/coral/gray), 1-day reference line, zone tint bands, prominent late-order lines
- [x] deneb/journey_explorer_spec.json updated to match embedded spec
- [x] docs/page_visual_specs.md section 3.4 updated
- [x] All 4 title boxes fixed: white title (#FFFFFF) + light blue subtitle (#A8C0D0) visible on navy bar
- [x] On-Time % card: static teal (#2E8B8B) — always ≥90% in WWI
- [x] Open Orders card: static coral (#E07A5F) — always > 0 in WWI
- [x] Git push: all 3 sessions synced to GitHub remote
