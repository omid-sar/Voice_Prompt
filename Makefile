VERSION = `head -n 1 version`

all:
	@echo "Read a document at the following URL to build a distributable package."
	@echo "https://github.com/pqrs-org/Karabiner-Elements/#how-to-build"

package: clean
	./make-package.sh
	$(MAKE) clean-launch-services-database

build:
	$(MAKE) -C src

clean:
	$(MAKE) -C src clean
	$(MAKE) -C tests clean
	rm -rf pkgroot
	rm -f *.dmg
	$(MAKE) clean-launch-services-database

clean-launch-services-database:
	bash scripts/clean-launch-services-database.sh

gitclean:
	git clean -f -x -d
	(cd src/vendor/Karabiner-DriverKit-VirtualHIDDevice && git clean -f -x -d)
	$(MAKE) clean-launch-services-database

notarize:
	xcrun notarytool \
		submit Karabiner-Elements-$(VERSION).dmg \
		--keychain-profile "pqrs.org notarization" \
		--wait
	$(MAKE) staple
	say "notarization completed"

staple:
	xcrun stapler staple Karabiner-Elements-$(VERSION).dmg

swift-format:
	find src/apps -name '*.swift' -print0 | xargs -0 swift-format -i

swiftlint:
	swiftlint
