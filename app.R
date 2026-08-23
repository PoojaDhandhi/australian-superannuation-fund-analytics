library(shiny)
library(ggplot2)
library(dplyr)
library(tidyr)
library(readr)
library(scales)
library(bslib)

data_path <- file.path("data", "mysuper_data.csv")

if (!file.exists(data_path)) {
  stop(
    "Missing data/mysuper_data.csv. See data/README.md for setup instructions.",
    call. = FALSE
  )
}

mysuper <- read_csv(
  data_path,
  show_col_types = FALSE,
  na = c("", "NA", "N/A")
) |>
  mutate(
    period = as.Date(period),
    across(
      c(
        total_assets_aud_m,
        return_target_above_cpi_pct,
        statement_fee_aud,
        property_benchmark_pct,
        infrastructure_benchmark_pct,
        commodities_benchmark_pct,
        other_investments_benchmark_pct
      ),
      as.numeric
    )
  ) |>
  filter(!is.na(period), !is.na(fund_type), fund_type != "")

fund_types <- sort(unique(mysuper$fund_type))

brand_blue <- "#0B3C5D"
accent_teal <- "#00A6A6"
accent_gold <- "#F4B942"
muted_ink <- "#52606D"

chart_theme <- theme_minimal(base_size = 13) +
  theme(
    plot.title = element_text(face = "bold", colour = brand_blue, size = 16),
    plot.subtitle = element_text(colour = muted_ink),
    panel.grid.minor = element_blank(),
    axis.title = element_text(colour = muted_ink),
    legend.position = "bottom",
    plot.margin = margin(12, 24, 12, 12)
  )

ui <- fluidPage(
  theme = bs_theme(
    version = 5,
    bootswatch = "flatly",
    primary = brand_blue,
    secondary = accent_teal
  ),
  tags$head(
    tags$style(HTML("\
      body { background: #F6F8FB; }\
      .container-fluid { max-width: 1500px; padding: 24px; }\
      .hero { background: linear-gradient(120deg, #0B3C5D, #126782);\
              color: white; border-radius: 16px; padding: 28px 32px;\
              margin-bottom: 20px; box-shadow: 0 10px 28px rgba(11,60,93,.15); }\
      .hero h1 { margin: 0 0 8px; font-size: 30px; font-weight: 750; }\
      .hero p { margin: 0; color: #DCEAF2; max-width: 900px; }\
      .panel-card { background: white; border: 1px solid #E4E9F0; border-radius: 14px;\
                    padding: 18px; margin-bottom: 18px; box-shadow: 0 5px 16px rgba(19,33,68,.06); }\
      .kpi { background: white; border: 1px solid #E4E9F0; border-radius: 12px;\
             padding: 16px 18px; margin-bottom: 16px; min-height: 96px; }\
      .kpi-label { color: #697386; font-size: 12px; text-transform: uppercase;\
                   letter-spacing: .06em; font-weight: 700; }\
      .kpi-value { color: #0B3C5D; font-size: 24px; font-weight: 750; margin-top: 5px; }\
      .nav-tabs { border-bottom: 1px solid #D9E1EA; }\
      .nav-tabs .nav-link { color: #52606D; font-weight: 650; }\
      .nav-tabs .nav-link.active { color: #0B3C5D; }\
      .insight { border-left: 4px solid #00A6A6; background: #F0FAFA;\
                 padding: 14px 16px; border-radius: 8px; margin-top: 10px; }\
      .source-note { color: #697386; font-size: 12px; margin-top: 14px; }\
    "))
  ),

  div(
    class = "hero",
    h1("Australian Superannuation Fund Performance Analytics"),
    p(
      "Decision-support analysis of historical Australian MySuper products, ",
      "covering fund scale, asset growth, benchmark allocation and fee-return targets."
    )
  ),

  fluidRow(
    column(
      width = 3,
      div(
        class = "panel-card",
        h4("Analysis controls"),
        selectInput(
          "fund_type",
          "Fund type",
          choices = fund_types,
          selected = if ("Industry" %in% fund_types) "Industry" else fund_types[[1]]
        ),
        downloadButton("download_data", "Download filtered data", class = "btn-primary"),
        hr(),
        tags$p(
          class = "source-note",
          "Historical product-level data sourced from APRA via Kaggle. ",
          "Figures are descriptive and are not financial advice."
        )
      )
    ),
    column(
      width = 9,
      fluidRow(
        column(3, div(class = "kpi", div(class = "kpi-label", "Latest period"), div(class = "kpi-value", textOutput("latest_period")))),
        column(3, div(class = "kpi", div(class = "kpi-label", "Fund AUM"), div(class = "kpi-value", textOutput("total_aum")))),
        column(3, div(class = "kpi", div(class = "kpi-label", "Funds"), div(class = "kpi-value", textOutput("fund_count")))),
        column(3, div(class = "kpi", div(class = "kpi-label", "Products"), div(class = "kpi-value", textOutput("product_count"))))
      ),
      div(
        class = "panel-card",
        tabsetPanel(
          tabPanel(
            "Market scale",
            plotOutput("top_funds_plot", height = "540px"),
            uiOutput("top_funds_insight")
          ),
          tabPanel(
            "Asset growth",
            plotOutput("growth_plot", height = "540px"),
            uiOutput("growth_insight")
          ),
          tabPanel(
            "Allocation",
            plotOutput("allocation_plot", height = "560px"),
            uiOutput("allocation_insight")
          ),
          tabPanel(
            "Fees & targets",
            plotOutput("cost_return_plot", height = "540px"),
            uiOutput("cost_return_insight")
          )
        )
      )
    )
  )
)

