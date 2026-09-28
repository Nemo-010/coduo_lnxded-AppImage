#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
# the server only needs libstdc++, libz, libgcc_s, libm and libc, all of
# which the base system already provides
pacman -Syu --noconfirm \
	base-devel \
	curl       \
	git        \
	jq         \
	patchelf

echo "Downloading Open CoD:UO dedicated server..."
echo "---------------------------------------------------------------"
RELEASE_JSON=$(curl -Ls https://api.github.com/repos/opencoduo/coduomp/releases/latest)
ASSET=$(printf '%s\n' "$RELEASE_JSON" | jq -r '
	.assets[]
	| select(.name | test("^opencoduo-server-linux-x86_64-.*\\.tar\\.gz$"))
	| "\(.browser_download_url) \((.digest // "") | sub("^sha256:"; ""))"')
TARBALL_URL=$(printf '%s\n' "$ASSET" | cut -d' ' -f1)
TARBALL_SHA=$(printf '%s\n' "$ASSET" | cut -d' ' -f2)
TARBALL=${TARBALL_URL##*/}
if [ -z "$TARBALL_URL" ]; then
	echo "Could not find the server linux-x86_64 release asset!" >&2
	exit 1
fi

if [ ! -f "$TARBALL" ]; then
	curl --retry-connrefused --retry 30 -Lo "$TARBALL" "$TARBALL_URL"
fi
if [ -n "$TARBALL_SHA" ]; then
	echo "$TARBALL_SHA  $TARBALL" | sha256sum -c -
fi

rm -rf pkg
mkdir -p pkg
tar -xzf "$TARBALL" -C pkg --strip-components=1
chmod +x pkg/coduo_lnxded_recovered pkg/uo/*.so
