LUA_SCRIPT = build_creatures_csv.lua
OUTPUT_DIR = html
CSV_FILES := $(wildcard *.csv)
RMD_FILES := $(filter-out creature_tmpl.Rmd planet_map_tmpl.Rmd,$(wildcard *.Rmd))
HTML_FILES := $(RMD_FILES:.Rmd=.html)

all: generate_csv $(HTML_FILES) creature_reports planet_maps

generate_csv:
	@echo "Running Lua script to generate CSV..."
	lua $(LUA_SCRIPT)

%.html: %.Rmd $(DATA_CSV) $(RMD_FILES)
	@echo "Rendering RMarkdown to HTML..."
	@mkdir -p $(OUTPUT_DIR)
	@Rscript -e "rmarkdown::render('$<', output_format = 'html_document', output_dir = '$(OUTPUT_DIR)')"

creature_reports:
	@echo "Rendering individual creature reports..."
	@Rscript render_creature_reports.R

planet_maps:
	@echo "Rendering planet spawn maps..."
	@mkdir -p $(OUTPUT_DIR)/maps
	@cp -r maps/* $(OUTPUT_DIR)/maps/
	@Rscript render_planet_maps.R

clean:
	@echo "Cleaning up..."
	@rm -rf $(DATA_CSV) $(OUTPUT_DIR)
