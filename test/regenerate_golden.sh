#!/usr/bin/bash
bazel build //digital/rtl/scripts/yis/test/...
cp $PROJ_DIR/bazel-bin/digital/rtl/scripts/yis/test/*_pkg.svh $PROJ_DIR/digital/rtl/scripts/yis/test/golden_outputs/
chmod +w $PROJ_DIR/digital/rtl/scripts/yis/test/golden_outputs/*.svh
