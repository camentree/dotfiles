import sys

def varint(number):
    out = bytearray()
    while True:
        byte = number & 0x7F
        number >>= 7
        if number:
            out.append(byte | 0x80)
        else:
            out.append(byte)
            return bytes(out)

def length_delimited(field, payload):
    return varint((field << 3) | 2) + varint(len(payload)) + payload

field = int(sys.argv[1])
systems = {"PHONE": 1, "FAX": 2, "EMAIL": 3}
result = b""
for entry in sys.argv[2:]:
    system, value = entry.split("=", 1)
    string_value = length_delimited(1, value.encode())
    contact_point = bytes([0x08, systems[system]]) + length_delimited(2, string_value) + bytes([0x18, 1])
    result += length_delimited(field, contact_point)
print(result.hex())
