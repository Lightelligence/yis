"""YAML Interface Spec parser and generator."""
# pylint: disable=too-many-lines
################################################################################
# stdlib
import argparse
import math
import sys
import os
import re
import textwrap
from collections import OrderedDict
from datetime import date

import ast

from jinja2 import Environment, FileSystemLoader, select_autoescape

import astor

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
                          "interface",
                          "typedef",
                          "union",
                          "type",
                          "class"]
RESERVED_WORDS_REGEXP = re.compile("^({})$".format("|".join(LIST_OF_RESERVED_WORDS)))

################################################################################
# Helpers
def is_verilog_primitive(value):
    """Encapsulate frequent check for primitive types."""
    return value in ["logic", "wire"]

def bits(value):
    """Equivalent to $bits system call in Verilog.
    Requires a lot of typing in python.
    """
    return int(math.ceil(math.log2(value)))

def only_run_once(function):
    """A cheap decorator to only allow a method to be invoked once.

    This is helpful when trying walk a dependency graph with possible circular
    links to make sure that a particular node only invokes a 'setup' function
    once.

    """
    def wrapper(self):
        run_once_dict = getattr(self, "_only_run_once", {})
        if function not in run_once_dict:
            run_once_dict[function] = True
            setattr(self, "_only_run_once", run_once_dict)
            return function(self)
        return None
    return wrapper

def memoize_property(function):
    """Memoize a class method. Intentionally only works on functions without args for now.

    If arguments added, need to make hash inputs to make unique key instead of
    just using function name.

    """
    @property
    def wrapper(self):
        memoize_properties = getattr(self, "_memoize_properties", {})
        try:
            return memoize_properties[function]
        except KeyError:
            result = function(self)
            memoize_properties[function] = result
            setattr(self, "_memoize_properties", memoize_properties)
            return result
    return wrapper


class EquationError(Exception):
    """Any error raised by the Equation class"""
    pass # pylint: disable=unnecessary-pass


