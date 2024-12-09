
MANIFEST=com.nitrokey.nitrokey-app2.yml


.PHONY: all clean reset pkg run bundle lint check-meta

all: venv rust-pypi-dependencies.json pre-pypi-dependencies.json app-pypi-dependencies.json

clean:
	rm -rf builddir .flatpak-builder repo tmp venv nk-app2.flatpak

reset: clean
	rm -f *requirements.txt* *.cargo-sources.json *-pypi-dependencies.json

pkg: $(MANIFEST)
	flatpak run org.flatpak.Builder --force-clean --sandbox --user --install --install-deps-from=flathub --ccache --mirror-screenshots-url=https://dl.flathub.org/repo/screenshots --repo=repo builddir $(MANIFEST)

run:
	flatpak run com.nitrokey.nitrokey-app2

bundle:
	flatpak build-bundle repo nk-app2.flatpak com.nitrokey.nitrokey-app2

lint:
	flatpak run --command=flatpak-builder-lint org.flatpak.Builder manifest $(MANIFEST)
	flatpak run --command=flatpak-builder-lint org.flatpak.Builder repo repo

check-meta:
	flatpak run --command=appstream-util org.flatpak.Builder validate builddir/export/share/metainfo/com.nitrokey.nitrokey-app2.appdata.xml


rust-pypi-dependencies.json: rust-requirements.txt venv
	mkdir -p tmp
	-flatpak --user remove runtime/org.kde.Sdk/x86_64/6.8
	venv/bin/python tools/flatpak-pip-generator --runtime="org.kde.Sdk//6.8" --requirements-file="rust-requirements.txt" --output rust-pypi-dependencies
	
	# extract maturin cargo pkgs, generate cargo sources, append to sources
	jq .modules[0].sources[0].url rust-pypi-dependencies.json | xargs curl -o tmp/maturin.tgz
	tar xf tmp/maturin.tgz -C tmp 
	venv/bin/python tools/flatpak-cargo-generator.py tmp/maturin*/Cargo.lock -o maturin.cargo-sources.json 
	jq '.modules[0].sources[.modules[0].sources| length] |= . + "maturin.cargo-sources.json"' rust-pypi-dependencies.json > rust-pypi-dependencies.json.tmp
	mv rust-pypi-dependencies.json.tmp rust-pypi-dependencies.json
	jq '.modules[0]."build-options".env.CARGO_HOME = "/run/build/python3-maturin/cargo"' rust-pypi-dependencies.json > rust-pypi-dependencies.json.tmp
	mv rust-pypi-dependencies.json.tmp rust-pypi-dependencies.json
	
	# extract cryptography cargo pkgs, generate cargo sources, append to sources
	jq .modules[1].sources[1].url rust-pypi-dependencies.json | xargs curl -o tmp/cryptography.tgz
	tar xf tmp/cryptography.tgz -C tmp 
	venv/bin/python tools/flatpak-cargo-generator.py tmp/cryptography*/src/rust/Cargo.lock -o cryptography.cargo-sources.json
	jq '.modules[1].sources[.modules[1].sources| length] |= . + "cryptography.cargo-sources.json"' rust-pypi-dependencies.json > rust-pypi-dependencies.json.tmp
	mv rust-pypi-dependencies.json.tmp rust-pypi-dependencies.json
	jq '.modules[1]."build-options".env.CARGO_HOME = "/run/build/python3-cryptography/cargo"' rust-pypi-dependencies.json > rust-pypi-dependencies.json.tmp
	mv rust-pypi-dependencies.json.tmp rust-pypi-dependencies.json

pre-pypi-dependencies.json: pre-requirements.txt venv
	-flatpak --user remove runtime/org.kde.Sdk/x86_64/6.8
	venv/bin/python tools/flatpak-pip-generator --runtime="org.kde.Sdk//6.8" --requirements-file="pre-requirements.txt" --output pre-pypi-dependencies

app-pypi-dependencies.json: app-requirements.txt venv
	-flatpak --user remove runtime/org.kde.Sdk/x86_64/6.8
	venv/bin/python tools/flatpak-pip-generator --runtime="org.kde.Sdk//6.8" --requirements-file="app-requirements.txt" --output app-pypi-dependencies

	# fix markupsafe
	sed -i -r 's/pip3 install --verbose(.*?)markupsafe(.*?)/pip3 install -I --verbose \1markupsafe\2/g' app-pypi-dependencies.json

venv:
	python -m venv venv
	venv/bin/pip install requirements-parser poetry aiohttp toml

# PY REQUIREMENTS

pre-requirements.txt:
	echo 'cffi==1.17.1; python_version >= "3.9" and python_version < "3.14"' > $@
	echo 'packaging==24.2; python_version >= "3.9" and python_version < "3.14"' >> $@
	echo 'setuptools-rust==1.8.1; python_version >= "3.9" and python_version < "3.14"' >> $@

rust-requirements.txt:
	echo 'maturin==1.4.0; python_version >= "3.9" and python_version < "3.14"' > $@
	echo 'cryptography==43.0.1 ; python_version >= "3.9" and python_version < "3.14"' >> $@


app-requirements.txt: poetry.lock
	venv/bin/poetry export --without-hashes -f requirements.txt --output app-requirements.txt
	sed -i -e '/hidapi/d' $@
	sed -i -e '/pyreadline3/d' $@
	sed -i -e '/pywin32/d' $@
	sed -i -e '/wmi/d' $@
	sed -i -e '/cryptography/d' $@
	sed -i -e '/cffi/d' $@
	sed -i -e '/cmsis-pack-manager/d' $@
	
	echo 'pyreadline3==3.4.1 ; python_version >= "3.9" and python_version < "3.13"' >> $@
	

