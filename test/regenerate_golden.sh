#!/usr/bin/bash
bazel build //digital/rtl/scripts/yis/test/...
cp $PROJ_DIR/bazel-bin/digital/rtl/scripts/yis/test/golden_inputs/*_rypkg.svh $PROJ_DIR/digital/rtl/scripts/yis/test/golden_outputs/
cp $PROJ_DIR/bazel-bin/digital/rtl/scripts/yis/test/golden_inputs/*_rypkg.html $PROJ_DIR/digital/rtl/scripts/yis/test/golden_outputs/
cp $PROJ_DIR/bazel-bin/digital/rtl/scripts/yis/test/golden_inputs/*_intf.html $PROJ_DIR/digital/rtl/scripts/yis/test/golden_outputs/
chmod +w $PROJ_DIR/digital/rtl/scripts/yis/test/golden_outputs/*.svh
chmod +w $PROJ_DIR/digital/rtl/scripts/yis/test/golden_outputs/*.html