class Equation(ast.NodeTransformer):
    """Allow some math to happen (referring to other nodes)"""

    class LinkNode(ast.Num): # pylint: disable=too-few-public-methods
        """Custom node to store information to another YisNode"""
        def __init__(self, value, link, attribute):
            self.link = link
            self.attribute = attribute
            super().__init__(value)

    # This is a hack to allow custom source generators in astor
    astor.op_util.precedence_data[LinkNode] = astor.op_util.precedence_data[ast.Num]

    class TextSourceGenerator(astor.SourceGenerator): # pylint: disable=too-few-public-methods
        """Support of LinkNode rendering"""
        def visit_LinkNode(self, node):
            """For text generation, just give the computed numerical value."""
            self.visit_Num(node)

    class HtmlSourceGenerator(astor.SourceGenerator): # pylint: disable=too-few-public-methods
        """Rerender the equation, but replace node references with html links to the objects."""
        link_map = {}
        def visit_LinkNode(self, node):
            """Return the precalculated link."""
            html_link = self.link_map[node]
            self.write(html_link)

    def __init__(self, yisnode, equation):
        super().__init__()
        self.yisnode = yisnode
        self.equation = equation
        self.simple_eq = False

        if isinstance(equation, int):
            self._result = equation
            self.simple_eq = True
            return

        self.linked_nodes = []

        # Change package refereces to . scoping to make python compiler happy
        equation = equation.replace("::", ".")
        self.tree_root = ast.parse(equation)
        # Transform the equation
        self.visit(self.tree_root)
        # Regenerate the equation with subsituted values
        new_eq = astor.to_source(self.tree_root, source_generator_class=self.TextSourceGenerator)

        try:
            self._result = eval(new_eq) # pylint: disable=eval-used
        except NameError as exc:
            name = re.search("name '(.*)' is not defined", exc.args[0]).group(1)
            raise EquationError(f"Did you forget to add '.width' or '.value' on the end of '{name}'")

        if self._result < 0:
            self.yisnode.log.error("Equation for %s evaluated to a negative number (%s).\n"
                                   "Only non-negative evaluations allowed.\n"
                                   "Original equation: '%s'",
                                   yisnode.name,
                                   self._result,
                                   equation)

    @property
    def computed_value(self):
        """Return previously calculated value."""
        return self._result

    @property
    def computed_width(self):
        """Return previously calculated value."""
        return self._result

    def get_doc_link(self):
        """Return a linked node."""
        if len(self.linked_nodes) != 1:
            raise EquationError("May not use doc linking unless attribute has exactly one link.")
        return self.linked_nodes[0].link

    def visit_Attribute(self, node): # pylint: disable=invalid-name
        """Override of ast.NodeTransformer function to find names and convert them to yisnode links."""
        if isinstance(node.value, ast.Name):
            # Local package
            symbol = node.value.id
            pkg = self.yisnode.get_nonyis_root().name
        elif isinstance(node.value, ast.Attribute):
            symbol = node.value.attr
            pkg = node.value.value.id
        else:
            raise EquationError(f"Couldn't parse symbol in equation:", astor.to_source(node))

        if "math" in [symbol, pkg]:
            return super().generic_visit(node)

        attribute = node.attr

        link_name = f"{pkg}::{symbol}"
        link = self.yisnode.resolve_link_from_str(link_name, allowed_symbols=[Pkg.LOCALPARAMS, Pkg.ENUMS, Pkg.TYPEDEFS])

        if not hasattr(link, f"computed_{attribute}"):
            raise EquationError(f"Succesful link to {link.name}, but no attribute {attribute}")

        value = getattr(link, f"computed_{attribute}")

        replacement_node = self.LinkNode(value, link, attribute)
        self.linked_nodes.append(replacement_node)
        return replacement_node

    def visit_Expr(self, node): # pylint: disable=invalid-name
        """Override of ast.NodeTransformer to find the top expression which makes eval easier."""
        if not isinstance(self.tree_root, ast.Expr):
            self.tree_root = node
        return super().generic_visit(node)

    def render_html(self, reference_yisnode):
        """Walk the AST and generate links for all the yis nodes."""
        if self.simple_eq:
            return self.equation
        html_map = {}
        for node in self.linked_nodes:
            html_map[node] = reference_yisnode.html_link_attribute_from_link(node.link, extra_text=f".{node.attribute}")
        class LocalHtmlSourceGenerator(self.HtmlSourceGenerator): # pylint: disable=too-few-public-methods
            """A derived class to have access to set link_map.
            Would prefer to pass this in, but not easy due to astor invoking by class, not instance.
            """
            link_map = html_map
        return astor.to_source(self.tree_root, source_generator_class=LocalHtmlSourceGenerator)

    def render_rtl(self):
        """Render the value of the eqaution for generated rtl.
        Adds the raw equation if the equation is not simple.
        """
        if self.simple_eq:
            comment = ""
        else:
            comment = f"/* {self.equation} */ "
        return f"{comment}{self.computed_value}"


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

    parser.add_argument('--gen-rtl',
                        default=False,
                        action='store_true',
                        help="Use the rtl generator for output.")

    parser.add_argument('--gen-dv',
                        default=False,
                        action='store_true',
                        help="Use the dv generator for output.")

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
        self.parent = None # Should never be set, but recursive walking easier
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
        if self._block_interface:
            self._block_interface.resolve_links()
        self.log.exit_if_warnings_or_errors("Found errors linking pkgs")

    def resolve_symbol(self, link_pkg, link_symbol, symbol_types):
        """Attempt to find a symbol in the specified pkg, raise a LinkError if it can't be found."""
        self.log.debug("Attempting to link %s::%s", link_pkg, link_symbol)
        try:
            return self._pkgs[link_pkg].resolve_inbound_symbol(link_symbol, symbol_types)
        except KeyError:
            self.log.error("%s not a defined pkg", link_pkg)
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

        if self.options.gen_rtl:
            template_directory = "rtl"
        elif self.options.gen_html:
            template_directory = "html"
        elif self.options.gen_dv:
            template_directory = "dv"
        else:
            self.log.critical("No generator specified.")

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
        self._check_naming_conventions()
        self.local_links = [] # Simplifies post-order-traversal algorithm
                              # (basically just moving some smarts to
                              # constructors)

    def __getattribute__(self, attr):
        """Override the default behaviour to make sure links are resolved before
        accessing any computed functions."""
        if attr.startswith("computed_"):
            self.resolve_links()
        return super().__getattribute__(attr)

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

    def get_nonyis_root(self):
        """Return second-highest level of the tree.
        Don't want the Yis root node, but either an a Pkg or Intf.
        """
        parent = self
        while parent and not isinstance(parent.parent, Yis):
            parent = parent.parent
        return parent

    def _render_formatted_width(self, raw_type):
        render_width = self.width.render_rtl()
        if render_width == 1:
            return F"{raw_type}"
        return F"{raw_type} [{render_width} - 1:0]"

    def render_doc_verbose(self, indent_width):
        """Render doc_verbose for a RTL_PKG template, requires an indent_width for spaces preceding //"""
        indent_spaces = " " * indent_width
        if self.doc_verbose is not None:
            wrapper = textwrap.TextWrapper(initial_indent="// ", subsequent_indent=F"{indent_spaces}// ")
            return wrapper.fill(self.doc_verbose)
        return ""

    def resolve_link_from_str(self, link_name, allowed_symbols=[]): # pylint: disable=dangerous-default-value
        """Given a string, attempt to likn to a matching YisNode."""
        if not isinstance(link_name, str):
            self.log.error("Attempting to resolve link from %s. Expected str, but got %s %s",
                           self.name, link_name, type(link_name))

        link_pkg, link_symbol = self._extract_link_pieces(link_name)

        root = self
        while root.parent:
            root = root.parent

        self.log.debug("Attempting to resolve link to %s::%s", link_pkg, link_symbol)
        try:
            link = root.resolve_symbol(link_pkg,
                                       link_symbol,
                                       allowed_symbols)
        except LinkError:
            self.log.error("Couldn't resolve a link from %s to %s", self.name, link_name)
            return None
        else:
            self.local_links.append(link)
        return link

    def _resolve_link(self, attr_name, allowed_symbols=[]): # pylint: disable=dangerous-default-value
        """Convert an attribute from a string to a linked object."""
        attr = getattr(self, attr_name)

        if isinstance(attr, int):
            return # Not a link

        link = self.resolve_link_from_str(attr, allowed_symbols=allowed_symbols)
        setattr(self, attr_name, link)

    @only_run_once
    def resolve_links(self):
        """Resolve links in all children."""
        for child in self.children.values():
            child.resolve_links()
            self.log.exit_if_warnings_or_errors("Errors linking %s", child)
        self.resolve_doc_links()

    def resolve_doc_links(self):
        """Resolve basic doc_* links from *.doc_* to the original definition."""
        attr_name_map = {'width' : 'width',
                         'type' : 'sv_type'}
        for doc_type in ['doc_summary', 'doc_verbose']:
            self.log.debug(F"Looking for {doc_type} on {self.name}")
            doc_attr = getattr(self, doc_type)
            for human_name, yis_internal_name in attr_name_map.items():
                if doc_attr == F"{human_name}.{doc_type}":
                    if not hasattr(self, yis_internal_name):
                        self.log.error("Attempting to use %s.%s, but %s doesn't have a %s member.",
                                       human_name, doc_type, self.__class__)
                        continue
                else:
                    continue
                linked_attr = getattr(self, yis_internal_name)
                if isinstance(linked_attr, Equation):
                    linked_attr = linked_attr.get_doc_link()
                try:
                    setattr(self, doc_type, getattr(linked_attr, doc_type))
                    self.log.debug("Linked up doc for %s", linked_attr.name)
                except AttributeError:
                    self.log.error(F"{self.get_parent_pkg().name}::{self.parent.name}.{self.name} "
                                   F"can't use a \"{human_name}.{doc_type}\" "
                                   F"{doc_type} link unless \"{human_name}\" field points links to exactly one object")

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

    def render_equation_as_html(self, attr_name):
        """If attribute is an equation, render it as html."""
        equation = getattr(self, attr_name)
        if isinstance(equation, Equation):
            return equation.render_html(self)
        if equation is None:
            return ""
        return equation

    def html_link_attribute(self, attr_name):
        """Build HTML string to render for an attribute that can be linked (e.g. width)."""
        attr = getattr(self, attr_name)
        if not isinstance(attr, (PkgItemBase, IntfItemBase)):
            if attr is None:
                return ""
            return attr
        return self.html_link_attribute_from_link(attr)

    def html_link_attribute_from_link(self, link, extra_text=""):
        """Pass a reference to another yisnode to create a relative HTML link from this object to that object."""
        my_root = self.get_nonyis_root()
        ref_root = link.get_nonyis_root()
        relpath = os.path.relpath(os.path.dirname(ref_root.source_file), os.path.dirname(my_root.source_file))

        pkg_prefix = ""
        if ref_root is not my_root:
            pkg_prefix = f"{ref_root.name}_rypkg::"

        href_target = os.path.join(relpath, f"{ref_root.name}_rypkg.html#{link.html_anchor()}")
        return f'<a href="{href_target}">{pkg_prefix}{link.name}{extra_text}</a>'

    def html_render_doc(self, attr_name):
        """Add cross references in documentation."""
        assert attr_name in ["doc_summary", "doc_verbose"]

        doc_link_re = re.compile(r"\[([a-zA-Z0-9_:]+)\]")

        attr = getattr(self, attr_name)
        def repl(match):
            name = match.group(1)
            link = self.resolve_link_from_str(name,
                                              allowed_symbols=[Pkg.LOCALPARAMS,
                                                               Pkg.ENUMS,
                                                               Pkg.TYPEDEFS,
                                                               Pkg.STRUCTS,
                                                               Pkg.UNIONS])
            return self.html_link_attribute_from_link(link)

        attr = doc_link_re.sub(repl, attr)
        return attr


