load("//digital/rtl/scripts/yis:yis.bzl", "yis_rtl_pkg")

def golden_test(name):
    """Compares a generated file to a statically checked in file."""

    yis_rtl_pkg(
        name = "{}".format(name),
        pkg_deps = [],
        pkg = ":golden_inputs/{}.yis".format(name),
    )

    native.sh_test(
        name = "{}_gold_test".format(name),
        size = "small",
        srcs = ["passthrough.sh"],
        data = [
            ":{}_pkg_svh".format(name),
            ":golden_outputs/{}_pkg.svh".format(name),
        ],
        args = ["diff $(location :{name}_pkg_svh) $(location golden_outputs/{name}_pkg.svh)".format(name=name)],
        tags = ["gold"],
    )

def golden_test_glob(yis_files):
    """Runs all golden tests"""
    for yis_file in yis_files:
        yis_file = yis_file.rsplit('/', 1)[1]
        yis_file = yis_file[:-4]
        golden_test(yis_file)
