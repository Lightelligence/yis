"""Load external repos into this project's namespace."""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def yis_repos(name = "_unused_variable"):  # buildifier: disable=unused-variable
    http_archive(
        name = "rules_python",
        sha256 = "a3a6e99f497be089f81ec082882e40246bfd435f52f4e82f37e89449b04573f6",
        strip_prefix = "rules_python-0.10.2",
        url = "https://github.com/bazelbuild/rules_python/archive/refs/tags/0.10.2.tar.gz",
    )

    http_archive(
        name = "rules_verilog",
        urls = ["https://github.com/Lightelligence/rules_verilog/archive/v0.1.0.tar.gz"],
        sha256 = "c1d2ad196f0cfc14330241028b3bc231f282c468acb8535cf0891a580413c227",
        strip_prefix = "rules_verilog-0.1.0",
    )
