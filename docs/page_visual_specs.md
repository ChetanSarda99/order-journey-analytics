# Power BI Report -- Page Visual Specifications

> **Canvas:** 1280 x 720 (16:9)
> **Font:** Segoe UI throughout. 24pt KPI values, 10pt body/labels, 9pt axis labels.
> **Background:** Warm gray `#F4F1ED` canvas, white `#FFFFFF` card/visual backgrounds.
> **Headers:** Dark navy `#1B2A4A` page titles and card headers.
> **Accent colors:** Teal `#2E8B8B` (positive / on-track), coral `#E07A5F` (negative / alert).
> **Tables source:** `wwi vw_order_rollup` (Import), `wwi vw_order_event` (DirectQuery), `dim_calendar` (Import), `wwi dim_stage` (Import).

---

## Global Elements (every page)

### Slicer Bar

| Property | Value |
|---|---|
| Position | Top strip, Y=0, full width (1280 x 50) |
| Background | `#1B2A4A` (dark navy), 100% opacity |
| Layout | Horizontal row of dropdown slicers, evenly spaced |

**Slicers (left to right):**

| # | Slicer field | Style | Width |
|---|---|---|---|
| 1 | `dim_calendar[year]` | Dropdown | 120 px |
| 2 | `dim_calendar[quarter]` | Dropdown | 120 px |
| 3 | `dim_calendar[month_year]` | Dropdown | 160 px |
| 4 | `wwi vw_order_rollup[CustomerCategoryName]` | Dropdown | 180 px |
| 5 | `wwi vw_order_rollup[StateProvinceName]` | Dropdown | 180 px |

**Formatting notes:**
- Slicer header text: white `#FFFFFF`, Segoe UI 10pt, bold.
- Dropdown background: `#FFFFFF`. Selected item highlight: `#2E8B8B`.
- "Select All" enabled on each slicer.
- Sync slicers across Pages 1-4. Page 5 has no slicers (documentation page).

### Page Title

| Property | Value |
|---|---|
| Position | Below slicer bar, Y=55, X=20 |
| Element | Text box |
| Font | Segoe UI, 16pt, bold, `#1B2A4A` |
| Content | Page-specific (see each page below) |

---

## Page 1: Control Tower (Executive)

**Page title:** "Control Tower"
**Subtitle text box:** "Are we okay? What changed? Where should we focus?" -- 10pt, `#1B2A4A`, italic, positioned at Y=75, X=20.

### Layout Grid

```
|--- Slicer Bar (full width, 0-50) ---|
|--- Title + Subtitle (55-95) ---|
| Card 1 | Card 2 | Card 3 | Card 4 |   <- Row 1 (Y: 100-200)
| On-Time Trend Line         | Orders by Method |   <- Row 2 (Y: 210-430)
| Red Alert Table (full width)                   |   <- Row 3 (Y: 440-700)
```

---

### 1.1 KPI Card -- Total Orders

| Property | Value |
|---|---|
| Visual type | Card |
| Position | Top-Left (X: 20, Y: 100) |
| Size | Quarter-width (295 x 100) |
| Field (Value) | `[Total Orders]` |
| Callout value | 24pt, bold, `#1B2A4A` |
| Category label | "Total Orders", 10pt, `#1B2A4A` |

**Delta indicator (text box below card):**
- Add a text box or use a second Card visual directly beneath (Y: 170, height: 30).
- Field: `[Orders MoM %]`
- Format as percentage, 1 decimal.
- Conditional formatting on font color: positive = `#2E8B8B`, negative = `#E07A5F`.
- Prefix with up/down arrow character: use DAX measure:
  ```
  Orders MoM Label =
  VAR v = [Orders MoM %]
  RETURN IF(v >= 0, UNICHAR(9650) & " " & FORMAT(v, "+0.0%;-0.0%"), UNICHAR(9660) & " " & FORMAT(v, "+0.0%;-0.0%"))
  ```
  Display this as a Card visual with no category label. 10pt font.

---

### 1.2 KPI Card -- On-Time %

| Property | Value |
|---|---|
| Visual type | Card |
| Position | Top-Center-Left (X: 335, Y: 100) |
| Size | Quarter-width (295 x 100) |
| Field (Value) | `[On-Time %]` |
| Format | Percentage, 1 decimal |
| Callout value | 24pt, bold. Conditional color: >= 90% `#2E8B8B`, < 90% `#E07A5F` |
| Category label | "On-Time %", 10pt, `#1B2A4A` |

**Delta indicator:**
- Same pattern as 1.1. Field: `[On-Time MoM pp]`
- Format: "+X.X pp" / "-X.X pp" (percentage points).
- DAX label measure:
  ```
  OnTime MoM Label =
  VAR v = [On-Time MoM pp]
  RETURN IF(v >= 0, UNICHAR(9650) & " " & FORMAT(v, "+0.0") & " pp", UNICHAR(9660) & " " & FORMAT(v, "+0.0") & " pp")
  ```

