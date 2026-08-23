# Methodology

## Analytical objective

The dashboard is a descriptive decision-support tool for exploring historical Australian MySuper product data. It compares fund scale, segment growth, selected benchmark allocations, and disclosed fees against long-term return targets.

## Grain and filters

The source grain is one MySuper product at one quarterly reporting date. Users select a fund type: Corporate, Industry, Public Sector or Retail.

## Metric definitions

### Latest-period fund assets

For each selected fund type, the dashboard finds the latest available reporting date and sums product-level `total_assets_aud_m` within each fund. This avoids adding the same fund's assets repeatedly across multiple quarters.

### Asset growth

Product assets are summed within each reporting period for the selected fund type. Changes may reflect genuine growth as well as product launches, closures, transfers or changes in reporting coverage.

### Benchmark allocation

The dashboard uses benchmark allocation fields, not upper range limits. When a fund has several MySuper products, product benchmarks are averaged using product assets as weights. Only Property, Infrastructure, Commodities and Other investments are displayed, so the stacked total is not intended to equal 100%.

### Fees and return targets

Each point represents a product in the latest reporting period. The y-axis is the annualised ten-year return target above CPI. It is not a realised return, forecast or recommendation. Dashed reference lines show the selected segment's medians.

## Corrections from the initial prototype

The portfolio version deliberately changes three parts of the original analysis:

1. Top funds use the latest period rather than a sum across all periods.
2. Allocation uses benchmark percentages and AUM weighting rather than stacking range limits across years.
3. The unsupported “risk-adjusted return” calculation was removed. A legitimate risk-adjusted measure would require a consistent realised return series and volatility definition.

## Data quality controls

- Invalid or blank reporting dates are excluded.
- Numeric fields are parsed after thousands separators are removed.
- Missing values are preserved and filtered only for analyses that require them.
- Fund ABNs remain text to avoid identifier formatting changes.

## Limitations

- The dataset ends in 2020 and is not current.
- Product-level disclosures are not necessarily comparable with whole-fund performance measures.
- Return targets are not realised performance.
- Fees may depend on the source disclosure basis and member assumptions.
- The dashboard is descriptive and does not establish causality.
- Nothing in this project is financial or investment advice.

## Source and licence

Data: [Superannuation MySuper Performance 2013-2020 on Kaggle](https://www.kaggle.com/datasets/darylb/superannuation-mysuper-product-by-product-2013-20), derived from APRA reporting and described by the publisher as CC BY 3.0 AU.
