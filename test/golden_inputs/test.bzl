"""Test helpers for yis."""

load("//:yis.bzl", "yis_html_intf", "yis_html_pkg", "yis_rtl_fifo", "yis_rtl_mem", "yis_rtl_pkg", "yis_hdr_pkg")

golden_out_location = "//test/golden_outputs:"

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
        srcs = ["//test:passthrough.sh"],
        data = [
            ":{}_rypkg_svh".format(name),
            "{}{}_rypkg.svh".format(golden_out_location, name),
        ],
        args = ["diff $(location :{name}_rypkg_svh) $(location {gout}{name}_rypkg.svh)".format(gout = golden_out_location, name = name)],
        tags = ["gold"],
    )

def golden_hdr_test(name, pkg_deps):
    """Compares a generated file to a statically checked in file."""

    yis_hdr_pkg(
        name = "{}".format(name),
        pkg_deps = pkg_deps,
        pkg = ":{}.yis".format(name),
    )

    native.sh_test(
        name = "{}_hdr_gold_test".format(name),
        size = "small",
        srcs = ["//test:passthrough.sh"],
        data = [
            ":{}_rypkg_hdr".format(name),
            "{}{}_rypkg.h".format(golden_out_location, name),
        ],
        args = ["diff $(location :{name}_rypkg_hdr) $(location {gout}{name}_rypkg.h)".format(gout = golden_out_location, name = name)],
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
        srcs = ["//test:passthrough.sh"],
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
        srcs = ["//test:passthrough.sh"],
        data = [
            ":{}_rtl_intf_html".format(name),
            ":{}_rtl_intf.html".format(name),
        ],
        args = ["diff $(location :{name}_rtl_intf_html) $(location {name}_rtl_intf.html)".format(name = name)],
        tags = ["gold"],
    )

def golden_rtl_mem_test(name, pkg_deps, sram_deps):
    """Compares a generated file to a statically checked in file."""

    yis_rtl_mem(
        name = "{}".format(name),
        pkg_deps = pkg_deps,
        sram_deps = sram_deps,
        mem = ":{}.yis".format(name),
    )

    native.sh_test(
        name = "{}_rtl_mem_gold_test".format(name),
        size = "small",
        srcs = ["//test:passthrough.sh"],
        data = [
            ":{}_mem_gen".format(name),
            "{}{}_mem.sv".format(golden_out_location, name),
        ],
        args = ["diff $(location :{name}_mem_gen) $(location {gout}{name}_mem.sv)".format(gout = golden_out_location, name = name)],
        tags = ["gold"],
    )

def golden_rtl_fifo_test(name, pkg_deps, sram_deps):
    """Compares a generated file to a statically checked in file."""

    yis_rtl_fifo(
        name = "{}".format(name),
        pkg_deps = pkg_deps,
        sram_deps = sram_deps,
        yis = ":{}.yis".format(name),
    )

    native.sh_test(
        name = "{}_rtl_fifo_gold_test".format(name),
        size = "small",
        srcs = ["//test:passthrough.sh"],
        data = [
            ":{}_fifo_gen".format(name),
            "{}{}_fifo.sv".format(golden_out_location, name),
        ],
        args = ["diff $(location :{name}_fifo_gen) $(location {gout}{name}_fifo.sv)".format(gout = golden_out_location, name = name)],
        tags = ["gold"],
    )

def golden_pkg_tests(deps):
    """Run all golden pkg tests, allow pkg dependencies."""
    for key, row in deps.items():
        golden_rtl_pkg_test(key, row)
        golden_hdr_test(key, row)
        golden_html_pkg_test(key, row)

def golden_intf_tests(deps):
    """Run all golden intf tests, allow pkg dependencies."""
    for key, row in deps.items():
        golden_html_intf_test(key, row)

def golden_mem_tests(deps):
    """Run all golden mem tests, allow pkg dependencies."""
    for key, row in deps.items():
        pkg_deps = []
        sram_deps = []
        for item in row:
            if item.endswith(".yis"):
                pkg_deps.append(item)
                # FIXME external dependency
            elif item.startswith("//digital/rtl/common:"):
                sram_deps.append(item)
            else:
                fail("Unrecoginized item in deps: {}".format(item))
        golden_rtl_mem_test(key, pkg_deps, sram_deps)

def golden_fifo_tests(deps):
    """Run all golden mem tests, allow pkg dependencies."""
    for key, row in deps.items():
        pkg_deps = []
        sram_deps = []
        for item in row:
            if item.endswith(".yis"):
                pkg_deps.append(item)
                # FIXME external dependency
            elif item.startswith("//digital/rtl/common:"):
                sram_deps.append(item)
            else:
                fail("Unrecoginized item in deps: {}".format(item))
        golden_rtl_fifo_test(key, pkg_deps, sram_deps)
