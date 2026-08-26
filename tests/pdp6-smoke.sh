#!/bin/sh
set -eu
guix_bin=${GUIX:-guix}
channel_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
out=${1:-$($guix_bin build -L "$channel_dir" --no-grafts --no-substitutes pdp6)}
find_output() { for p in $($guix_bin build "$2"); do test -x "$p/$1" && { printf '%s\n' "$p"; return; }; done; return 1; }
python=$(find_output bin/python3 python)
xorg=$(find_output bin/Xvfb xorg-server)
xwininfo=$(find_output bin/xwininfo xwininfo)
util=$(find_output bin/unshare util-linux)
test -x "$out/bin/pdp6"; test -x "$out/libexec/pdp6/pdp6"
test ! -e "$out/libexec/pdp6/init.ini" || ! grep -E 'net(mem|cons)|mount' "$out/libexec/pdp6/init.ini"
exec "$util/bin/unshare" --user --map-root-user --net --fork "$python/bin/python3" - "$out" "$xorg/bin/Xvfb" "$xwininfo/bin/xwininfo" <<'PY'
import os,pathlib,subprocess,sys,tempfile,time
out,xvfb,xwininfo=map(pathlib.Path,sys.argv[1:])
with tempfile.TemporaryDirectory() as t:
 p=pathlib.Path(t); env={'HOME':str(p),'XDG_RUNTIME_DIR':str(p),'DISPLAY':':99','SDL_VIDEODRIVER':'x11','SDL_AUDIODRIVER':'dummy','SDL_JOYSTICK_DISABLED':'1','PATH':''}
 x=subprocess.Popen([xvfb,':99','-screen','0','1399x740x24','-nolisten','tcp'],env=env)
 try:
  time.sleep(.4); assert x.poll() is None
  q=subprocess.Popen([out/'bin/pdp6'],env=env,cwd=p)
  for _ in range(60):
   r=subprocess.run([xwininfo,'-root','-tree'],env=env,text=True,stdout=subprocess.PIPE)
   if '0x200001' in r.stdout: break
   time.sleep(.1)
  else: raise AssertionError('PDP-6 console window missing: '+r.stdout)
  q.terminate(); q.wait(5)
 finally:
  x.terminate(); x.wait(5)
print('pdp6 offline smoke passed')
PY
