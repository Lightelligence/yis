def yis_rtl_pkg(name, pkg_deps, pkg):
    """Create a single yis-generate RTL pkg."""
    native.genrule(name = "{}_pkg_svh".format(name),
                   srcs = pkg_deps + [pkg],
                   outs = ["{}_pkg.svh".format(name)],
                   cmd = "$(location //digital/rtl/scripts/yis:yis) --pkgs $(SRCS) --output-file $@",
                   output_to_bindir = True,
                   tools = ["//digital/rtl/scripts/yis:yis"],
               )

def yis_html_pkg(name, pkg_deps, pkg):
    expected_name = pkg.rsplit(":")[1][:-4]
    if name != expected_name:
        fail("Expect yis target name to be: {}, not {}".format(expected_name, name))
    native.genrule(name = "{}_pkg_html".format(name),
                   srcs = pkg_deps + [pkg] + [pkg_dep[:-4] + "_pkg_html" for pkg_dep in pkg_deps],
                   outs = ["{}_pkg.html".format(name)],
                   cmd = "$(location //digital/rtl/scripts/yis:yis) --pkgs $(SRCS) --output-file $@ --gen-html",
                   output_to_bindir = True,
                   tools = ["//digital/rtl/scripts/yis:yis"] + [pkg_dep[:-4] + "_pkg_html" for pkg_dep in pkg_deps],
                   visibility = ["//visibility:public"],
                   tags = ["doc_export"],
               )

def yis_html_intf(name, pkg_deps, intf):
    expected_name = intf.rsplit(":")[1][:-4]
    if name != expected_name:
        fail("Expect yis target name to be: {}".format(expected_name))
        
    native.genrule(name = "{}_rtl_intf_html".format(name),
                   srcs = pkg_deps + [intf] + [pkg_dep[:-4] + "_pkg_html" for pkg_dep in pkg_deps],
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
    yis_html_intf(name, pkg_deps, intf)
