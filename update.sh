
base_url=https://github.com/Nitrokey/nitrokey-app2/archive/

if [[ "$1" = "" ]]; then
  echo "Usage: bash update.sh <git-branch-tag-commit>"
  exit 1
fi

archive=$1

url=${base_url}${archive}.tar.gz

echo "downloading..."
wget --quiet -O imported/archive.tar.gz "$url"

echo "hashing..."
hash=$(sha256sum imported/archive.tar.gz | cut -d " " -f 1)

echo "unpack archive..."
tar xf imported/archive.tar.gz -C imported

echo "copy pyproject.toml & poetry.lock..."

if [[ "${archive:0:1}" == "v" ]]; then
  dname=${archive:1}
else
  dname=${archive}
fi

cp imported/nitrokey-app2-${dname}/pyproject.toml imported/
cp imported/nitrokey-app2-${dname}/poetry.lock imported/

echo "writing manifest..."
venv/bin/python manifest-update.py "$url" "$hash"


