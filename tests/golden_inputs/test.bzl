"""Test helpers for yis."""

load("@yis//:yis.bzl", "yis_html_intf", "yis_html_pkg", "yis_rtl_pkg", "yis_c_hdr", "yis_rdl_pkg")

golden_out_location = "@yis//tests/golden_outputs:"

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
        srcs = ["@yis//tests:passthrough.sh"],
        data = [
            ":{}_rypkg_svh".format(name),
            "{}{}_rypkg.svh".format(golden_out_location, name),
        ],
        args = ["diff $(location :{name}_rypkg_svh) $(location {gout}{name}_rypkg.svh)".format(gout = golden_out_location, name = name)],
        tags = ["gold"],
    )

def golden_hdr_test(name, pkg_deps):
    """Compares a generated file to a statically checked in file."""

    yis_c_hdr(
        name = "{}".format(name),
        pkg_deps = pkg_deps,
        pkg = ":{}.yis".format(name),
    )

    native.sh_test(
        name = "{}_hdr_gold_test".format(name),
        size = "small",
        srcs = ["@yis//tests:passthrough.sh"],
        data = [
            ":{}_h".format(name),
            "{}{}.h".format(golden_out_location, name),
        ],
        args = ["diff $(location :{name}_h) $(location {gout}{name}.h)".format(gout = golden_out_location, name = name)],
        tags = ["gold"],
    )

def golden_rdl_test(name, pkg_deps):
    """Compares a generated file to a statically checked in file."""

    yis_rdl_pkg(
        name = "{}".format(name),
        pkg_deps = pkg_deps,
        pkg = ":{}.yis".format(name),
    )

    native.sh_test(
        name = "{}_rdl_pkg_gold_test".format(name),
        size = "small",
        srcs = ["@yis//tests:passthrough.sh"],
        data = [
            ":{}_yis_rdl".format(name),
            "{}{}_yis.rdl".format(golden_out_location, name),
        ],
        args = ["diff $(location :{name}_yis_rdl) $(location {gout}{name}_yis.rdl)".format(gout = golden_out_location, name = name)],
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
        srcs = ["@yis//tests:passthrough.sh"],
        data = [
            ":{}_rypkg_html".format(name),
            ":{}_rypkg.html".format(name),
        ],
        args = ["diff $(location :{name}_rypkg_html) $(location {name}_rypkg.html)".format(name = name)],
        tags = ["gold"],
    )

def golden_html_intf_test(name, pkg_deps):
    """Compares a generated file to a statically checked in file."""

    yis_html_intf(
        name = "{}".format(name),
        pkg_deps = pkg_deps,
        intf = ":{}.yis".format(name),
    )

    native.sh_test(
        name = "{}_html_intf_gold_test".format(name),
        size = "small",
        srcs = ["@yis//tests:passthrough.sh"],
        data = [
            ":{}_rtl_intf_html".format(name),
            ":{}_rtl_intf.html".format(name),
        ],
        args = ["diff $(location :{name}_rtl_intf_html) $(location {name}_rtl_intf.html)".format(name = name)],
        tags = ["gold"],
    )

def golden_pkg_tests(deps):
    """Run all golden pkg tests, allow pkg dependencies."""
    for key, row in deps.items():
        golden_rtl_pkg_test(key, row)
        golden_hdr_test(key, row)
        golden_html_pkg_test(key, row)
        golden_rdl_test(key, row)

def golden_intf_tests(deps):
    """Run all golden intf tests, allow pkg dependencies."""
    for key, row in deps.items():
        golden_html_intf_test(key, row)
