package(default_visibility = ["//visibility:public"])

load("//env:lt_py.bzl", "lt_py_pylint")
load(":yis.bzl", "yis_rtl_pkg")

all_jinja_templates = [
    "templates/rtl_pkg.svh",
    "templates/base.html",
    "templates/rtl_intf.html",
]

py_binary(
    name = "yis",
    srcs = ["yis.py"],
    data = all_jinja_templates,
    deps = ["//scripts:cmn_logging"],
)

lt_py_pylint(
    name = "yis",
    files = [
        "yis.py",
    ],
)
