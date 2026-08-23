library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(scales)

data_path <- file.path("data", "mysuper_data.csv")
output_dir <- "screenshots"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

data <- read_csv(data_path, show_col_types = FALSE, na = c("", "NA")) |>
  mutate(period = as.Date(period))

fund_type <- "Industry"
history <- data |> filter(.data$fund_type == .env$fund_type)
latest_period <- max(history$period, na.rm = TRUE)
latest <- history |> filter(period == latest_period)

brand_blue <- "#0B3C5D"
accent_teal <- "#00A6A6"
accent_gold <- "#F4B942"
muted_ink <- "#52606D"

portfolio_theme <- theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", colour = brand_blue, size = 18),
    plot.subtitle = element_text(colour = muted_ink),
    panel.grid.minor = element_blank(),
    axis.title = element_text(colour = muted_ink),
    legend.position = "bottom",
    plot.background = element_rect(fill = "white", colour = NA),
    panel.background = element_rect(fill = "white", colour = NA),
    plot.margin = margin(18, 30, 18, 18)
  )

save_plot <- function(plot, filename, width = 13, height = 7.2) {
  ggsave(
    file.path(output_dir, filename),
    plot,
    width = width,
    height = height,
    dpi = 160,
    bg = "white"
  )
}

top_funds <- latest |>
  filter(!is.na(total_assets_aud_m), total_assets_aud_m >= 0) |>
  group_by(fund_name) |>
  summarise(total_assets_aud_m = sum(total_assets_aud_m), .groups = "drop") |>
  slice_max(total_assets_aud_m, n = 10, with_ties = FALSE) |>
  arrange(total_assets_aud_m)

p_top <- ggplot(top_funds, aes(total_assets_aud_m, reorder(fund_name, total_assets_aud_m))) +
  geom_col(fill = accent_teal, width = 0.72) +
  geom_text(
    aes(label = dollar(total_assets_aud_m, accuracy = 1, suffix = "m")),
    hjust = -0.08,
    colour = brand_blue,
    size = 4
  ) +
  scale_x_continuous(labels = label_dollar(suffix = "m"), expand = expansion(mult = c(0, 0.2))) +
  labs(
    title = paste("Largest", fund_type, "funds by assets"),
    subtitle = paste("Latest available period:", format(latest_period, "%d %b %Y")),
    x = "Assets under management (AUD millions)",
    y = NULL
  ) +
  portfolio_theme
save_plot(p_top, "top-10-funds.png")

growth <- history |>
  group_by(period) |>
  summarise(total_assets_aud_m = sum(total_assets_aud_m, na.rm = TRUE), .groups = "drop")

p_growth <- ggplot(growth, aes(period, total_assets_aud_m)) +
  geom_area(fill = alpha(accent_teal, 0.18)) +
  geom_line(colour = brand_blue, linewidth = 1.2) +
  geom_point(colour = accent_teal, size = 2.3) +
  scale_y_continuous(labels = label_dollar(suffix = "m")) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(
    title = paste(fund_type, "segment asset history"),
    subtitle = "Quarterly sum of reported product assets",
    x = NULL,
    y = "Assets under management (AUD millions)"
  ) +
  portfolio_theme
save_plot(p_growth, "asset-growth.png")

eligible_funds <- top_funds$fund_name
allocation <- latest |>
  filter(fund_name %in% eligible_funds, !is.na(total_assets_aud_m), total_assets_aud_m > 0) |>
  select(
    fund_name,
    total_assets_aud_m,
    property_benchmark_pct,
    infrastructure_benchmark_pct,
    commodities_benchmark_pct,
    other_investments_benchmark_pct
  ) |>
  pivot_longer(ends_with("_benchmark_pct"), names_to = "asset_class", values_to = "allocation_pct") |>
  filter(!is.na(allocation_pct)) |>
  mutate(
    asset_class = recode(
      asset_class,
      property_benchmark_pct = "Property",
      infrastructure_benchmark_pct = "Infrastructure",
      commodities_benchmark_pct = "Commodities",
      other_investments_benchmark_pct = "Other investments"
    )
  ) |>
  group_by(fund_name, asset_class) |>
  summarise(allocation_pct = weighted.mean(allocation_pct, total_assets_aud_m), .groups = "drop")

p_allocation <- ggplot(allocation, aes(fund_name, allocation_pct, fill = asset_class)) +
  geom_col(width = 0.72) +
  coord_flip() +
  scale_fill_manual(values = c(
    "Property" = brand_blue,
    "Infrastructure" = accent_teal,
    "Commodities" = accent_gold,
    "Other investments" = "#8B5CF6"
  )) +
  scale_y_continuous(labels = label_percent(scale = 1), expand = expansion(mult = c(0, 0.05))) +
  labs(
    title = "Selected benchmark asset allocations",
    subtitle = "Latest-period AUM-weighted averages; selected classes do not represent the full portfolio",
    x = NULL,
    y = "Benchmark allocation",
    fill = NULL
  ) +
  portfolio_theme
save_plot(p_allocation, "asset-allocation.png")

cost_return <- latest |>
  filter(!is.na(statement_fee_aud), !is.na(return_target_above_cpi_pct))

p_cost <- ggplot(cost_return, aes(statement_fee_aud, return_target_above_cpi_pct, colour = risk_level_label)) +
  geom_vline(xintercept = median(cost_return$statement_fee_aud), linetype = "dashed", colour = "#A7B0BE") +
  geom_hline(yintercept = median(cost_return$return_target_above_cpi_pct), linetype = "dashed", colour = "#A7B0BE") +
  geom_point(size = 4, alpha = 0.82) +
  scale_x_continuous(labels = label_dollar()) +
  scale_y_continuous(labels = label_percent(scale = 1)) +
  labs(
    title = "Fees versus long-term return targets",
    subtitle = "Each point is a MySuper product; dashed lines show selected-segment medians",
    x = "Statement of fees and other costs (AUD)",
    y = "Annualised return target above CPI",
    colour = "Risk label"
  ) +
  portfolio_theme
save_plot(p_cost, "cost-return-analysis.png")
