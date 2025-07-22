#!/bin/bash

set -euxo pipefail

org_json=generated/pypi-dependencies.json

PKG=$1

mkdir -p tmp

# extract cargo pkgs, generate cargo sources, append to sources
IDX=`jq -r '.modules | map(.name) | index("python3-'$PKG'")' ${org_json}`
jq -r '.modules['$IDX'].sources[] | select(.url | contains("'$PKG'")) | .url' ${org_json} | xargs curl -o tmp/${PKG}.tgz
tar xf tmp/${PKG}.tgz -C tmp

# aaaaaahhhhhh!!!!!!
if [[ "$PKG" = "cryptography" ]]; then
  lockfile=src/rust/Cargo.lock
else
  lockfile=Cargo.lock
fi

venv/bin/python tools/flatpak-cargo-generator.py tmp/${PKG}*/$lockfile -o generated/${PKG}.cargo-sources.json


jq '.modules['$IDX'].sources[.modules['$IDX'].sources| length] |= . + "'$PKG'.cargo-sources.json"' ${org_json} > ${org_json}.tmp
mv ${org_json}.tmp ${org_json}
jq '.modules['$IDX']."build-options".env.CARGO_HOME = "/run/build/python3-'$PKG'/cargo"' ${org_json} > ${org_json}.tmp
mv ${org_json}.tmp ${org_json}
	