---

### 1.3 KPI Card -- Median Cycle Days

| Property | Value |
|---|---|
| Visual type | Card |
| Position | Top-Center-Right (X: 650, Y: 100) |
| Size | Quarter-width (295 x 100) |
| Field (Value) | `[Median Cycle Days]` |
| Format | Whole number or 1 decimal |
| Callout value | 24pt, bold, `#1B2A4A` |
| Category label | "Median Cycle Days", 10pt |

**Delta indicator:**
- Field: `[Cycle Time MoM]`
- Note: for cycle time, *lower is better*, so invert color logic: negative change = `#2E8B8B` (good), positive change = `#E07A5F` (bad).

---

### 1.4 KPI Card -- Open Orders

| Property | Value |
|---|---|
| Visual type | Card |
| Position | Top-Right (X: 965, Y: 100) |
| Size | Quarter-width (295 x 100) |
| Field (Value) | `[Open Orders]` |
| Callout value | 24pt, bold, `#E07A5F` if > 0, else `#2E8B8B` |
| Category label | "Open Orders", 10pt |

No MoM delta needed for this card.

---

### 1.5 On-Time % Trend Line

| Property | Value |
|---|---|
| Visual type | Line chart |
| Position | Middle-Left (X: 20, Y: 210) |
| Size | ~60% width (750 x 220) |
| X-Axis | `dim_calendar[month_year]` |
| Y-Axis | `[On-Time %]` |
| Sort | `dim_calendar[Date]` ascending (sort month_year by underlying Date) |

**Formatting:**
- Line color: `#2E8B8B`, weight 2.5.
- Data labels: ON, 9pt, show percentage.
- Add a constant line at 90% (reference line), dashed, color `#E07A5F`, label "Target 90%".
- Y-axis range: 0% to 100%. Grid lines: light gray `#E0E0E0`.
- X-axis labels: 9pt, angled 45 degrees if needed.
- Title: "On-Time % Trend", 12pt bold, `#1B2A4A`.

---

### 1.6 Orders by Delivery Method

| Property | Value |
|---|---|
| Visual type | Clustered bar chart (horizontal) |
| Position | Middle-Right (X: 790, Y: 210) |
| Size | ~40% width (470 x 220) |
| Y-Axis (Category) | `wwi vw_order_rollup[CustomerCategoryName]` |
| X-Axis (Value) | `[Total Orders]` |
| Sort | `[Total Orders]` descending |

**Formatting:**
- Bar color: `#2E8B8B`.
- Data labels: ON, 9pt, outside end.
- Title: "Orders by Delivery Method", 12pt bold, `#1B2A4A`.
- No legend needed (single series).
- Y-axis labels: 9pt, truncate at 25 characters.

---

### 1.7 Red Alert Table -- Worst Lanes by SLA Breach

| Property | Value |
|---|---|
| Visual type | Table |
| Position | Bottom (X: 20, Y: 440) |
| Size | Full-width (1240 x 260) |
| Title | "Red Alert: Lanes with Highest SLA Breach", 12pt bold, `#1B2A4A` |

**Columns (left to right):**

| # | Column / Measure | Header text | Width | Alignment | Format |
|---|---|---|---|---|---|
| 1 | `wwi vw_order_rollup[StateProvinceName]` | State | 160 | Left | Text |
| 2 | `wwi vw_order_rollup[CustomerCategoryName]` | Method | 160 | Left | Text |
| 3 | `[Total Orders]` | Orders | 100 | Right | Whole number |
| 4 | `[Late Orders]` | Late | 100 | Right | Whole number |
| 5 | `[SLA Breach %]` | Breach % | 110 | Right | Percentage, 1 decimal |
| 6 | `[Median Cycle Days]` | Med. Cycle | 110 | Right | 1 decimal |
| 7 | `[P90 Cycle Days]` | P90 Cycle | 110 | Right | 1 decimal |

**Formatting:**
- Sort by `[SLA Breach %]` descending.
- Top N filter: show top 10 by `[SLA Breach %]`.
- Conditional formatting on `[SLA Breach %]`: background color gradient from white (0%) to `#E07A5F` (100%). Apply via column > Format > Background color > Rules.
- Conditional formatting on `[P90 Cycle Days]`: font color -- if value > 7, color `#E07A5F`; else `#1B2A4A`.
- Header row: background `#1B2A4A`, font white `#FFFFFF`, 10pt bold.
- Alternating row colors: white `#FFFFFF` and `#F4F1ED`.
- Grid lines: thin, `#E0E0E0`.

