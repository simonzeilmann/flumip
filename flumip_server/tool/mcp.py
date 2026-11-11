#!/usr/bin/env python3
"""Calls Serverpod's and Dart's MCP servers from a shell.

Both servers speak MCP over stdio and are meant to be registered with an agent
(`.mcp.json`). That registration is not allowed here, so this is the same
conversation held by hand: start the server, initialize, run the commands given
on the command line in one session, print what comes back.

    tool/mcp.py serverpod list
    tool/mcp.py serverpod call tail_server_logs '{"limit": 30}'
    tool/mcp.py serverpod call hot_restart
    tool/mcp.py serverpod read serverpod://vm-service

    tool/mcp.py dart list
    tool/mcp.py dart --app call get_runtime_errors
    tool/mcp.py dart --app call widget_inspector '{"command": "get_widget_tree", "summaryOnly": true}'

Several commands may follow one another; they share the session, which matters
for the Dart server, where connecting to an app and then asking about it are two
calls. `--app` does the connecting: it asks the Serverpod runner for the Flutter
app's Dart Tooling Daemon address and connects before the first command.

`serverpod` needs the runner (`tool/dev.sh up`); only `tail_runner_logs` works
without it. `dart --app` also needs the app (`tool/dev.sh app`).

Not everything answers: Dart's `analyze_files` gave nothing back within three
minutes through this client. `dart analyze` is the tool for that anyway.

Exits 1 when a tool reports an error, 2 on a usage or protocol problem.
"""

import json
import os
import select
import shutil
import subprocess
import sys

SERVER_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
REPO = os.path.dirname(SERVER_DIR)
HOME = os.path.expanduser('~')
TIMEOUT = float(os.environ.get('FLUMIP_MCP_TIMEOUT', '180'))


def find(name, fallback):
    return shutil.which(name) or fallback


SERVERS = {
    'serverpod': [
        find('serverpod', f'{HOME}/.local/state/Dart/install/bin/serverpod'),
        '--no-analytics', 'mcp-server', '--server-dir', SERVER_DIR,
    ],
    'dart': [find('dart', f'{HOME}/frameworks/flutter/bin/dart'), 'mcp-server'],
}

# What the Dart server may look at: the three packages.
ROOTS = [
    {'uri': f'file://{REPO}/{name}', 'name': name}
    for name in ('flumip_server', 'flumip_client', 'flumip_flutter')
]


class Session:
    def __init__(self, argv):
        env = dict(os.environ)
        env['PATH'] = os.pathsep.join(
            [env.get('PATH', ''), f'{HOME}/frameworks/flutter/bin',
             f'{HOME}/.local/state/Dart/install/bin'])
        self.proc = subprocess.Popen(
            argv, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL, text=True, env=env)
        self.next_id = 0
        self.request('initialize', {
            'protocolVersion': '2025-06-18',
            'capabilities': {'roots': {}},
            'clientInfo': {'name': 'flumip-tool', 'version': '1'},
        })
        self.send({'jsonrpc': '2.0', 'method': 'notifications/initialized'})

    def send(self, message):
        self.proc.stdin.write(json.dumps(message) + '\n')
        self.proc.stdin.flush()

    def request(self, method, params=None):
        self.next_id += 1
        message = {'jsonrpc': '2.0', 'id': self.next_id, 'method': method}
        if params is not None:
            message['params'] = params
        self.send(message)
        while True:
            ready, _, _ = select.select([self.proc.stdout], [], [], TIMEOUT)
            if not ready:
                sys.exit(f'No answer to {method} within {TIMEOUT:.0f} s.')
            line = self.proc.stdout.readline()
            if not line:
                sys.exit(f'The MCP server closed the connection during {method}.')
            try:
                reply = json.loads(line)
            except ValueError:
                continue
            if 'method' in reply and 'id' in reply:
                self.answer(reply)
            elif reply.get('id') == self.next_id:
                if 'error' in reply:
                    sys.exit(f"{method}: {reply['error'].get('message', reply['error'])}")
                return reply['result']

    def answer(self, request):
        """The server asking the client something. Only roots are offered."""
        if request['method'] == 'roots/list':
            result = {'roots': ROOTS}
        elif request['method'] == 'ping':
            result = {}
        else:
            self.send({'jsonrpc': '2.0', 'id': request['id'],
                       'error': {'code': -32601, 'message': 'Not supported'}})
            return
        self.send({'jsonrpc': '2.0', 'id': request['id'], 'result': result})

    def call(self, tool, arguments=None):
        result = self.request('tools/call',
                              {'name': tool, 'arguments': arguments or {}})
        text = '\n'.join(part.get('text', json.dumps(part))
                         for part in result.get('content', []))
        return text, bool(result.get('isError'))

    def close(self):
        try:
            self.proc.stdin.close()
            self.proc.terminate()
            self.proc.wait(timeout=5)
        except Exception:
            self.proc.kill()


