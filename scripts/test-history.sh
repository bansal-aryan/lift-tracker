#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
xcrun swiftc -target arm64-apple-macosx14.0 -module-cache-path /tmp/lift-module-cache Lift/Domain.swift Lift/Models.swift Lift/HistoryImport.swift Tests/HistoryImportTests.swift -o /tmp/lift-history-tests
/tmp/lift-history-tests
