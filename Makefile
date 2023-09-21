.PHONY: build-app build-dmg

build-app:
	xcodebuild -project "Audio Device Blocker.xcodeproj"

build-dmg:
	rm AudioDeviceBlocker.dmg
	rm -rf ./dmg-content
	mkdir ./dmg-content
	cp -r "./build/Release/Audio Device Blocker.app" ./dmg-content
	ln -s /Applications ./dmg-content/
	./create-dmg/create-dmg AudioDeviceBlocker.dmg "./dmg-content"