**Interaction:** This table acts as a cross-filter source. Clicking a row filters the trend line and bar chart above.

---

## Page 2: Bottleneck Finder (Operations)

**Page title:** "Bottleneck Finder"
**Subtitle:** "Where is delay happening in the workflow?" -- 10pt, italic.

### Layout Grid

```
|--- Slicer Bar (full width, 0-50) ---|
|--- Title + Subtitle (55-95) ---|
| Stage Duration Bars (full width)               |   <- Row 1 (Y: 100-300)
| Volume vs Delay Scatter | Breach Heatmap       |   <- Row 2 (Y: 310-510)
| P90 vs Median Comparison (full width)          |   <- Row 3 (Y: 520-700)
```

---

### 2.1 Median Stage Duration -- Horizontal Bar Chart

| Property | Value |
|---|---|
| Visual type | Clustered bar chart (horizontal) |
| Position | Top (X: 20, Y: 100) |
| Size | Full-width (1240 x 200) |
| Title | "Median Days by Stage Transition", 12pt bold |

**Fields:**

| Slot | Field |
|---|---|
| Y-Axis (Category) | Use a manually constructed table or 3 separate bars. See approach below. |
| X-Axis (Value) | Duration measures |

**Approach -- since stage transitions are separate measures, not a single column, use one of these methods:**

**Option A -- Disconnected table (recommended):**
1. Create a DAX calculated table:
   ```
   StageTransition = DATATABLE(
       "Transition", STRING, "SortOrder", INTEGER,
       {
           {"Created to Picked", 1},
           {"Picked to Invoiced", 2},
           {"Invoiced to Delivered", 3}
       }
   )
   ```
2. Create a SWITCH measure:
   ```
   Median Stage Duration =
   SWITCH(
       SELECTEDVALUE(StageTransition[Transition]),
       "Created to Picked", [Median Created-to-Picked],
       "Picked to Invoiced", [Median Picked-to-Invoiced],
       "Invoiced to Delivered", [Median Invoiced-to-Delivered]
   )
   ```
3. Bar chart: Y-Axis = `StageTransition[Transition]`, X-Axis = `[Median Stage Duration]`.
4. Sort by `StageTransition[SortOrder]` ascending.

**Formatting:**
- Bar color: `#2E8B8B`.
- Data labels: ON, outside end, 10pt, show value with 1 decimal ("X.X days").
- X-axis title: "Median Days". Y-axis title: OFF.
- Grid lines: light gray.

---

### 2.2 Volume vs Delay Scatter

| Property | Value |
|---|---|
| Visual type | Scatter chart |
| Position | Middle-Left (X: 20, Y: 310) |
| Size | Half-width (610 x 200) |
| Title | "Volume vs Delay (by State)", 12pt bold |

**Fields:**

| Slot | Field |
|---|---|
| X-Axis (Values) | `[Total Orders]` |
| Y-Axis (Values) | `[Median Cycle Days]` |
| Details | `wwi vw_order_rollup[StateProvinceName]` |
| Size | `[Late Orders]` |

**Tooltips:**
- `wwi vw_order_rollup[StateProvinceName]`
- `[Total Orders]`
- `[Median Cycle Days]`
- `[SLA Breach %]`
- `[P90 Cycle Days]`

**Formatting:**
- Bubble color: `#2E8B8B`. Consider conditional: if `[SLA Breach %]` > 20% then `#E07A5F`.
  - To implement: use a DAX measure for color:
    ```
    Scatter Color = IF([SLA Breach %] > 0.20, "#E07A5F", "#2E8B8B")
    ```
    Apply via Conditional formatting > Marker color > Field value > `[Scatter Color]`.
- Bubble min/max size: 5 to 25.
- Add quadrant reference lines: X-axis constant line at median of Total Orders, Y-axis constant line at overall Median Cycle Days. Both dashed, gray `#AAAAAA`.
- X-axis title: "Order Volume". Y-axis title: "Median Cycle Days".
- Axis labels: 9pt.

---

### 2.3 Breach % Heatmap Matrix

| Property | Value |
|---|---|
| Visual type | Matrix |
| Position | Middle-Right (X: 650, Y: 310) |
| Size | Half-width (610 x 200) |
| Title | "SLA Breach % by Stage x Method", 12pt bold |

**Fields:**

| Slot | Field |
|---|---|
| Rows | `wwi vw_order_rollup[FurthestStage]` |
| Columns | `wwi vw_order_rollup[CustomerCategoryName]` |
| Values | `[SLA Breach %]` |

**Formatting:**
- Values format: percentage, 1 decimal.
- Conditional formatting on `[SLA Breach %]` cell background: gradient scale.
  - Minimum (0%): white `#FFFFFF`.
  - Maximum (highest value): `#E07A5F`.
  - Middle: light coral `#F2C6B8`.
