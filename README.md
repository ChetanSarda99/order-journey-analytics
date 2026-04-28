# 📊 Event-Log Analytics — Order Journey Timelines in Power BI

> Transforming operational workflows into event logs to visualize **customer order journeys**, identify **bottlenecks**, and analyze **process inefficiencies** using Power BI and advanced analytics.

[![SQL Server](https://img.shields.io/badge/SQL_Server-SSMS-CC2927?style=flat&logo=microsoft-sql-server&logoColor=white)](https://www.microsoft.com/sql-server)
[![Power BI](https://img.shields.io/badge/Power_BI-Desktop-F2C811?style=flat&logo=powerbi&logoColor=black)](https://powerbi.microsoft.com/)
[![Deneb](https://img.shields.io/badge/Deneb-Vega--Lite-blue?style=flat)](https://deneb-viz.github.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## 🎯 Project Overview

Most business dashboards focus on **aggregate metrics** (totals, averages, trends), but operational teams need to answer deeper questions:

- ❓ **Where do orders actually get delayed?**
- ❓ **Which stage creates the biggest bottleneck?**
- ❓ **How do different segments (ship method, region, customer) impact delivery times?**

This project addresses these questions by:
- Modeling order milestones as an **event log** (one row per order per stage)
- Building **journey timeline visualizations** using Deneb in Power BI
- Enabling **process mining** and **operational analytics**

**Dataset:** Wide World Importers (WWI) — OLTP + Data Warehouse  
**Last Updated:** February 2, 2026

---

## ✨ Key Features

- **Event Log Modeling** — Converts transactional data into process-mining-ready format
- **Timeline Visualizations** — Journey maps showing order progression across stages
- **Bottleneck Analysis** — Identify delays and inefficiencies in operational workflows
- **Segment Analysis** — Compare performance across ship methods, regions, customers, products
- **Reusable SQL Patterns** — Modular scripts for schema setup, views, and metrics
- **Comprehensive Documentation** — Data dictionary, metric definitions, business rules

---

## 📁 Repository Structure

```
order-journey-analytics/
├── sql/                    # Database objects and queries
│   ├── 00_setup/          # Schema creation and dimension tables
│   ├── 01_views/          # Event log view (vw_order_event)
│   └── 02_metrics/        # Aggregated metrics and KPIs
├── docs/                   # Project documentation
│   ├── data_dictionary.md
│   ├── metric_definitions.md
│   ├── business_rules.md
│   ├── dataset_workflow.md
│   └── report_storyboard.md
├── powerbi/               # Power BI artifacts
│   ├── deneb_specs/      # Vega-Lite specifications
│   └── screenshots/      # Report screenshots
├── assets/               # Images and diagrams
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites
- SQL Server (2017+) or Azure SQL Database
- SQL Server Management Studio (SSMS)
- Power BI Desktop
- Wide World Importers sample database ([download here](https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0))

### Installation

1. **Set up the database**
   ```bash
   # Import WWI OLTP + DW into SQL Server
   # See docs/dataset_workflow.md for detailed steps
   ```

2. **Run SQL scripts**
   ```sql
   -- Execute scripts in order
   -- Start with sql/00_setup/00_create_schema.sql
   -- Then sql/00_setup/01_dim_stage.sql
   -- Finally sql/01_views/01_vw_order_event.sql
   ```

3. **Connect Power BI**
   - Open Power BI Desktop
   - Connect to your SQL Server instance
   - Import/DirectQuery from `wwi_analytics.wwi.*` schema
   - Build visualizations using `docs/report_storyboard.md`

4. **Explore the data**
   - Check `docs/data_dictionary.md` for field definitions
   - Review `docs/metric_definitions.md` for KPI calculations
   - Follow `docs/business_rules.md` for data validation logic

---

## 🛠️ Tech Stack

| Technology | Purpose |
|-----------|---------|
| **SQL Server** | Data storage and transformation |
| **T-SQL** | Event log modeling, views, metrics |
| **Power BI** | Visualization and dashboards |
| **Deneb (Vega-Lite)** | Custom timeline visualizations |
| **Wide World Importers** | Sample OLTP + DW dataset |

---

## 📊 Screenshots

> 📸 *Screenshots coming soon — visualizations of order journey timelines, bottleneck analysis, and segment comparisons*

---

## 📚 Documentation

- **[Data Dictionary](docs/data_dictionary.md)** — Field definitions and descriptions
- **[Metric Definitions](docs/metric_definitions.md)** — KPI calculations and formulas
- **[Business Rules](docs/business_rules.md)** — Data validation and transformation logic
- **[Dataset Workflow](docs/dataset_workflow.md)** — Database setup instructions
- **[Report Storyboard](docs/report_storyboard.md)** — Visualization design guide
- **[Build Log](docs/build_log.md)** — Development timeline and decisions

---

## 🎓 What I Learned

- Event log modeling techniques for process mining
- Advanced T-SQL for time-series and stage-based analysis
- Custom visualizations in Power BI using Deneb/Vega-Lite
- Dimensional modeling and star schema design
- Documentation best practices for analytics projects

---

## 🔮 Future Enhancements

- [ ] Add Sankey diagrams for order flow paths
- [ ] Implement predictive analytics for delay forecasting
- [ ] Create DAX measures for dynamic stage comparisons
- [ ] Build automated data refresh pipeline
- [ ] Add more granular customer segmentation

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🤝 Connect

If you found this project interesting or have questions, feel free to reach out!

**Chetan Sarda**  
[![GitHub](https://img.shields.io/badge/GitHub-ChetanSarda99-181717?style=flat&logo=github)](https://github.com/ChetanSarda99)

---

<div align="center">
  
**⭐ If you found this project helpful, please consider giving it a star!**

</div>
