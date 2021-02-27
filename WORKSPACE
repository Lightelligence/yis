workspace(name = "yis")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "com_google_protobuf",
    commit = "fe1790ca0df67173702f70d5646b82f48f412b99",
    remote = "https://github.com/protocolbuffers/protobuf",
    shallow_since = "1576187991 -0800",
)

http_archive(
    name = "com_google_protobuf_buildifier",
    strip_prefix = "protobuf-52b2447247f535663ac1c292e088b4b27d2910ef",
    urls = ["https://github.com/protocolbuffers/protobuf/archive/52b2447247f535663ac1c292e088b4b27d2910ef.zip"],
)

load("@com_google_protobuf//:protobuf_deps.bzl", "protobuf_deps")

protobuf_deps()

http_archive(
    name = "rules_verilog",
    urls = ["https://github.com/Lightelligence/rules_verilog/archive/v0.0.0.tar.gz"],
    sha256 = "ab64a872410d22accb383c7ffc6d42e90f4de40a7cd92f43f4c26471c4f14908",
    strip_prefix = "rules_verilog-0.0.0",
)

git_repository(
    name = "project_doc_server",
    commit = "17ad3f72730d1b6f35caeac9948b9b06130b842a",
    remote = "git@ssh.dev.azure.com:v3/LightelligencePlatform/project_doc_server/project_doc_server",
    shallow_since = "1613180335 +0000",
)
