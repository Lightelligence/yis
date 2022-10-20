"""Load the dependencies for this project."""

load("@rules_verilog//:deps.bzl", "verilog_dependencies")

def yis_dependencies(name = "_unused_variable"):  # buildifier: disable=unused-variable
    verilog_dependencies()
