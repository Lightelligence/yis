# What is YIS?
YIS stands for YAML Interface Specification.
It is a tool that allows designers to specify SystemVerilog package definitions and inter-block interfaces using YAML.
YIS converts these specifications to RTL, HTML documentation, and other output formats.
The HTML documentation is automatically updated on a webpage whenever a new change is pushed to master.  

Specifications are broken up into two types of files - pkg (package) files and intf (interface) files.
pkg files specify the underlying SV primitives (localparams, enums, typedefs, structs, and unions) that need to be used for intf definitions.
intf files contain no primitive declarations.
Instead, they define one or more components that constitute a higher-level interface between two blocks (for example, a handshake protocol), and each component has one or more connections (the actual RTL ports).  

Both pkgs and intfs may reference other pkgs, but intfs are considered to be top-level specifications and can't be referenced by pkgs or other intfs.
Every item in any pkg must define a name and doc_summary (short form documentation).
Additionally, every item may define a doc_verbose (long form multi-line documentation).
You may create cross references to other yis types inside doc_summary and doc_verbose by enclosing the type in square braces.

# Running YIS
YIS is run under bazel.
In order to run YIS on pkgs and intfs, your BUILD file needs to load the appropriate rules from @yis//:yis.bzl and the rules need to be added to your BUILD file.
YIS target in your BUILD file generates the collateral for one YIS file.

## yis_pkg
The yis_pkg rule creates the RTL and docs collateral for a single pkg.
The pkg_deps argument is an in-order list of the YIS pkgs that must be parsed before parsing the target pkg.
This list may be empty. The pkg argument is the target pkg that you want to generate RTL and docs collateral for.  

Note that YIS-generated packages use the `_rypkg.svh` suffix, which stands for "RTL YIS pkg".
This is to disambiguate from future DV YIS pkgs, and other tools that generate RTL and DV pkgs.

## yis_intf
The yis_intf rule is similar to the yis_pkg rule.
pkgs_deps is the list of pkgs that must be parsed before parsing the target intf file. intf is the target to generate docs collateral for.

# pkgs
A pkg defines the SV primitives that can be used in an intf definition.
Additionally, they can be used to specify any primitive to generate documentation.  

Any type or width field within a package can reference local and external definitions.
External definitions must be referenced with the pkg scope operator "::".

## localparams
localparams require a name, doc_summary, width, and value.
width and value may either be int or can reference other localparams. localparams names must be ALL_CAPS and must not end in `_E`.

## enums
enums require a name, doc_summary, width, and a list of values.
width can either be an int or reference a localparam. enums names must be ALL_CAPS and end in `_E`.

### enum-values
enum-values require a name, doc_summary, and optionally specify a value.
If a value is specified, all enum-values under the same enum type must have a value specified. enum-value names must be ALL_CAPS and must not end with `_E`.

## typedefs
typedefs require a name, doc_summary, a base_type (basically, the thing you're arraying) and a width (the number of base_types that you're arraying).
typedef names must be lower_case and end in `_t`.
base_type can be "logic", "wire", an enum, a struct, a union, or another typedef.
width can be an int or a localparam.

Explicit multidimensional typedefs are not supported.
Instead, multidimensional typedefs can be created by cascading several typedefs.

## structs
typdefs require a name, doc_summary, and a list of fields.
struct names must be lower_case and end with `_t`.
The first field in the list of fields is the most significant field.

### struct fields
struct fields require a name, a doc_summary, a type, and optionally a width.
Width is required if type is "logic" or "wire" and is illegal otherwise.
A width can be a localparam. A type can be "logic", "wire", or an enum, struct, a union, or typedef.  

struct fields can optionally use a shortcut for both doc_summary and doc_verbose.
If the field is using a localparam for a width, doc_summary and doc_verbose can both be "width.doc_summary" or "width.doc_verbose".
This copies the source's doc_* field into this field.
If the field is using something other than "logic" or "width" for type, type.doc_summary and type.doc_verbose can be used to copy the doc from the referenced type.

## Unions
Unions behave very very similarly to structs, including naming conventions and breakdown per field.
The main difference is that all fields of a union must be the same size.
YIS does not implicitly do any padding to make 2 differently-sized structs to fit into an enum together.

## Transactions (Xactions)
Transactions (shortened in YIS to xactions) are the only item that can be defined in a YIS pkg that isn't an SV primitive.
However, it provides a way to define multi-cycle xactions that use the other defined items.
Definiting an xaction in a provides consistency/naming checking for individual cycles, generates structs DV can use, and generates HTML documentation to help visualize the full transaction.  

xactions are defined nearly identically to structs.
The only exception is that the "fields" key is calls "cycles".
The first cycle in the list of cycles is cycle 0.

# intfs
An intf uses the primitives defined in pkgs to describe the interface between two blocks.
An intf consists of one or more components, and each component consists of one or more connections.  

components are groups of individual port-to-port connections that constitute a higher-level protocol or logical grouping of signals.
Ports describe how an component looks like in terms of width and direction.
Connections describe if an component is instantiated multiple times.
For example, if two blocks had a `val/rdy` handshake, the `val` and `rdy` are ports described in `ports` section.
If this same handshake ports are used multiply to connecting other blocks, those are described inthe `connections` section.
Both ports and connections would be contained within a component.

## components
An intf can have several components, where each component describes a independent logical function.
Components require a name, doc_summary, and a list of connections.

## connections
Connections defines the number of instantiation of component.
Connections require a name, optional doc_summary

## ports
Ports defines the structure such as width and direction of component.
Ports require a name, doc_summary, a type, a direction, and an optional width.
The specification schema for ports is otherwise very similar to struct fields with one major exception.
A port that has `logic` or `wire` as a type must either have a width of 1 or use a localparam.
If a port needs to be wider than 1-bit, the width must be declared in a pkg and referenced.

# Dependencies
YIS depends on [Bazel](https://bazel.build/), [rules_verilog](https://github.com/Lightelligence/rules_verilog), and some python packages.
YIS was tested against `Bazel` version 5.2.0 and `rules_verilog` version 0.1.0.
The python dependencies are listed in env/requirements.txt but aren't automatically pulled in via Bazel.
They are instead already expected to be available modules.
Lightelligence uses [conda](https://docs.conda.io/en/latest/) to manage python dependency versions.

# Usage
The following sample code shows how to instantiate a YIS target in a BUILD file.
In this example, `foo.yis` has no dependencies, `bar.yis` depends on `common.yis` from another directory, and `zip.yis` depends on both `foo.yis` and `bar.yis`.


```
load("@yis//:yis.bzl", "yis_pkg")

yis_pkg(
    name = "foo_yis",
    pkg = ":foo.yis",
    pkg_deps = [],
)

yis_pkg(
    name = "bar_yis",
    pkg = ":bar.yis",
    pkg_deps = [
        "//digital/rtl/common:common.yis"
    ],
)

yis_pkg(
    name = "zip_yis",
    pkg = ":zip.yis",
    pkg_deps = [
        ":foo.yis",
        "//digital/rtl/common:common.yis"
        ":bar.yis",
    ],
)
```
It's important to note that YIS can't compute transitive dependencies.
In this example, that means that even if `zip.yis` doesn't explicitly depend on `common.yis`,
the `zip_yis` macro must still list `common.yis` in the `pkg_deps` list before `bar.yis`.
YIS can't automatically determine that `common.yis` is a transitive dependency of `zip.yis`.

For full examples, see the `tests/golden_inputs` and `tests/golden_outputs` directories.
