#!/usr/bin/env bash
bazel build //test/...
cp bazel-bin/test/golden_inputs/*_rypkg.svh  test/golden_outputs/
cp bazel-bin/test/golden_inputs/*_rypkg.h  test/golden_outputs/
# cp bazel-bin/test/golden_inputs/*_mem.svh    test/golden_outputs/
cp bazel-bin/test/golden_inputs/*_rypkg.html test/golden_outputs/
cp bazel-bin/test/golden_inputs/*_intf.html  test/golden_outputs/
chmod +w test/golden_outputs/*.sv*
chmod +w test/golden_outputs/*.h
chmod +w test/golden_outputs/*.html
