load("//digital/rtl/scripts/yis:yis.bzl", "yis_rtl_pkg")

def golden_test(name, pkg_deps):
    """Compares a generated file to a statically checked in file."""

    yis_rtl_pkg(
        name = "{}".format(name),
        pkg_deps = pkg_deps,
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

def golden_tests(deps):
    """Run all golden tests, allow pkg dependencies."""
    for key, row in deps.items():
        golden_test(key, row)
