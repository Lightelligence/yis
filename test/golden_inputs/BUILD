load(":test.bzl", "golden_pkg_tests", "golden_intf_tests")

golden_pkg_tests(
    deps = {
        "test_pkg_a" : [],
        "test_pkg_b" : ["test_pkg_a.yis"],
    }
)

golden_intf_tests(
    deps = {
        "test_intf_a" : [
            "test_pkg_a.yis",
            "test_pkg_b.yis",
            ],
    }
)
