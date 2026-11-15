#!/usr/bin/python3 -I
import json
import os
import socket
import struct
import sys
import threading

socket_path = os.path.expanduser("~/.cache/tab-grouper.sock")
answer_timeout_seconds = 5

pending: dict[int, dict] = {}
pending_lock = threading.Lock()
stdout_lock = threading.Lock()
next_request_id = 0


def send_to_extension(message: dict) -> None:
    encoded = json.dumps(message).encode()
    with stdout_lock:
        sys.stdout.buffer.write(struct.pack("=I", len(encoded)))
        sys.stdout.buffer.write(encoded)
        sys.stdout.buffer.flush()


def read_from_extension() -> None:
    while True:
        header = sys.stdin.buffer.read(4)
        if len(header) < 4:
            break
        (length,) = struct.unpack("=I", header)
        message = json.loads(sys.stdin.buffer.read(length))
        with pending_lock:
            waiter = pending.get(message.get("id"))
        if waiter:
            waiter["answer"] = message
            waiter["event"].set()
    if os.path.exists(socket_path):
        os.unlink(socket_path)
    os._exit(0)


def answer_client(connection: socket.socket) -> None:
    global next_request_id
    with connection, connection.makefile("rwb") as stream:
        line = stream.readline()
        try:
            request = json.loads(line)
        except json.JSONDecodeError:
            answer = {"ok": False, "error": "request is not JSON"}
        else:
            with pending_lock:
                next_request_id += 1
                request_id = next_request_id
                waiter = {"event": threading.Event(), "answer": None}
                pending[request_id] = waiter
            send_to_extension({**request, "id": request_id})
            if waiter["event"].wait(answer_timeout_seconds):
                answer = waiter["answer"]
            else:
                answer = {"ok": False, "error": "the Tab Grouper extension did not answer"}
            with pending_lock:
                pending.pop(request_id, None)
        stream.write(json.dumps(answer).encode() + b"\n")
        stream.flush()


def main() -> None:
    os.makedirs(os.path.dirname(socket_path), exist_ok=True)
    if os.path.exists(socket_path):
        os.unlink(socket_path)
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(socket_path)
    server.listen()
    threading.Thread(target=read_from_extension, daemon=True).start()
    while True:
        connection, _ = server.accept()
        threading.Thread(target=answer_client, args=(connection,), daemon=True).start()


main()