class Pkg(YisNode):
    """Class to hold a set of PkgItemBase objects, representing the whole pkg."""
    LOCALPARAMS = 'localparams'
    ENUMS = 'enums'
    XACTIONS = 'xactions'
    STRUCTS = 'structs'
    TYPEDEFS = 'typedefs'
    UNIONS = 'unions'
    offspring = OrderedDict([(LOCALPARAMS, 'PkgLocalparam'),
                             (ENUMS, 'PkgEnum'),
                             (XACTIONS, 'PkgXaction'), # This is cheating - we need this before structs otherwise we'll attempt to create PkgXactions as PkgStructs # pylint: disable=line-too-long
                             (STRUCTS, 'PkgStruct'),
                             (TYPEDEFS, 'PkgTypedef'),
                             (UNIONS, 'PkgUnion'),])

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        self.finished_link = False
        def initialize(offspring):
            setattr(self, offspring, OrderedDict())
            cls = getattr(sys.modules[__name__], self.offspring[offspring])

            # Handle case when an item type is defined but it's empty
            if kwargs.get(offspring) is None:
                return

            for row in kwargs.get(offspring, []):
                cls(parent=self, log=self.log, **row)

        self._offspring_iterate(initialize)
        self.source_file = kwargs['source_file']

    def _offspring_iterate(self, _fn, *args, **kwargs):
        for offspring in self.offspring.keys():
            _fn(offspring, *args, **kwargs)

    def add_child(self, child):
        """Override super add_child to add in differentiation between
        localparams, enums, structs, typedefs, and unions.
        """
        super().add_child(child)

        self.children[child.name] = child
        for offspring, offspring_type in self.offspring.items():
            if isinstance(child, getattr(sys.modules[__name__], offspring_type)):
                offspring_handle = getattr(self, offspring)
                offspring_handle[child.name] = child
                break
        else:
            raise ValueError(F"Can't add {child.name} to pkg {self.name} because it is a {type(child)}. "
                             "Can only add localparams, enums, structs, typedefs, and unions.")

    @only_run_once
    def resolve_links(self):
        """Find and resolve links between types starting at
        localparms, then enums, then structs, then unions, then typdefs.
        """
        self.log.debug("Attempting to resolve links in %s", self.name)
        self.finished_link = True
        super().resolve_links()

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
        return f"Pkg(name={self.name})"

    def pretty_print(self):
        """Pretty print. Well, not so pretty."""
        return (F"Pkg name: {self.name}\n"
                "Localparams:\n  -{localparams}\n"
                "Enums:\n  -{enums}\n"
                "Structs:\n  -{structs}\n"
                "Typedefs:\n  -{typedefs}\n"
                "Unions:\n  -{unions}\n"
                .format(localparams="\n  -".join([str(param) for param in self.localparams.values()]),
                        enums="\n  -".join([str(param) for param in self.enums.values()]),
                        structs="\n  -".join([str(param) for param in self.structs.values()]),
                        typedefs="\n  -".join([str(param) for param in self.typedefs.values()]),
                        unions="\n  -".join([str(param) for param in self.unions.values()])))

    def post_order_traversal_for_rtl_render(self):
        """Walk all "top_level" children to find the dependency order.

        Generated compile won't compile if dependent types are previously
        declared.

        """
        done = {}
        ordered = [] # This could be a yield, just annoying to debug in jinja
        for offspring in self.offspring:
            for item in getattr(self, offspring).values():
                for potll in item.post_order_traversal_local_links():
                    if potll in done:
                        continue
                    done[potll] = True
                    # children apparently have this function as well
                    # if hasattr(potll, 'render_rtl_sv_pkg'):
                    for offspring_inner in self.offspring:
                        if potll in getattr(self, offspring_inner).values():
                            ordered.append(potll)
        return ordered


