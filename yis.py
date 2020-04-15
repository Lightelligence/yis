"""YAML Interface Spec parser and generator."""
# pylint: disable=too-many-lines
################################################################################
# stdlib
import argparse
import sys
import os
import re
import textwrap
from collections import OrderedDict
from datetime import date

from jinja2 import Environment, FileSystemLoader, select_autoescape

import yaml
try:
    from yaml import CLoader as Loader
except ImportError:
    from yaml import Loader as Loader # pylint: disable=useless-import-alias
import yamale

################################################################################
from scripts import cmn_logging

################################################################################
# Constants
PKG_SCOPE_REGEXP = re.compile("(.*)::(.*)")
LIST_OF_RESERVED_WORDS = ["logic",
                          "wire",
                          "enum",
                          "struct",
                          "bit",
                          "real",
                          "input",
                          "output",
                          "real",
                          "interface",
                          "typedef"]
RESERVED_WORDS_REGEXP = re.compile("|".join(LIST_OF_RESERVED_WORDS))

################################################################################
# Helpers

class YisFileFilterAction(argparse.Action): # pylint: disable=too-few-public-methods
    """
    Having some bazel dependency issues where some deps aren't getting built.
    It's easier (and hackier) to solve this by just adding these deps to the genrule srcs,
    but we want to ignore those files because they aren't really consumed here.
    """
    def __call__(self, parser, namespace, values, option_string=None):
        setattr(namespace, self.dest, [])
        for value in values:
            if os.path.splitext(value)[1] == ".yis":
                getattr(namespace, self.dest).append(value)


def parse_args(argv):
    """Parse script arguments."""
    parser = argparse.ArgumentParser(description="Parse an interface spec and generate the associated collateral.",
                                     formatter_class=argparse.RawTextHelpFormatter)

    parser.add_argument('--pkgs',
                        nargs='*',
                        action=YisFileFilterAction,
                        help="YAML files defining pkgs needed for block interfaces")

    parser.add_argument('--block-interface',
                        default=False,
                        action='store_true',
                        help="Indicates if the last .yis file passed in is an intf definition")

    parser.add_argument('--output-file',
                        required=True,
                        help="Path to the output file, which might either be a package or a block interface.")

    parser.add_argument('--gen-html',
                        default=False,
                        action='store_true',
                        help="Use the html generator for output.")

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
    def __init__(self, block_interface, pkgs, log, options):
        self.log = log
        self.options = options
        self._pkgs = OrderedDict()
        self._block_interface = None
        self._parse_files(block_interface, pkgs)
        self._link_symbols()

    def _parse_files(self, block_interface, pkgs):
        """Determine which files to parse as a Pkg or as an Intf."""
        intf_to_parse = None
        pkgs_to_parse = pkgs
        if block_interface:
            intf_to_parse = pkgs[-1]
            if len(pkgs) > 1:
                pkgs_to_parse = pkgs[:-1]
        self._parse_pkgs(pkgs_to_parse)
        if block_interface:
            self._parse_block_interface(intf_to_parse)
        self.log.exit_if_warnings_or_errors("Found errors parsing input files")

    def _parse_pkgs(self, pkgs_to_parse):
        """Parse all pkgs."""
        for fname in pkgs_to_parse:
            self._parse_one_pkg(fname)

    def _yamale_validate(self, schema_file, data_file):
        schema = yamale.make_schema(schema_file)
        data = yamale.make_data(data_file)
        try:
            yamale.validate(schema, data, strict=True)
        except ValueError as exc:
            self.log.error(F"Error validating input file {data_file}{str(exc)}")

    def _parse_one_pkg(self, fname):
        try:
            self.log.info(F"Parsing pkg {fname}")
            self._yamale_validate('digital/rtl/scripts/yis/yamale_schemas/rtl_pkg.yaml', fname)
            self.log.exit_if_warnings_or_errors("Previous errors")
            with open(fname) as yfile:
                data = yaml.load(yfile, Loader)
                pkg_name = os.path.splitext(os.path.basename(fname))[0]
                new_pkg = Pkg(log=self.log,
                              name=pkg_name,
                              parent=self,
                              source_file=fname,
                              **data)
                self._pkgs[pkg_name] = new_pkg
                self.log.exit_if_warnings_or_errors(F"Found errors parsing {pkg_name}")
        except IOError:
            self.log.critical("Couldn't open {}".format(fname))

    def _parse_block_interface(self, intf_to_parse):
        """Parse a block interface file, deserialize into relevant objects."""
        try:
            self.log.info(F"Parsing intf {intf_to_parse}")
            self._yamale_validate('digital/rtl/scripts/yis/yamale_schemas/rtl_intf.yaml', intf_to_parse)
            self.log.exit_if_warnings_or_errors("Previous errors")
            with open(intf_to_parse) as yfile:
                data = yaml.load(yfile, Loader)
                interface_name = os.path.splitext(os.path.basename(intf_to_parse))[0]
                self._block_interface = Intf(log=self.log,
                                             name=interface_name,
                                             parent=self,
                                             source_file=intf_to_parse,
                                             **data)
                self.log.exit_if_warnings_or_errors(F"Found errors parsing {interface_name}")
        except IOError:
            self.log.critical("Couldn't open {}".format(intf_to_parse))

    def _link_symbols(self):
        """Walk all children, link the appropriate types, fields, etc."""
        # Only do a link first. Skip computing widths until after link is finished
        for pkg in self._pkgs.values():
            pkg.resolve_links()
        # Compute widths after link is finished
        for pkg in self._pkgs.values():
            pkg.compute_widths()
        if self._block_interface:
            self._block_interface.resolve_links()
        self.log.exit_if_warnings_or_errors("Found errors linking pkgs")

    def resolve_symbol(self, link_pkg, link_symbol, symbol_types):
        """Attempt to find a symbol in the specified pkg, raise a LinkError if it can't be found."""
        self.log.debug("Attempting to link %s::%s", link_pkg, link_symbol)
        try:
            return self._pkgs[link_pkg].resolve_inbound_symbol(link_symbol, symbol_types)
        except KeyError:
            self.log.error(F"{link_pkg} not a defined pkg")
            raise LinkError

    def render_output(self, output_file):
        """Render the appropriate output file, either a pkg or an intf."""
        env = Environment(
            loader=FileSystemLoader('digital/rtl/scripts/yis/templates'),
            autoescape=select_autoescape(
                enabled_extensions=('html'),
                default_for_string=True,
            ))
        year = date.today().year

        template_directory = "rtl"
        if self.options.gen_html:
            template_directory = "html"

        template_name = "pkg"
        if self._block_interface:
            template_name = "intf"

        template_name = os.path.join(template_directory, template_name)

        self.log.debug("Rendering %s with %s", self, template_name)
        template = env.get_template(template_name)
        target_pkg = next(reversed(self._pkgs.values()))
        output_content = template.render(year=year,
                                         interface=self._block_interface,
                                         pkgs=self._pkgs,
                                         target_pkg=target_pkg)

        with open(output_file, 'w') as fileh:
            self.log.info(F"Writing {os.path.abspath(output_file)}")
            fileh.write(output_content)

    def add_child(self, child):
        """Dummy add_child function to make the class inheritance for YisNode work."""
        pass # pylint: disable=unnecessary-pass


