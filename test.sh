#!/bin/bash
# Run Lune tests for Legions & Cycles: Ancient Rome
# Usage: ./test.sh

set -e

echo "Running Lune tests..."
lune run tests/init.luau
