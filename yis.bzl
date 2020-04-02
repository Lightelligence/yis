def yis_rtl_pkg(name, pkg_deps, pkg):
    """Create a single yis-generate RTL pkg."""
    native.genrule(name = "{}_pkg_svh".format(name),
                   srcs = pkg_deps + [pkg],
                   outs = ["{}_pkg.svh".format(name)],
                   cmd = "$(location //digital/rtl/scripts/yis:yis) --pkgs $(SRCS) --output-file $@",
                   output_to_bindir = True,
                   tools = ["//digital/rtl/scripts/yis:yis"],
               )

def yis_rtl_intf(name, pkg_deps, intf):
    """Create a single yis-generate RTL intf."""
    native.genrule(name = "{}_rtl_intf_html".format(name),
                   srcs = pkg_deps + [intf],
                   outs = ["{}_rtl_intf.html".format(name)],
                   cmd = "$(location //digital/rtl/scripts/yis:yis) --pkgs $(SRCS) --output-file $@ --block-interface",
                   output_to_bindir = True,
                   tools = ["//digital/rtl/scripts/yis:yis"],
               )


