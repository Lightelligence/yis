import re

from instruction_pb2 import Field, InstructionFormat, AllInstructionFormat


def walk_fields(iformat, struct):
    # This is gross, need a better way to do it:
    if 'Struct' in struct.sv_type.__class__.__name__:
        for child in struct.sv_type.children.values():
            walk_fields(iformat, child)
    elif 'Union' in struct.sv_type.__class__.__name__:
        raise ValueError("Unions not support in instruction generator")
    else:
        new_field = iformat.fields.add()
        new_field.CopyFrom(Field(name=struct.name, width=struct.computed_width))
        # iformat.fields.append(Field(name=struct.name, width=struct.computed_width))


def store_op_codes(enums, op_code_map):
    for enum in enums.children.values():
        op_code_map[enum.name.upper()] = enum.sv_value


def render(pkg):
    """Render the packages as a proto definition."""

    aif = AllInstructionFormat()

    for child in pkg.children.values():
        if child.name == "OPCODE__ET":
            store_op_codes(child, aif.op_code_map)
            continue

        if not re.search("^([a-zA-Z0-9_\-]+) instruction\.$", child.doc_summary):
            # FIXME ^^ need a better way to indicate this
            continue

        struct = child
        instruction_name = re.search("^([a-z0-9_]+)__st$", struct.name).group(1)

        iformat = InstructionFormat(name=instruction_name.upper())
        for struct_child in struct.children.values():
            walk_fields(iformat, struct_child)

        new_format = aif.instruction_formats.add()
        new_format.CopyFrom(iformat)
        # aif.instruction_formats.append(iformat)

    return aif.SerializeToString()
    # For debug write as text
    # Also need to edit yis.py to change open file call to not be binary
    # return str(aif)
