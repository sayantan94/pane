.PHONY: build install uninstall clean

build:
	swift build -c release --arch arm64 --arch x86_64

install: build
	mkdir -p Pane.app/Contents/MacOS
	cp .build/apple/Products/Release/Pane Pane.app/Contents/MacOS/Pane
	rm -rf /Applications/Pane.app
	cp -r Pane.app /Applications/Pane.app
	codesign --force --deep --sign - /Applications/Pane.app
	tccutil reset AppleEvents com.pane.app 2>/dev/null || true
	@echo "Installed to /Applications/Pane.app"
	@echo "First run: grant Automation permission when macOS prompts."

uninstall:
	rm -rf /Applications/Pane.app
	@echo "Uninstalled"

clean:
	swift package clean
	rm -rf Pane.app .build
