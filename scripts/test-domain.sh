#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
xcrun swiftc -module-cache-path /tmp/lift-module-cache Lift/Domain.swift Tests/DomainTests.swift -o /tmp/lift-domain-tests
/tmp/lift-domain-tests
