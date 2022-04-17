#!/bin/bash
set -euo pipefail

### ---- ###

echo "Switch back to master"
git checkout master
git reset --hard origin/master

### ---- ###

version=$(curl -s "https://lv.luzifer.io/v1/catalog/code-server/latest/version")
grep -q "CODE_SERVER_VERSION=${version}$" Dockerfile && exit 0 || echo "Update required"

sed -Ei \
  -e "s/CODE_SERVER_VERSION=[0-9.]+/CODE_SERVER_VERSION=${version}/" \
  Dockerfile

### ---- ###

echo "Testing build..."
docker build .

### ---- ###

echo "Updating repository..."
git add Dockerfile
git -c user.name='Luzifer.io Jenkins' -c user.email='jenkins@luzifer.io' \
  commit -m "Code-Server ${version}"
git tag ${version}

git push -q https://${GH_USER}:${GH_TOKEN}@github.com/luzifer-docker/code-server master --tags
