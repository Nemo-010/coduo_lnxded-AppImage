#!/bin/sh

set -eu

ARCH=$(uname -m)
export VERSION=$(git ls-remote --tags --refs --sort=-v:refname \
	https://github.com/opencoduo/coduomp.git |
	sed 's|.*refs/tags/||' |
	head -n 1)
if [ -z "$VERSION" ]; then
	echo "Could not determine the current version!" >&2
	exit 1
fi
export ARCH
export OUTPATH=./dist
export OUTNAME=coduo_lnxded-"$ARCH".AppImage
export ADD_HOOKS="self-updater.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export ICON=./coduo_lnxded.png
export DESKTOP=./coduo_lnxded.desktop
export MAIN_BIN=coduo_lnxded_recovered
export APPDIR=${PWD}/AppDir

# Deploy dependencies
quick-sharun \
	"$PWD/pkg/coduo_lnxded_recovered"          \
	"$PWD"/pkg/uo/game.mp.uo.x86_64.so

# the server looks for its game module at "<fs_basepath>/uo/", so it has to
# sit at APPDIR/uo/ instead of under lib/
mkdir -p "$APPDIR"/uo
for m in game.mp.uo.x86_64.so; do
	found=$(find "$APPDIR"/lib -name "$m" -print | head -n 1)
	if [ -z "$found" ]; then
		echo "ERROR: $m was not deployed!" >&2
		exit 1
	fi
	mv -f "$found" "$APPDIR"/uo/"$m"
done
find "$APPDIR"/lib -type d -empty -delete

# lib.path was written before the move, so it still lists the old location
"$APPDIR"/sharun -g

# quick-sharun generates AppRun itself; the paths the server needs are set
# from a hook, which AppRun sources from bin/
cp -f 90-coduo-lnxded-paths.hook "$APPDIR"/bin/90-coduo-lnxded-paths.hook

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the test fails due to the app
# having issues running in the CI use --simple-test instead
quick-sharun --simple-test ./dist/*.AppImage