class YisNode: # pylint: disable=too-few-public-methods
    """Base class for any type of specification."""
    def __init__(self, **kwargs):
        self.log = kwargs.pop('log')
        self.name = kwargs.pop('name')
        self.doc_summary = kwargs.pop('doc_summary')
        self.doc_verbose = kwargs.pop('doc_verbose', None)
        self.parent = kwargs.pop('parent')
        self.parent.add_child(self)
        self.children = OrderedDict()
        self.computed_width = None
        self._check_naming_conventions()

    def _check_naming_conventions(self):
        self._check_reserved_word_name()
        self._naming_convention_callback()

    def _check_reserved_word_name(self):
        if RESERVED_WORDS_REGEXP.search(self.name):
            self.log.error(F"{self.name} is not a valid name - Can't contain any reserved words:\n"
                           F"{LIST_OF_RESERVED_WORDS}")

    def _check_caps_name_ending(self):
        if self.name[-2:] in ["_E", "_T"]:
            self.log.error(F"{self.name} is an invalid name, it must not end with _E or _T")

    def _check_lower_name_ending(self):
        if self.name[-2:] in ["_e", "_t"]:
            self.log.error(F"{self.name} is an invalid name, it must not end with _e or _t")

    def _naming_convention_callback(self):
        """Hook to allow subclasses to run additional naming convention checks."""
        pass # pylint: disable=unnecessary-pass

    def _check_dunder_name(self):
        if "__" in self.name:
            self.log.error(F"{self.name} is not a valid name - double underscores in names are not allowed in "
                           "names in this context.")

    def _render_formatted_width(self, raw_type):
        render_width = self._get_render_attr('width')
        if render_width == 1:
            return F"{raw_type}"
        return F"{raw_type} [{render_width} - 1:0]"

    def compute_attr(self, attr_name):
        """Compute the raw value of an attr, recursively computing the value of a linked attr."""
        attr = getattr(self, attr_name)
        computed_attr_name = F"computed_{attr_name}"
        current_computed_attr = getattr(self, computed_attr_name)
        if isinstance(attr, int):
            setattr(self, computed_attr_name, attr)
        elif not isinstance(attr, int) and not current_computed_attr:
            setattr(self, computed_attr_name, attr.compute_attr(attr_name))

        return getattr(self, computed_attr_name)

    def render_doc_verbose(self, indent_width):
        """Render doc_verbose for a RTL_PKG template, requires an indent_width for spaces preceding //"""
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

    def resolve_symbol(self, link_pkg, link_symbol, symbol_types):
        """Recursively call parent.resolve_symbol until we hit the top-level Yis instance."""
        return self.parent.resolve_symbol(link_pkg, link_symbol, symbol_types)

    def html_anchor(self):
        """Build a parent hierarchy in order to build HTML anchors."""
        anchor_hierarchy = []
        parent = self
        while parent:
            if not isinstance(parent, YisNode):
                break
            anchor_hierarchy.append(parent.name)
            parent = parent.parent
        return "__".join(reversed(anchor_hierarchy))


