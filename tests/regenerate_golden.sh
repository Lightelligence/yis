#!/usr/bin/env bash
bazel build //tests/...
cp bazel-bin/tests/golden_inputs/*_rypkg.svh  tests/golden_outputs/
cp bazel-bin/tests/golden_inputs/*_pkg_*.h  tests/golden_outputs/
cp bazel-bin/tests/golden_inputs/*_rypkg.html tests/golden_outputs/
cp bazel-bin/tests/golden_inputs/*_intf.html  tests/golden_outputs/
cp bazel-bin/tests/golden_inputs/*_pkg_*.rdl  tests/golden_outputs/
chmod +w tests/golden_outputs/*.sv*
chmod +w tests/golden_outputs/*.h
chmod +w tests/golden_outputs/*.html

