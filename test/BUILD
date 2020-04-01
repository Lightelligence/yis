load(":test.bzl", "golden_pkg_tests", "golden_intf_tests")

golden_pkg_tests(
    deps = {
        "test_pkg_a" : [],
        "test_pkg_b" : ["golden_inputs/test_pkg_a.yis"],
    }
)

golden_intf_tests(
    deps = {
        "test_intf_c" : [
            "golden_inputs/test_pkg_a.yis",
            "golden_inputs/test_pkg_b.yis",
            ],
    }
)
