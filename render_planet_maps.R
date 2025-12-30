library(rmarkdown)

# List of planets with map images
planets <- c(
  "corellia",
  "dantooine",
  "dathomir",
  "endor",
  "lok",
  "naboo",
  "rori",
  "talus",
  "tatooine",
  "yavin4"
)

output_dir <- "html/maps"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

cat(sprintf("Rendering %d planet maps...\n", length(planets)))

for (i in seq_along(planets)) {
  planet <- planets[i]
  cat(sprintf("[%d/%d] %s\n", i, length(planets), planet))

  tryCatch({
    render(
      "planet_map_tmpl.Rmd",
      params = list(planet_name = planet),
      output_file = paste0(planet, ".html"),
      output_dir = output_dir,
      quiet = TRUE
    )
  }, error = function(e) {
    cat(sprintf("  ERROR: %s\n", e$message))
  })
}

cat("Done.\n")