class PkgItemBase(YisNode):
    """Base class for all objects contained in a pkg."""
    allowed_symbols_for_linking = []

    def _extract_link_pieces(self, link_name):
        parent_pkg = self.get_parent_pkg()
        match = PKG_SCOPE_REGEXP.match(link_name)
        if match:
            # If it looks like we're scoping out of pkg
            link_pkg = match.group(1)
            link_symbol = match.group(2)
        else:
            link_pkg = parent_pkg.name
            link_symbol = link_name
        return link_pkg, link_symbol

    def post_order_traversal_local_links(self):
        """Post order traversal of this objects dependencies."""
        for local_l in self.local_links:
            for ll_potll in local_l.post_order_traversal_local_links():
                yield ll_potll
        for child in self.children.values():
            for cpotll in child.post_order_traversal_local_links():
                yield cpotll
        yield self

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


class PkgLocalparam(PkgItemBase):
    """Definition for a localparam in a pkg."""
    allowed_symbols_for_linking = [Pkg.LOCALPARAMS]

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.width = kwargs.pop('width')
        self.value = kwargs.pop('value')

    def __repr__(self):
        return F"{id(self)} {self.name}, width {self.width}, value {self.value}"

    def _naming_convention_callback(self):
        self._check_caps_name_ending()

    @only_run_once
    def resolve_links(self):
        """Call superclass to resolve width links, then resolve type links."""
        super().resolve_links()
        self.width = Equation(self, self.width)
        self.value = Equation(self, self.value)

    @memoize_property
    def computed_width(self):
        """Recurse if necessary"""
        if isinstance(self.width, int):
            return self.width
        return self.width.computed_width

    @memoize_property
    def computed_value(self):
        """Recurse if necessary"""
        if isinstance(self.value, int):
            value = self.value
        else:
            value = self.value.computed_value

        max_value = (1 << self.width.computed_value) - 1
        if value > max_value:
            self.log.error("%s computed value of %s exceeds maximum value (%s) allowed by width (%s)",
                           self.name,
                           value,
                           max_value,
                           self.width.computed_value)
        return value

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
        render_width = self.width.render_rtl()
        render_value = self.value.render_rtl()
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

    @only_run_once
    def resolve_links(self):
        """Call superclass to resolve width links, then resolve type links."""
        super().resolve_links()
        self.width = Equation(self, self.width)

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

    @memoize_property
    def computed_width(self):
        """Compute the raw width of this enum."""
        if isinstance(self.width, int):
            return self.width
        # We need a localparam value for the enum width
        # For example, if you have a localparam [31:0] MY_PARAM = 5, then an enum of width MY_PARAM,
        # the enum width is the 5, not the localparam width
        return self.width.computed_value

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
        ret_arr.append(F"typedef enum {formatted_type} {{")

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

    def render_html_value(self):
        """Render for html."""
        if self.sv_value is None:
            return ""
        return self.sv_value

