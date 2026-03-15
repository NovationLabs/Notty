APP_NAME = Notty
BUNDLE = $(APP_NAME).app
BINARY = $(BUNDLE)/Contents/MacOS/$(APP_NAME)

.PHONY: all run clean re kill

all: $(BINARY)

$(BINARY): $(APP_NAME).swift | $(BUNDLE)/Contents/MacOS
	swiftc $< -o $@ -framework Cocoa

$(BUNDLE)/Contents/MacOS:
	mkdir -p $@

# Tuer l'ancien process avant de relancer
kill:
	@pkill -f "$(BUNDLE)" 2>/dev/null || true
	@sleep 0.5

run: kill all
	open $(BUNDLE)

clean:
	rm -f $(BINARY)

re: kill clean all
