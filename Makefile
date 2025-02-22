LUA_SCRIPT = build_creatures_csv.lua
OUTPUT_DIR = html
DATA_CSV = data.csv
RMD_FILE = index.Rmd
HTML_FILE = $(OUTPUT_DIR)/index.html

all: $(HTML_FILE)

$(DATA_CSV): $(LUA_SCRIPT)
	@echo "Running Lua script to generate CSV..."
	lua $(LUA_SCRIPT)

$(HTML_FILE): $(DATA_CSV) $(RMD_FILE)
	@echo "Rendering RMarkdown to HTML..."
	@mkdir -p $(OUTPUT_DIR)
	@Rscript -e 'rmarkdown::render("$(RMD_FILE)", output_dir="$(OUTPUT_DIR)")'

clean:
	@echo "Cleaning up..."
	@rm -rf $(DATA_CSV) $(OUTPUT_DIR)
