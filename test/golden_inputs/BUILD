package(default_visibility = ["//visibility:public"])

load("@yis//test/golden_inputs:test.bzl", "golden_intf_tests", "golden_pkg_tests")

golden_pkg_tests(
    deps = {
        "test_pkg_a": [],
        "test_pkg_b": ["test_pkg_a.yis"],
    },
)

golden_pkg_tests(
    deps = {
        "test_pkg_c": [],
    },
)

golden_intf_tests(
    deps = {
        "test_intf_a": [
            "test_pkg_a.yis",
            "test_pkg_b.yis",
        ],
    },
)
exports_files([
    "test_pkg_a.yis",
    "test.bzl",
])
