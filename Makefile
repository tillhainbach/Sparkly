.PHONY: appcast archive build check-version clean format \
				lint release rm-container server test test-feed-url zip 

ARCHIVE_DIR=.archive
PRODUCT_DIR=.product
PROJECT_NAME=SparklyExample
SCRIPT_DIR=scripts
SERVER_DIR=.dev/server
SERVER_LOG=$(SERVER_DIR)/logs/server.log
SERVER_PID=$(SERVER_DIR)/logs/save_pid.txt
INFO_PLIST=$(PROJECT_NAME)/$(PROJECT_NAME)/Info.plist
LOCAL_URL=https://127.0.0.1:8080/appcast.xml
CI_URL=https://tillhainbach.github.io/Sparkly/appcast.xml
VERSION="0.0.2"

appcast:
	generate_appcast $(PRODUCT_DIR)

archive: clean build-release
	xcodebuild archive \
	    -workspace Sparkly.xcworkspace \
	    -scheme $(PROJECT_NAME) \
			-destination 'generic/platform=macOS,name=Any Mac' \
	    -archivePath $(ARCHIVE_DIR)/$(PROJECT_NAME).xcarchive
	
	xcodebuild \
	    -exportArchive \
	    -archivePath $(ARCHIVE_DIR)/$(PROJECT_NAME).xcarchive \
	    -exportPath $(PRODUCT_DIR)/ \
	    -exportOptionsPlist exportOptions.plist

build:
	xcodebuild clean build \
	    -workspace Sparkly.xcworkspace \
	    -scheme $(PROJECT_NAME) \
	    -configuration $(BUILD_CONFIG) \
			-destination 'generic/platform=macOS,name=Any Mac'

build-dev:
	@make build BUILD_CONFIG=Debug

build-release:
	@make build BUILD_CONFIG=Release

ci-test:
	@make test SKIP_TESTS="-skip-testing SparklyExampleTests/UpdateViewModelTests/testUserInitiatedUpdateCheck"

clean:
	rm -rf $(ARCHIVE_DIR)/*
	rm -rf $(PRODUCT_DIR)/*

format:
	swift-format format -ir Sources SparklyExample --configuration .swift-format.json .

kill-all-servers:
	ps -ef | grep -v  "grep" | grep "http-server" | \
		while read -r; do if [[ ! -z "$${REPLY}" ]]; then kill -9 "$${REPLY:6:5}"; fi; done

kill-local-server:
	kill -9 `cat $(SERVER_PID)`
	rm $(SERVER_PID)
	rm $(SERVER_LOG) 

lint:
	swift-format lint -r Sources SparklyExample --configuration .swift-format.json .

local-server:
	nohup http-server $(PRODUCT_DIR) -S -C $(SERVER_DIR)/cert.pem -K $(SERVER_DIR)/key.pem > $(SERVER_LOG) & echo $$! > $(SERVER_PID)

local-test: set-local-url kill-all-servers
	@make local-server
	@make test
	@make kill-local-server
	@make set-ci-url

release: set-release-version archive zip appcast restore-version

restore-version:
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion \$$(CURRENT_PROJECT_VERSION)" $(INFO_PLIST)
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString \$$(MARKETING_VERSION)" $(INFO_PLIST)

rm-container:
	rm -rf ~/Library/Containers/de.hainbach.SparklyExample

set-release-version:
	/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $(VERSION)" $(INFO_PLIST)
	/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $(VERSION)" $(INFO_PLIST)

set-ci-url:
	@make set-url URL=$(CI_URL)

set-local-url:
	@make set-url URL=$(LOCAL_URL)

set-url:
	/usr/libexec/PlistBuddy -c "Set :SUFeedURL $(URL)" $(INFO_PLIST)

show-running-servers:
	ps -ef | grep -v  "grep" | grep "http-server"

test: build-dev
	xcodebuild test \
		-workspace Sparkly.xcworkspace \
		-scheme All \
		-destination 'platform=macOS,arch=x86_64' \
		$(SKIP_TESTS)

test-feed-url:
ifneq ($(shell /usr/libexec/PlistBuddy -c "Print :SUFeedURL" $(INFO_PLIST)),$(CI_URL))
	@echo "❌ SUFeedURL must be set to $(CI_URL) for ci!\nrun 'make set-ci-url' before pushing!"
	@exit -1
else
	@echo "✅ SUFeedURL"
endif

update-gh-release:
	-gh release delete $(VERSION)
	-git tag -d $(VERSION)
	-git push --delete origin $(VERSION)
	-gh release create $(VERSION) $(PRODUCT_DIR)/SparklyExample.zip -n "This release of the test app is only for ci. Do not use!" -t "CI-Test Release"

zip:
	zsh scripts/zip-archive.sh $(PROJECT_NAME) $(PRODUCT_DIR)
