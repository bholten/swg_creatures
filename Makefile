LUA_SCRIPT = build_creatures_csv.lua
OUTPUT_DIR = html
DATA_CSV = data.csv
RMD_FILES := $(wildcard *.Rmd)
HTML_FILES := $(RMD_FILES:.Rmd=.html)

all: $(HTML_FILES)

$(DATA_CSV):
	@echo "Running Lua script to generate CSV..."
	lua $(LUA_SCRIPT)

%.html: %.Rmd $(DATA_CSV) $(RMD_FILES)
	@echo "Rendering RMarkdown to HTML..."
	@mkdir -p $(OUTPUT_DIR)
	@Rscript -e "rmarkdown::render('$<', output_format = 'html_document', output_dir = '$(OUTPUT_DIR)')"

clean:
	@echo "Cleaning up..."
	@rm -rf $(DATA_CSV) $(OUTPUT_DIR)