- Row headers: 10pt, `#1B2A4A`.
- Column headers: 10pt, `#1B2A4A`.
- Stepped layout: OFF (tabular).
- Grid: thin borders `#E0E0E0`.
- +/- icons: OFF. Row subtotals: OFF. Column subtotals: OFF (keep it clean).

---

### 2.4 P90 vs Median Comparison Bars

| Property | Value |
|---|---|
| Visual type | Clustered bar chart (horizontal, grouped) |
| Position | Bottom (X: 20, Y: 520) |
| Size | Full-width (1240 x 180) |
| Title | "P90 vs Median Cycle Days by Stage Transition", 12pt bold |

**Approach -- use the same `StageTransition` disconnected table from 2.1:**

Create two SWITCH measures:
```
P90 Stage Duration =
SWITCH(
    SELECTEDVALUE(StageTransition[Transition]),
    "Created to Picked", [P90 Created-to-Picked],
    "Picked to Invoiced", [P90 Picked-to-Invoiced],
    "Invoiced to Delivered", [P90 Invoiced-to-Delivered]
)
```

**Fields:**

| Slot | Field |
|---|---|
| Y-Axis (Category) | `StageTransition[Transition]` |
| X-Axis (Value) | `[Median Stage Duration]`, `[P90 Stage Duration]` |
| Legend | Auto-generated from two measures |

**Formatting:**
- Median bars: `#2E8B8B`. P90 bars: `#E07A5F`.
- Data labels: ON, outside end, 9pt.
- Sort by `StageTransition[SortOrder]` ascending.
- Legend position: top-right. Legend text: 9pt.
- X-axis title: "Days".

---

## Page 3: Journey Explorer (Deneb)

**Page title:** "Journey Explorer"
**Subtitle:** "Show one order's journey end-to-end" -- 10pt, italic.

### Layout Grid

```
|--- Slicer Bar (full width, 0-50) ---|
|--- Title + Subtitle (55-95) ---|
| Customer Slicer | OrderID Slicer |  Cards  |   <- Row 1 (Y: 100-160)
| Deneb Timeline (large, main visual)  | Stats |   <- Row 2 (Y: 170-700)
```

---

### 3.1 Customer Name Slicer

| Property | Value |
|---|---|
| Visual type | Slicer |
| Position | Top-Left (X: 20, Y: 100) |
| Size | Third-width (380 x 55) |
| Field | `wwi vw_order_event[CustomerName]` |
| Style | Dropdown, single-select |

**Formatting:**
- Background: white. Border: 1px `#1B2A4A`.
- Header: "Customer", 10pt bold, `#1B2A4A`.
- Search enabled: YES (important -- there are many customers).

---

### 3.2 Order ID Slicer

| Property | Value |
|---|---|
| Visual type | Slicer |
| Position | Top-Center (X: 420, Y: 100) |
| Size | Third-width (300 x 55) |
| Field | `wwi vw_order_event[OrderID]` |
| Style | Dropdown, single-select |

**Formatting:**
- Same style as 3.1.
- Header: "Order ID", 10pt bold.
- Search enabled: YES.
- This slicer should be filtered by the Customer slicer (natural cross-filter through the data model).

---

### 3.3 Selected Order Stats Cards

| Property | Value |
|---|---|
| Position | Right sidebar (X: 1010, Y: 170) |
| Size | 250 x 530 (tall sidebar) |

Place 5 individual Card visuals stacked vertically in a white-background group/container:

| Card # | Y offset | Field | Label | Format |
|---|---|---|---|---|
| 1 | 170 | `[Event Count]` | Events | Whole number |
| 2 | 270 | `[Median Cycle Days]` | Cycle Days | 1 decimal |
| 3 | 370 | `wwi vw_order_rollup[FurthestStage]` displayed via measure* | Stage Reached | Text |
| 4 | 470 | `wwi vw_order_rollup[CustomerCategoryName]` displayed via measure* | Method | Text |
| 5 | 570 | On-time indicator measure* | On Time? | Text |

*Create helper measures for single-order context:

```
Selected Order Stage =
IF(HASONEVALUE('wwi vw_order_rollup'[OrderID]),
    SELECTEDVALUE('wwi vw_order_rollup'[FurthestStage]),
    "Select an order")

Selected Order Method =
IF(HASONEVALUE('wwi vw_order_rollup'[OrderID]),
    SELECTEDVALUE('wwi vw_order_rollup'[CustomerCategoryName]),
    "-")

Selected Order OnTime =
IF(HASONEVALUE('wwi vw_order_rollup'[OrderID]),
    IF(SELECTEDVALUE('wwi vw_order_rollup'[IsOnTime]) = 1, "Yes", "No"),
    "-")
```

