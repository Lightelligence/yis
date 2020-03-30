"""YAML Interface Spec parser and generator."""
################################################################################
# stdlib
import argparse
import sys
import os
import re
from collections import OrderedDict
from datetime import date

from jinja2 import Template

import yaml
try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader as Loader # pylint: disable=useless-import-alias

################################################################################
from scripts import cmn_logging

################################################################################
# Constants
PACKAGE_SCOPE_REGEXP = re.compile("(.*)::(.*)")

RTL_PKG_TEMPLATE = Template("""// Copyright (c) {{ year }} Lightelligence
//
// Description: SV Package generated from {{ package.name }}.yis by YIS

`ifndef __{{ package.name | upper }}_SVH__
  `define __{{ package.name | upper }}_SVH__

package {{ package.name }};

  // localparams
  {% for localparam in package.localparams.values() %}
  {{ localparam.render_rtl_sv_pkg() }}
  {% endfor %}
  // enums
  {% for enum in package.enums.values() %}
  {{ enum.render_rtl_sv_pkg() }}
  {% endfor %}
  // structs
  {% for struct in package.structs.values() %}
  {{ struct.render_rtl_sv_pkg() }}
  {% endfor %}

endpackage : {{ package.name }}
`endif
""")

################################################################################
# Helpers

