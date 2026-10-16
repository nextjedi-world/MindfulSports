# Repo contract (nextjedi/platform docs/CONTRACTS.md): setup, dev, verify, e2e.
# `make verify` is what CI and the Claude Stop hook run. It must stay green.
GRADLEW ?= sh ./gradlew
GRADLE_FLAGS ?= --console=plain
APP_ID := com.ashutosh.mindfultennis

.DEFAULT_GOAL := help
.PHONY: help setup dev verify lint test build e2e format baseline ios-framework clean

help: ## List targets
	@grep -E '^[a-zA-Z_-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-14s %s\n", $$1, $$2}'

setup: ## Install git hooks, create local config from the examples, warm Gradle
	@if command -v lefthook >/dev/null 2>&1; then lefthook install; else echo "lefthook not installed: skipping git hooks (npm i -g lefthook / brew install lefthook)"; fi
	@test -f .env || cp .env.example .env
	@test -f local.properties || cp local.properties.example local.properties
	$(GRADLEW) $(GRADLE_FLAGS) help

dev: ## Build, install and launch the Android app on the connected device or emulator
	$(GRADLEW) $(GRADLE_FLAGS) :composeApp:installDebug
	adb shell am start -n $(APP_ID)/.MainActivity

verify: ## Lint + format check, commonMain typecheck, unit tests, Android lint and debug build
	$(GRADLEW) $(GRADLE_FLAGS) ktlintCheck detekt :shared:compileKotlinMetadata :shared:testDebugUnitTest :composeApp:testDebugUnitTest :composeApp:lintDebug :composeApp:assembleDebug

lint: ## ktlint + detekt + Android lint only
	$(GRADLEW) $(GRADLE_FLAGS) ktlintCheck detekt :composeApp:lintDebug

test: ## Unit tests only
	$(GRADLEW) $(GRADLE_FLAGS) :shared:testDebugUnitTest :composeApp:testDebugUnitTest

build: ## Debug APK only
	$(GRADLEW) $(GRADLE_FLAGS) :composeApp:assembleDebug

e2e: ## Instrumented tests on a connected device/emulator (skips when none is attached)
	@if adb get-state >/dev/null 2>&1; then $(GRADLEW) $(GRADLE_FLAGS) :composeApp:connectedDebugAndroidTest; else echo "e2e: no Android device or emulator attached, skipping"; fi

format: ## Auto-fix Kotlin formatting
	$(GRADLEW) $(GRADLE_FLAGS) ktlintFormat

baseline: ## Re-record the lint baselines (only after fixing old findings)
	$(GRADLEW) $(GRADLE_FLAGS) ktlintGenerateBaseline detektBaseline :composeApp:updateLintBaseline

ios-framework: ## (macOS) Link the shared framework for the iOS simulator
	$(GRADLEW) $(GRADLE_FLAGS) :shared:linkDebugFrameworkIosSimulatorArm64

clean: ## Remove build outputs
	$(GRADLEW) $(GRADLE_FLAGS) clean
