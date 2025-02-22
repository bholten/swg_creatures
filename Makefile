LUA_SCRIPT = build_creatures_csv.lua
DATA_CSV = data.csv
RMD_FILE = index.Rmd
HTML_FILE = index.html

all: $(HTML_FILE)

$(DATA_CSV): $(LUA_SCRIPT)
	@echo "Running Lua script to generate CSV..."
	lua $(LUA_SCRIPT)

$(HTML_FILE): $(DATA_CSV) $(RMD_FILE)
	@echo "Rendering RMarkdown to HTML..."
	@Rscript -e 'rmarkdown::render("$(RMD_FILE)")'

clean:
	@echo "Cleaning up..."
	@rm -f $(DATA_CSV) $(HTML_FILE)
