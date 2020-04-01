"""YAML Interface Spec parser and generator."""
################################################################################
# stdlib
import argparse
import sys
import os
import re
import textwrap
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
PKG_SCOPE_REGEXP = re.compile("(.*)::(.*)")

RTL_INTF_TEMPLATE = Template("""
""")

RTL_PKG_TEMPLATE = Template("""// Copyright (c) {{ year }} Lightelligence
//
// Description: SV Pkg generated from {{ pkg.name }}.yis by YIS

`ifndef __{{ pkg.name | upper }}_PKG_SVH__
  `define __{{ pkg.name | upper }}_PKG_SVH__

{{ pkg.render_doc_verbose(0) }}
package {{ pkg.name }}; // {{ pkg.doc_summary }}

  /////////////////////////////////////////////////////////////////////////////
  // localparams
  /////////////////////////////////////////////////////////////////////////////
  {% for localparam in pkg.localparams.values() %}
  {{ localparam.render_rtl_sv_pkg() }}
  {% endfor %}
  /////////////////////////////////////////////////////////////////////////////
  // enums
  /////////////////////////////////////////////////////////////////////////////
  {% for enum in pkg.enums.values() %}
  {{ enum.render_rtl_sv_pkg() }}
  {% endfor %}
  /////////////////////////////////////////////////////////////////////////////
  // structs
  /////////////////////////////////////////////////////////////////////////////
  {% for struct in pkg.structs.values() %}
  {{ struct.render_rtl_sv_pkg() }}
  {% endfor %}

endpackage : {{ pkg.name }}
`endif // guard
""")

################################################################################
# Helpers

