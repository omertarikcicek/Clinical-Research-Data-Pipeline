# ---------------------------------------------------------
# Clinical Data Cleaning Pipeline
# Author: Omer Tarik Cicek
# Purpose: Validate, clean, and preprocess DBS cohort data
# ---------------------------------------------------------

library(tidyr)
library(dplyr)
library(lubridate)
library(readr)

# ---------------------------
# 1. Load Raw Data
# ---------------------------

raw_data <- read_csv("data/mock_dbs_cohort.csv",
                     show_col_types = FALSE)

# ---------------------------
# 2. Enforce Data Types
# ---------------------------

clean_data <- raw_data %>%
  mutate(
    patient_id = as.character(patient_id),
    sex = factor(sex),
    stimulation_target = factor(stimulation_target),
    surgery_date = as.Date(surgery_date),
    complication = as.integer(complication)
  )

# ---------------------------
# 3. Missing Data Summary
# ---------------------------

missing_summary <- clean_data %>%
  summarise(across(everything(),
                   ~ sum(is.na(.)))) %>%
  pivot_longer(cols = everything(),
               names_to = "variable",
               values_to = "missing_count")

print("Missing Data Summary:")
print(missing_summary)

# ---------------------------
# 4. Clinical Range Validation
# ---------------------------

validate_ranges <- function(df) {
  df %>%
    mutate(
      baseline_flag = ifelse(baseline_updrs < 0 | baseline_updrs > 100, 1, 0),
      m6_flag = ifelse(month_6_updrs < 0 | month_6_updrs > 100, 1, 0),
      m12_flag = ifelse(month_12_updrs < 0 | month_12_updrs > 100, 1, 0)
    )
}

clean_data <- validate_ranges(clean_data)

# ---------------------------
# 5. Outlier Detection Function
# ---------------------------

flag_outliers <- function(x) {
  q1 <- quantile(x, 0.25, na.rm = TRUE)
  q3 <- quantile(x, 0.75, na.rm = TRUE)
  iqr <- q3 - q1
  lower <- q1 - 1.5 * iqr
  upper <- q3 + 1.5 * iqr
  ifelse(x < lower | x > upper, 1, 0)
}

clean_data <- clean_data %>%
  mutate(
    baseline_outlier = flag_outliers(baseline_updrs),
    m12_outlier = flag_outliers(month_12_updrs)
  )

# ---------------------------
# 6. Derived Variables
# ---------------------------

clean_data <- clean_data %>%
  mutate(
    updrs_improvement_12m = baseline_updrs - month_12_updrs,
    responder_30pct = ifelse(updrs_improvement_12m /
                               baseline_updrs >= 0.30, 1, 0)
  )

# ---------------------------
# 7. Remove Impossible Rows (Optional Strict Mode)
# ---------------------------

clean_data <- clean_data %>%
  filter(baseline_flag == 0,
         m6_flag == 0,
         m12_flag == 0)

# ---------------------------
# 8. Save Cleaned Dataset
# ---------------------------

dir.create("data/cleaned", showWarnings = FALSE)

write_csv(clean_data,
          "data/cleaned/cleaned_dbs_cohort.csv")

cat("Data cleaning completed successfully.\n")