**Formatting for all cards:**
- Callout: 18pt bold, `#1B2A4A`.
- Category label: 9pt, `#1B2A4A`.
- Card background: white `#FFFFFF`, 1px border `#E0E0E0`.
- Each card size: 250 x 90.

---

### 3.4 Deneb Timeline Visual

| Property | Value |
|---|---|
| Visual type | Deneb (custom Vega-Lite) |
| Position | Main area (X: 20, Y: 170) |
| Size | Large (970 x 530) |
| Spec file | `deneb/journey_explorer_spec.json` (source of truth) |
| Status | **Embedded in PBIR** — already wired in `denebTimeline/visual.json` |

**Data fields wired into Deneb query (8 fields):**

| Field | Use |
|---|---|
| `wwi vw_order_event[OrderID]` | Per-order grouping + tooltip |
| `wwi vw_order_event[EventTS]` | Converted to `DaysFromStart` via window transform |
| `wwi vw_order_event[Stage]` | X-axis (nominal, fixed sort order) |
| `wwi vw_order_event[StageSort]` | Retained for reference |
| `wwi vw_order_event[StageGroup]` | Zone tint (Pre-Ship / In-Transit) |
| `wwi vw_order_event[CustomerName]` | Tooltip |
| `wwi vw_order_event[ExpectedDeliveryDate]` | Retained for reference |
| `wwi vw_order_event[IsOnTime]` | Line/dot color encoding |

> **Note:** `CustomerCategoryName` was removed — it causes a DirectQuery schema cache error on this column.

**How the spec works (6 layers):**

| Layer | Type | Role |
|---|---|---|
| 1 | `rect` | Faint teal/coral column bands per zone (Pre-Ship / In-Transit) |
| 2 | `text` | "Pre-Ship" / "In-Transit" italic labels |
| 3 | `rule` | Dashed amber line at Y=1 day (SLA reference) |
| 4 | `text` | "1-day mark (93% of orders)" annotation |
| 5 | `line` | Per-order journey path; late orders 3× more opaque than on-time |
| 6 | `circle` | Stage milestone dots; Delivered dot is larger (outcome) |

**Key transforms:**
```
EventTSMs   = toNumber(datum['EventTS'])          // datetime → epoch ms
OrderStartMs = window min(EventTSMs) by OrderID   // each order's t=0
DaysFromStart = (EventTSMs - OrderStartMs) / 86400000
Status      = Open | On Time | Late               // from IsOnTime (0/1/null)
```

**Y-axis insight:** All orders normalized to start at 0. Lines ending below the 1-day dashed rule = on-time. Lines rising above = late. The stage where the slope steepens = the bottleneck.

**Colors:** On Time → teal `#2E8B8B`, Late → coral `#E07A5F`, Open → gray `#A0ADB8`.

**Usage:** Select a customer from the Customer slicer (single-select). All their orders fan out from Y=0. Use the Order ID slicer to drill into one specific order.

---

## Page 4: Root Cause Lab (Analyst)

**Page title:** "Root Cause Lab"
**Subtitle:** "Why are we late?" -- 10pt, italic.

### Layout Grid

```
|--- Slicer Bar (full width, 0-50) ---|
|--- Title + Subtitle (55-95) ---|
| Pareto Chart (full width)                      |   <- Row 1 (Y: 100-330)
| Decomposition Tree (full width)                |   <- Row 2 (Y: 340-510)
| Drill-Through Detail Table (full width)        |   <- Row 3 (Y: 520-700)
```

---

### 4.1 Pareto Chart -- Top Causes of Late Deliveries

| Property | Value |
|---|---|
| Visual type | Line and clustered column chart (combo chart) |
| Position | Top (X: 20, Y: 100) |
| Size | Full-width (1240 x 230) |
| Title | "Pareto: Top Contributors to Late Deliveries", 12pt bold |

**Fields:**

| Slot | Field |
|---|---|
| X-Axis (Category) | `wwi vw_order_rollup[CustomerCategoryName]` (or `[StateProvinceName]` -- choose the dimension that produces the most useful breakdown; can swap later) |
| Column Y-Axis | `[Late Orders]` |
| Line Y-Axis | Cumulative % measure (see below) |

**Required DAX measure:**
```
Cumulative Late % =
VAR CurrentLate = [Late Orders]
VAR AllRows =
    SUMMARIZE(
        ALLSELECTED('wwi vw_order_rollup'),
        'wwi vw_order_rollup'[CustomerCategoryName],
        "@Late", [Late Orders]
    )
VAR TotalLate = SUMX(AllRows, [@Late])
VAR RunningTotal =
    SUMX(
        FILTER(AllRows, [@Late] >= CurrentLate),
        [@Late]
    )
RETURN DIVIDE(RunningTotal, TotalLate)
```

