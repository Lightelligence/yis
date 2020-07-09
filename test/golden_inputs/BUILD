package(default_visibility = ["//visibility:public"])

load(":test.bzl", "golden_fifo_tests", "golden_intf_tests", "golden_mem_tests", "golden_pkg_tests")
#load("//:yis.bzl", "yis_rtl_mem")  # @unused

golden_pkg_tests(
    deps = {
        "test_pkg_a": [],
        "test_pkg_b": ["test_pkg_a.yis"],
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

# yis_rtl_mem(
#     name = "test_mem_a",
#     mem = ":test_mem_a.yis",
#     pkg_deps = [":test_pkg_a.yis",],
#     sram_deps = [
#         "//digital/rtl/common:sadglsph4s2p768x16m4b8w0c1p0d0r1s10",
#         "//digital/rtl/common:sad2lsph4s1p784x16m4b1w0c1p0d0r3s10",
#         ],
# )

# FIXME external reference
# golden_mem_tests(
#     deps = {
#         "test_mem_a": [
#             "test_pkg_a.yis",
#             "//digital/rtl/common:sadglsph4s2p768x16m4b8w0c1p0d0r1s10",
#             "//digital/rtl/common:sad2lsph4s1p784x16m4b1w0c1p0d0r3s10",
#         ],
#     },
# )

# FIXME external reference
# golden_fifo_tests(
#     deps = {
#         "test_fifo_a": [
#         ],
#     },
# )

exports_files([
    "test_pkg_a.yis",
    "test_mem_a.yis",
])
