#!/usr/bin/env bash

# Update this when a new stable version comes around
STABLE_DEFINITIONS="5.3.29 5.4.45 5.5.38 5.6.40 7.0.33 7.1.33 7.2.34 7.3.33 7.4.33 8.0.30 8.1.28 8.2.18 8.3.6 phpbinary-8.3.4"

TIME="$(date "+%Y%m%d%H%M%S")"

DEFINITIONS="$(./bin/php-build --definitions)"

#BUILD_PREFIX="/tmp/php-build-test-$TIME"
BUILD_PREFIX="/tmp/phpbinary"
BUILD_LIST=
FAILED=

usage() {
    echo "Usage: ./run-tests.sh all|stable|<definition>,..."
}

if ! command -v bats > /dev/null; then
    echo "You need http://github.com/sstephenson/bats installed." >&2
    exit 1
fi

case "$1" in
    stable)
        BUILD_LIST="$STABLE_DEFINITIONS"
        ;;
    *)
        if [ $# -eq 0 ]; then
            usage
            exit 1
        fi
        BUILD_LIST="$@"
        ;;
esac

echo "Testing definitions $BUILD_LIST"
echo

[ -n "$TRAVIS" ] && while true; do echo "..."; sleep 60; done & #https://github.com/php-build/php-build/issues/134

for definition in $BUILD_LIST; do
    echo -n "Building '$definition'..."
    if ./bin/php-build "$definition" "$BUILD_PREFIX"; then
        echo "BUILD OK"

        export TEST_PREFIX="$BUILD_PREFIX"
        export DEFINITION_CONFIG=$(./bin/php-build --definition "$definition")
        export PHP_MINOR_VERSION=${definition%.*}
        export PHP_MAJOR_VERSION=${definition:0:1}

        echo "Running Tests..."
        $TEST_PREFIX/bin/php -m
        $TEST_PREFIX/bin/php -n -m
        
    else
        echo "BUILD FAIL"
        FAILED="$FAILED $definition"
    fi
done

[ -n "$TRAVIS" ] && kill %1 #https://github.com/php-build/php-build/issues/134

if [ -z "$FAILED" ]; then
    echo "Done"
else
    echo "Build fail."
    echo "Failed Definitions:$FAILED"
    exit 1
fi