**Formatting:**
- Column color: `#E07A5F` (these are late orders -- the "problem").
- Line color: `#1B2A4A`, weight 2, with markers.
- Line Y-axis: 0% to 100%, label "Cumulative %".
- Column Y-axis: label "Late Orders".
- Sort: `[Late Orders]` descending (this is what makes it a Pareto).
- Data labels on columns: ON, 9pt.
- Add a constant line on the Line Y-axis at 80%, dashed gray, label "80% threshold".

---

### 4.2 Decomposition Tree

| Property | Value |
|---|---|
| Visual type | Decomposition Tree |
| Position | Middle (X: 20, Y: 340) |
| Size | Full-width (1240 x 170) |
| Title | "Decompose Late Orders", 12pt bold |

**Fields:**

| Slot | Field |
|---|---|
| Analyze | `[Late Orders]` |
| Explain By | `wwi vw_order_rollup[CustomerCategoryName]` |
| | `wwi vw_order_rollup[StateProvinceName]` |
| | `wwi vw_order_rollup[FurthestStage]` |
| | `wwi vw_order_rollup[CustomerName]` |

**Formatting:**
- Bar color: `#E07A5F`.
- Font: 9pt body.
- Tree level connector: default gray.
- AI splits: ON (allow Power BI to suggest "High value" splits).

**Usage note:** The user can click through the tree to drill into which Method > State > Stage combination drives the most late orders. This is interactive -- no fixed drill path needed.

---

### 4.3 Drill-Through Detail Table

| Property | Value |
|---|---|
| Visual type | Table |
| Position | Bottom (X: 20, Y: 520) |
| Size | Full-width (1240 x 180) |
| Title | "Order Detail (filtered by selections above)", 12pt bold |

**Configure this as a drill-through page target (optional alternative):**
If you want this as a separate drill-through page, create a copy of this table on a hidden page and add drill-through fields. For now, place it inline on Page 4.

**Columns:**

| # | Column / Measure | Header | Width | Format |
|---|---|---|---|---|
| 1 | `wwi vw_order_rollup[OrderID]` | Order ID | 90 | Whole number |
| 2 | `wwi vw_order_rollup[CustomerName]` | Customer | 180 | Text |
| 3 | `wwi vw_order_rollup[CreatedDate]` | Created | 100 | Short date |
| 4 | `wwi vw_order_rollup[DeliveredDate]` | Delivered | 100 | Short date |
| 5 | `wwi vw_order_rollup[ExpectedDeliveryDate]` | Expected | 100 | Short date |
| 6 | `wwi vw_order_rollup[CycleTimeDays]` | Cycle Days | 90 | Whole number |
| 7 | `wwi vw_order_rollup[DaysFromExpected]` | Days Late | 90 | Whole number |
| 8 | `wwi vw_order_rollup[FurthestStage]` | Stage | 100 | Text |
| 9 | `wwi vw_order_rollup[CustomerCategoryName]` | Method | 140 | Text |
| 10 | `wwi vw_order_rollup[StateProvinceName]` | State | 120 | Text |

**Filters:**
- Visual-level filter: `wwi vw_order_rollup[IsOnTime]` = 0 (show only late/undelivered orders).

**Formatting:**
- Sort: `wwi vw_order_rollup[DaysFromExpected]` descending (worst offenders first).
- Conditional formatting on `Days Late`:
  - Font color rules: value > 0 = `#E07A5F` (bold), value <= 0 = `#2E8B8B`.
  - Value = BLANK = gray `#999999`.
- Conditional formatting on `Stage`:
  - Data bars or icon set: "Delivered" = green check icon, anything else = amber warning.
  - Alternative: background color -- "Delivered" = light teal `#D4EDED`, else light coral `#F9E0D8`.
- Header row: `#1B2A4A` background, white text, 10pt bold.
- Alternating rows: `#FFFFFF` / `#F4F1ED`.

**Interaction:**
- Clicking a row in the Pareto chart or a branch in the Decomposition Tree should cross-filter this table.
- Ensure Edit Interactions is set: Pareto > Filter > Detail Table. Decomposition Tree > Filter > Detail Table.

---

### 4.4 Drill-Through Configuration (Optional Enhancement)

To enable right-click drill-through from Pages 1 or 2 into Page 4:

1. On Page 4, add a drill-through field:
   - Drag `wwi vw_order_rollup[StateProvinceName]` to the **Drill through** filter well on the Visualizations pane.
   - Also add `wwi vw_order_rollup[CustomerCategoryName]` to the drill-through well.
2. This allows a user on Page 1's Red Alert table to right-click a row > "Drill through" > "Root Cause Lab", pre-filtered to that state and method.
3. Power BI automatically adds a Back button. Position it at top-left (X: 20, Y: 60), style: outline, `#1B2A4A`.

