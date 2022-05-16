#!/usr/bin/sh

# restore old binary and early-exit
quit() {
	echo "$1"
	echo "Restoring binary from backup"
	mkdir -p "$BINARY_DIR"
	cp "$BACKUP_DIR/chatterino" "$BINARY_DIR/"
	exit 1
}

# set defaults
JOBS=${JOBS:-"12"}
PATCHES_DIR="$HOME/git/patches/chatterino2"
C2_DIR="/opt/chatterino2"

# backup old binary, just in case build fails
BACKUP_DIR=$(mktemp -d -p /tmp)
BINARY_DIR="$C2_DIR/build/bin"
echo "Backing up $BINARY_DIR/chatterino"
cp "$BINARY_DIR/chatterino" "$BACKUP_DIR/"

# checkout to where "production" Chatterino is located
cd "$C2_DIR"

# pull newest changes
#git reset --hard && git clean -d -f # revert patches later instead
git pull
git submodule update --init --recursive

# apply patches
for x in $(ls "$PATCHES_DIR"/*.patch); do
	echo "Applying $x"
	git apply $x || quit "Failed to apply $x"
done

# clean up the environment
rm -rf build
mkdir -p build && cd build

# build the app
cmake -DCMAKE_BUILD_TYPE=Debug \
	-DUSE_PRECOMPILED_HEADERS=Off \
	-DBUILD_WITH_QT6=Off \
	-DCMAKE_EXPORT_COMPILE_COMMANDS=YES \
	..
make -j$JOBS 1>/dev/null || quit "Something went wrong while building"

# make it nightly
echo nightly > ./bin/modes

# revert patches
echo "App built, reverting patches"
cd "$C2_DIR"
for x in $(ls "$PATCHES_DIR"/*.patch | sort -r); do
	echo "Reverting $x"
	git apply -R $x || (echo "Failed to revert $x" && exit 1) #TODO: This might be the way to go
	#git apply -R $x || exit 1
done

# removing backup
rm -rf "$BACKUP_DIR"