server <- function(input, output, session) {
  selected_history <- reactive({
    req(input$fund_type)
    mysuper |> filter(fund_type == input$fund_type)
  })

  latest_snapshot <- reactive({
    history <- selected_history()
    latest_period <- max(history$period, na.rm = TRUE)
    history |> filter(period == latest_period)
  })

  top_funds <- reactive({
    latest_snapshot() |>
      filter(!is.na(total_assets_aud_m), total_assets_aud_m >= 0) |>
      group_by(fund_name) |>
      summarise(total_assets_aud_m = sum(total_assets_aud_m), .groups = "drop") |>
      slice_max(total_assets_aud_m, n = 10, with_ties = FALSE) |>
      arrange(total_assets_aud_m)
  })

  allocation_data <- reactive({
    eligible_funds <- latest_snapshot() |>
      filter(!is.na(total_assets_aud_m), total_assets_aud_m > 0) |>
      group_by(fund_name) |>
      summarise(total_assets_aud_m = sum(total_assets_aud_m), .groups = "drop") |>
      slice_max(total_assets_aud_m, n = 10, with_ties = FALSE) |>
      pull(fund_name)

    latest_snapshot() |>
      filter(fund_name %in% eligible_funds, !is.na(total_assets_aud_m), total_assets_aud_m > 0) |>
      select(
        fund_name,
        total_assets_aud_m,
        property_benchmark_pct,
        infrastructure_benchmark_pct,
        commodities_benchmark_pct,
        other_investments_benchmark_pct
      ) |>
      pivot_longer(
        ends_with("_benchmark_pct"),
        names_to = "asset_class",
        values_to = "allocation_pct"
      ) |>
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
      summarise(
        allocation_pct = weighted.mean(allocation_pct, total_assets_aud_m),
        .groups = "drop"
      )
  })

  output$latest_period <- renderText({
    format(max(selected_history()$period, na.rm = TRUE), "%b %Y")
  })

  output$total_aum <- renderText({
    value <- sum(latest_snapshot()$total_assets_aud_m, na.rm = TRUE)
    dollar(value, accuracy = 1, suffix = "m")
  })

  output$fund_count <- renderText({
    n_distinct(latest_snapshot()$fund_name)
  })

  output$product_count <- renderText({
    n_distinct(latest_snapshot()$product_name)
  })

  output$top_funds_plot <- renderPlot({
    plot_data <- top_funds()
    validate(need(nrow(plot_data) > 0, "No AUM data is available for this fund type."))

    ggplot(plot_data, aes(total_assets_aud_m, reorder(fund_name, total_assets_aud_m))) +
      geom_col(fill = accent_teal, width = 0.72) +
      geom_text(
        aes(label = dollar(total_assets_aud_m, accuracy = 1, suffix = "m")),
        hjust = -0.08,
        colour = brand_blue,
        size = 3.8
      ) +
      scale_x_continuous(labels = label_dollar(suffix = "m"), expand = expansion(mult = c(0, 0.2))) +
      labs(
        title = paste("Largest", input$fund_type, "funds by assets"),
        subtitle = paste("Latest available period:", format(max(selected_history()$period), "%d %b %Y")),
        x = "Assets under management (AUD millions)",
        y = NULL
      ) +
      chart_theme
  })

  output$top_funds_insight <- renderUI({
    leader <- top_funds() |> slice_tail(n = 1)
    div(
      class = "insight",
      tags$b("Decision insight: "),
      sprintf(
        "%s has the largest latest-period AUM in the selected segment at %s. This is a scale indicator, not a measure of investment performance.",
        leader$fund_name,
        dollar(leader$total_assets_aud_m, accuracy = 1, suffix = "m")
      )
    )
  })

  output$growth_plot <- renderPlot({
    plot_data <- selected_history() |>
      group_by(period) |>
      summarise(total_assets_aud_m = sum(total_assets_aud_m, na.rm = TRUE), .groups = "drop")

    validate(need(nrow(plot_data) > 1, "Insufficient history is available for this fund type."))

    ggplot(plot_data, aes(period, total_assets_aud_m)) +
      geom_area(fill = alpha(accent_teal, 0.18)) +
      geom_line(colour = brand_blue, linewidth = 1.15) +
      geom_point(colour = accent_teal, size = 2.2) +
      scale_y_continuous(labels = label_dollar(suffix = "m")) +
      scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
      labs(
        title = paste(input$fund_type, "segment asset history"),
        subtitle = "Quarterly sum of reported product assets",
        x = NULL,
        y = "Assets under management (AUD millions)"
      ) +
      chart_theme
  })

  output$growth_insight <- renderUI({
    series <- selected_history() |>
      group_by(period) |>
      summarise(total_assets_aud_m = sum(total_assets_aud_m, na.rm = TRUE), .groups = "drop") |>
      arrange(period)
    change <- last(series$total_assets_aud_m) / first(series$total_assets_aud_m) - 1
    div(
      class = "insight",
      tags$b("Decision insight: "),
      sprintf(
        "Reported segment assets changed by %s between %s and %s. Product launches, closures and reporting coverage can also affect this series.",
        percent(change, accuracy = 0.1),
        format(first(series$period), "%b %Y"),
        format(last(series$period), "%b %Y")
      )
    )
  })

  output$allocation_plot <- renderPlot({
    plot_data <- allocation_data()
    validate(need(nrow(plot_data) > 0, "No benchmark allocation data is available for this fund type."))

    ggplot(plot_data, aes(fund_name, allocation_pct, fill = asset_class)) +
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
      chart_theme
  })

  output$allocation_insight <- renderUI({
    plot_data <- allocation_data()
    if (nrow(plot_data) == 0) return(NULL)
    dominant <- plot_data |>
      group_by(asset_class) |>
      summarise(mean_allocation = mean(allocation_pct), .groups = "drop") |>
      slice_max(mean_allocation, n = 1, with_ties = FALSE)
    div(
      class = "insight",
      tags$b("Decision insight: "),
      sprintf(
        "%s is the largest of the four selected benchmark classes on average (%s). Compare these targets alongside risk level and the fund's full allocation mix.",
        dominant$asset_class,
        percent(dominant$mean_allocation / 100, accuracy = 0.1)
      )
    )
  })

  output$cost_return_plot <- renderPlot({
    plot_data <- latest_snapshot() |>
      filter(!is.na(statement_fee_aud), !is.na(return_target_above_cpi_pct))
    validate(need(nrow(plot_data) > 2, "Insufficient fee and return-target data is available."))

    median_fee <- median(plot_data$statement_fee_aud)
    median_target <- median(plot_data$return_target_above_cpi_pct)

    ggplot(plot_data, aes(statement_fee_aud, return_target_above_cpi_pct, colour = risk_level_label)) +
      geom_vline(xintercept = median_fee, linetype = "dashed", colour = "#A7B0BE") +
      geom_hline(yintercept = median_target, linetype = "dashed", colour = "#A7B0BE") +
      geom_point(size = 3.6, alpha = 0.82) +
      scale_x_continuous(labels = label_dollar()) +
      scale_y_continuous(labels = label_percent(scale = 1)) +
      labs(
        title = "Fees versus long-term return targets",
        subtitle = "Each point is a MySuper product; dashed lines show selected-segment medians",
        x = "Statement of fees and other costs (AUD)",
        y = "Annualised return target above CPI",
        colour = "Risk label"
      ) +
      chart_theme
  })

  output$cost_return_insight <- renderUI({
    plot_data <- latest_snapshot() |>
      filter(!is.na(statement_fee_aud), !is.na(return_target_above_cpi_pct))
    div(
      class = "insight",
      tags$b("Decision insight: "),
      sprintf(
        "The selected segment has a median disclosed fee of %s and a median long-term target of %s above CPI. Targets are not realised returns and should not be treated as forecasts.",
        dollar(median(plot_data$statement_fee_aud), accuracy = 1),
        percent(median(plot_data$return_target_above_cpi_pct) / 100, accuracy = 0.1)
      )
    )
  })

  output$download_data <- downloadHandler(
    filename = function() {
      paste0("mysuper-", tolower(gsub(" ", "-", input$fund_type)), "-data.csv")
    },
    content = function(file) {
      write_csv(selected_history(), file, na = "")
    }
  )
}

shinyApp(ui = ui, server = server)
