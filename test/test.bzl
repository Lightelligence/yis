load("//digital/rtl/scripts/yis:yis.bzl", "yis_rtl_pkg", "yis_rtl_intf")

def golden_pkg_test(name, pkg_deps):
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

# def golden_intf_test(name, pkg_deps):
#     """Compares a generated file to a statically checked in file."""

#     yis_rtl_intf(
#         name = "{}".format(name),
#         pkg_deps = pkg_deps,
#         intf = ":golden_inputs/{}.yis".format(name),
#     )

#     native.sh_test(
#         name = "{}_gold_test".format(name),
#         size = "small",
#         srcs = ["passthrough.sh"],
#         data = [
#             ":{}_rtl_intf_sv".format(name),
#             ":golden_outputs/{}_rtl_inft.sv".format(name),
#         ],
#         args = ["diff $(location :{name}_rtl_intf_sv) $(location golden_outputs/{name}_rtl_intf.sv)".format(name=name)],
#         tags = ["gold"],
#     )

def golden_pkg_tests(deps):
    """Run all golden pkg tests, allow pkg dependencies."""
    for key, row in deps.items():
        golden_pkg_test(key, row)

def golden_intf_tests(deps):
    """Run all golden intf tests, allow pkg dependencies."""
    pass
    # for key, row in deps.items():
    #     golden_intf_test(key, row)