class Pkg(YisNode):
    """Class to hold a set of PkgItemBase objects, representing the whole pkg."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.finished_link = False
        self.localparams = OrderedDict()
        self.enums = OrderedDict()
        self.structs = OrderedDict()
        self.typedefs = OrderedDict()
        self.source_file = kwargs['source_file']

        for row in kwargs.get('localparams', []):
            PkgLocalparam(parent=self, log=self.log, **row)
        for row in kwargs.get('enums', []):
            PkgEnum(parent=self, log=self.log, **row)
        for row in kwargs.get('structs', []):
            PkgStruct(parent=self, log=self.log, **row)
        for row in kwargs.get('typedefs', []):
            PkgTypedef(parent=self, log=self.log, **row)

    def add_child(self, child):
        """Override super add_child to add in differentiation between localparams, enums, structs, and typedefs."""
        super().add_child(child)

        self.children[child.name] = child
        if isinstance(child, PkgLocalparam):
            self.localparams[child.name] = child
        elif isinstance(child, PkgEnum):
            self.enums[child.name] = child
        elif isinstance(child, PkgTypedef):
            self.typedefs[child.name] = child
        elif isinstance(child, PkgStruct):
            self.structs[child.name] = child
        else:
            raise ValueError(F"Can't add {child.name} to pkg {self.name} because it is a {type(child)}. "
                             "Can only add localparams, enums, structs, and typedefs.")

    def resolve_links(self):
        """Find and resolve links between types starting at localparms, then enums, then structs, then typdefs."""
        self.log.debug("Attempting to resolve links in %s", self.name)
        self.finished_link = True
        self._link_localparams()
        self._link_enums()
        self._link_structs()
        self._link_typedefs()

    def compute_widths(self):
        """Compute widths of all underlying items, assuming link process finished successfully."""
        self.log.debug("Attempting to resolve links in %s", self.name)
        self._compute_localparams()
        self._compute_enums()
        self._compute_typedefs()
        self._compute_structs()

    def _link_localparams(self):
        """Link localparam widths and values, then compute absolute widths and values."""
        for localparam in self.localparams.values():
            localparam.resolve_links()

        self.log.exit_if_warnings_or_errors("Errors linking localparams")

    def _compute_localparams(self):
        # Compute values after all localparams have been linked to ensure you don't try to compute width
        # from a localparam that hasn't been linked yet.
        for localparam in self.localparams.values():
            localparam.compute_width()
            localparam.compute_value()

    def _link_enums(self):
        for enum in self.enums.values():
            enum.resolve_links()

        self.log.exit_if_warnings_or_errors("Errors linking enums")

    def _compute_enums(self):
        for enum in self.enums.values():
            enum.compute_width()

    def _link_structs(self):
        for struct in self.structs.values():
            struct.resolve_links()

        self.log.exit_if_warnings_or_errors("Errors linking structs")

    def _compute_structs(self):
        # Compute values after all structs have been linked to ensure you don't try to compute width
        # from a struct that hasn't been linked yet.
        for struct in self.structs.values():
            struct.compute_width()

    def _link_typedefs(self):
        for typedef in self.typedefs.values():
            typedef.resolve_links()

        self.log.exit_if_warnings_or_errors("Errors linking typedefs")

    def _compute_typedefs(self):
        for typedef in self.typedefs.values():
            typedef.compute_width()

    def resolve_outbound_symbol(self, link_pkg, link_symbol, symbol_types):
        """Resolve links leaving this pkg."""
        self.log.debug("Attempting to resolve outbound link from %s to %s::%s", self.name, link_pkg, link_symbol)
        return self.parent.resolve_symbol(link_pkg, link_symbol, symbol_types)

    def resolve_inbound_symbol(self, link_symbol, symbol_types):
        """Resolve a link from another pkg attempting to reference a symbol in this pkg."""
        self.log.debug("Attempting to resolve an inbound link %s::%s of types %s",
                       self.name,
                       link_symbol,
                       symbol_types)
        if not self.finished_link:
            self.log.error(F"Can't resolve {link_symbol} into {self.name}, it hasn't been compiled yet")
            raise LinkError

        for symbol_type in symbol_types:
            try:
                self.log.debug("Looking for a(n) %s link to %s::%s",
                               symbol_type,
                               self.name,
                               link_symbol)
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
                "Typedefs:\n  -{typedefs}\n"
                .format(localparams="\n  -".join([str(param) for param in self.localparams.values()]),
                        enums="\n  -".join([str(param) for param in self.enums.values()]),
                        structs="\n  -".join([str(param) for param in self.structs.values()]),
                        typedefs="\n  -".join([str(param) for param in self.typedefs.values()])))



class PkgItemBase(YisNode):
    """Base class for all objects contained in a pkg."""
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

    def html_link_attribute(self, attr_name):
        """Build HTML string to render for an attribute that can be linked (e.g. width)."""
        attr = getattr(self, attr_name)
        if not isinstance(attr, PkgItemBase):
            if attr is None:
                return ""
            return attr

        my_root = self.get_parent_pkg()
        ref_root = attr.get_parent_pkg()
        relpath = os.path.relpath(os.path.dirname(ref_root.source_file), os.path.dirname(my_root.source_file))

        pkg_prefix = ""
        if ref_root is not my_root:
            pkg_prefix = f"{ref_root.name}_rypkg::"

        href_target = os.path.join(relpath, f"{ref_root.name}_rypkg.html#{attr.html_anchor()}")
        return f'<a href="{href_target}">{pkg_prefix}{attr.name}</a>'

    def resolve_links(self):
        """Resolve links in widths and values."""
        self._resolve_width_links()

    def _resolve_width_links(self):
        """Resolve width links. A width can only be an int or a localparam, so call resolve_localparam_links."""
        self._resolve_localparam_links('width')

    def _resolve_value_links(self):
        """Resolve value links. A value can only be an int or a localparam, so call resolve_localparam_links."""
        self._resolve_localparam_links('value')

    def _resolve_localparam_links(self, attr_name):
        """Resolve links to localparams for the specified object attr."""
        valid_attrs = ['width', 'value']
        if attr_name not in valid_attrs:
            raise ValueError(F"Can't resolve localparam for {attr_name}, only {valid_attrs} are allowed")

        # If attr is already an int, don't try to resolve a link
        attr = getattr(self, attr_name)
        if not isinstance(attr, int):
            self.log.debug("%s, %s %s is a type that must be linked", self.name, attr_name, attr)
            localparams = self._get_parent_localparams()
            match = PKG_SCOPE_REGEXP.match(attr)
            # If it looks like we're scoping out of pkg
            if match:
                link_pkg = match.group(1)
                link_symbol = match.group(2)
                try:
                    self.log.debug("Attempting to resolve external %s::%s", link_pkg, link_symbol)
                    new_attr = self.get_parent_pkg().resolve_outbound_symbol(link_pkg,
                                                                             link_symbol,
                                                                             ["localparams"])
                    setattr(self, attr_name, new_attr)
                except LinkError:
                    self.log.error(F"Couldn't resolve a link from %s to %s" % (self.name, attr))
            # If it doesn't look like we're scoping out of pkg, try to look in this pkg
            elif attr in localparams:
                self.log.debug("%s is a valid localparam in pkg %s", attr_name, self.get_parent_pkg().name)
                setattr(self, attr_name, localparams[attr])
            else:
                self.log.error(F"Couldn't resolve a {attr_name} link for {self.name} to {attr}")

    def _get_render_attr(self, attr_name):
        attr = getattr(self, attr_name)
        if not isinstance(attr, int) and (self.get_parent_pkg() is not attr.get_parent_pkg()):
            ret_str = F"{attr.parent.name}_rypkg::{attr.name}"
        elif isinstance(attr, int):
            ret_str = attr
        else:
            ret_str = attr.name
        return ret_str


class PkgLocalparam(PkgItemBase):
    """Definition for a localparam in a pkg."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.width = kwargs.pop('width')
        self.value = kwargs.pop('value')
        self.computed_value = None

    def __repr__(self):
        return F"{id(self)} {self.name}, width {self.width}, value {self.value}"

    def _naming_convention_callback(self):
        self._check_caps_name_ending()

    def resolve_links(self):
        """Call superclass to resolve width links, then resolve type links."""
        super().resolve_links()
        self._resolve_value_links()

    def compute_width(self):
        """Compute the raw width of this localparam."""
        self.compute_attr('width')
        return self.computed_width

    def compute_value(self):
        """Computing localparam value is straightforward - use YisNode.compute_attr to resolve value."""
        return self.compute_attr('value')

    def render_rtl_sv_pkg(self):
        """Render the SV for this localparam.

        The general form is:
        // doc_summary
        // (optional) doc_verbose
        localparam [WIDTH - 1:0] NAME = VALUE;

        Pay careful attention to how to pull out width, because width either points to an int or
        it points to another PkgLocalparam.
        """
        ret_arr = []
        # If there is no doc_verbose, don't append to ret_array to avoid extra newlines
        doc_verbose = self.render_doc_verbose(2)
        if doc_verbose:
            ret_arr.append(doc_verbose)
        render_width = self._get_render_attr('width')
        render_value = self._get_render_attr('value')
        ret_arr.append(F"localparam [{render_width} - 1:0] {self.name} = {render_value}; // {self.doc_summary}")
        return "\n  ".join(ret_arr)


