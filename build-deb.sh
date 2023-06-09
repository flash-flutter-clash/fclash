#!/bin/bash

# run go
./build-clash-lib.py

# build linux
echo "build flutter package in $PWD"
flutter build linux --release

# create files
mkdir -p ./debian/build-src/opt/apps/cn.kingtous.fclash/files/lib

# rm
pushd ./debian/build-src/opt/apps/cn.kingtous.fclash/files || exit
rm -rf ./*
popd || exit

# cp
cp -r ./build/linux/x64/release/bundle/* ./debian/build-src/opt/apps/cn.kingtous.fclash/files

echo "build deb package"
pushd ./debian || exit

dpkg -b ./build-src cn.kingtous.fclash.deb

popd || exit
