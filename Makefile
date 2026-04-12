.PHONY: build install uninstall clean

build:
	swift build -c release --arch arm64 --arch x86_64

install: build
	mkdir -p Pane.app/Contents/MacOS
	cp .build/apple/Products/Release/Pane Pane.app/Contents/MacOS/Pane
	cp -r Pane.app /Applications/Pane.app
	@echo "Installed to /Applications/Pane.app"

uninstall:
	rm -rf /Applications/Pane.app
	@echo "Uninstalled"

clean:
	swift package clean
	rm -rf Pane.app .build