class PkgEnum(PkgItemBase):
    """Definition for an enum inside a pkg."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.width = kwargs.pop('width')
        for row in kwargs.pop('values'):
            PkgEnumValue(parent=self, log=self.log, **row)
        self._check_enum_value_consistency()

    def __repr__(self):
        values = "\n    -".join([str(child) for child in self.children.values()])
        return F"{id(self)} {self.name}, width {self.width}, values:\n    -{values}"

    def _check_enum_value_consistency(self):
        # I had a list comprehension that was way cooler, but it was hard to read
        explicit_values = []
        implicit_values = []

        for child in self.children.values():
            value_attr = getattr(child, 'sv_value', None)
            if value_attr is None:
                implicit_values.append(child)
            else:
                explicit_values.append(child)

        if explicit_values and implicit_values:
            self.log.error(F"Enum {self.name} is using a mix of explicit and implicit values")

    def compute_width(self):
        """Compute the raw width of this enum."""
        if isinstance(self.width, int):
            self.computed_width = self.width
        else:
            # We need a localparam value for the enum width
            # For example, if you have a localparam [31:0] MY_PARAM = 5, then an enum of width MY_PARAM,
            # the enum width is the 5, not the localparam width
            self.computed_width = self.width.compute_value()
        return self.computed_width

    def render_rtl_sv_pkg(self):
        """Render the SV for this enum.

        The general form is:
        // doc_summary
        // (optional) doc_verbose
        typedef enum logic [WIDTH - 1:0] {
          // children
        } NAME;
        """
        ret_arr = []
        # If there is no doc_verbose, don't append to ret_array to avoid extra newlines
        doc_verbose = self.render_doc_verbose(2)
        if doc_verbose:
            ret_arr.append(doc_verbose)

        formatted_type = self._render_formatted_width("logic")
        ret_arr.append(F"type enum {formatted_type} {{")

        # Render each enum_value, note they are 2 indented farther
        enum_value_arr = []
        for row in self.children.values():
            enum_value_arr.extend(row.render_rtl_sv_pkg())

        # Add leading spaces to make all children line up
        enum_value_arr[0] = F"  {enum_value_arr[0]}"

        # Strip trailing comma from last enum_value
        idx_of_comma = enum_value_arr[-1].index(",")
        enum_value_arr[-1] = enum_value_arr[-1][:idx_of_comma] + enum_value_arr[-1][idx_of_comma + 1:]

        ret_arr.append("\n    ".join(enum_value_arr))
        ret_arr.append(F"}} {self.name}; // {self.doc_summary}")
        return "\n  ".join(ret_arr)


class PkgEnumValue(PkgItemBase):
    """Definition for a single item value."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.sv_value = kwargs.pop('value', None)

    def _naming_convention_callback(self):
        self._check_dunder_name()
        self._check_caps_name_ending()

    def __repr__(self):
        return F"{id(self)} {self.name} {self.sv_value}"

    def render_rtl_sv_pkg(self):
        """Render RTL in a SV pkg for this enun value."""
        ret_arr = []
        # If there is no doc_verbose, don't append to ret_array to avoid extra newlines
        doc_verbose = self.render_doc_verbose(4)
        if doc_verbose:
            ret_arr.append(doc_verbose)

        # Strip _E from the rendered RTL name
        parent_base_name = self.parent.name[:-2]
        exp_sv_value = ""
        if self.sv_value is not None:
            exp_sv_value = F" = {self.sv_value}"
        ret_arr.append(F"{parent_base_name}_{self.name}{exp_sv_value}, // {self.doc_summary}")
        return ret_arr


