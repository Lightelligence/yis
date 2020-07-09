#!/usr/bin/bash
bazel build //test/...
cp $PROJ_DIR/bazel-bin/test/golden_inputs/*_rypkg.svh  $PROJ_DIR/test/golden_outputs/
cp $PROJ_DIR/bazel-bin/test/golden_inputs/*_mem.svh    $PROJ_DIR/test/golden_outputs/
cp $PROJ_DIR/bazel-bin/test/golden_inputs/*_rypkg.html $PROJ_DIR/test/golden_outputs/
cp $PROJ_DIR/bazel-bin/test/golden_inputs/*_intf.html  $PROJ_DIR/test/golden_outputs/
chmod +w $PROJ_DIR/test/golden_outputs/*.sv*
chmod +w $PROJ_DIR/test/golden_outputs/*.html
