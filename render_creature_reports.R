library(readr)
library(rmarkdown)

creatures <- read_csv("creatures.csv", show_col_types = FALSE)
creature_names <- unique(creatures$creatureName)

output_dir <- "html/creatures"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

total <- length(creature_names)
cat(sprintf("Rendering %d creature reports...\n", total))

for (i in seq_along(creature_names)) {
  name <- creature_names[i]
  cat(sprintf("[%d/%d] %s\n", i, total, name))

  tryCatch({
    render(
      "creature_tmpl.Rmd",
      params = list(creature_name = name),
      output_file = paste0(name, ".html"),
      output_dir = output_dir,
      quiet = TRUE
    )
  }, error = function(e) {
    cat(sprintf("  ERROR: %s\n", e$message))
  })
}

cat("Done.\n")