class PkgTypedef(PkgItemBase):
    """Definition for a typedef inside a pkg."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.base_sv_type = kwargs.pop('base_type')
        self.width = kwargs.pop('width')

    def __repr__(self):
        return F"typedef {id(self)} {self.base_type} {self.array_length}"

    def _naming_convention_callback(self):
        if self.name[-2:] == "_e":
            self.log.error(F"{self.name} is an invalid name, typedef names can't end in _e")

    def _resolve_base_type_links(self):
        """Resolve links in base_type, which can be wire/logic, or it can be any enum/typedef/struct type."""
        # If field_type is a logic or a wire, don't need to resolve a type
        self.log.debug("%s type %s is a base_type that must be linked" % (self.name, self.base_sv_type))
        parent_pkg = self.get_parent_pkg()
        match = PKG_SCOPE_REGEXP.match(self.base_sv_type)
        # If it looks like we're scoping out of pkg
        if match:
            link_pkg = match.group(1)
            link_symbol = match.group(2)
            try:
                self.log.debug("Attempting to resolve external %s::%s" % (link_pkg, link_symbol))
                self.base_sv_type = parent_pkg.resolve_outbound_symbol(link_pkg,
                                                                       link_symbol,
                                                                       ["structs", "typedefs", "enums"])
            except LinkError:
                self.log.error(F"Couldn't resolve a link from %s to %s" % (self.name, self.width))
        # If it doesn't look like we're scoping out of pkg, try to look in this pkg
        elif self.base_sv_type in parent_pkg.enums:
            self.log.debug("%s type %s is a valid enum in pkg %s" % (self.name, self.base_sv_type, parent_pkg.name))
            self.base_sv_type = parent_pkg.enums[self.base_sv_type]
        elif self.base_sv_type in parent_pkg.typedefs:
            self.log.debug("%s type %s is a valid typedef in pkg %s" % (self.name, self.base_sv_type, parent_pkg.name))
            self.base_sv_type = parent_pkg.typedefs[self.base_sv_type]
        elif self.base_sv_type in parent_pkg.structs:
            self.log.debug("%s type %s is a valid struct in pkg %s" % (self.name, self.base_sv_type, parent_pkg.name))
            self.base_sv_type = parent_pkg.structs[self.base_sv_type]
        else:
            self.log.error(F"Couldn't resolve a type link for {self.name} to {self.base_sv_type}")

    def _get_render_base_sv_type(self):
        if self.base_sv_type in ["logic", "wire"]:
            render_type = self.base_sv_type
        elif self.get_parent_pkg() is not self.base_sv_type.get_parent_pkg():
            render_type = F"{self.base_sv_type.parent.name}::{self.base_sv_type.name}"
        else:
            render_type = self.base_sv_type.name
        return render_type

    def resolve_links(self):
        if self.base_sv_type not in ["logic", "wire"]:
            self._resolve_base_type_links() # Link in any typedef, enum, struct
        self._resolve_width_links()

    def compute_width(self):
        """Computing width for a typedef requires two parts - width of the base_sv_type and *value* of the width."""
        if self.computed_width is None:
            # Default sv_type_width to 1 for logic/wire types
            base_sv_type_width = 1
            # If the base type is not a logic or a wire, it must be a linked type
            if self.base_sv_type not in ["logic", "wire"]:
                base_sv_type_width = self.base_sv_type.compute_width()

            # int width is easy
            if isinstance(self.width, int):
                width_value = self.width
            # localparam width means we need the *value* of the localparam
            elif isinstance(self.width, PkgLocalparam):
                # Note, can use width.computed_value instead of doing the call stack b/c enums compute before typedefs
                width_value = self.width.computed_value
            # Anything else means we need the width as usual
            else:
                width_value = self.width.compute_width()

            self.computed_width = base_sv_type_width * width_value
        return self.computed_width

    def render_rtl_sv_pkg(self):
        """Render RTL for an sv pkg.

        The general form is:
        // (optional) doc_verbose
        typedef base_sv_type [width - 1:0] name; // doc_summary
        """
        ret_arr = []
        # If there is no doc_verbose, don't append to ret_array to avoid extra newlines
        doc_verbose = self.render_doc_verbose(2)
        if doc_verbose:
            ret_arr.append(doc_verbose)

        render_type = self._get_render_base_sv_type()
        render_width = self._get_render_attr("width")
        ret_arr.append(F"typedef {render_type} [{render_width} - 1:0] {self.name} // {self.doc_summary}")
        return "\n  ".join(ret_arr)

class PkgStruct(PkgItemBase):
    """Definition for a struct inside a pkg."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        for row in kwargs.pop('fields'):
            PkgStructField(parent=self, log=self.log, **row)

    def __repr__(self):
        fields = "\n    -".join([str(child) for child in self.children.values()])
        return F"{id(self)} {self.name}, fields:\n    -{fields}"

    def resolve_links(self):
        """Resolve links for type and width, then check for width/type conflicts."""
        self._resolve_width_links()
        self._resolve_type_links()
        self._resolve_doc_links()
        self._check_type_width_conflicts()

    def _resolve_width_links(self):
        """Override superclass definition of resolve_width_links to know how to resolve width links in each field."""
        for child in self.children.values():
            child.resolve_width_links()

    def _resolve_type_links(self):
        """Resolve type links for each field in a struct."""
        for child in self.children.values():
            if child.sv_type not in ['logic', 'wire']:
                child.resolve_type_links()

    def _resolve_doc_links(self):
        """Resolve links to doc_verbose and doc_summary for each field in a struct."""
        for child in self.children.values():
            child.resolve_doc_links()

    def _check_type_width_conflicts(self):
        for child in self.children.values():
            child.check_type_width_conflicts()

    def compute_width(self):
        """Compute the width of a struct by computing width of all fields."""
        cumulative_width = 0
        for child in self.children.values():
            cumulative_width += child.compute_width()
        self.computed_width = cumulative_width
        return self.computed_width

    def render_rtl_sv_pkg(self):
        """Render the SV for this struct.

        The general form is:
        // (optional) doc_verbose
        typedef struct packed {
          // struct_fields
        } NAME;
        """
        ret_arr = []
        # If there is no doc_verbose, don't append to ret_array to avoid extra newlines
        doc_verbose = self.render_doc_verbose(2)
        if doc_verbose:
            ret_arr.append(doc_verbose)

        ret_arr.append(F"typedef struct packed {{")

        # Render each field, note they are 2 indented farther
        field_arr = []
        for child in self.children.values():
            field_arr.extend(child.render_rtl_sv_pkg())

        # Add leading spaces to make all fields line up
        field_arr[0] = F"  {field_arr[0]}"

        ret_arr.append("\n    ".join(field_arr))
        ret_arr.append(F"}} {self.name}; // {self.doc_summary}")
        return "\n  ".join(ret_arr)

    @property
    def html_canvas_data(self):
        """Return a dictionoary of data to render the struct-canvas in html."""
        data = {"field_names" : [],
                "msbs" : [],
                "lsbs" : []}
        current_bit = 0
        for child in reversed(self.children.values()):
            data["field_names"].insert(0, child.name)
            data["lsbs"].insert(0, current_bit)
            current_bit += child.computed_width - 1
            data["msbs"].insert(0, current_bit)
            current_bit += 1
        return data

