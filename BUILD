package(default_visibility = ["//visibility:public"])

load("@com_google_protobuf//:protobuf.bzl", "py_proto_library", "cc_proto_library")

all_jinja_templates = glob(["templates/**"])

all_yamale_schemas = glob(["yamale_schemas/**"])

filegroup(
    name = "instruction_proto_proto_srcs",
    srcs = ["instruction.proto"],
)

cc_proto_library(
    name = "instruction_proto_cc",
    srcs = ["instruction.proto"],
)

py_proto_library(
    name = "instruction_proto_py",
    srcs = ["instruction.proto"],
)

py_library(
    name = "instruction",
    srcs = ["instruction.py"],
    deps = [":instruction_proto_py"],
)

py_binary(
    name = "yis",
    srcs = ["yis.py"],
    data = all_jinja_templates + all_yamale_schemas,
    deps = [
        ":instruction",
        ":gen_prot",
        ":cmn_logging",
    ],
)

py_library(
    name = "cmn_logging",
    srcs = ["cmn_logging.py"],
)

py_binary(
    name = "gen_prot",
    srcs = ["gen_prot.py"],
    deps = [":cmn_logging"],
)
