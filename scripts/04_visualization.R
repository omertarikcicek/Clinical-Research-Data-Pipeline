# ---------------------------------------------------------
# Visualization Pipeline
# Author: Omer Tarik Cicek
# Purpose: Publication-ready cohort visualizations
# ---------------------------------------------------------

library(dplyr)
library(readr)
library(ggplot2)
library(tidyr)

# ---------------------------
# 1. Load Clean Data
# ---------------------------

data <- read_csv("data/cleaned/cleaned_dbs_cohort.csv",
                 show_col_types = FALSE)

# ---------------------------
# 2. Minimal Publication Theme
# ---------------------------

theme_publication <- function() {
  theme_minimal(base_size = 14) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(linewidth = 0.2),
      axis.title = element_text(face = "bold"),
      plot.title = element_text(face = "bold", hjust = 0.5),
      legend.position = "top"
    )
}

# ---------------------------
# 3. Paired Baseline vs 12m Plot
# ---------------------------

paired_plot <- ggplot(data, aes(x = 1)) +
  geom_point(aes(y = baseline_updrs), alpha = 0.4) +
  geom_point(aes(y = month_12_updrs), alpha = 0.4) +
  geom_segment(aes(x = 1,
                   xend = 1,
                   y = baseline_updrs,
                   yend = month_12_updrs),
               alpha = 0.2) +
  labs(
    x = "",
    y = "UPDRS Score",
    title = "Baseline vs 12-Month UPDRS Improvement"
  ) +
  theme_publication() +
  theme(axis.text.x = element_blank())

# ---------------------------
# 4. Longitudinal Trajectory Plot
# ---------------------------

long_data <- data %>%
  select(patient_id,
         baseline_updrs,
         month_6_updrs,
         month_12_updrs) %>%
  pivot_longer(
    cols = -patient_id,
    names_to = "timepoint",
    values_to = "updrs_score"
  )

trajectory_plot <- ggplot(long_data,
                          aes(x = timepoint,
                              y = updrs_score,
                              group = patient_id)) +
  geom_line(alpha = 0.15) +
  stat_summary(aes(group = 1),
               fun = mean,
               geom = "line",
               linewidth = 1.2) +
  stat_summary(aes(group = 1),
               fun.data = mean_se,
               geom = "errorbar",
               width = 0.1) +
  labs(
    x = "Timepoint",
    y = "UPDRS Score",
    title = "Longitudinal UPDRS Trajectory"
  ) +
  theme_publication()

# ---------------------------
# 5. Save Outputs
# ---------------------------

dir.create("outputs", showWarnings = FALSE)

ggsave("outputs/paired_updrs_plot.png",
       paired_plot,
       width = 7,
       height = 5,
       dpi = 300)

ggsave("outputs/trajectory_plot.png",
       trajectory_plot,
       width = 7,
       height = 5,
       dpi = 300)

cat("Visualization pipeline completed successfully.\n")
