package(default_visibility = ["//visibility:public"])

load("@com_google_protobuf//:protobuf.bzl", "py_proto_library", "cc_proto_library")

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


