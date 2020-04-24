load("@verilog_tools//:rtl.bzl", "rtl_pkg")
load("@verilog_tools//:dv.bzl", "dv_lib")

def yis_rtl_pkg(name, pkg_deps, pkg):
    """Create a single yis-generate RTL pkg."""
    native.genrule(name = "{}_rypkg_svh".format(name),
                   srcs = pkg_deps + [pkg],
                   outs = ["{}_rypkg.svh".format(name)],
                   cmd = "$(location //digital/rtl/scripts/yis:yis) --pkgs $(SRCS) --output-file $@ --gen-rtl",
                   output_to_bindir = True,
                   tools = ["//digital/rtl/scripts/yis:yis"],
               )
    rtl_pkg(
        name = "{}_rypkg".format(name),
        direct = [":{}_rypkg_svh".format(name)],
        deps = [pkg_dep[:-4] + "_rypkg" for pkg_dep in pkg_deps],
    )

def yis_dv_intf(name, pkg_deps, pkg):
    """Create a single yis-generate DV interface pkg."""
    native.genrule(name = "{}_dv_intf_svh".format(name),
                   srcs = pkg_deps + [pkg],
                   outs = ["{}_intf.svh".format(name)],
                   cmd = "$(location //digital/rtl/scripts/yis:yis) --pkgs $(SRCS) --output-file $@ --block-interface --gen-dv",
                   output_to_bindir = True,
                   tools = ["//digital/rtl/scripts/yis:yis"],
               )
    dv_lib(
        name = "{}_dv_intf".format(name),
        srcs = [":{}_dv_intf_svh".format(name)],
        in_flist = [":{}_dv_intf_svh".format(name)],
        deps = [pkg_dep[:-4] + "_rypkg" for pkg_dep in pkg_deps],
    )


def yis_html_pkg(name, pkg_deps, pkg):
    expected_name = pkg.rsplit(":")[1][:-4]
    if name != expected_name:
        fail("Expect yis target name to be: {}, not {}".format(expected_name, name))
    native.genrule(name = "{}_rypkg_html".format(name),
                   srcs = pkg_deps + [pkg] + [pkg_dep[:-4] + "_rypkg_html" for pkg_dep in pkg_deps],
                   outs = ["{}_rypkg.html".format(name)],
                   cmd = "$(location //digital/rtl/scripts/yis:yis) --pkgs $(SRCS) --output-file $@ --gen-html",
                   output_to_bindir = True,
                   tools = ["//digital/rtl/scripts/yis:yis"] + [pkg_dep[:-4] + "_rypkg_html" for pkg_dep in pkg_deps],
                   visibility = ["//visibility:public"],
                   tags = ["doc_export"],
               )

def yis_html_intf(name, pkg_deps, intf):
    expected_name = intf.rsplit(":")[1][:-4]
    if name != expected_name:
        fail("Expect yis target name to be: {}".format(expected_name))
        
    native.genrule(name = "{}_rtl_intf_html".format(name),
                   srcs = pkg_deps + [intf] + [pkg_dep[:-4] + "_rypkg_html" for pkg_dep in pkg_deps],
                   outs = ["{}_rtl_intf.html".format(name)],
                   cmd = "$(location //digital/rtl/scripts/yis:yis) --pkgs $(SRCS) --output-file $@ --block-interface --gen-html",
                   output_to_bindir = True,
                   tools = ["//digital/rtl/scripts/yis:yis"],
                   visibility = ["//visibility:public"],
                   tags = ["doc_export"],
               )


def yis_pkg(name, pkg_deps, pkg):
    yis_rtl_pkg(name, pkg_deps, pkg)
    yis_html_pkg(name, pkg_deps, pkg)

def yis_intf(name, pkg_deps, intf):
    src_block, dst_block = intf.strip(":").split("__")
    dst_block = dst_block.split(".")[0]
    current_block = native.package_name().rsplit("/")[-1]
    print(src_block)
    print(dst_block)
    print(current_block)
    if src_block != current_block:
        fail("yis_intf files must be named <src>__<dst>.intf.\n" + 
             "The file should live in the rtl/<src> directory.\n" +
             "The rtl/<dst> may create a symlink back to rtl/<src>/<src>__<dst>.yis for convenience.\n" +
             "However to prevent bazel from double building, only the rtl/<src>/BUILD may declare the yis_intf rule\n" +
             "Error: trying to build '{}' in the '{}' directory when it should be in '{}'".format(intf, current_block, src_block))
    yis_html_intf(name, pkg_deps, intf)
    yis_dv_intf(name, pkg_deps, intf)
