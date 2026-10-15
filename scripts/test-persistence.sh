#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
xcrun swiftc -target arm64-apple-macosx14.0 -module-cache-path /tmp/lift-module-cache Lift/Domain.swift Lift/Models.swift Tests/PersistenceTests.swift -o /tmp/lift-persistence-tests
/tmp/lift-persistence-tests
