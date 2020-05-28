package(default_visibility = ["//visibility:public"])

load("//env:lt_py.bzl", "lt_py_pylint")
load("//env:doc.bzl", "markdown_to_html")

all_jinja_templates = glob(["templates/**"])

all_yamale_schemas = glob(["yamale_schemas/**"])

py_binary(
    name = "yis",
    srcs = ["yis.py"],
    data = all_jinja_templates + all_yamale_schemas,
    deps = [
        "//digital/rtl/scripts:gen_prot",
        "//scripts:cmn_logging",
    ],
)

markdown_to_html(
    name = "yis_html",
    srcs = ["README.md"],
    imgs = [],
)

lt_py_pylint(
    name = "yis_pylint",
    files = [
        "yis.py",
    ],
)
