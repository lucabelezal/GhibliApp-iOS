.PHONY: all setup generate lint format clean help

# Default target
all: generate

# Setup: Install dependencies
setup:
	@echo "📦 Installing dependencies..."
	@which xcodegen > /dev/null || (echo "Installing XcodeGen..." && brew install xcodegen)
	@which swiftgen > /dev/null || (echo "Installing SwiftGen..." && brew install swiftgen)
	@which swiftlint > /dev/null || (echo "Installing SwiftLint..." && brew install swiftlint)
	@which swiftformat > /dev/null || (echo "Installing SwiftFormat..." && brew install swiftformat)
	@echo "✅ Setup complete"

# Generate Xcode project and resources
generate:
	@echo "🔨 Generating Xcode project..."
	@xcodegen generate
	@echo "📝 Generating localized strings..."
	@swiftgen config run --config swiftgen.yml
	@echo "✅ Project ready"

# Run SwiftLint
lint:
	@echo "🔍 Running SwiftLint..."
	@swiftlint

# Run SwiftFormat
format:
	@echo "✨ Formatting code..."
	@swiftformat .

# Clean generated files
clean:
	@echo "🧹 Cleaning generated files..."
	@rm -rf GhibliApp.xcodeproj
	@rm -rf GhibliApp/Resources/Generated/*.swift
	@rm -rf build/
	@rm -rf DerivedData/
	@echo "✅ Clean complete"

# Help
help:
	@echo "GhibliApp - Available commands:"
	@echo ""
	@echo "  make setup     - Install all required dependencies"
	@echo "  make generate  - Generate Xcode project and resources (default)"
	@echo "  make lint      - Run SwiftLint"
	@echo "  make format    - Format code with SwiftFormat"
	@echo "  make clean     - Remove generated files"
	@echo "  make all       - Run generate (same as default)"
	@echo "  make help      - Show this help message"
