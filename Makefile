
MANIFEST=com.nitrokey.nitrokey-app2.yml


.PHONY: all clean reset pkg run bundle lint check-meta

all: venv generated/pypi-dependencies.json
	
clean:
	rm -rf builddir .flatpak-builder repo tmp venv nk-app2.flatpak imported/archive.tar.gz

reset: clean
	rm -f generated/*

pkg: $(MANIFEST)
	flatpak run org.flatpak.Builder --disable-rofiles-fuse --force-clean --sandbox --user --install --install-deps-from=flathub --ccache --mirror-screenshots-url=https://dl.flathub.org/repo/screenshots --repo=repo builddir $(MANIFEST)

run:
	flatpak run com.nitrokey.nitrokey-app2

bundle:
	flatpak build-bundle repo nk-app2.flatpak com.nitrokey.nitrokey-app2

lint:
	flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest $(MANIFEST)
	flatpak run --command=flatpak-builder-lint org.flatpak.Builder repo repo

check-meta:
	flatpak run --command=appstream-util org.flatpak.Builder validate builddir/export/share/metainfo/com.nitrokey.nitrokey-app2.appdata.xml

generated/pypi-dependencies.json: generated/requirements.txt venv
	-flatpak --user remove runtime/org.kde.Sdk/x86_64/6.8
	venv/bin/python tools/flatpak-pip-generator --runtime="org.kde.Sdk//6.8" --requirements-file="$<" --output generated/pypi-dependencies

	# fix markupsafe
	sed -i -r 's/pip3 install --verbose(.*?)markupsafe(.*?)/pip3 install -I --verbose \1markupsafe\2/g' $@

	bash prepare-rust-package.sh maturin
	bash prepare-rust-package.sh cryptography
	
venv:
	python -m venv venv
	venv/bin/pip install requirements-parser poetry poetry-plugin-export aiohttp toml ruamel.yaml


generated/requirements.txt: imported/poetry.lock
	venv/bin/poetry export -C imported --without-hashes -f requirements.txt --output ../$@

	# exclude windows packages
	sed -i -e '/Windows/d' $@

	# more missing deps		
	sed -i '1 i\maturin' $@
	sed -i '1 i\setuptools_rust' $@
	sed -i '1 i\scikit-build-core' $@

	echo "poetry-core" >> $@
