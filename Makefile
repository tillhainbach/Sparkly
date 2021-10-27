.PHONY: appcast archive build check-version clean format \
				lint release rm-container server test zip

PROJECT_NAME=SparklyExample
SCRIPT_DIR=scripts

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
	xcodebuild clean \
	    -project $(PROJECT_NAME)/$(PROJECT_NAME).xcodeproj \
	    -configuration Release \
	    -alltargets
clean:
	rm -rf Archive/*
	rm -rf Product/*

format:
	swift-format format -ir --configuration .swift-format.json .

lint:
	swift-format lint -r --configuration .swift-format.json .

release: archive zip appcast

rm-container:
	rm -rf /Users/tillhainbach/Library/Containers/de.hainbach.SparklyExample

server:
	nohup npx http-server Product -S -C dev/server/cert.pem Product -K dev/server/key.pem > server.log 2>&1 & echo $$! > save_pid.txt

test: 
	@make server
	xcodebuild test \
		-workspace Sparkly.xcworkspace \
		-scheme SparklyExample
	@make kill-server

kill-server:
	kill -9 `cat save_pid.txt`
	rm save_pid.txt
	rm server.log

zip:
	zsh scripts/zip-archive.sh $(PROJECT_NAME)