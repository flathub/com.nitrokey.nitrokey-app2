
base_url=https://github.com/Nitrokey/nitrokey-app2/archive/
download_dir=downloaded
import_dir=imported

if [[ "$1" = "" ]]; then
  echo "Usage: bash update.sh <git-branch-tag-commit>"
  exit 1
fi

archive=$1

url=${base_url}${archive}.tar.gz

mkdir -p ${download_dir}

echo "downloading..."
wget --quiet -O ${download_dir}/archive.tar.gz "$url"

echo "hashing..."
hash=$(sha256sum ${download_dir}/archive.tar.gz | cut -d " " -f 1)

echo "unpack archive..."
tar xf ${download_dir}/archive.tar.gz -C ${download_dir}

echo "copy pyproject.toml & poetry.lock..."

if [[ "${archive:0:1}" == "v" ]]; then
  dname=${archive:1}
else
  dname=${archive}
fi

cp ${download_dir}/nitrokey-app2-${dname}/pyproject.toml ${import_dir}/
cp ${download_dir}/nitrokey-app2-${dname}/poetry.lock ${import_dir}/

echo "writing manifest..."
venv/bin/python manifest-update.py "$url" "$hash"


