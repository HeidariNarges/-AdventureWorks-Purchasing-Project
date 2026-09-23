# AdventureWorks Purchasing Process Improvement

## Selected Process
Purchasing process from AdventureWorks 2019 database

## Why This Process?
After exploring the database, Purchasing was selected due to rich data 
(delays, costs, vendor performance) and improvable bottlenecks.

## Project Phases
- **Phase 1**: BPMN As-Is + 6 analytical questions
- **Phase 2**: T-SQL (View, SP, RFM, Star Schema)
- **Phase 3**: Power BI Dashboard
- **Phase 4**: BPMN To-Be + Expected Impact
- **Phase 5**: Storytelling
- **Phase 6**: Publication

## Key Findings
1. 86 low-frequency vendors = 25 days
2. 79 high-frequency vendors = 9 days
3. Bipolar vendor distribution
4. RFM: 4 to remove + 3 to increase frequency
5. Worst delay: 187 days

## To-Be Recommendation
Adding "Low-frequency?" Gateway + two paths:
- Merge At Risk vendors
- Consolidate orders to increase frequency

## Project Structure
- `/bpm` — BPMN As-Is and To-Be
- `/sql` — Queries, Views, SP, RFM
- `/powerbi` — Power BI Dashboard
- `/docs` — Documentation and Presentations

## How to Run
1. Run `sql/*.sql` files in SQL Server
2. Open `powerbi/adventureworks.pbix` in Power BI
3. View BPMN models in `/bpm`
4. View presentations in `/docs`

## Team Contribution
| Name | Role | Contributions |
|------|------|----------------|
| Narges Heidari | Power BI & Dashboard | 4-page Dashboard, DAX Measures, Dashboard Screenshots, Performance Optimization |
| Sara ValiPoor | BPM, SQL & Process Improvement | BPMN As-Is/To-Be, Analytical Queries, Views, SP, RFM,  Storytelling |

