import socket
import sys

port = int(sys.argv[1])
output_path = sys.argv[2]

server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
server.bind(("127.0.0.1", port))
server.listen()

while True:
    connection, _ = server.accept()
    buffer = b""
    while True:
        chunk = connection.recv(65536)
        if not chunk:
            break
        buffer += chunk
        while b"\x1c\x0d" in buffer:
            frame, buffer = buffer.split(b"\x1c\x0d", 1)
            message = frame.lstrip(b"\x0b").decode()
            with open(output_path, "a") as output:
                output.write(message.replace("\r", "\n") + "\n\n")
            msh_fields = message.split("\r")[0].split("|")
            control_id = msh_fields[9]
            ack = (
                f"MSH|^~\\&|{msh_fields[4]}|{msh_fields[5]}|{msh_fields[2]}|{msh_fields[3]}|{msh_fields[6]}||ACK|{control_id}|P|2.5\r"
                f"MSA|AA|{control_id}\r"
            )
            connection.sendall(b"\x0b" + ack.encode() + b"\x1c\x0d")
    connection.close()
