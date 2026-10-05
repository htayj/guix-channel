#!/usr/bin/env python3
"""Compile installed Affect libraries and exercise their real native API."""
import ctypes
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

out, evidence, scratch = map(Path, sys.argv[1:4])
compiler, findlib, cmdliner, gcc = map(Path, sys.argv[4:8])


def require(condition, message):
    if not condition:
        raise AssertionError(message)


require(os.getuid() == int(os.environ['EXPECTED_UID']), 'namespace changed UID')
require(os.getgid() == int(os.environ['EXPECTED_GID']), 'namespace changed GID')
libc = ctypes.CDLL(None, use_errno=True)
libc.mount.argtypes = [ctypes.c_char_p, ctypes.c_char_p, ctypes.c_char_p,
                       ctypes.c_ulong, ctypes.c_void_p]
for source, target, kind, flags in [
    (b'/gnu/store', b'/gnu/store', None, 4096),
    (b'/gnu/store', b'/gnu/store', None, 4096 | 32 | 1 | 2 | 4),
    (b'proc', b'/proc', b'proc', 2 | 4 | 8),
]:
    if libc.mount(source, target, kind, flags, None):
        error = ctypes.get_errno()
        raise OSError(error, os.strerror(error), os.fsdecode(target))
require(bool(os.statvfs('/gnu/store').f_flag & os.ST_RDONLY), 'store is writable')
net_ns = os.readlink('/proc/self/ns/net')
pid_ns = os.readlink('/proc/self/ns/pid')
require(net_ns != os.environ['HOST_NET_NS'], 'network namespace not isolated')
require(pid_ns != os.environ['HOST_PID_NS'], 'PID namespace not isolated')
require(os.getpid() == 1, 'private proc mount lacks PID namespace')
interfaces = [line.split(':')[0].strip()
              for line in Path('/proc/net/dev').read_text().splitlines() if ':' in line]
require(interfaces == ['lo'], 'external network interface present')
for key in ('HOME', 'XDG_CONFIG_HOME', 'XDG_CACHE_HOME', 'XDG_DATA_HOME',
            'XDG_STATE_HOME', 'XDG_RUNTIME_DIR'):
    Path(os.environ[key]).mkdir(mode=0o700)
os.chdir(scratch)

# The package records the exact compiler that built its CMIs/CMXAs.  Never
# resolve the distribution's default compiler or bring a second ABI into play.
os.environ['PATH'] = ':'.join([str(compiler / 'bin'), str(findlib / 'bin'),
                              str(gcc / 'bin'), os.environ['PATH']])
os.environ['OCAMLLIB'] = str(compiler / 'lib/ocaml')
os.environ['OCAMLPATH'] = ':'.join(map(str, [out / 'lib/ocaml/site-lib',
    cmdliner / 'lib/ocaml/site-lib', compiler / 'lib/ocaml']))
os.environ['CAML_LD_LIBRARY_PATH'] = str(out / 'lib/ocaml/site-lib/stublibs')


def run(label, command):
    with (evidence / (label + '.stdout')).open('wb') as stdout, \
         (evidence / (label + '.stderr')).open('wb') as stderr:
        subprocess.run(list(map(str, command)), stdin=subprocess.DEVNULL,
                       stdout=stdout, stderr=stderr, check=True, timeout=90)
    return (evidence / (label + '.stdout')).read_text()


version = run('compiler-version', [compiler / 'bin/ocamlopt', '-version']).strip()
require(tuple(map(int, version.split('.')[:2])) >= (5, 5), 'compiler below 5.5')
findlib_version = run('findlib-compiler-version', [findlib / 'bin/ocamlfind',
                                                'ocamlopt', '-version']).strip()
require(version == findlib_version, 'findlib selected a different compiler')
for package, path in [('affect', out), ('affect.unix', out), ('affect.tmp', out),
                      ('affect.cli', out), ('cmdliner', cmdliner)]:
    resolved = run('query-' + package, [findlib / 'bin/ocamlfind', 'query', package]).strip()
    require(Path(resolved).is_relative_to(path), 'wrong installed library: ' + package)
cmdliner_version = run('cmdliner-version', [findlib / 'bin/ocamlfind', 'query',
    '-format', '%v', 'cmdliner']).strip()
require(int(cmdliner_version.split('.')[0]) >= 2, 'Cmdliner below version 2')
commit = (out / 'share/affect/source-commit').read_text().strip()
require(commit == '780faa266d62f9567fd9d23f84bddc77f77087c0', 'wrong source commit')


def compile_native(label, source, packages):
    executable = scratch / (label + '.native')
    run('compile-' + label, [findlib / 'bin/ocamlfind', 'ocamlopt', '-thread',
        '-package', packages, '-linkpkg', source, '-o', executable])
    require(executable.read_bytes()[:4] == b'\x7fELF', 'consumer is not native ELF')
    return executable


for label in ('quick_start', 'blueprint_cli'):
    source = scratch / (label + '.ml')
    shutil.copyfile(out / 'share/affect/examples' / (label + '.ml'), source)
    binary = compile_native(label, source, 'affect.cli,affect.unix,affect.tmp')
    if label == 'quick_start':
        require(run(label, [binary]) == '3', 'upstream native quick-start result')
    else:
        require('SYNOPSIS' in run('cli-help', [binary, '--help=plain']),
                'upstream CLI did not expose Cmdliner help')
        run('cli-run', [binary, '-P', '2'])

