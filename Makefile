.PHONNY: lint

lint: 
	swift-format lint -r --configuration .swift-format.json .

format:
	swift-format format -ir --configuration .swift-format.json .
