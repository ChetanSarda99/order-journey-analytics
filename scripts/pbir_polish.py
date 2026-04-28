#!/usr/bin/env python3
"""Comprehensive PBIR visual polish: professional titles, subtitles, and content."""
import json
import os

BASE = os.path.join(
    r"C:\Users\Chetan\Desktop\Projects\order-journey-analytics",
    "powerbi", "wwi_order_jounrney_analytics.Report", "definition", "pages"
)

# ============================================================
# 1. CHART VISUAL TITLES (string manipulation preserves \u0027)
# ============================================================

VCO_TEMPLATE = """    "visualContainerObjects": {{
        "title": [
            {{
                "properties": {{
                    "show": {{ "expr": {{ "Literal": {{ "Value": "true" }} }} }},
                    "text": {{ "expr": {{ "Literal": {{ "Value": "\\u0027{title}\\u0027" }} }} }},
                    "fontSize": {{ "expr": {{ "Literal": {{ "Value": "13D" }} }} }},
                    "fontColor": {{ "solid": {{ "color": {{ "expr": {{ "Literal": {{ "Value": "\\u0027#1B2A4A\\u0027" }} }} }} }} }},
                    "fontFamily": {{ "expr": {{ "Literal": {{ "Value": "\\u0027Segoe UI\\u0027" }} }} }},
                    "bold": {{ "expr": {{ "Literal": {{ "Value": "true" }} }} }}
                }}
            }}
        ],
        "subTitle": [
            {{
                "properties": {{
                    "show": {{ "expr": {{ "Literal": {{ "Value": "true" }} }} }},
                    "text": {{ "expr": {{ "Literal": {{ "Value": "\\u0027{subtitle}\\u0027" }} }} }},
                    "fontSize": {{ "expr": {{ "Literal": {{ "Value": "10D" }} }} }},
                    "fontColor": {{ "solid": {{ "color": {{ "expr": {{ "Literal": {{ "Value": "\\u0027#888888\\u0027" }} }} }} }} }},
                    "fontFamily": {{ "expr": {{ "Literal": {{ "Value": "\\u0027Segoe UI\\u0027" }} }} }}
                }}
            }}
        ]
    }}"""

charts = {
    "ControlTower/lineOnTimeTrend": (
        "On-Time Delivery Trend",
        "Monthly -- trending up or down?"
    ),
    "ControlTower/barOrdersByMethod": (
        "Volume by Customer Category",
        "Which segments drive the most business?"
    ),
    "ControlTower/tableRedAlert": (
        "SLA Risk Zones",
        "Highest breach rates first -- where should we act?"
    ),
    "BottleneckFinder/barMedianStage": (
        "Stage Duration Breakdown",
        "Median days per step -- where do orders stall?"
    ),
    "BottleneckFinder/scatterVolumeDelay": (
        "Volume vs. Delay by State",
        "Top-right = high volume, slow delivery -- act first"
    ),
    "BottleneckFinder/matrixBreachHeatmap": (
        "Breach Rate by Stage and Category",
        "Darker zones signal systemic fulfillment gaps"
    ),
    "BottleneckFinder/barP90vsMedian": (
        "P90 vs. Median Duration",
        "Big gap = unpredictable process -- why the variance?"
    ),
    "JourneyExplorer/denebTimeline": (
        "Order Journey Timeline",
        "Each line = one order moving through the fulfillment pipeline"
    ),
    "RootCauseLab/paretoLateOrders": (
        "Late Delivery Concentration",
        "A few categories drive most late deliveries"
    ),
    "RootCauseLab/keyInfluencers": (
        "Key Influencers",
        "AI finds what factors increase breach risk most"
    ),
    "RootCauseLab/tableDetail": (
        "Order-Level Investigation",
        "Drill into individual orders for root cause"
    ),
}

print("=== Adding chart visual titles ===")
for rel_path, (title, subtitle) in charts.items():
    parts = rel_path.split("/")
    filepath = os.path.join(BASE, parts[0], "visuals", parts[1], "visual.json")
    with open(filepath, "r", encoding="utf-8-sig") as f:
        content = f.read()

    content = content.rstrip()

    # Find last } (root close) and second-to-last } (visual close)
    last_brace = content.rfind("}")
    second_last = content[:last_brace].rstrip().rfind("}")

    vco = VCO_TEMPLATE.format(title=title, subtitle=subtitle)
    new_content = content[:second_last + 1] + ",\n" + vco + "\n}\n"

    with open(filepath, "w", encoding="utf-8-sig") as f:
        f.write(new_content)

    print(f'  + {rel_path}: "{title}"')

# ============================================================
# 2. TITLE BOXES (full JSON rewrite with professional content)
# ============================================================

