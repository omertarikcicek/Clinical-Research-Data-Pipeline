# ---------------------------------------------------------
# Mock DBS Clinical Cohort Generator
# Author: Omer Tarik Cicek
# Purpose: Generate realistic neuromodulation cohort dataset
# ---------------------------------------------------------

set.seed(2026)

n <- 60

# Patient ID
patient_id <- sprintf("P%03d", 1:n)

# Demographics
age <- round(rnorm(n, mean = 63, sd = 7))
age[age < 45] <- sample(45:50, sum(age < 45), replace = TRUE)
age[age > 80] <- sample(75:80, sum(age > 80), replace = TRUE)

sex <- sample(c("Male", "Female"), n, replace = TRUE, prob = c(0.6, 0.4))

disease_duration_years <- round(rnorm(n, mean = 9, sd = 3))
disease_duration_years[disease_duration_years < 3] <- sample(3:5, sum(disease_duration_years < 3), replace = TRUE)

# Surgery date
surgery_date <- sample(seq(as.Date("2022-01-01"),
                           as.Date("2024-06-01"),
                           by = "day"), n)

# Stimulation target
stimulation_target <- sample(c("STN", "GPi"),
                             n,
                             replace = TRUE,
                             prob = c(0.7, 0.3))

# Baseline UPDRS
baseline_updrs <- round(rnorm(n, mean = 48, sd = 8))

# Improvement pattern
improvement_factor <- ifelse(stimulation_target == "STN",
                             rnorm(n, mean = 18, sd = 4),
                             rnorm(n, mean = 14, sd = 4))

month_6_updrs <- baseline_updrs - round(improvement_factor * 0.8)
month_12_updrs <- baseline_updrs - round(improvement_factor)

# Ensure scores are realistic
month_6_updrs[month_6_updrs < 5] <- sample(5:10, sum(month_6_updrs < 5), replace = TRUE)
month_12_updrs[month_12_updrs < 5] <- sample(5:10, sum(month_12_updrs < 5), replace = TRUE)

# Complication probability (slightly higher with age)
complication_prob <- plogis(-5 + 0.05 * age + 0.02 * baseline_updrs)
complication <- rbinom(n, 1, complication_prob)

# Build dataframe
dbs_cohort <- data.frame(
  patient_id,
  age,
  sex,
  disease_duration_years,
  surgery_date,
  stimulation_target,
  baseline_updrs,
  month_6_updrs,
  month_12_updrs,
  complication
)

# Introduce minor missingness (realistic)
dbs_cohort$month_6_updrs[sample(1:n, 3)] <- NA
dbs_cohort$disease_duration_years[sample(1:n, 2)] <- NA

# Save
dir.create("data", showWarnings = FALSE)
write.csv(dbs_cohort,
          "data/mock_dbs_cohort.csv",
          row.names = FALSE)

cat("Mock dataset generated successfully.\n")
