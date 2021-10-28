.PHONY: appcast archive build check-version clean format \
				lint release rm-container server test zip

ARCHIVE_DIR=.archive
PRODUCT_DIR=.product
PROJECT_NAME=SparklyExample
SCRIPT_DIR=scripts
SERVER_DIR=.dev/server
SERVER_LOG=$(SERVER_DIR)/logs/server.log
SERVER_PID=$(SERVER_DIR)/logs/save_pid.txt
INFO_PLIST=$(PROJECT_NAME)/$(PROJECT_NAME)/Info.plist

appcast:
	generate_appcast ./Product

archive: clean build
	xcodebuild archive \
	    -workspace Sparkly.xcworkspace \
	    -scheme $(PROJECT_NAME) \
	    -archivePath $(ARCHIVE_DIR)/$(PROJECT_NAME).xcarchive
	
	xcodebuild \
	    -exportArchive \
	    -archivePath $(ARCHIVE_DIR)/$(PROJECT_NAME).xcarchive \
	    -exportPath $(PRODUCT_DIR)/ \
	    -exportOptionsPlist exportOptions.plist

build:
	xcodebuild \
	    -workspace Sparkly.xcworkspace \
	    -scheme $(PROJECT_NAME) \
	    -configuration Release \

clean-build:
	xcodebuild clean \
	    -project $(PROJECT_NAME)/$(PROJECT_NAME).xcodeproj \
	    -configuration Release \
	    -alltargets

	@make build

clean:
	rm -rf $(ARCHIVE_DIR)/*.xcarchive
	rm -rf $(PRODUCT_DIR)/*.zip
	rm -rf $(PRODUCT_DIR)/*.app
	rm -rf $(PRODUCT_DIR)/appcast

format:
	swift-format format -ir --configuration .swift-format.json .

kill-local-server:
	kill -9 `cat $(SERVER_PID)`
	rm $(SERVER_PID)
	rm $(SERVER_LOG) 

lint:
	swift-format lint -r --configuration .swift-format.json .

local-server:
	nohup http-server Product -S -C $(SERVER_DIR)/cert.pem -K $(SERVER_DIR)/key.pem > $(SERVER_LOG) & echo $$! > $(SERVER_PID)

local-test: set-local-url kill-http-server
	@make local-server
	@make test
	@make kill-local-server
	@make set-ci-url

release: archive zip appcast

rm-container:
	rm -rf /Users/tillhainbach/Library/Containers/de.hainbach.SparklyExample

test:
	xcodebuild test \
		-workspace Sparkly.xcworkspace \
		-scheme All \
		-destination 'platform=macOS,arch=x86_64'

ci-test:
	xcodebuild test \
		-workspace Sparkly.xcworkspace \
		-scheme All \
		-skip-testing "SparklyExampleTests/UpdateViewModelTests/testUserInitiatedUpdateCheck"

set-local-url:
	@make set-url URL=https://127.0.0.1:8080/appcast.xml

set-ci-url:
	@make set-url URL=https://tillhainbach.github.io/Sparkly/appcast.xml

set-url:
	/usr/libexec/PlistBuddy -c "Set :SUFeedURL $(URL)" $(INFO_PLIST)

show-running-servers:
	ps -ef | grep -v  "grep" | grep "http-server"

kill-http-server:
	ps -ef | grep -v  "grep" | grep "http-server" | while read -r; do kill -9 "${REPLY:4:5}"; done

zip:
	zsh scripts/zip-archive.sh $(PROJECT_NAME)
