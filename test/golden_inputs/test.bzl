load("//digital/rtl/scripts/yis:yis.bzl", "yis_rtl_pkg", "yis_html_pkg")

def golden_rtl_pkg_test(name, pkg_deps):
    """Compares a generated file to a statically checked in file."""

    yis_rtl_pkg(
        name = "{}".format(name),
        pkg_deps = pkg_deps,
        pkg = ":{}.yis".format(name),
    )

    native.sh_test(
        name = "{}_rtl_pkg_gold_test".format(name),
        size = "small",
        srcs = ["//digital/rtl/scripts/yis/test:passthrough.sh"],
        data = [
            ":{}_pkg_svh".format(name),
            ":{}_pkg.svh".format(name),
        ],
        args = ["diff $(location :{name}_pkg_svh) $(location {name}_pkg.svh)".format(name=name)],
        tags = ["gold"],
    )

def golden_html_pkg_test(name, pkg_deps):
    """Compares a generated file to a statically checked in file."""

    yis_html_pkg(
        name = "{}".format(name),
        pkg_deps = pkg_deps,
        pkg = ":{}.yis".format(name),
    )

    native.sh_test(
        name = "{}_html_pkg_gold_test".format(name),
        size = "small",
        srcs = ["//digital/rtl/scripts/yis/test:passthrough.sh"],
        data = [
            ":{}_pkg_html".format(name),
            ":{}_pkg.html".format(name),
        ],
        args = ["diff $(location :{name}_pkg_html) $(location {name}_pkg.html)".format(name=name)],
        tags = ["gold"],
    )

def golden_pkg_tests(deps):
    """Run all golden pkg tests, allow pkg dependencies."""
    for key, row in deps.items():
        golden_rtl_pkg_test(key, row)
        golden_html_pkg_test(key, row)

def golden_intf_tests(deps):
    """Run all golden intf tests, allow pkg dependencies."""
    pass
    # for key, row in deps.items():
    #     golden_html_test(key, row)
