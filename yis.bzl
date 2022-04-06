"""Rules (well macros) for building yis files."""

load("@rules_verilog//verilog:defs.bzl", "verilog_dv_library", "verilog_rtl_library", "verilog_rtl_pkg", "verilog_rtl_unit_test")
load("@project_doc_server//:doc.bzl", "rst_html_wrapper")

def yis_rtl_pkg(name, pkg_deps, pkg):
    """Create a single yis-generate RTL pkg."""
    native.genrule(
        name = "{}_rypkg_svh".format(name),
        srcs = pkg_deps + [pkg],
        outs = ["{}_rypkg.svh".format(name)],
        cmd = "$(location @yis//:yis_gen) --pkgs $(SRCS) --output-file $@ --gen-rtl",
        output_to_bindir = True,
        tools = ["@yis//:yis_gen"],
    )
    verilog_rtl_pkg(
        name = "{}_rypkg".format(name),
        direct = [":{}_rypkg_svh".format(name)],
        deps = [pkg_dep[:-4] + "_rypkg" for pkg_dep in pkg_deps],
    )

def yis_c_hdr(name, pkg_deps, pkg):
    """Create a single yis-generate C header file."""
    native.genrule(
        name = "{}_h".format(name),
        srcs = pkg_deps + [pkg],
        outs = ["{}.h".format(name)],
        cmd = "$(location @yis//:yis_gen) --pkgs $(SRCS) --output-file $@ --gen-c-hdr",
        output_to_bindir = True,
        tools = ["@yis//:yis_gen"],
    )

def yis_instruction(name, pkg_deps, pkg):
    """Create a single yis-generate instruction proto."""
    native.genrule(
        name = "{}_instruction_pb".format(name),
        srcs = pkg_deps + [pkg],
        outs = ["{}_instruction.pb2".format(name)],
        cmd = "$(location @yis//:yis_gen) --pkgs $(SRCS) --output-file $@ --gen-instruction",
        output_to_bindir = True,
        exec_tools = ["@yis//:yis_gen"],
        visibility = ["//visibility:public"],
    )

def yis_rdl_pkg(name, pkg_deps, pkg):
    """Create a single yis-generate RDL pkg."""
    native.genrule(
        name = "{}_yis_rdl".format(name),
        srcs = pkg_deps + [pkg],
        outs = ["{}_yis.rdl".format(name)],
        cmd = "$(location @yis//:yis_gen) --pkgs $(SRCS) --output-file $@ --gen-rdl",
        output_to_bindir = True,
        tools = ["@yis//:yis_gen"],
        visibility = ["//visibility:public"],
    )

def yis_dv_intf(name, pkg_deps, pkg):
    """Create a single yis-generate DV interface pkg."""
    native.genrule(
        name = "{}_dv_intf_svh".format(name),
        srcs = pkg_deps + [pkg],
        outs = ["{}_intf.svh".format(name)],
        cmd = "$(location @yis//:yis_gen) --pkgs $(SRCS) --output-file $@ --block-interface --gen-dv",
        output_to_bindir = True,
        visibility = ["//visibility:public"],
        tools = ["@yis//:yis_gen"],
    )
    verilog_dv_library(
        name = "{}_dv_intf".format(name),
        srcs = [":{}_dv_intf_svh".format(name)],
        in_flist = [":{}_dv_intf_svh".format(name)],
        deps = [pkg_dep[:-4] + "_rypkg" for pkg_dep in pkg_deps],
        visibility = ["//visibility:public"],
    )

