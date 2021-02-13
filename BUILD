package(default_visibility = ["//visibility:public"])

all_jinja_templates = glob(["templates/**"])

all_yamale_schemas = glob(["yamale_schemas/**"])

py_library(
    name = "instruction",
    srcs = ["instruction.py"],
    deps = ["//yis_sdk:instruction_proto_py"],
)

py_binary(
    name = "yis_gen",
    srcs = ["yis_gen.py"],
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
