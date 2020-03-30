package(default_visibility = ["//visibility:public"])

load("//env:lt_py.bzl", "lt_py_pylint")
load(":yis.bzl", "yis_rtl_pkg")

py_binary(
    name = "yis",
    srcs = ["yis.py"],
    deps = ["//scripts:cmn_logging"],
)

lt_py_pylint(
    name = "yis",
    files = [
        "yis.py",
    ],
)
