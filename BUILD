load("@pip_deps//:requirements.bzl", "requirement")

package(default_visibility = ["//visibility:public"])

all_jinja_templates = glob(["templates/**"])

all_yamale_schemas = glob(["yamale_schemas/**"])

py_binary(
    name = "yis_gen",
    srcs = ["yis_gen.py"],
    data = all_jinja_templates + all_yamale_schemas,
    deps = [
        ":cmn_logging",
        requirement("astor"),
        requirement("jinja2"),
        requirement("pyyaml"),
        requirement("yamale"),
    ],
)

py_library(
    name = "cmn_logging",
    srcs = ["cmn_logging.py"],
)

exports_files([
    "rst_html_wrapper.template",
])
