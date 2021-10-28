#!/usr/bin/env sh
set -e

PRODUCT_DIR=$2
PROJECT_NAME=$1
ARCHIVE_NAME="$PROJECT_NAME.zip"

pushd "$PRODUCT_DIR/"
zip -r "$ARCHIVE_NAME" $PROJECT_NAME.app
popd
