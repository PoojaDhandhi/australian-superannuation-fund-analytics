# Dataset

This folder contains the cleaned, analysis-ready dataset used by the Shiny application.

## File

- [`mysuper_data.csv`](mysuper_data.csv) - 2,987 historical MySuper product-period records with 14 selected fields.

## Provenance

The source is the Kaggle dataset [Superannuation MySuper Performance 2013-2020](https://www.kaggle.com/datasets/darylb/superannuation-mysuper-product-by-product-2013-20), which states that the underlying information was sourced from the Australian Prudential Regulation Authority (APRA).

The source description identifies the data as licensed under the [Creative Commons Attribution 3.0 Australia Licence](https://creativecommons.org/licenses/by/3.0/au/). APRA does not endorse this project.

## Cleaning performed

- Removed the source units row and more than one million comma-only rows.
- Retained 2,987 records with valid reporting dates.
- Converted dates from `DD/MM/YYYY` to ISO `YYYY-MM-DD`.
- Removed thousands separators from numeric fields.
- Selected only fields required by the dashboard.
- Renamed columns to analysis-friendly `snake_case` names.

No observations were imputed. Missing source values remain blank.

## Schema

| Column | Meaning |
|---|---|
| `period` | Quarterly reporting date |
| `product_name` | MySuper product name |
| `product_type` | Product category |
| `fund_name` | Superannuation fund name |
| `fund_abn` | Fund ABN, retained as text |
| `fund_type` | Corporate, Industry, Public Sector or Retail |
| `total_assets_aud_m` | Total assets in AUD millions |
| `return_target_above_cpi_pct` | Annualised ten-year return target above CPI, percentage points |
| `risk_level_label` | Source investment-risk label |
| `statement_fee_aud` | Statement of fees and other costs, AUD |
| `property_benchmark_pct` | Property benchmark allocation |
| `infrastructure_benchmark_pct` | Infrastructure benchmark allocation |
| `commodities_benchmark_pct` | Commodities benchmark allocation |
| `other_investments_benchmark_pct` | Other-investments benchmark allocation |

## Important limitation

This is historical data ending in 2020. It must not be presented as a current comparison of superannuation funds.
