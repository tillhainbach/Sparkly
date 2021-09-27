#!/usr/bin/env sh
set -e

PROJECT_NAME=$1
ARCHIVE_NAME="$PROJECT_NAME.zip"

pushd Product/
zip -r "$ARCHIVE_NAME" $PROJECT_NAME.app
popd
