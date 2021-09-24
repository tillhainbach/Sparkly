.PHONY: check-version \
    build \
    archive \
    clean \
    zip \
		lint \
		server

PROJECT_NAME=SparklyExample
SCRIPT_DIR=scripts

rm-container:
	rm -rf /Users/tillhainbach/Library/Containers/de.hainbach.SparklyExample

clean:
	rm -rf Archive/*
	rm -rf Product/*

build:
	xcodebuild clean \
	    -project $(PROJECT_NAME)/$(PROJECT_NAME).xcodeproj \
	    -configuration Release \
	    -alltargets

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

zip:
	zsh scripts/zip-archive.sh $(PROJECT_NAME)

appcast:
	generate_appcast ./Product

release: archive zip appcast


server:
	http-server Product -S -C dev/server/cert.pem Product -K dev/server/key.pem

lint: 
	swift-format lint -r --configuration .swift-format.json .

format:
	swift-format format -ir --configuration .swift-format.json .