def yis_html_pkg(name, pkg_deps, pkg):
    expected_name = pkg.rsplit(":")[1][:-4]
    if name != expected_name:
        fail("Expect yis target name to be: {}, not {}".format(expected_name, name))
    native.genrule(
        name = "{}_rypkg_html".format(name),
        srcs = pkg_deps + [pkg] + [pkg_dep[:-4] + "_rypkg_html" for pkg_dep in pkg_deps],
        outs = ["{}_rypkg.html".format(name)],
        cmd = "$(location @yis//:yis_gen) --pkgs $(SRCS) --output-file $@ --gen-html",
        output_to_bindir = True,
        tools = ["@yis//:yis_gen"] + [pkg_dep[:-4] + "_rypkg_html" for pkg_dep in pkg_deps],
        visibility = ["//visibility:public"],
        tags = ["doc_export"],
    )
    rst_html_wrapper(
        name = "{}_rypkg_rst".format(name),
        title = "{} YIS".format(name.upper()),
        html_file = "{}_rypkg.html".format(name),
        tags = ["doc_export"],
    )

def yis_html_intf(name, pkg_deps, intf):
    expected_name = intf.rsplit(":")[1][:-4]
    if name != expected_name:
        fail("Expect yis target name to be: {}".format(expected_name))

    native.genrule(
        name = "{}_rtl_intf_html".format(name),
        srcs = pkg_deps + [intf] + [pkg_dep[:-4] + "_rypkg_html" for pkg_dep in pkg_deps],
        outs = ["{}_rtl_intf.html".format(name)],
        cmd = "$(location @yis//:yis_gen) --pkgs $(SRCS) --output-file $@ --block-interface --gen-html",
        output_to_bindir = True,
        tools = ["@yis//:yis_gen"],
        visibility = ["//visibility:public"],
        tags = ["doc_export"],
    )
    rst_html_wrapper(
        name = "{}_rtl_intf_rst".format(name),
        title = "{} Interface".format(name.upper().replace("__", " to ")),
        html_file = "{}_rtl_intf.html".format(name),
        tags = ["doc_export"],
    )

def yis_pkg(name, pkg_deps, pkg):
    if not name.endswith("_yis"):
        fail("yis_pkg rule names must end with '_yis': {}".format(name))
    yis_rtl_pkg(name[:-4], pkg_deps, pkg)
    yis_rdl_pkg(name[:-4], pkg_deps, pkg)
    yis_html_pkg(name[:-4], pkg_deps, pkg)

def yis_intf(name, pkg_deps, intf):
    if not name.endswith("_yis"):
        fail("yis_intf rule names must end with '_yis': {}".format(name))

    src_block, dst_block = intf.strip(":").split("__")
    dst_block = dst_block.split(".")[0]
    current_block = native.package_name().rsplit("/")[-1]

    if src_block != current_block:
        fail("yis_intf files must be named <src>__<dst>.intf.\n" +
             "The file should live in the rtl/<src> directory.\n" +
             "The rtl/<dst> may create a symlink back to rtl/<src>/<src>__<dst>.yis for convenience.\n" +
             "However to prevent bazel from double building, only the rtl/<src>/BUILD may declare the yis_intf rule\n" +
             "Error: trying to build '{}' in the '{}' directory when it should be in '{}'".format(intf, current_block, src_block))
    yis_html_intf(name[:-4], pkg_deps, intf)
    yis_dv_intf(name[:-4], pkg_deps, intf)

def _rst_html_wrapper_impl(ctx):

    if not ctx.attr.name.endswith("_rst"):
        fail("Expect yis_rst_html_wrapper name to end in _rst")
    name = ctx.attr.name[:-4] + ".rst"
    out = ctx.actions.declare_file(name)

    ctx.actions.expand_template(
        template = ctx.file.template,
        output = out,
        substitutions = {
            "{TITLE}": ctx.attr.title,
            "{TITLE_UNDERSZAP}" : "="*len(ctx.attr.title),
            "{HTML_FILE}": ctx.attr.html_file,
        },
    )
    return [
        DefaultInfo(files=depset([out])),
    ]

yis_rst_html_wrapper = rule(
    doc = "Create a wrapping .rst file for HTML documentation.",
    implementation = _rst_html_wrapper_impl,
    attrs = {
        "title" : attr.string(doc="String to insert as title of page"),
        "html_file" : attr.string(doc="html file name"),
        "template" : attr.label(
            default = Label("@yis//:rst_html_wrapper.template"),
            allow_single_file = True,
        ),
    },
)
