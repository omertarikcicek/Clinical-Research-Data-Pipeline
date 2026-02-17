# ---------------------------------------------------------
# Statistical Analysis Pipeline
# Author: Omer Tarik Cicek
# Purpose: Cohort statistical testing and predictive modeling
# ---------------------------------------------------------

library(dplyr)
library(readr)
library(ggplot2)
library(pROC)

# ---------------------------
# 1. Load Clean Data
# ---------------------------

data <- read_csv("data/cleaned/cleaned_dbs_cohort.csv",
                 show_col_types = FALSE)

# ---------------------------
# 2. Normality Testing (Improvement)
# ---------------------------

shapiro_result <- shapiro.test(data$updrs_improvement_12m)

print("Shapiro-Wilk Normality Test:")
print(shapiro_result)

# ---------------------------
# 3. Paired Baseline vs 12m Comparison
# ---------------------------

if (shapiro_result$p.value > 0.05) {
  
  test_result <- t.test(data$baseline_updrs,
                        data$month_12_updrs,
                        paired = TRUE)
  
  test_used <- "Paired t-test"
  
} else {
  
  test_result <- wilcox.test(data$baseline_updrs,
                             data$month_12_updrs,
                             paired = TRUE)
  
  test_used <- "Wilcoxon signed-rank test"
}

cat("\nTest Used:", test_used, "\n")
print(test_result)

# ---------------------------
# 4. Logistic Regression
# Outcome: Complication
# ---------------------------

model <- glm(complication ~ age +
               baseline_updrs +
               stimulation_target,
             data = data,
             family = binomial())

summary_model <- summary(model)

print("Logistic Regression Summary:")
print(summary_model)

# ---------------------------
# 5. Odds Ratios with CI
# ---------------------------

odds_ratios <- exp(cbind(
  OR = coef(model),
  confint(model)
))

print("Odds Ratios with 95% CI:")
print(odds_ratios)

# ---------------------------
# 6. ROC Curve
# ---------------------------

predicted_probs <- predict(model,
                           type = "response")

roc_curve <- roc(data$complication,
                 predicted_probs)

auc_value <- auc(roc_curve)

cat("\nModel AUC:", auc_value, "\n")

# Save ROC plot
dir.create("outputs", showWarnings = FALSE)

png("outputs/roc_curve.png", width = 800, height = 600)
plot(roc_curve,
     main = "ROC Curve - Complication Prediction")
dev.off()

cat("\nStatistical analysis completed successfully.\n")