class PkgTypedef(PkgItemBase):
    """Definition for a typedef inside a pkg."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.base_sv_type = kwargs.pop('base_type')
        self.width = kwargs.pop('width')

    def __repr__(self):
        return F"typedef {id(self)} {self.name}"

    def _naming_convention_callback(self):
        if self.name[-2:] == "_e":
            self.log.error(F"{self.name} is an invalid name, typedef names can't end in _e")

    def _get_render_base_sv_type(self):
        if is_verilog_primitive(self.base_sv_type):
            render_type = self.base_sv_type
        elif self.get_parent_pkg() is not self.base_sv_type.get_parent_pkg():
            render_type = F"{self.base_sv_type.parent.name}_rypkg::{self.base_sv_type.name}"
        else:
            render_type = self.base_sv_type.name
        return render_type

    @only_run_once
    def resolve_links(self):
        if not is_verilog_primitive(self.base_sv_type):
            self._resolve_link("base_sv_type", allowed_symbols=[Pkg.TYPEDEFS, Pkg.ENUMS, Pkg.STRUCTS, Pkg.UNIONS])
        self.width = Equation(self, self.width)
        super().resolve_links()

    @memoize_property
    def computed_width(self):
        """Computing width for a typedef requires two parts - width of the base_sv_type and *value* of the width."""
        # Default sv_type_width to 1 for logic/wire types
        base_sv_type_width = 1
        # If the base type is not a logic or a wire, it must be a linked type
        if not is_verilog_primitive(self.base_sv_type):
            base_sv_type_width = self.base_sv_type.computed_width

        # int width is easy
        if isinstance(self.width, int):
            width_value = self.width
        # localparam width means we need the *value* of the localparam
        elif isinstance(self.width, PkgLocalparam):
            # Note, can use width.computed_value instead of doing the call stack b/c enums compute before typedefs
            width_value = self.width.computed_value
        # Anything else means we need the width as usual
        else:
            width_value = self.width.computed_width

        return base_sv_type_width * width_value

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
        render_width = self.width.render_rtl()
        ret_arr.append(F"typedef {render_type} [{render_width} - 1:0] {self.name}; // {self.doc_summary}")
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

    @memoize_property
    def computed_width(self):
        """Compute the width of a struct by computing width of all fields."""
        return sum([c.computed_width for c in self.children.values()])

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

    def html_canvas_data(self, label=""):
        """Return a dictionary of data to render the struct-canvas in html."""
        data = {"field_names" : [],
                "msbs" : [],
                "lsbs" : []}
        if label:
            data["label"] = label
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

    @only_run_once
    def resolve_links(self):
        if is_verilog_primitive(self.sv_type):
            self.width = Equation(self, self.width)
        else:
            self._resolve_link("sv_type", allowed_symbols=[Pkg.TYPEDEFS, Pkg.ENUMS, Pkg.STRUCTS, Pkg.UNIONS])
        super().resolve_links()
        self.check_type_width_conflicts()

    def check_type_width_conflicts(self):
        """Check to see if this struct field defines both a width and a non-logic/wire type."""
        if not is_verilog_primitive(self.sv_type) and self.width is not None:
            self.log.error(F"Struct field {self.parent.name}.{self.name} has width specified for "
                           "a non-logic/wire type. Only logic/wire can have a width")

    @memoize_property
    def computed_width(self):
        """Compute width by looking at width and type."""
        self.log.debug(F"Computing width for %s - width is %s, type is %s", self.name, self.width, self.sv_type)
        if is_verilog_primitive(self.sv_type) and isinstance(self.width, int):
            return self.width
        if is_verilog_primitive(self.sv_type):
            return self.width.computed_value
        return self.sv_type.computed_width

    def render_rtl_sv_pkg(self):
        """Render RTL in a SV pkg for this struct field."""
        if is_verilog_primitive(self.sv_type):
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


class PkgXaction(PkgStruct):
    """An Xaction is basically a struct with a few special properties.

    Instead of fields, an Xaction has cycles
    All cycles must be the same width (like a union), but the computed width is aggregate across all cycles.
    HTML rendering for an Xaction borrows the enum implementation where it renders at depth 1 instead of depth 0.
    """
    def __init__(self, **kwargs):
        kwargs['fields'] = kwargs.pop('cycles')
        super().__init__(**kwargs)

    @memoize_property
    def computed_width(self):
        """Xactions must have equal width cycles, but the total width is aggregrate across all cycles."""
        width = 0
        first = None
        for i, child in enumerate(self.children.values()):
            if i == 0:
                first = child
                width = child.computed_width
            else:
                if child.computed_width != width:
                    self.log.error(("In %s, field %s and %s have different widths: %s and %s.\n"
                                    "Union fields must be padded to match widths exactly."),
                                   self.name,
                                   first.name,
                                   child.name,
                                   width,
                                   child.computed_width)

        return width * len(self.children)

    def html_canvas_data(self):
        """Return a dictionary of data to render the struct-canvas in html."""
        all_data = []
        for child in self.children.values():
            if isinstance(child.sv_type, PkgStruct):
                all_data.append(child.sv_type.html_canvas_data(label=child.name))
                continue
            data = {"field_names" : [],
                    "msbs" : [],
                    "lsbs" : [],
                    "label" : child.name}
            current_bit = 0
            data["field_names"].insert(0, child.name)
            data["lsbs"].insert(0, current_bit)
            current_bit += child.computed_width - 1
            data["msbs"].insert(0, current_bit)
            current_bit += 1
            all_data.append(data)
        return all_data


class PkgUnion(PkgItemBase):
    """Definition for a union inside a pkg."""
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        for row in kwargs.pop('fields'):
            PkgUnionField(parent=self, log=self.log, **row)

    def __repr__(self):
        fields = "\n    -".join([str(child) for child in self.children.values()])
        return F"{id(self)} {self.name}, fields:\n    -{fields}"

    @memoize_property
    def computed_width(self):
        """Unions have a simple implemention. They must all be the same width for now (padding implemented by user)"""
        width = 0
        first = None
        for i, child in enumerate(self.children.values()):
            if i == 0:
                first = child
                width = child.computed_width
            else:
                if child.computed_width != width:
                    self.log.error(("In %s, field %s and %s have different widths: %s and %s.\n"
                                    "Union fields must be padded to match widths exactly."),
                                   self.name,
                                   first.name,
                                   child.name,
                                   width,
                                   child.computed_width)
        return width

    def render_rtl_sv_pkg(self):
        """Render the SV for this union.

        The general form is:
        // (optional) doc_verbose
        typedef union packed {
          // union_fields
        } NAME;
        """
        ret_arr = []
        # If there is no doc_verbose, don't append to ret_array to avoid extra newlines
        doc_verbose = self.render_doc_verbose(2)
        if doc_verbose:
            ret_arr.append(doc_verbose)

        ret_arr.append(F"typedef union packed {{")

        # Render each field, note they are 2 indented farther
        field_arr = []
        for child in self.children.values():
            field_arr.extend(child.render_rtl_sv_pkg())

        # Add leading spaces to make all fields line up
        field_arr[0] = F"  {field_arr[0]}"

        ret_arr.append("\n    ".join(field_arr))
        ret_arr.append(F"}} {self.name}; // {self.doc_summary}")
        return "\n  ".join(ret_arr)

    def html_canvas_data(self):
        """Return a dictionary of data to render the struct-canvas in html."""
        all_data = []
        for child in self.children.values():
            if isinstance(child.sv_type, PkgStruct):
                all_data.append(child.sv_type.html_canvas_data(label=child.name))
                continue
            data = {"field_names" : [],
                    "msbs" : [],
                    "lsbs" : [],
                    "label" : child.name}
            current_bit = 0
            data["field_names"].insert(0, child.name)
            data["lsbs"].insert(0, current_bit)
            current_bit += child.computed_width - 1
            data["msbs"].insert(0, current_bit)
            current_bit += 1
            all_data.append(data)
        return all_data

class PkgUnionField(PkgItemBase):
    """Definition for a single field inside a union."""
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

    @only_run_once
    def resolve_links(self):
        if is_verilog_primitive(self.sv_type):
            self.width = Equation(self, self.width)
        else:
            self._resolve_link("sv_type", allowed_symbols=[Pkg.TYPEDEFS, Pkg.ENUMS, Pkg.STRUCTS, Pkg.UNIONS])
        super().resolve_links()
        self.check_type_width_conflicts()


    def check_type_width_conflicts(self):
        """Check to see if this union field defines both a width and a non-logic/wire type."""
        if not is_verilog_primitive(self.sv_type) and self.width is not None:
            self.log.error(F"Union field {self.parent.name}.{self.name} has width specified for "
                           "a non-logic/wire type. Only logic/wire can have a width")

    @memoize_property
    def computed_width(self):
        """Compute width by looking at width and type."""
        self.log.debug(F"Computing width for %s - width is %s, type is %s", self.name, self.width, self.sv_type)
        if is_verilog_primitive(self.sv_type) and isinstance(self.width, int):
            return self.width
        if is_verilog_primitive(self.sv_type):
            return self.width.computed_value
        return self.sv_type.computed_width

    def render_rtl_sv_pkg(self):
        """Render RTL in a SV pkg for this union field."""
        if is_verilog_primitive(self.sv_type):
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

    def src_dst_extract(self, name):
        """Extract the source and dst out of name."""
        try:
            return re.search(r"^([a-zA-Z0-9_]+)__([a-zA-Z0-9_]+)((__)|(\.yis))", name).group(1, 2)
        except AttributeError:
            self.log.critical("Failed to extract intf src/dst from %s in %s", name, self.name)

    def src(self):
        """Return the src block for this interface"""
        return self.src_dst_extract(os.path.basename(self.source_file))[0]

    def dst(self):
        """Return the dst block for this interface"""
        return self.src_dst_extract(os.path.basename(self.source_file))[1]

    def __repr__(self):
        return (F"Intf name: {self.name}\n"
                "Components:\n  -{components}\n"
                .format(components="\n  -".join([repr(component) for component in self.children.values()])))

    @memoize_property
    def computed_width(self):
        """Compute width of the each child object, then accumulate all widths to form master width."""
        return sum([c.computed_width for c in self.children.values()])


class IntfItemBase(YisNode):
    """Base class for anything contained in an Intf."""
    def _naming_convention_callback(self):
        """All IntfItems shouldn't end with _e or _t."""
        self._check_lower_name_ending()

    def _extract_link_pieces(self, link_name):
        match = PKG_SCOPE_REGEXP.match(link_name)
        if not match:
            self.log.error(("%s has invalid %s"
                            "%s references in RTL intf files must be package scoped"),
                           self.name,
                           link_name,
                           link_name)

        # If it looks like we're scoping out of pkg
        link_pkg = match.group(1)
        link_symbol = match.group(2)

        return link_pkg, link_symbol

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

    @memoize_property
    def computed_width(self):
        """Compute width for this Component by iterating through all children."""
        return sum([c.computed_width for c in self.children.values()])


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
        if is_verilog_primitive(self.sv_type) and isinstance(self.width, int) and self.width != 1:
            self.log.error(F"{self.name} has a {self.sv_type} type with a raw int greater than 1 as the width. "
                           "The port width must be specified in a pkg and referenced by the connection.")

    @only_run_once
    def resolve_links(self):
        """Resolve links from IntfCompConn to a package.

        Note that this is similar to resolve_width_links, but only external package links are allowed here.
        """
        # If the sv_type is not a logic or wire, try to resolve the sv_type link
        if not is_verilog_primitive(self.sv_type):
            self._resolve_link("sv_type", allowed_symbols=[Pkg.ENUMS, Pkg.STRUCTS, Pkg.TYPEDEFS, Pkg.UNIONS])
        if self.width:
            self.width = Equation(self, self.width)
        # Else sv_type is a logic and it has an int width, so leave it alone
        super().resolve_links()
        self.check_type_width_conflicts()

    def check_type_width_conflicts(self):
        """Check to see if this struct field defines both a width and a non-logic/wire type."""
        if not is_verilog_primitive(self.sv_type) and self.width is not None:
            self.log.error(F"Interface connection {self.parent.name}.{self.name} has width specified for a "
                           "non-logic/wire type. Only logic/wire can have a width")

    @memoize_property
    def computed_width(self):
        """Compute width by looking at width and type."""
        if is_verilog_primitive(self.sv_type) and isinstance(self.width, int):
            return self.width
        if is_verilog_primitive(self.sv_type):
            return self.width.computed_width
        return self.sv_type.computed_width

    def _get_render_type(self):
        return F"{self.sv_type.parent.name}_rypkg::{self.sv_type.name}"

    @property
    def short_name(self):
        """Return a short version of this this name where the common intf portion is stripped out.
        This is nicer for DV where pkg scoping can become very long.
        """
        return re.search("^.*?__.*?__(.*)", self.name).group(1)

    def render_rtl_sv_pkg(self, use_short_name=False):
        """Render RTL in a SV pkg for this struct field."""
        if is_verilog_primitive(self.sv_type):
            render_type = self._render_formatted_width(self.sv_type)
        else:
            render_type = self._get_render_type()

        ret_arr = []
        # If there is no doc_verbose, don't append to ret_array to avoid extra newlines
        doc_verbose = self.render_doc_verbose(4)
        if doc_verbose:
            ret_arr.append(doc_verbose)
        name = self.short_name if use_short_name else self.name
        ret_arr.append(F"{render_type} {name}; // {self.doc_summary}")

        return ret_arr


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