---

## Page 5: Show Your Work

**Page title:** "Show Your Work"
**Subtitle:** "Engineering, governance, and methodology" -- 10pt, italic.

This page has no slicers and no interactive visuals. It is a documentation page built with text boxes and static content.

### Layout Grid

```
|--- Title Bar (navy strip, 0-50) ---|
|--- Title + Subtitle (55-95) ---|
| Data Dictionary     | Metric Definitions      |   <- Row 1 (Y: 100-380)
| SQL Snippet         | Data Lineage Diagram     |   <- Row 2 (Y: 390-620)
| Business Rules + Links (full width)            |   <- Row 3 (Y: 630-710)
```

---

### 5.1 Data Dictionary

| Property | Value |
|---|---|
| Visual type | Text box |
| Position | Top-Left (X: 20, Y: 100) |
| Size | Half-width (610 x 280) |
| Background | White `#FFFFFF`, 1px border `#E0E0E0`, 8px corner radius |

**Content (paste this text, format in Power BI):**

Title line (12pt bold, `#1B2A4A`):
```
Data Dictionary
```

Body (9pt, `#1B2A4A`):
```
SOURCE TABLES
  wwi vw_order_rollup (Import)
    One row per order. Stage timestamps, cycle time,
    SLA flags, geography, delivery method.
    Key columns: OrderID, CreatedDate, PickedDate,
    InvoicedDate, DeliveredDate, CycleTimeDays,
    IsDelivered, IsOnTime, DaysFromExpected

  wwi vw_order_event (DirectQuery)
    Event log. One row per order per stage milestone.
    Key columns: OrderID, EventTS, Stage, StageSort,
    StageGroup

  dim_calendar (Import)
    Standard date dimension. Linked to CreatedDate
    and EventTS.

  wwi dim_stage (Import)
    Stage reference table. 4 rows: Order Created,
    Picked, Invoiced, Delivered. Sorted by stage_sort.
```

---

### 5.2 Metric Definitions

| Property | Value |
|---|---|
| Visual type | Text box |
| Position | Top-Right (X: 650, Y: 100) |
| Size | Half-width (610 x 280) |
| Background | White, 1px border, 8px radius |

**Content:**

Title (12pt bold):
```
Metric Definitions
```

Body (9pt):
```
CORE COUNTS
  Total Orders     COUNT of OrderID
  Delivered Orders COUNTROWS where IsDelivered = 1
  Open Orders      Total Orders - Delivered Orders
  Delivered %      Delivered Orders / Total Orders

SLA METRICS
  On-Time Orders   COUNTROWS where IsOnTime = 1
  Late Orders      Delivered - On-Time
  On-Time %        On-Time Orders / Delivered Orders
  SLA Breach %     1 - On-Time %

CYCLE TIME
  Median Cycle Days   MEDIAN of CycleTimeDays
  P90 Cycle Days      PERCENTILE.INC(CycleTimeDays, 0.9)
  Avg Cycle Days      AVERAGE of CycleTimeDays

STAGE DURATION (median + P90 for each)
  Created-to-Picked     MEDIAN(CreatedToPickedDays)
  Picked-to-Invoiced    MEDIAN(PickedToInvoicedDays)
  Invoiced-to-Delivered  MEDIAN(InvoicedToDeliveredDays)

PERIOD COMPARISON
  Orders MoM %     Month-over-month change in Total Orders
  On-Time MoM pp   Month-over-month change in On-Time %
  Cycle Time MoM   Month-over-month change in Median Cycle
```

---

### 5.3 SQL Snippet

| Property | Value |
|---|---|
| Visual type | Text box |
| Position | Bottom-Left (X: 20, Y: 390) |
| Size | Half-width (610 x 230) |
| Background | `#1B2A4A` (dark navy), white text -- to look like a code block |

**Content (white text, 9pt, monospace if possible -- Power BI text boxes default to Segoe UI, which is fine):**

Title (11pt bold, white):
```
Event Log SQL (vw_order_event excerpt)
```

Body (9pt, white, `Consolas` or `Courier New` if available via rich text paste):
```sql
SELECT o.OrderID,
       CAST(o.OrderDate AS DATETIME2(0)) AS EventTS,
       s.stage_name AS Stage,
       s.stage_sort AS StageSort,
       s.stage_group AS StageGroup,
       c.CustomerName,
       dm.CustomerCategoryName
FROM   WideWorldImporters.Sales.Orders o
JOIN   wwi.dim_stage s
         ON s.stage_name = 'Order Created'
LEFT JOIN cust c ON c.CustomerID = o.CustomerID
-- UNION ALL for Picked, Invoiced, Delivered...
-- Full script: /sql/01_views/01_vw_order_event.sql
```

