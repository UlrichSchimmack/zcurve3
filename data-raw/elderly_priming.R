# Build data/elderly_priming.rda from the source spreadsheet.
# Run from the package root:  source("data-raw/elderly_priming.R")
#
# The spreadsheet holds one row per elderly-priming ("slow walking" and related
# behavioural outcomes) test, with the reported standardized effect size and its
# standard error. We keep only the complete cases and the columns z-curve needs.

library(readxl)

# data.frame() (check.names = TRUE) sanitizes the spreadsheet headers, e.g.
# "yi (d)" -> "yi..d." -- matching how the column is referenced below.
raw <- data.frame(read_xlsx("data-raw/elderly_priming.xlsx"))

keep <- !is.na(raw$SE) & !is.na(raw[["yi..d."]])

elderly_priming <- data.frame(
  study = trimws(raw$Article[keep]),          # study label (article + experiment)
  d     = round(raw[["yi..d."]][keep], 3),     # observed Cohen's d (signed)
  se    = round(raw$SE[keep], 3),              # standard error of d
  stringsAsFactors = FALSE
)
elderly_priming$z   <- round(elderly_priming$d / elderly_priming$se, 3)
elderly_priming$sig <- abs(elderly_priming$z) > qnorm(1 - 0.05 / 2)

if (!dir.exists("data")) dir.create("data")
# version = 2 keeps the .rda readable by older R (matches zcurve) and avoids a
# Depends: R (>= 3.5.0) requirement.
save(elderly_priming, file = "data/elderly_priming.rda", version = 2)
