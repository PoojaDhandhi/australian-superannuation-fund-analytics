# Deployment guide

## Run locally

From the project root:

```r
install.packages(c("shiny", "ggplot2", "dplyr", "tidyr", "readr", "scales", "bslib"))
shiny::runApp()
```

## Deploy to shinyapps.io

```r
install.packages("rsconnect")
rsconnect::setAccountInfo(
  name = "YOUR_ACCOUNT_NAME",
  token = "YOUR_TOKEN",
  secret = "YOUR_SECRET"
)
rsconnect::deployApp(appDir = ".")
```

Do not commit the token or secret. Configure them locally through RStudio or environment variables.

After deployment, replace the live-demo URL in the root README if the application address changes.

## Publish to GitHub

GitHub access is not required to prepare this project. To publish it yourself:

```bash
git init
git add .
git commit -m "Build Australian superannuation analytics portfolio project"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/australian-superannuation-fund-analytics.git
git push -u origin main
```

Before pushing, confirm that the live app opens and that the relative links and images render in GitHub's README preview.
