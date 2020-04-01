def yis_rtl_pkg(name, pkg_deps, pkg):
    """Create a single yis-generate RTL pkg."""
    native.genrule(name = "{}_pkg_svh".format(name),
                   srcs = pkg_deps + [pkg],
                   outs = ["{}_pkg.svh".format(name)],
                   cmd = "$(location //digital/rtl/scripts/yis:yis) --pkgs $(SRCS) --output-file $@",
                   output_to_bindir = True,
                   tools = ["//digital/rtl/scripts/yis:yis"],
               )


