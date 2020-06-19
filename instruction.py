import re

from digital.rtl.scripts.yis.instruction_pb2 import Field, InstructionFormat, AllInstructionFormat


def walk_fields(iformat, struct):
    # This is gross, need a better way to do it:
    if 'Struct' in struct.sv_type.__class__.__name__:
        for child in struct.sv_type.children.values():
            walk_fields(iformat, child)
    elif 'Union' in struct.sv_type.__class__.__name__:
        raise ValueError("Unions not support in instruction generator")
    else:
        iformat.fields.append(Field(name=struct.name, width=struct.computed_width))


def render(pkg):
    """Render the packages as a proto definition."""

    aif = AllInstructionFormat()

    for child in pkg.children.values():
        if not re.search("^([a-zA-Z0-9_\-]+) instruction\.$", child.doc_summary):
            # FIXME ^^ need a better way to indicate this
            continue

        struct = child
        instruction_name = re.search("^([a-z0-9_]+)__st$", struct.name).group(1)

        iformat = InstructionFormat(name=instruction_name)
        for struct_child in struct.children.values():
            walk_fields(iformat, struct_child)

        aif.instruction_formats.append(iformat)

    return aif.SerializeToString()
    # For debug write as text
    # Also need to edit yis.py to change open file call to not be binary
    # return str(aif)
