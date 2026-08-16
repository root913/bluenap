# --- CONFIGURATION ---
APP_NAME = BlueNap
SCHEME = BlueNap
CONFIGURATION = Release
BUILD_DIR = ./build

# Local overrides (e.g. DEVELOPMENT_TEAM) go in Makefile.local (git-ignored)
-include Makefile.local

# Installation paths
INSTALL_DIR = /Applications
APP_BUNDLE = $(BUILD_DIR)/Build/Products/$(CONFIGURATION)/$(APP_NAME).app

# Extra signing flags when a development team is configured locally
SIGNING_FLAGS = $(if $(DEVELOPMENT_TEAM),DEVELOPMENT_TEAM=$(DEVELOPMENT_TEAM) CODE_SIGN_IDENTITY="$(CODE_SIGN_IDENTITY)")

.PHONY: all build test install clean

# Default target
all: build install

# Build the application
build:
	@echo "🔨 Building $(APP_NAME)..."
	xcodebuild -project $(APP_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(BUILD_DIR) \
		$(SIGNING_FLAGS) \
		build

# Run unit tests
test:
	@echo "🧪 Testing $(APP_NAME)..."
	xcodebuild -project $(APP_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration Debug \
		-destination 'platform=macOS' \
		-derivedDataPath $(BUILD_DIR) \
		$(SIGNING_FLAGS) \
		test

# Install to /Applications
install:
	@echo "🚀 Installing $(APP_NAME) to $(INSTALL_DIR)..."
	@mkdir -p $(INSTALL_DIR)
	@rm -rf "$(INSTALL_DIR)/$(APP_NAME).app"
	@cp -R "$(APP_BUNDLE)" "$(INSTALL_DIR)/"
	@echo "✅ Installation complete!"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build files..."
	@rm -rf $(BUILD_DIR)
	@echo "✨ Cleaned!"