TITLE_BOX_TEMPLATE = """\ufeff{{
    "$schema": "https://developer.microsoft.com/json-schemas/fabric/item/report/definition/visualContainer/2.5.0/schema.json",
    "name": "{name}",
    "position": {{
        "x": 20,
        "y": 10,
        "z": 11000,
        "height": 46,
        "width": 280,
        "tabOrder": 11000
    }},
    "visual": {{
        "visualType": "textbox",
        "objects": {{
            "general": [
                {{
                    "properties": {{
                        "paragraphs": [
                            {{
                                "textRuns": [
                                    {{
                                        "value": "{title}",
                                        "textStyle": {{
                                            "fontFamily": "\\u0027Segoe UI\\u0027",
                                            "fontSize": "\\u002720px\\u0027",
                                            "fontWeight": "\\u0027bold\\u0027",
                                            "color": "\\u0027#1B2A4A\\u0027"
                                        }}
                                    }}
                                ]
                            }},
                            {{
                                "textRuns": [
                                    {{
                                        "value": "{subtitle}",
                                        "textStyle": {{
                                            "fontFamily": "\\u0027Segoe UI\\u0027",
                                            "fontSize": "\\u002711px\\u0027",
                                            "fontStyle": "\\u0027italic\\u0027",
                                            "color": "\\u0027#666666\\u0027"
                                        }}
                                    }}
                                ]
                            }}
                        ]
                    }}
                }}
            ]
        }},
        "drillFilterOtherVisuals": true
    }}
}}
"""

title_boxes = {
    "ControlTower/titleBox": (
        "titleBox",
        "Control Tower",
        "Performance at a glance -- are we delivering on our promises?"
    ),
    "BottleneckFinder/titleBox": (
        "titleBox",
        "Bottleneck Finder",
        "Which workflow steps are slowing orders down?"
    ),
    "JourneyExplorer/titleBox": (
        "titleBox",
        "Journey Explorer",
        "Follow any order from creation to delivery"
    ),
    "RootCauseLab/titleBox": (
        "titleBox",
        "Root Cause Lab",
        "What drives late deliveries? Where should we intervene?"
    ),
}

print("\n=== Updating page title boxes ===")
for rel_path, (name, title, subtitle) in title_boxes.items():
    parts = rel_path.split("/")
    filepath = os.path.join(BASE, parts[0], "visuals", parts[1], "visual.json")
    content = TITLE_BOX_TEMPLATE.format(name=name, title=title, subtitle=subtitle)

    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

    print(f'  + {rel_path}: "{title}" / "{subtitle}"')

# ============================================================
# 3. FIX DATADICTIONARY ENCODING (em-dash artifacts -> --)
# ============================================================

print("\n=== Fixing DataDictionary encoding ===")
dd_path = os.path.join(BASE, "DataDictionary", "visuals", "textDataDictionary", "visual.json")
with open(dd_path, "r", encoding="utf-8-sig") as f:
    content = f.read()

# The double-encoded em-dash shows as various character sequences
original_len = len(content)

# Try multiple patterns for the garbled em-dash
replacements = [
    ("\u00c3\u00a2\u00e2\u201a\u00ac\u00e2\u20ac\u0094", " -- "),
    ("\u00c3\u00a2\u00e2\u201a\u00ac\u00e2\u20ac\"", " -- "),
    ("Ã¢â\u200a¬â\u20ac\"", " -- "),
]

for old, new in replacements:
    content = content.replace(old, new)

# Also try raw byte approach
if len(content) == original_len:
    print("  Warning: standard replacements did not match, trying character-by-character")
    # The sequence in the file (as UTF-8 bytes decoded) is the characters:
    # U+00C3 U+00A2 U+00E2 U+201A U+00AC U+00E2 U+2014
    # or similar combinations
    import re
    content = re.sub(r"[\u00c0-\u00c5][\u00a0-\u00af][\u00e0-\u00ef].{1,3}", " -- ", content)

with open(dd_path, "w", encoding="utf-8-sig") as f:
    f.write(content)

print("  Done")

# ============================================================
# 4. VERIFY ALL FILES ARE VALID JSON
# ============================================================

print("\n=== JSON Validation ===")
errors = 0
all_files = list(charts.keys()) + [k for k in title_boxes.keys()]
for rel_path in all_files:
    parts = rel_path.split("/")
    filepath = os.path.join(BASE, parts[0], "visuals", parts[1], "visual.json")
    try:
        with open(filepath, "r", encoding="utf-8-sig") as f:
            json.load(f)
    except json.JSONDecodeError as e:
        print(f"  ERROR: {rel_path} - Invalid JSON: {e}")
        errors += 1

# Also validate DataDictionary
try:
    with open(dd_path, "r", encoding="utf-8-sig") as f:
        json.load(f)
except json.JSONDecodeError as e:
    print(f"  ERROR: DataDictionary - Invalid JSON: {e}")
    errors += 1

if errors == 0:
    print(f"  All {len(all_files) + 1} files are valid JSON")
else:
    print(f"  {errors} files have JSON errors!")

print(f"\nDONE! Updated {len(charts)} chart titles + {len(title_boxes)} title boxes + 1 encoding fix")
