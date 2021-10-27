.PHONY: appcast archive build check-version clean format \
				lint release rm-container server test zip

PROJECT_NAME=SparklyExample
SCRIPT_DIR=scripts
SERVER_DIR=dev/server
SERVER_LOG=$(SERVER_DIR)/logs/server.log
SERVER_PID=$(SERVER_DIR)/logs/save_pid.txt
INFO_PLIST=$(PROJECT_NAME)/$(PROJECT_NAME)/Info.plist

appcast:
	generate_appcast ./Product

archive: clean build
	xcodebuild archive \
	    -workspace Sparkly.xcworkspace \
	    -scheme $(PROJECT_NAME) \
	    -archivePath Archive/$(PROJECT_NAME).xcarchive
	xcodebuild \
	    -exportArchive \
	    -archivePath Archive/$(PROJECT_NAME).xcarchive \
	    -exportPath Product/ \
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
	rm -rf Archive/*
	rm -rf Product/*.zip
	rm -rf Product/*.app
	rm -rf Product/appcast

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

local-test: set-local-url
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
		-scheme SparklyExample

ci-test:
	xcodebuild test \
		-workspace Sparkly.xcworkspace \
		-scheme SparklyExample
		-skip-testing:SparklyExampleTests/UpdateViewModelTests/testUserInitiatedUpdateCheck

set-local-url:
	@make set-url URL=https://127.0.0.1:8080/appcast.xml

set-ci-url:
	@make set-url URL=https://tillhainbach.github.io/Sparkly/appcast.xml

set-url:
	/usr/libexec/PlistBuddy -c "Set :SUFeedURL $(URL)" $(INFO_PLIST)

zip:
	zsh scripts/zip-archive.sh $(PROJECT_NAME)