class PkgStructField(PkgItemBase):
    """Definition for a single field inside a struct."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.sv_type = kwargs.pop('type')
        self.width = kwargs.pop('width', None)

    def _naming_convention_callback(self):
        self._check_dunder_name()
        self._check_lower_name_ending()

    def __repr__(self):
        return F"{id(self)} type {self.sv_type} width {self.width}"

    def _get_render_type(self):
        if self.get_parent_pkg() is not self.sv_type.get_parent_pkg():
            return F"{self.sv_type.parent.name}_rypkg::{self.sv_type.name}"
        return F"{self.sv_type.name}"

    def resolve_width_links(self):
        """Override superclass resolve_width_links to not call if type isn't a logic or a wire"""
        if self.sv_type in ["logic", "wire"]:
            self.log.debug("Resolving a width link for %s width %s", self.name, self.width)
            super()._resolve_width_links()

    def resolve_type_links(self):
        """Resolve links in type."""
        # If field_type is a logic or a wire, don't need to resolve a type
        self.log.debug("%s type %s is a type that must be linked" % (self.name, self.sv_type))
        parent_pkg = self.get_parent_pkg()
        match = PKG_SCOPE_REGEXP.match(self.sv_type)
        # If it looks like we're scoping out of pkg
        if match:
            link_pkg = match.group(1)
            link_symbol = match.group(2)
            try:
                self.log.debug("Attempting to resolve external %s::%s" % (link_pkg, link_symbol))
                self.sv_type = parent_pkg.resolve_outbound_symbol(link_pkg,
                                                                  link_symbol,
                                                                  ["structs", "typedefs", "enums"])
            except LinkError:
                self.log.error(F"Couldn't resolve a link from %s to %s" % (self.name, self.width))
        # If it doesn't look like we're scoping out of pkg, try to look in this pkg
        elif self.sv_type in parent_pkg.enums:
            self.log.debug("%s type %s is a valid enum in pkg %s" % (self.name, self.sv_type, parent_pkg.name))
            self.sv_type = parent_pkg.enums[self.sv_type]
        elif self.sv_type in parent_pkg.typedefs:
            self.log.debug("%s type %s is a valid typedef in pkg %s" % (self.name, self.sv_type, parent_pkg.name))
            self.sv_type = parent_pkg.typedefs[self.sv_type]
        elif self.sv_type in parent_pkg.structs:
            self.log.debug("%s type %s is a valid struct in pkg %s" % (self.name, self.sv_type, parent_pkg.name))
            self.sv_type = parent_pkg.structs[self.sv_type]
        else:
            self.log.error("Couldn't resolve a type link for {self.name} to {self.width}")

    def resolve_doc_links(self):
        """Resolve basic doc_* links from *.doc_* to the original definition."""
        for doc_type in ['doc_summary', 'doc_verbose']:
            self.log.debug(F"Looking for {doc_type} on {self.name}")
            doc_attr = getattr(self, doc_type)
            if (self.sv_type in ["logic", "wire"]) and (doc_attr == F"width.{doc_type}"):
                try:
                    setattr(self, doc_type, getattr(self.width, doc_type))
                    self.log.debug("Linked up doc for %s" % (self.width.name))
                except AttributeError:
                    self.log.error(F"{self.get_parent_pkg().name}::{self.parent.name}.{self.name} "
                                   F"can't use a \"width.{doc_type}\" "
                                   F"{doc_type} link unless \"width\" field points to a localparam")
            elif (self.sv_type not in ["logic", "wire"]) and (doc_attr == F"type.{doc_type}"):
                try:
                    setattr(self, doc_type, getattr(self.sv_type, doc_type))
                    self.log.debug("Linked up doc for %s" % (self.sv_type.name))
                except AttributeError:
                    self.log.error(F"{self.get_parent_pkg().name}::{self.parent.name}.{self.name} "
                                   F"can't use a \"type.{doc_type}\" "
                                   F"{doc_type} link unless \"type\" field points to a valid type")

    def check_type_width_conflicts(self):
        """Check to see if this struct field defines both a width and a non-logic/wire type."""
        if self.sv_type not in ["logic", "wire"] and self.width is not None:
            self.log.error(F"Struct field {self.parent.name}.{self.name} has width specified for "
                           "a non-logic/wire type. Only logic/wire can have a width")

    def compute_width(self):
        """Compute width by looking at width and type."""
        self.log.debug(F"Computing width for %s - width is %s, type is %s", self.name, self.width, self.sv_type)
        if self.sv_type in ["logic", "wire"] and isinstance(self.width, int):
            self.computed_width = self.width
        elif self.sv_type in ["logic", "wire"]:
            self.computed_width = self.width.compute_value()
        else:
            self.computed_width = self.sv_type.compute_width()

        return self.computed_width

    def render_rtl_sv_pkg(self):
        """Render RTL in a SV pkg for this struct field."""
        if self.sv_type in ["logic", "wire"]:
            render_type = self._render_formatted_width(self.sv_type)
        else:
            render_type = self._get_render_type()

        ret_arr = []
        # If there is no doc_verbose, don't append to ret_array to avoid extra newlines
        doc_verbose = self.render_doc_verbose(4)
        if doc_verbose:
            ret_arr.append(doc_verbose)
        ret_arr.append(F"{render_type} {self.name}; // {self.doc_summary}")

        return ret_arr