---

### 5.4 Data Lineage Diagram

| Property | Value |
|---|---|
| Visual type | Text box (or Image if you export a diagram) |
| Position | Bottom-Right (X: 650, Y: 390) |
| Size | Half-width (610 x 230) |
| Background | White, 1px border |

**Content -- text-based lineage (paste as formatted text):**

Title (12pt bold):
```
Data Lineage
```

Body (10pt):
```
WideWorldImporters (OLTP - SQL Server)
  Sales.Orders ──────────┐
  Sales.Invoices ────────┤
  Application.Cities ────┤
  Application.DeliveryMethods ─┤
                         │
                    ┌────▼────────────────┐
                    │  wwi_analytics DB   │
                    │  ┌────────────────┐ │
                    │  │ vw_order_event │ │  (DirectQuery)
                    │  │ vw_order_rollup│ │  (Import)
                    │  │ dim_stage      │ │  (Import)
                    │  └────────────────┘ │
                    └────────┬────────────┘
                             │
                    ┌────────▼────────────┐
                    │   Power BI Model    │
                    │  + dim_calendar     │  (Import)
                    │  + DAX measures     │
                    │  + Deneb visual     │
                    └─────────────────────┘
```

If you prefer a proper diagram, create it in draw.io or PowerPoint, export as PNG, and insert as an Image visual at the same position.

---

### 5.5 Business Rules and Links

| Property | Value |
|---|---|
| Visual type | Text box |
| Position | Bottom strip (X: 20, Y: 630) |
| Size | Full-width (1240 x 80) |
| Background | White, 1px border |

**Content (10pt):**

Title (11pt bold):
```
Business Rules & Links
```

Body:
```
- On-time = DeliveredDate <= ExpectedDeliveryDate
- NULL milestone = stage not reached (no fake dates inserted)
- Multiple invoices per order: MIN() timestamp used
- Stage order enforced by dim_stage.stage_sort
- Full documentation + SQL scripts:
  github.com/ChetanSarda99/order-journey-analytics
```

---

## Appendix: Setup Checklist

Use this checklist after building each page to verify completeness.

### Pre-build (one-time)

- [ ] `StageTransition` calculated table created (for Page 2 visuals 2.1 and 2.4)
- [ ] `Median Stage Duration` SWITCH measure created
- [ ] `P90 Stage Duration` SWITCH measure created
- [ ] `Cumulative Late %` measure created (for Page 4 Pareto)
- [ ] `Orders MoM Label` measure created (for Page 1 delta cards)
- [ ] `OnTime MoM Label` measure created
- [ ] `Scatter Color` measure created (for Page 2 scatter)
- [ ] `Selected Order Stage`, `Selected Order Method`, `Selected Order OnTime` measures created (for Page 3 sidebar)
- [ ] Slicer sync group configured across Pages 1-4

### Per-page checks

**Page 1:**
- [ ] 4 KPI cards render values correctly
- [ ] MoM delta labels show arrows and correct colors
- [ ] Trend line shows On-Time % by month with 90% target line
- [ ] Bar chart sorts delivery methods descending by volume
- [ ] Red Alert table shows top 10 worst lanes with conditional formatting
- [ ] Cross-filter: clicking a table row filters the trend line and bar chart

**Page 2:**
- [ ] Stage duration bars show 3 transitions in correct order
- [ ] Scatter plot shows bubbles with conditional coloring at 20% breach threshold
- [ ] Matrix heatmap gradient displays correctly
- [ ] P90 vs Median grouped bars use correct colors (teal = median, coral = P90)

**Page 3:**
- [ ] Customer slicer has search enabled
- [ ] Selecting a customer filters available OrderIDs
- [ ] Selecting an OrderID renders the Deneb timeline
- [ ] Deneb shows stage circles on Y-axis, time on X-axis
- [ ] Expected delivery dashed line appears in coral
- [ ] Sidebar cards populate with selected order info
- [ ] No visual errors when no order is selected (measures return fallback text)

**Page 4:**
- [ ] Pareto sorts by Late Orders descending
- [ ] Cumulative line reaches 100% at the right edge
- [ ] 80% reference line visible
- [ ] Decomposition tree allows interactive drill into Method > State > Stage > Customer
- [ ] Detail table shows only late/undelivered orders (IsOnTime = 0 filter active)
- [ ] Days Late column conditional formatting: red for positive, teal for negative/zero
- [ ] Drill-through from Page 1 or 2 lands on Page 4 with correct filter context

**Page 5:**
- [ ] All text boxes render without clipping
- [ ] SQL snippet box has dark background with readable white text
- [ ] Lineage diagram is legible
- [ ] GitHub link is present and correct