def parse_args(argv):
    """Parse script arguments."""
    parser = argparse.ArgumentParser(description="Parse an interface spec and generate the associated collateral.",
                                     formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument('--pkgs',
                        nargs='*',
                        help="YAML files defining pkgs needed for block interfaces")

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
    def __init__(self, block_interface, pkgs, log):
        self._block_interface = block_interface
        self._pkgs = pkgs
        self.log = log
        self.pkgs = OrderedDict()
        self.block_interface = None

    def parse_pkgs(self):
        """Parse all pkgs."""
        for fname in self._pkgs:
            self._parse_one_pkg(fname)

    def _parse_one_pkg(self, fname):
        try:
            with open(fname) as yfile:
                data = yaml.load(yfile, Loader)
                pkg_name = os.path.splitext(os.path.basename(fname))[0]
                new_pkg = Pkg(log=self.log,
                              name=pkg_name,
                              parent=self,
                              **data)
                self.pkgs[pkg_name] = new_pkg
                self.log.exit_if_warnings_or_errors(F"Found errors parsing {pkg_name}")
        except IOError:
            self.log.critical("Couldn't open {}".format(fname))

    def parse_block_interface(self):
        """Parse a block interface file, deserialize into relevant objects."""
        try:
            fname = self._block_interface
            with open(fname) as yfile:
                data = yaml.load(yfile, Loader)
                interface_name = os.path.splitext(os.path.basename(fname))[0]
                self.block_interface = Intf(log=self.log,
                                            name=interface_name,
                                            parent=self,
                                            **data)
                self.log.exit_if_warnings_or_errors(F"Found errors parsing {interface_name}")
        except IOError:
            self.log.critical("Couldn't open {}".format(fname))

    def link_symbols(self):
        """Walk all children, link the appropriate types, fields, etc."""
        # Localparams are always first
        for pkg in self.pkgs.values():
            pkg.resolve_links()
        self.log.exit_if_warnings_or_errors("Found errors linking pkgs")

    def resolve_symbol(self, link_pkg, link_symbol, symbol_types):
        """Attempt to find a symbol in the specified pkg, raise a LinkError if it can't be found."""
        self.log.debug("Attempting to link %s::%s" % (link_pkg, link_symbol))
        try:
            return self.pkgs[link_pkg].resolve_inbound_symbol(link_symbol, symbol_types)
        except KeyError:
            self.log.error(F"{link_pkg} not a defined pkg")
            raise LinkError


class YisNode: # pylint: disable=too-few-public-methods
    """Base class for any type of specification."""
    def __init__(self, **kwargs):
        self.log = kwargs.pop('log')
        self.name = kwargs.pop('name')
        self.doc_summary = kwargs.pop('doc_summary')
        self.doc_verbose = kwargs.pop('doc_verbose', None)
        self.children = {}

    def render_doc_verbose(self, indent_width):
        """Render doc_verbose for a RTL_PKG template, requires an indent_width for spaces preceeding //"""
        indent_spaces = " " * indent_width
        if self.doc_verbose is not None:
            wrapper = textwrap.TextWrapper(initial_indent="// ", subsequent_indent=F"{indent_spaces}// ")
            return wrapper.fill(self.doc_verbose)
        return ""

    def add_child(self, child):
        """Add a child item to this pkg."""
        if child.name in self.children:
            self.log.error(F"{child.name} already exists in {self.name} as a "
                           F"{type(self.children[child.name]).__name__}")
        self.children[child.name] = child

class Pkg(YisNode):
    """Class to hold a set of PkgItemBase objects, representing the whole pkg."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.finished_link = False
        self.parent = kwargs.pop('parent')
        self.localparams = OrderedDict()
        self.enums = OrderedDict()
        self.structs = OrderedDict()
        self.children = OrderedDict()
        for row in kwargs.get('localparams', []):
            PkgLocalparam(parent=self, log=self.log, **row)
        for row in kwargs.get('enums', []):
            PkgEnum(parent=self, log=self.log, **row)
        for row in kwargs.get('structs', []):
            PkgStruct(parent=self, log=self.log, **row)

    def add_child(self, child):
        """Override super add_child to add in differentiation between localparams, enums, and structs."""
        super().add_child(child)

        self.children[child.name] = child
        if isinstance(child, PkgLocalparam):
            self.localparams[child.name] = child
        elif isinstance(child, PkgEnum):
            self.enums[child.name] = child
        elif isinstance(child, PkgStruct):
            self.structs[child.name] = child
        else:
            raise ValueError(F"Can't add {child.name} to pkg {self.name} becuase it is a {type(child)}. "
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

    def resolve_outbound_symbol(self, link_pkg, link_symbol, symbol_types):
        """Resolve links leaving this pkg."""
        self.log.debug("Attempting to resolve outbound link from %s to %s::%s" % (self.name, link_pkg, link_symbol))
        return self.parent.resolve_symbol(link_pkg, link_symbol, symbol_types)

    def resolve_inbound_symbol(self, link_symbol, symbol_types):
        """Resolve a link from another pkg attempting to reference a symbol in this pkg."""
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

        self.log.error(F"Can't find {link_symbol} in pkg {self.name} for types {symbol_types}")
        raise LinkError

    def __repr__(self):
        return (F"Pkg name: {self.name}\n"
                "Localparams:\n  -{localparams}\n"
                "Enums:\n  -{enums}\n"
                "Structs:\n  -{structs}\n"
                .format(localparams="\n  -".join([str(param) for param in self.localparams.values()]),
                        enums="\n  -".join([str(param) for param in self.enums.values()]),
                        structs="\n  -".join([str(param) for param in self.structs.values()])))


class PkgItemBase(YisNode):
    """Base class for all objects contained in a pkg."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.parent = kwargs.pop('parent')
        self.parent.add_child(self)
        self.children = {}
        self.render_width = None

    def _get_parent_localparams(self):
        parent = self.parent
        while True:
            try:
                return parent.localparams
            except AttributeError:
                parent = parent.parent

    def get_parent_pkg(self):
        """Recursively walks up parents until a Pkg is found, returns the Pkg instance."""
        parent = self.parent
        while True:
            if isinstance(parent, Pkg):
                return parent
            parent = parent.parent

    def resolve_width_links(self):
        """Resolve links in width. Resolving links in value gets dicey."""
        # If self.width is already an int, don't try to resolve a link
        if not isinstance(self.width, int):
            self.log.debug("%s, width %s is a type that must be linked" % (self.name, self.width))
            localparams = self._get_parent_localparams()
            match = PKG_SCOPE_REGEXP.match(self.width)
            # If it looks like we're scoping out of pkg
            if match:
                link_pkg = match.group(1)
                link_symbol = match.group(2)
                try:
                    self.log.debug("Attempting to resolve external %s::%s" % (link_pkg, link_symbol))
                    self.width = self.get_parent_pkg().resolve_outbound_symbol(link_pkg,
                                                                               link_symbol,
                                                                               ["localparams"])
                    self.render_width = self.width.name
                except LinkError:
                    self.log.error(F"Couldn't resolve a link from %s to %s" % (self.name, self.width))
            # If it doesn't look like we're scoping out of pkg, try to look in this pkg
            elif self.width in localparams:
                self.log.debug("%s is a valid localparam in pkg %s" % (self.width, self.get_parent_pkg().name))
                self.width = localparams[self.width]
            else:
                self.log.error(F"Couldn't resolve a width link for {self.name} to {self.width}")

    def _get_render_width(self):
        if not isinstance(self.width, int) and (self.get_parent_pkg() is not self.width.get_parent_pkg()):
            ret_str = F"{self.width.parent.name}::{self.width.name}"
        elif isinstance(self.width, int):
            ret_str = self.width
        else:
            ret_str = self.width.name
        return ret_str


class PkgLocalparam(PkgItemBase):
    """Definition for a localparam in a pkg."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.width = kwargs.pop('width')
        self.value = kwargs.pop('value')
        self._check_naming_conventions()

    def _check_naming_conventions(self):
        if not self.name.isupper():
            self.log.error(F"{self.get_parent_pkg().name}::{self.name} doesn't comply with naming conventions. "
                           F"localparam names must be uppercase")

    def __repr__(self):
        return F"{id(self)} {self.name}, width {self.width}, value {self.value}"

    def render_rtl_sv_pkg(self):
        """Render the SV for this localparam.

        The general form is:
        // doc_summary
        // (optional) doc_verbose
        localparam [WIDTH - 1:0] NAME = VALUE;

        Pay careful attention to how to pull out width, because width either points to an int or
        it points to another PkgLocalparam.
        """
        ret_arr = [self.render_doc_verbose(2)]
        render_width = self._get_render_width()
        ret_arr.append(F"localparam [{render_width} - 1:0] {self.name} = {self.value}; // {self.doc_summary}")
        return "\n  ".join(ret_arr)


class PkgEnum(PkgItemBase):
    """Definition for an enum inside a pkg."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.width = kwargs.pop('width')
        self.enum_values = []
        for row in kwargs.pop('values'):
            self.enum_values.append(PkgEnumValue(parent=self, log=self.log, **row))
        self._check_naming_conventions()

    def _check_naming_conventions(self):
        if not (self.name.isupper() and self.name[-2:] == "_E"):
            self.log.error(F"{self.get_parent_pkg().name}::{self.name} doesn't comply with naming conventions. "
                           F"Enum names must be uppercase and end with _E")
        for enum_value in self.enum_values:
            if not enum_value.name.isupper():
                self.log.error(F"{self.get_parent_pkg().name}::{self.name}.{enum_value.name} doesn't comply "
                               F"with naming conventions. Enum values must be uppercase")

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
        ret_arr = [self.render_doc_verbose(2)]
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


class PkgEnumValue(PkgItemBase):
    """Definition for a single item value."""
    def __repr__(self):
        return F"{id(self)} {self.name}"

    def render_rtl_sv_pkg(self):
        """Render RTL in a SV pkg for this enun value."""
        ret_arr = [self.render_doc_verbose(4)]
        # Strip _E from the rendered RTL name
        parent_base_name = self.parent.name[-2:]
        ret_arr.append(F"{parent_base_name}_{self.name}, // {self.doc_summary}")
        return ret_arr


class PkgStruct(PkgItemBase):
    """Definition for a localparam inside a pkg."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.fields = []
        for row in kwargs.pop('fields'):
            self.fields.append(PkgStructField(parent=self, log=self.log, **row))
        self._check_naming_conventions()

    def _check_naming_conventions(self):
        if not (self.name.islower() and self.name[-2:] == "_t"):
            self.log.error(F"{self.get_parent_pkg().name}::{self.name} doesn't comply with naming conventions. "
                           F"struct names must be all lowercase and end with _t")
        for field in self.fields:
            if not field.name.islower():
                self.log.error(F"{self.get_parent_pkg().name}::{self.name}.{field.name} doesn't comply "
                               F"with naming conventions. struct fields must be lowercase")

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
        ret_arr = [self.render_doc_verbose(2)]
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


class PkgStructField(PkgItemBase):
    """Definition for a single field inside a struct."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.field_type = kwargs.pop('type')
        self.width = kwargs.pop('width', None)

    def __repr__(self):
        return F"{id(self)} type {self.field_type} width {self.width}"

    def _get_render_type(self):
        if self.get_parent_pkg() is not self.field_type.get_parent_pkg():
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
        parent_pkg = self.get_parent_pkg()
        match = PKG_SCOPE_REGEXP.match(self.field_type)
        # If it looks like we're scoping out of pkg
        if match:
            link_pkg = match.group(1)
            link_symbol = match.group(2)
            try:
                self.log.debug("Attempting to resolve external %s::%s" % (link_pkg, link_symbol))
                self.field_type = parent_pkg.resolve_outbound_symbol(link_pkg,
                                                                     link_symbol,
                                                                     ["structs", "enums"])
            except LinkError:
                self.log.error(F"Couldn't resolve a link from %s to %s" % (self.name, self.width))
        # If it doesn't look like we're scoping out of pkg, try to look in this pkg
        elif self.field_type in parent_pkg.enums:
            self.log.debug("%s type %s is a valid enum in pkg %s" % (self.name, self.field_type, parent_pkg.name))
            self.field_type = parent_pkg.enums[self.field_type]
        elif self.field_type in parent_pkg.structs:
            self.log.debug("%s type %s is a valid struct in pkg %s" % (self.name, self.field_type, parent_pkg.name))
            self.field_type = parent_pkg.structs[self.field_type]
        else:
            self.log.error("Couldn't resolve a width link for {self.name} to {self.width}")

    def resolve_doc_links(self):
        """Resolve basic doc_* links from *.doc_* to the original definition."""
        for doc_type in ['doc_summary', 'doc_verbose']:
            self.log.debug(F"Looking for {doc_type} on {self.name}")
            doc_attr = getattr(self, doc_type)
            if (self.field_type in ["logic", "wire"]) and (doc_attr == F"width.{doc_type}"):
                try:
                    setattr(self, doc_type, getattr(self.width, doc_type))
                    self.log.debug(F"Linked up doc for {self.width.name}, it is now {getattr(self, doc_type)}")
                except AttributeError:
                    self.log.error(F"{self.get_parent_pkg().name}::{self.parent.name}.{self.name} "
                                   F"can't use a \"FROM_TYPE\" "
                                   F"{doc_type} link unless \"width\" field points to a localparam")
            elif (self.field_type not in ["logic", "wire"]) and (doc_attr == F"type.{doc_type}"):
                try:
                    setattr(self, doc_type, getattr(self.field_type, doc_type))
                    self.log.debug(F"Linked up doc for {self.field_type.name}, it is now {getattr(self, doc_type)}")
                except AttributeError:
                    self.log.error(F"{self.get_parent_pkg().name}::{self.parent.name}.{self.name} "
                                   F"can't use a \"type.{doc_type}\" "
                                   F"{doc_type} link unless \"type\" field points to a valid type")

    def render_rtl_sv_pkg(self):
        """Render RTL in a SV pkg for this enun value."""
        if self.field_type in ["logic", "wire"]:
            render_width = self._get_render_width()
            render_type = F"{self.field_type} [{render_width} - 1:0]"
            if render_width == "1":
                render_type = F"{self.field_type}"
        else:
            render_type = self._get_render_type()
        ret_arr = [self.render_doc_verbose(4)]
        ret_arr.append(F"{render_type} {self.name}; // {self.doc_summary}")

        return ret_arr

class Intf(YisNode): # pylint: disable=too-few-public-methods
    """Class to hold IntfItemBase objects, representikng a whole intf."""
    pass # pylint: disable=unnecessary-pass

def main(options, log):
    """Main execution."""
    if (not options.pkgs) and (not options.block_interface):
        log.critical("Didn't find anything to render via cmd line. Must render at least 1 pkg or a block interface")

    yis = Yis(options.block_interface, options.pkgs, log)
    yis.parse_pkgs()
    yis.link_symbols()
    for pkg in yis.pkgs.values():
        log.debug(F"Pkg {repr(pkg)}")

    year = date.today().year

    # if a block_interface is defined, that's the thing we need to render. Parse it first, then render it
    if options.block_interface:
        # yis.parse_block_interface()
        output_content = RTL_INTF_TEMPLATE.render(year=year, interface=yis.block_interface)
    # If it isn't defined, assume we're rendering a pkg. Assume the pkg to render is the last one in the args
    else:
        target_pkg = next(reversed(yis.pkgs))
        output_content = RTL_PKG_TEMPLATE.render(year=year, pkg=yis.pkgs[target_pkg])

    fname = options.output_file
    with open(fname, 'w') as fileh:
        log.info("Writing " + os.path.abspath(fname))
        fileh.write(output_content)

def setup_context():
    """Set up options, log, and other context for main to run."""
    options = parse_args(sys.argv[1:])
    verbosity = cmn_logging.DEBUG if options.tool_debug else cmn_logging.INFO
    log = cmn_logging.build_logger("yis", level=verbosity)
    main(options, log)

if __name__ == "__main__":
    setup_context()
