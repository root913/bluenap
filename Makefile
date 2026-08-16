# --- CONFIGURATION ---
APP_NAME = BlueNap
SCHEME = BlueNap
CONFIGURATION = Release
BUILD_DIR = ./build

# Installation paths
INSTALL_DIR = /Applications
APP_BUNDLE = $(BUILD_DIR)/Build/Products/$(CONFIGURATION)/$(APP_NAME).app

.PHONY: all build install clean

# Default target
all: build install

# Build the application
build:
	@echo "🔨 Building $(APP_NAME)..."
	xcodebuild -project $(APP_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-derivedDataPath $(BUILD_DIR) \
		build

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
