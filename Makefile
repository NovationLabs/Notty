APP_NAME = Notty
BUNDLE = $(APP_NAME).app
BINARY = $(BUNDLE)/Contents/MacOS/$(APP_NAME)

.PHONY: all run clean re kill dmg

all: $(BINARY)

$(BINARY): $(APP_NAME).swift | $(BUNDLE)/Contents/MacOS
	swiftc $< -o $@ -framework Cocoa

$(BUNDLE)/Contents/MacOS:
	mkdir -p $@

# Kill old instance (if any) before running a new one
kill:
	@pkill -f "$(BUNDLE)" 2>/dev/null || true
	@sleep 0.5

run: kill all
	open $(BUNDLE)

clean:
	rm -f $(BINARY)
	rm -f /usr/local/bin/nt
	rm -f /usr/local/bin/notty

# Install "nt" and "notty" commands globally
install: all
	ln -sf $(realpath $(BINARY)) /usr/local/bin/nt
	ln -sf $(realpath $(BINARY)) /usr/local/bin/notty
	@echo "Commands 'nt' and 'notty' installed. Type 'nt help' for options."

# Create .dmg installer using DMGMaker (custom Notty background)
dmg: all
	@rm -f $(APP_NAME).dmg
	cd DMGMaker && swift run "DMG Maker" --app "../$(BUNDLE)" --name "$(APP_NAME)"
	@echo "Created $(APP_NAME).dmg"

re: kill clean all