class Intf(YisNode):
    """Class to hold IntfItemBase objects, representing a whole intf."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.source_file = kwargs['source_file']
        for row in kwargs.pop('components'):
            IntfComp(parent=self, log=self.log, **row)

    def __repr__(self):
        return (F"Intf name: {self.name}\n"
                "Components:\n  -{components}\n"
                .format(components="\n  -".join([repr(component) for component in self.children.values()])))

    def resolve_links(self):
        """Find and resolve type links in all components."""
        for child in self.children.values():
            child.resolve_links()

    def compute_width(self):
        """Compute width of the each child object, then accumulate all widths to form master width."""
        cumulative_width = 0
        for child in self.children.values():
            cumulative_width += child.compute_width()
        self.computed_width = cumulative_width


class IntfItemBase(YisNode):
    """Base class for anything contained in an Intf."""
    def _naming_convention_callback(self):
        """All IntfItems shouldn't end with _e or _t."""
        self._check_lower_name_ending()

class IntfComp(IntfItemBase):
    """Definition for a Comp(onent) - a set of individual port symbols - on an interface."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        for connection in kwargs.pop('connections'):
            IntfCompConn(parent=self, log=self.log, **connection)

    def __repr__(self):
        return (F"Component name: {self.name}\n"
                "Connections:\n  -{connections}\n"
                .format(connections="\n  -".join([repr(connection) for connection in self.children.values()])))

    def resolve_links(self):
        """Resolve links for each CompConn child."""
        for child in self.children.values():
            child.resolve_links()
            child.check_type_width_conflicts()

    def compute_width(self):
        """Compute width for this Component by iterating through all children."""
        cumulative_width = 0
        for child in self.children.values():
            cumulative_width += child.compute_width()
        self.computed_width = cumulative_width
        return self.computed_width


class IntfCompConn(IntfItemBase):
    """Definition for a Conn(onent) in a Comp(onent)."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.sv_type = kwargs.pop('type')
        self.width = kwargs.pop('width', None)
        self._render_type = self.sv_type
        self._render_width = self.width
        self._check_width_consistency()

    def __repr__(self):
        return F"Conn {self.name}, {self.sv_type}, {self.width}"

    def _naming_convention_callback(self):
        self._check_extra_dunder_name()
        self._check_lower_name_ending()

    def _check_extra_dunder_name(self):
        if self.name.count("__") > 2:
            self.log.error(F"{self.name} is not a valid name. Connection names must have exactly 2 underscores -"
                           " one between source and destination, one between destintation and \'functional\' name")

    def _check_width_consistency(self):
        if self.sv_type in ["logic", "wire"] and isinstance(self.width, int) and self.width != 1:
            self.log.error(F"{self.name} has a {self.sv_type} type with a raw int greater than 1 as the width. "
                           "The port width must be specified in a pkg and referenced by the connection.")

    def resolve_links(self):
        """Resolve links from IntfCompConn to a package.

        Note that this is similar to resolve_width_links, but only external package links are allowed here.
        """
        # If the sv_type is not a logic or wire, try to resolve the sv_type link
        if self.sv_type not in ['logic', 'wire']:
            self._resolve_type_link()
        # If sv_type is a logic or wire but width isn't an int, try to resolve the width link
        elif not isinstance(self.width, int):
            self._resolve_width_link()
        # Else sv_type is a logic and it has an int width, so leave it alone

        self._resolve_doc_links()

    def check_type_width_conflicts(self):
        """Check to see if this struct field defines both a width and a non-logic/wire type."""
        if self.sv_type not in ["logic", "wire"] and self.width is not None:
            self.log.error(F"Interface connection {self.parent.name}.{self.name} has width specified for a "
                           "non-logic/wire type. Only logic/wire can have a width")

    def _resolve_type_link(self):
        self.log.debug("%s, type %s must be linked" % (self.name, self.sv_type))
        match = PKG_SCOPE_REGEXP.match(self.sv_type)
        # If it looks like we're scoping out of pkg
        if match:
            link_pkg = match.group(1)
            link_symbol = match.group(2)
            try:
                self.log.debug("Attempting to resolve %s::%s" % (link_pkg, link_symbol))
                self.sv_type = self.parent.resolve_symbol(link_pkg, link_symbol, ["enums", "structs", "typedefs"])
                self._render_type = F"{self.sv_type.get_parent_pkg().name}::{self.sv_type.name}"
                self.log.debug("%s type is now %s" % (self.name, self.sv_type.name))
            except LinkError:
                self.log.error(F"Couldn't resolve a link from %s to %s" % (self.name, self.sv_type))
        else:
            self.log.error(F"{self.name} has invalid type {self.sv_type}. "
                           "Type references in RTL intf files must be package scoped")

    def _resolve_width_link(self):
        self.log.debug("%s, width %s is a type that must be linked" % (self.name, self.width))
        match = PKG_SCOPE_REGEXP.match(self.width)
        # If it looks like we're scoping out of pkg
        if match:
            link_pkg = match.group(1)
            link_symbol = match.group(2)
            try:
                self.log.debug("Attempting to resolve %s::%s" % (link_pkg, link_symbol))
                self.width = self.parent.resolve_symbol(link_pkg, link_symbol, ["localparams"])
                self._render_width = F"{self.width.get_parent_pkg().name}_rypkg::{self.width.name}"
                self.log.debug("%s width is now %s" % (self.name, self.width.name))
            except LinkError:
                self.log.error(F"Couldn't resolve a link from %s to %s" % (self.name, self.width))
        else:
            self.log.error(F"{self.name} has invalid width {self.width}. "
                           "Width references in RTL intf files must be package scoped")

    def _resolve_doc_links(self):
        """Resolve basic doc_* links from *.doc_* to the original definition."""
        for doc_type in ['doc_summary', 'doc_verbose']:
            self.log.debug(F"Looking for {doc_type} on {self.name}")
            doc_attr = getattr(self, doc_type)
            if (self.sv_type in ["logic", "wire"]) and (doc_attr == F"width.{doc_type}"):
                try:
                    setattr(self, doc_type, getattr(self.width, doc_type))
                    self.log.debug("Linked up doc for %s" % (self.width.name))
                except AttributeError:
                    self.log.error(F"{self.parent.name}.{self.name} "
                                   F"can't use a \"width.{doc_type}\" "
                                   F"{doc_type} link unless \"width\" points to a localparam")
            elif (self.sv_type not in ["logic", "wire"]) and (doc_attr == F"type.{doc_type}"):
                try:
                    setattr(self, doc_type, getattr(self.sv_type, doc_type))
                    self.log.debug("Linked up doc for %s" % (self.sv_type.name))
                except AttributeError:
                    self.log.error(F"{self.parent.name}.{self.name} "
                                   F"can't use a \"type.{doc_type}\" "
                                   F"{doc_type} link unless \"type\" points to a valid type")

    def compute_width(self):
        """Compute width by looking at width and type."""
        if self.sv_type in ["logic", "wire"] and isinstance(self.width, int):
            self.computed_width = self.width
        elif self.sv_type in ["logic", "wire"]:
            self.computed_width = self.width.computed_width
        else:
            self.computed_width = self.sv_type.computed_width
        return self.computed_width

    def html_link_attribute(self, attr_name):
        """Build HTML string to render for an attribute that can be linked (e.g. width)."""
        attr = getattr(self, attr_name)
        if not isinstance(attr, PkgItemBase):
            if attr is None:
                return ""
            return attr

        my_root = self.parent.parent # Assumption intf is two levels up
        ref_root = attr.get_parent_pkg()
        relpath = os.path.relpath(os.path.dirname(ref_root.source_file), os.path.dirname(my_root.source_file))

        pkg_prefix = ""
        if ref_root is not my_root:
            pkg_prefix = f"{ref_root.name}_rypkg::"

        href_target = os.path.join(relpath, f"{ref_root.name}_rypkg.html#{attr.html_anchor()}")
        return f'<a href="{href_target}">{pkg_prefix}{attr.name}</a>'

def main(options, log):
    """Main execution."""
    if not options.pkgs:
        log.critical("Didn't find anything to render via cmd line. Must specify at least .yis")

    yis = Yis(options.block_interface, options.pkgs, log, options=options)
    yis.render_output(options.output_file)

def setup_context():
    """Set up options, log, and other context for main to run."""
    options = parse_args(sys.argv[1:])
    verbosity = cmn_logging.DEBUG if options.tool_debug else cmn_logging.INFO
    log = cmn_logging.build_logger("yis", level=verbosity)
    main(options, log)

if __name__ == "__main__":
    setup_context()