consumer_source = r'''open Affect
module U = Affect_unix.Unix
module M = Affect_unix.Mtime

let require condition message = if not condition then failwith message
exception Expected_failure

let concurrency domains =
  Fun.Async.main ~domain_count:domains @@ fun () ->
  let jobs = List.init 100 (fun index -> Fun.Async.call @@ fun () ->
    Fun.Async.yield (); index + 1) in
  require (List.fold_left (+) 0 (Fun.Async.get_all jobs) = 5050)
    "concurrent results differ";
  let failed = Fun.Async.call (fun () -> raise Expected_failure) in
  let propagated = try ignore (Fun.Async.get failed); false
    with Expected_failure -> true in
  require propagated "child exception did not propagate"

let unix_io domains = U.main ~domain_count:domains @@ fun () ->
  let rd, wr = U.pipe ~cloexec:true () in
  U.set_nonblock rd; U.set_nonblock wr;
  Fun.Async.protect ~finally:(fun () -> U.close_noerr rd; U.close_noerr wr) @@ fun () ->
  let message = "affect-native-pipe-roundtrip" in
  let reader = Fun.Async.call @@ fun () ->
    let bytes = Bytes.create (String.length message) in
    let rec loop offset = if offset < Bytes.length bytes then begin
      let count = U.read rd bytes offset (Bytes.length bytes - offset) in
      require (count > 0) "unexpected pipe EOF"; loop (offset + count)
    end in
    loop 0; Bytes.to_string bytes
  in
  let writer = Fun.Async.call @@ fun () ->
    M.wait_for M.Span.(1 * ms);
    let rec loop offset = if offset < String.length message then begin
      let count = U.write_substring wr message offset (String.length message - offset) in
      require (count > 0) "empty pipe write"; loop (offset + count)
    end in loop 0
  in
  require (Fun.Async.get reader = message) "Unix cooperative I/O mismatch";
  Fun.Async.get writer;
  U.close wr;
  require (U.read rd (Bytes.create 1) 0 1 = 0) "EOF was not delivered"

let unix_cancel domains = U.main ~domain_count:domains @@ fun () ->
  let rd, wr = U.pipe ~cloexec:true () in
  U.set_nonblock rd; U.set_nonblock wr;
  Fun.Async.protect ~finally:(fun () -> U.close_noerr rd; U.close_noerr wr) @@ fun () ->
  let ready = Port.make () in
  let finalized = Atomic.make false in
  let blocked = Fun.Async.call @@ fun () ->
    Fun.Async.protect ~finally:(fun () -> Atomic.set finalized true) @@ fun () ->
    Port.offer ready ();
    ignore (U.read rd (Bytes.create 1) 0 1)
  in
  Port.take ready;
  M.wait_for M.Span.(1 * ms);
  require (not (Fun.Async.has_returned blocked)) "empty pipe read failed to block";
  Fun.Async.cancel blocked;
  let cancelled = try Fun.Async.get blocked; false
    with Fun.Async.Cancelled -> true in
  require cancelled "blocked Unix read was not cancelled";
  require (Atomic.get finalized) "cancellation skipped protected finalizer";
  (* Exercise the native fd watcher after the cancelled read's blocker is removed. *)
  M.wait_for M.Span.(1 * ms);
  let bad, other = U.pipe ~cloexec:true () in
  U.close bad;
  let raises_ebadf action = try Action.invoke action; false
    with U.Unix_error (U.EBADF, _, _) -> true in
  require (raises_ebadf (U.wait_readable bad ())) "wait_readable lost EBADF";
  require (raises_ebadf (U.wait_writable bad ())) "wait_writable lost EBADF";
  U.close other

let () =
  List.iter (fun domains ->
    concurrency domains;
    Printf.printf "CONCURRENCY domains=%d sum=5050 exception=propagated\n%!" domains;
    unix_io domains;
    Printf.printf "UNIX_IO domains=%d roundtrip=ok eof=ok\n%!" domains;
    unix_cancel domains;
    Printf.printf "UNIX_CANCEL domains=%d cancelled=ok finalizer=ok ebadf=ok\n%!" domains
  ) [1; 2]
'''
source = scratch / 'consumer.ml'
source.write_text(consumer_source)
(evidence / 'consumer.ml').write_text(consumer_source)
binary = compile_native('consumer', source, 'affect.cli,affect.unix,affect.tmp')
result = run('consumer', [binary])
for domains in (1, 2):
    for marker in ('CONCURRENCY', 'UNIX_IO', 'UNIX_CANCEL'):
        require(f'{marker} domains={domains} ' in result, 'missing real API scenario')
(evidence / 'runtime.json').write_text(json.dumps({
    'status': 'passed', 'uid': os.getuid(), 'gid': os.getgid(),
    'store_read_only': True, 'network_namespace': net_ns, 'pid_namespace': pid_ns,
    'host_network_namespace': os.environ['HOST_NET_NS'],
    'host_pid_namespace': os.environ['HOST_PID_NS'], 'interfaces': interfaces,
    'source_commit': commit, 'compiler': str(compiler), 'findlib': str(findlib),
    'compiler_version': version, 'cmdliner_version': cmdliner_version,
    'native_elf_consumers': ['quick_start', 'blueprint_cli', 'consumer'],
    'domain_counts': [1, 2],
    'scenarios': ['upstream quick-start', 'Cmdliner CLI', 'async values and exception',
                  'cooperative pipe read/write and EOF', 'blocked read cancellation',
                  'protected finalizer', 'closed fd readable/writable EBADF'],
    'upstream_full_b0_suite_run': False,
    'limitations': ['No full B0_testing/stress suites or external network interoperability'],
}, indent=2) + '\n')
