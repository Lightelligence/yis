package(default_visibility = ["//visibility:public"])

load("//env:lt_py.bzl", "lt_py_pylint")
load("//env:doc.bzl", "markdown_to_html")
load(":yis.bzl", "yis_rtl_pkg")

all_jinja_templates = glob(["templates/**"])
all_yamale_schemas = glob(["yamale_schemas/**"])

py_binary(
    name = "yis",
    srcs = ["yis.py"],
    data = all_jinja_templates + all_yamale_schemas,
    deps = ["//scripts:cmn_logging"],
)

markdown_to_html(
    name = "yis_html",
    srcs = ["README.md"],
)

lt_py_pylint(
    name = "yis",
    files = [
        "yis.py",
    ],
)
