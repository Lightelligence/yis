"""Load the dependencies for this project."""

load("@rules_python//python:pip.bzl", "pip_install")
load("@rules_verilog//:deps.bzl", "verilog_dependencies")

def yis_dependencies(name = "_unused_variable"):  # buildifier: disable=unused-variable
    pip_install(
        name = "pip_deps",
        requirements = "@yis//env:requirements.txt",
    )

    verilog_dependencies()