def parse_args(argv):
    """Parse script arguments."""
    parser = argparse.ArgumentParser(description="Parse an interface spec and generate the associated collateral.",
                                     formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument('--packages',
                        nargs='*',
                        help="YAML files defining packages needed for block interfaces")

    parser.add_argument('--block-interface',
                        nargs='?',
                        help="YAML file defining block-to-block interface")

    parser.add_argument('--output-file',
                        required=True,
                        help="Path to the output file, which might either be a packge or a block interface.")

    parser.add_argument('--tool-debug',
                        default=False,
                        action='store_true',
                        help='Set the verbosity of this tool to debug level.')

    options = parser.parse_args(argv)
    return options

################################################################################
# Classes

class LinkError(Exception):
    """Error raised when a link or a cross-link can't resolve."""
    pass # pylint: disable=unnecessary-pass

class Yis:
    """Yaml Interface Spec parser and generator class."""
    def __init__(self, block_interface, packages, log):
        self._block_interface = block_interface
        self._packages = packages
        self.log = log
        self.packages = OrderedDict()
        self.interfaces = {}

    def parse_packages(self):
        """Parse all packages."""
        for fname in self._packages:
            self._parse_one_package(fname)

    def _parse_one_package(self, fname):
        try:
            with open(fname) as yfile:
                data = yaml.load(yfile, Loader)
                package_name = os.path.splitext(os.path.basename(fname))[0]
                new_package = Package(log=self.log,
                                      name=package_name,
                                      parent=self,
                                      **data)
                self.packages[package_name] = new_package
        except IOError:
            self.log.critical("Couldn't open {}".format(fname))

    def link_symbols(self):
        """Walk all children, link the appropriate types, fields, etc."""
        # Localparams are always first
        for package in self.packages.values():
            package.resolve_links()
        self.log.exit_if_warnings_or_errors("Found errors linking packages")

    def resolve_symbol(self, link_package, link_symbol, symbol_types):
        """Attempt to find a symbol in the specified package, raise a LinkError if it can't be found."""
        self.log.debug("Attempting to link %s::%s" % (link_package, link_symbol))
        try:
            return self.packages[link_package].resolve_inbound_symbol(link_symbol, symbol_types)
        except KeyError:
            self.log.error(F"{link_package} not a defined package")
            raise LinkError


class SpecNode: # pylint: disable=too-few-public-methods
    """Base class for any type of specification."""
    def __init__(self, **kwargs):
        self.log = kwargs.pop('log')
        self.name = kwargs.pop('name')
        self.doc_summary = kwargs.pop('doc_summary')
        self.doc_verbose = kwargs.pop('doc_verbose', None)


class Package(SpecNode):
    """Class to hold a set of PackageItemBase objects, representing the whole package."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.finished_link = False
        self.parent = kwargs.pop('parent')
        self.localparams = OrderedDict()
        self.enums = OrderedDict()
        self.structs = OrderedDict()
        self.children = OrderedDict()
        for row in kwargs.get('localparams', []):
            PackageLocalparam(parent=self, log=self.log, **row)
        for row in kwargs.get('enums', []):
            PackageEnum(parent=self, log=self.log, **row)
        for row in kwargs.get('structs', []):
            PackageStruct(parent=self, log=self.log, **row)

    def add_child(self, child):
        """Add a child item to this package."""
        if child.name in self.children:
            raise ValueError(F"{child.name} already exists in {self.name} as a {type(self.children[child.name])}")

        self.children[child.name] = child
        if isinstance(child, PackageLocalparam):
            self.localparams[child.name] = child
        elif isinstance(child, PackageEnum):
            self.enums[child.name] = child
        elif isinstance(child, PackageStruct):
            self.structs[child.name] = child
        else:
            raise ValueError(F"Can't add {child.name} to package {self.name} becuase it is a {type(child)}. "
                             "Can only add localparams, enums, and structs.")

    def resolve_links(self):
        """Find and resolve links between types starting at localparms, then enums, then structs."""
        self.log.debug("Attempting to resolve links in %s" % (self.name))
        self.finished_link = True
        for localparam in self.localparams.values():
            localparam.resolve_width_links()

        for enum in self.enums.values():
            enum.resolve_width_links()

        for struct in self.structs.values():
            struct.resolve_width_links()
            struct.resolve_type_links()
            struct.resolve_doc_links()

    def resolve_outbound_symbol(self, link_package, link_symbol, symbol_types):
        """Resolve links leaving this package."""
        self.log.debug("Attempting to resolve outbound link from %s to %s::%s" % (self.name, link_package, link_symbol))
        return self.parent.resolve_symbol(link_package, link_symbol, symbol_types)

    def resolve_inbound_symbol(self, link_symbol, symbol_types):
        """Resolve a link from another package attempting to reference a symbol in this package."""
        self.log.debug("Attempting to resolve an inbound link %s::%s of types %s" % (self.name,
                                                                                     link_symbol,
                                                                                     symbol_types))
        if not self.finished_link:
            self.log.error(F"Can't resolve {link_symbol} into {self.name}, it hasn't been compiled yet")
            raise LinkError

        for symbol_type in symbol_types:
            try:
                self.log.debug("Looking for a(n) %s link to %s::%s" % (symbol_type, self.name, link_symbol))
                return getattr(self, symbol_type)[link_symbol]
            except KeyError:
                pass

        self.log.error(F"Can't find {link_symbol} in package {self.name} for types {symbol_types}")
        raise LinkError

    def __repr__(self):
        return (F"Package name: {self.name}\n"
                "Localparams:\n  -{localparams}\n"
                "Enums:\n  -{enums}\n"
                "Structs:\n  -{structs}\n"
                .format(localparams="\n  -".join([str(param) for param in self.localparams.values()]),
                        enums="\n  -".join([str(param) for param in self.enums.values()]),
                        structs="\n  -".join([str(param) for param in self.structs.values()])))


class PackageItemBase(SpecNode):
    """Base class for all objects contained in a package."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.parent = kwargs.pop('parent')
        self.parent.add_child(self)
        self.children = {}
        self.render_width = None

    def add_child(self, child):
        """Add a child item to this package."""
        if child.name in self.children:
            raise ValueError(F"{child.name} already exists in {self.name} as a {type(self.children[child.name])}")
        self.children[child.name] = child

    def _get_parent_localparams(self):
        parent = self.parent
        while True:
            try:
                return parent.localparams
            except AttributeError:
                parent = parent.parent

    def get_parent_package(self):
        """Recursively walks up parents until a Package is found, returns the Package instance."""
        parent = self.parent
        while True:
            if isinstance(parent, Package):
                return parent
            parent = parent.parent

    def resolve_width_links(self):
        """Resolve links in width. Resolving links in value gets dicey."""
        # If self.width is already an int, don't try to resolve a link
        if not isinstance(self.width, int):
            self.log.debug("%s, width %s is a type that must be linked" % (self.name, self.width))
            localparams = self._get_parent_localparams()
            match = PACKAGE_SCOPE_REGEXP.match(self.width)
            # If it looks like we're scoping out of package
            if match:
                link_package = match.group(1)
                link_symbol = match.group(2)
                try:
                    self.log.debug("Attempting to resolve external %s::%s" % (link_package, link_symbol))
                    self.width = self.get_parent_package().resolve_outbound_symbol(link_package,
                                                                                   link_symbol,
                                                                                   ["localparams"])
                    self.render_width = self.width.name
                except LinkError:
                    self.log.error(F"Couldn't resolve a link from %s to %s" % (self.name, self.width))
            # If it doesn't look like we're scoping out of package, try to look in this package
            elif self.width in localparams:
                self.log.debug("%s is a valid localparam in package %s" % (self.width, self.get_parent_package()))
                self.width = localparams[self.width]
            else:
                self.log.error(F"Couldn't resolve a width link for {self.name} to {self.width}")

    def _render_rtl_comment_docs(self, indent_width):
        """Return array of strings that print doc_summary and doc_verbose for RTL."""
        indent_spaces = " " * indent_width
        ret_arr = []
        if self.doc_verbose is not None:
            split_verbose = self.doc_verbose.splitlines()
            ret_arr.append("// {}".format("\n{}// ".format(indent_spaces).join(split_verbose)))
        return ret_arr

    def _get_render_width(self):
        if not isinstance(self.width, int) and (self.get_parent_package() is not self.width.get_parent_package()):
            ret_str = F"{self.width.parent.name}::{self.width.name}"
        elif isinstance(self.width, int):
            ret_str = self.width
        else:
            ret_str = self.width.name
        return ret_str


class PackageLocalparam(PackageItemBase):
    """Definition for a localparam in a package."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.width = kwargs.pop('width')
        self.value = kwargs.pop('value')

    def __repr__(self):
        return F"{id(self)} {self.name}, width {self.width}, value {self.value}"

    def render_rtl_sv_pkg(self):
        """Render the SV for this localparam.

        The general form is:
        // doc_summary
        // (optional) doc_verbose
        localparam [WIDTH - 1:0] NAME = VALUE;

        Pay careful attention to how to pull out width, because width either points to an int or
        it points to another PackageLocalparam.
        """
        ret_arr = self._render_rtl_comment_docs(2)
        render_width = self._get_render_width()
        ret_arr.append(F"localparam [{render_width} - 1:0] {self.name} = {self.value}; // {self.doc_summary}")
        return "\n  ".join(ret_arr)


class PackageEnum(PackageItemBase):
    """Definition for an enum inside a package."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.width = kwargs.pop('width')
        self.enum_values = []
        for row in kwargs.pop('values'):
            self.enum_values.append(PackageEnumValue(parent=self, log=self.log, **row))

    def __repr__(self):
        values = "\n    -".join([str(enum) for enum in self.enum_values])
        return F"{id(self)} {self.name}, width {self.width}, values:\n    -{values}"

    def render_rtl_sv_pkg(self):
        """Render the SV for this enum.

        The general form is:
        // doc_summary
        // (optional) doc_verbose
        typedef enum logic [WIDTH - 1:0] {
          // enum_values
        } NAME;
        """
        ret_arr = self._render_rtl_comment_docs(2)
        render_width = self._get_render_width()
        ret_arr.append(F"type enum logic [{render_width} - 1:0] {{")

        # Render each enum_value, note they are 2 indented farther
        enum_value_arr = []
        for row in self.enum_values:
            enum_value_arr.extend(row.render_rtl_sv_pkg())

        # Add leading spaces to make all enum_values line up
        enum_value_arr[0] = F"  {enum_value_arr[0]}"

        # Strip trailing comma from last enum_value
        enum_value_arr[-1] = enum_value_arr[-1][:-1]

        ret_arr.append("\n    ".join(enum_value_arr))
        ret_arr.append(F"}} {self.name}; // {self.doc_summary}")
        return "\n  ".join(ret_arr)


class PackageEnumValue(PackageItemBase):
    """Definition for a single item value."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.enum_value = kwargs.pop('value')

    def __repr__(self):
        return F"{id(self)} {self.name}, value {self.enum_value}"

    def render_rtl_sv_pkg(self):
        """Render RTL in a SV package for this enun value."""
        ret_arr = self._render_rtl_comment_docs(4)
        ret_arr.append(F"{self.name}, // {self.doc_summary}")
        return ret_arr


class PackageStruct(PackageItemBase):
    """Definition for a localparam inside a package."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.fields = []
        for row in kwargs.pop('fields'):
            self.fields.append(PackageStructField(parent=self, log=self.log, **row))

    def __repr__(self):
        fields = "\n    -".join([str(field) for field in self.fields])
        return F"{id(self)} {self.name}, fields:\n    -{fields}"

    def resolve_width_links(self):
        """Override superclass definition of resolve_width_links to know how to resolve width links in each field."""
        for field in self.fields:
            field.resolve_width_links()

    def resolve_type_links(self):
        """Resolve type links for each field in a struct."""
        for field in self.fields:
            if field.field_type not in ['logic', 'wire']:
                field.resolve_type_links()

    def resolve_doc_links(self):
        """Resolve links to doc_verbose and doc_summary for each field in a struct."""
        for field in self.fields:
            field.resolve_doc_links()

    def render_rtl_sv_pkg(self):
        """Render the SV for this struct.

        The general form is:
        // (optional) doc_verbose
        typedef struct packed {
          // struct_fields
        } NAME;
        """
        ret_arr = self._render_rtl_comment_docs(2)
        ret_arr.append(F"typedef struct packed {{")

        # Render each field, note they are 2 indented farther
        field_arr = []
        for row in self.fields:
            field_arr.extend(row.render_rtl_sv_pkg())

        # Add leading spaces to make all fields line up
        field_arr[0] = F"  {field_arr[0]}"

        ret_arr.append("\n    ".join(field_arr))
        ret_arr.append(F"}} {self.name}; // {self.doc_summary}")
        return "\n  ".join(ret_arr)


class PackageStructField(PackageItemBase):
    """Definition for a single field inside a struct."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.field_type = kwargs.pop('type')
        self.width = kwargs.pop('width', None)

    def __repr__(self):
        return F"{id(self)} type {self.field_type} width {self.width}"

    def _get_render_type(self):
        if self.get_parent_package() is not self.field_type.get_parent_package():
            return F"{self.field_type.parent.name}::{self.field_type.name}"
        return F"{self.field_type.name}"

    def resolve_width_links(self):
        """Override superclass resolve_width_links to not call """
        if self.field_type in ["logic", "wire"]:
            super().resolve_width_links()

    def resolve_type_links(self):
        """Resolve links in type."""
        # If field_type is a logic or a wire, don't need to resolve a type
        self.log.debug("%s type %s is a type that must be linked" % (self.name, self.field_type))
        parent_package = self.get_parent_package()
        match = PACKAGE_SCOPE_REGEXP.match(self.field_type)
        # If it looks like we're scoping out of package
        if match:
            link_package = match.group(1)
            link_symbol = match.group(2)
            try:
                self.log.debug("Attempting to resolve external %s::%s" % (link_package, link_symbol))
                self.field_type = parent_package.resolve_outbound_symbol(link_package,
                                                                         link_symbol,
                                                                         ["structs", "enums"])
            except LinkError:
                self.log.error(F"Couldn't resolve a link from {self.name} to {self.width}")
        # If it doesn't look like we're scoping out of package, try to look in this package
        elif self.field_type in parent_package.enums:
            self.log.debug("%s type %s is a valid enum in package %s" % (self.name, self.field_type, parent_package))
            self.field_type = parent_package.enums[self.field_type]
        elif self.field_type in parent_package.structs:
            self.log.debug("%s type %s is a valid struct in package %s" % (self.name, self.field_type, parent_package))
            self.field_type = parent_package.structs[self.field_type]
        else:
            self.log.error("Couldn't resolve a width link for {self.name} to {self.width}")

    def resolve_doc_links(self):
        """Resolve basic doc_* links from :FROM_TYPE to the original definition."""
        for doc_type in ['doc_summary', 'doc_verbose']:
            self.log.debug(F"Looking for {doc_type} on {self.name}")
            doc_attr = getattr(self, doc_type)
            if doc_attr == "FROM_TYPE":
                if self.field_type in ["logic", "wire"]:
                    try:
                        setattr(self, doc_type, getattr(self.width, doc_type))
                        self.log.debug(F"Linked up doc for {self.width.name}, it is now {getattr(self, doc_type)}")
                    except AttributeError:
                        self.log.error(F"{self.get_parent_package()}::{self.parent.name}.{self.name} "
                                       F"can't use a \"FROM_TYPE\" "
                                       F"{doc_type} link unless \"width\" field points to a localparam")
                else:
                    try:
                        setattr(self, doc_type, getattr(self.field_type, doc_type))
                        self.log.debug(F"Linked up doc for {self.field_type.name}, it is now {getattr(self, doc_type)}")
                    except AttributeError:
                        self.log.error(F"{self.get_parent_package()}::{self.parent.name}.{self.name} "
                                       F"can't use a \"FROM_TYPE\" "
                                       F"{doc_type} link unless \"type\" field points to a valid type")

    def render_rtl_sv_pkg(self):
        """Render RTL in a SV package for this enun value."""
        if self.field_type in ["logic", "wire"]:
            render_width = self._get_render_width()
            render_type = F"{self.field_type} [{render_width} - 1:0]"
            if render_width == "1":
                render_type = F"{self.field_type}"
        else:
            render_type = self._get_render_type()
        ret_arr = self._render_rtl_comment_docs(4)
        ret_arr.append(F"{render_type} {self.name}; // {self.doc_summary}")

        return ret_arr


def main(options, log):
    """Main execution."""
    if (not options.packages) and (not options.block_interface):
        log.critical("Didn't find anything to render via cmd line. Must render at least 1 package or a block interface")

    yis = Yis(options.block_interface, options.packages, log)
    yis.parse_packages()
    yis.link_symbols()
    for package in yis.packages.values():
        log.debug(F"Package {repr(package)}")

    # if a block_interface is defined, that's the thing we need to render. Parse it first, then render it
    if options.block_interface:
        pass # FIXME # pylint: disable=fixme,unnecessary-pass
    # If it isn't defined, assume we're rendering a package. Assume the package to render is the last one in the args
    else:
        target_pkg = next(reversed(yis.packages))
        fname = options.output_file
        year = date.today().year
        with open(fname, 'w') as fileh:
            log.info("Writing " + os.path.abspath(fname))
            fileh.write(RTL_PKG_TEMPLATE.render(year=year, package=yis.packages[target_pkg]))
#    yis.parse_block_interface()
#     yis.print_all_packages()

def setup_context():
    """Set up options, log, and other context for main to run."""
    options = parse_args(sys.argv[1:])
    verbosity = cmn_logging.DEBUG if options.tool_debug else cmn_logging.INFO
    log = cmn_logging.build_logger("yis", level=verbosity)
    main(options, log)

if __name__ == "__main__":
    setup_context()