def readable(text):
    """Serverpod's log tools answer with one JSON array; print it as lines."""
    try:
        entries = json.loads(text)
    except ValueError:
        return text
    if isinstance(entries, list) and all(isinstance(e, str) for e in entries):
        return '\n'.join(entries)
    if isinstance(entries, dict) and 'description' in entries and 'children' in entries:
        return outline(entries)
    if not (isinstance(entries, list) and entries
            and all(isinstance(e, dict) for e in entries)):
        return text if not isinstance(entries, (dict, list)) else json.dumps(entries, indent=2)
    lines = []
    for e in entries:
        if e.get('type') == 'operation':
            mark = 'ok  ' if e.get('success') else 'FAIL'
            lines.append(f"{e.get('completedAt', '')}  {mark}  {e.get('label', '')}"
                         f"  {e.get('durationMs', '?')} ms")
        elif e.get('type') == 'log':
            message = str(e.get('message', '')).replace('\n', '\n    ')
            lines.append(f"{e.get('time', '')}  {e.get('level', ''):5} {message}")
            for key in ('error', 'stackTrace'):
                if e.get(key):
                    lines.append('    ' + str(e[key]).replace('\n', '\n    '))
        else:
            lines.append(json.dumps(e))
    return '\n'.join(lines)


def outline(node, depth=0):
    """A widget tree as indented names; `*` marks widgets from this project."""
    mark = '*' if node.get('createdByLocalProject') else ' '
    lines = [f"{mark} {'  ' * depth}{node.get('description', '?')}"]
    for child in node.get('children') or []:
        lines.append(outline(child, depth + 1))
    return '\n'.join(lines)


def flutter_app_dtd():
    """The running Flutter app's DTD address, from the Serverpod runner."""
    bridge = Session(SERVERS['serverpod'])
    try:
        text, failed = bridge.call('get_flutter_app_dtd')
    finally:
        bridge.close()
    if failed:
        sys.exit(text)
    uris = [uri for uri in json.loads(text).values() if uri]
    if not uris:
        sys.exit('The Flutter app is not running under the runner yet. '
                 'Start it with tool/dev.sh app and wait for it to load.')
    return uris[0]


def usage(problem=None):
    if problem:
        print(problem, file=sys.stderr)
    print(__doc__, file=sys.stderr)
    sys.exit(2)


def main(args):
    if not args or args[0] in ('-h', '--help', 'help'):
        usage()
    server = args.pop(0)
    if server not in SERVERS:
        usage(f'Unknown server "{server}": serverpod or dart.')
    connect_app = False
    if args and args[0] == '--app':
        if server != 'dart':
            usage('--app belongs to the dart server.')
        connect_app = True
        args.pop(0)
    if not args:
        usage('Nothing to do: list, call <tool> [json] or read <uri>.')

    dtd = flutter_app_dtd() if connect_app else None
    session = Session(SERVERS[server])
    failed = False
    try:
        if dtd:
            text, error = session.call('dtd', {'command': 'connect', 'uri': dtd})
            if error:
                sys.exit(text)
        while args:
            command = args.pop(0)
            if command == 'list':
                for tool in session.request('tools/list')['tools']:
                    summary = ' '.join((tool.get('description') or '').split())
                    print(f"{tool['name']}: {summary[:150]}")
                try:
                    for res in session.request('resources/list')['resources']:
                        print(f"resource {res['uri']}")
                except SystemExit:
                    pass
            elif command == 'call':
                if not args:
                    usage('call needs a tool name.')
                tool = args.pop(0)
                arguments = {}
                if args and args[0].lstrip().startswith('{'):
                    try:
                        arguments = json.loads(args.pop(0))
                    except ValueError as e:
                        usage(f'The arguments for {tool} are not JSON: {e}')
                text, error = session.call(tool, arguments)
                print(readable(text))
                failed = failed or error
            elif command == 'read':
                if not args:
                    usage('read needs a resource uri.')
                result = session.request('resources/read', {'uri': args.pop(0)})
                for part in result.get('contents', []):
                    print(part.get('text', json.dumps(part)))
            else:
                usage(f'Unknown command "{command}".')
    finally:
        session.close()
    sys.exit(1 if failed else 0)


if __name__ == '__main__':
    main(sys.argv[1:])
