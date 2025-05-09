required_packages <- c(
  "DT",
  "readr",
  "dplyr",
  "magrittr",
  "stringr",
  "glue"
)
new_packages <- required_packages[!(required_packages %in% installed.packages()[,"Package"])]
if (length(new_packages)) install.packages(new_packages)
