# Makefile

# Default target: run bundle
bundle:
	@bundle

# Target to serve the Jekyll site
serve:
	@bundle exec jekyll serve

# Optional: a clean target for cleaning up build artifacts
clean:
	@rm -rf _site

# Specify default target if none is provided
.DEFAULT_GOAL := bundle
