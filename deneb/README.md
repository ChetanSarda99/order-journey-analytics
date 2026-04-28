# Journey Explorer -- Deneb (Vega-Lite) Visual

A connected-dot timeline that visualises each order's progression through fulfillment stages inside Power BI.

## Prerequisites

- **Deneb** custom visual installed in Power BI Desktop (AppSource, free).
- The `wwi vw_order_event` table loaded in your model with columns:
  `OrderID`, `EventTS`, `Stage`, `StageSort`, `StageGroup`, `CustomerName`.

## Setup Steps

1. **Add columns to the Deneb visual field well**
   Drag these columns from `wwi vw_order_event` into the Deneb visual's **Values** bucket:

   | Column         | Purpose                         |
   |----------------|---------------------------------|
   | OrderID        | Groups dots into per-order lines |
   | EventTS        | Y-axis temporal position         |
   | Stage          | X-axis categorical position      |
   | StageSort      | (optional) kept for slicer use   |
   | StageGroup     | Colour encoding (Pre-Ship / In-Transit) |
   | CustomerName   | Tooltip detail                   |

2. **Paste the spec**
   - Select the Deneb visual on the canvas.
   - Open the Deneb editor (pencil icon or double-click).
   - Choose **Vega-Lite** as the provider.
   - Delete any default spec and paste the full contents of `journey_explorer_spec.json`.
   - Click **Create** (or **Apply**).

3. **Recommended slicer**
   The visual works best with 20-50 orders visible at once. Add a slicer on
   `OrderID` or `CustomerName` so users can narrow the view.

## Visual Design

- **X-axis**: Stage (categorical) -- Order Created, Picked, Invoiced, Delivered.
- **Y-axis**: EventTS (temporal) -- date/time of each milestone.
- **Lines**: Thin connecting lines per order, semi-transparent for overlap handling.
- **Dots**: Circle marks at each milestone, white-stroked for separation.
- **Colour**: Teal (#2E8B8B) for Pre-Ship stages, Coral (#E07A5F) for In-Transit.
- **Background bands**: Subtle shaded zones behind Pre-Ship and In-Transit regions.
- **Tooltips**: Order, Stage, Timestamp, Group, Customer.

## Customisation Tips

| Want to change...         | Edit this in the spec                                      |
|---------------------------|------------------------------------------------------------|
| Colours                   | `scale.range` arrays in the `color` encoding               |
| Dot size                  | `mark.size` in the circle layer (default 60)               |
| Line thickness            | `mark.strokeWidth` in the line layer (default 1.2)         |
| Opacity / transparency    | `mark.opacity` on line (0.3) and circle (0.7) layers       |
| Date format on Y-axis     | `axis.format` string, e.g. `"%Y-%m-%d"`                   |
| Tooltip date format       | `format` inside the EventTS tooltip entry                  |
| Background band intensity | `mark.opacity` on the rect layers (default 0.04)           |
| Font                      | `config.font` at the top level (default Segoe UI)          |
