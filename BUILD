package(default_visibility = ["//visibility:public"])

load("//env:lt_py.bzl", "lt_py_pylint")
load(":yis.bzl", "yis_rtl_pkg")

all_jinja_templates = glob(["templates/**"])

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
