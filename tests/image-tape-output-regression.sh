#!/bin/sh
# Hardware-free regression test for image-tape output safety.
set -eu

root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmp=$(mktemp -d "${TMPDIR:-/tmp}/image-tape-test.XXXXXX")
trap 'rm -rf "$tmp"' EXIT HUP INT TERM

guix_bin=${GUIX:-guix}
find_guix_tool ()
{
  package=$1
  tool=$2
  for output in $($guix_bin build "$package"); do
    if [ -x "$output/bin/$tool" ]; then
      printf '%s\n' "$output/bin/$tool"
      return 0
    fi
  done
  echo "could not find $tool in Guix package $package" >&2
  return 1
}

tar=$(find_guix_tool tar tar)
patch=$(find_guix_tool patch patch)
dd=$(find_guix_tool coreutils dd)

compile ()
{
  "$guix_bin" shell --pure gcc-toolchain -- gcc "$@"
}

archive=${IMAGE_TAPE_SOURCE_ARCHIVE:-}
if [ -z "$archive" ]; then
  archive=$($guix_bin build -L "$root" --source larsbrinkhoff-image-tape-source)
fi
mkdir "$tmp/source"
"$tar" -xf "$archive" -C "$tmp/source"
set -- "$tmp/source"/*
if [ "$#" -ne 1 ] || [ ! -d "$1" ]; then
  echo "could not identify unpacked image-tape source" >&2
  exit 1
fi
source=$1
"$patch" -d "$source" -p1 <"$root/tay/packages/patches/image-tape-safe-output.patch"

cat >"$tmp/tape-shim.c" <<'EOF'
#include <errno.h>
#include <fcntl.h>
#include <string.h>
#include <unistd.h>

int
open_tape (const char *device)
{
  (void) device;
  return open ("/dev/null", O_RDONLY);
}

const char *
tape_drive (int fd)
{
  (void) fd;
  return "test tape";
}

int
read_record (int fd, void *buffer, size_t size)
{
  static int call;
  static const unsigned char record[] = { 0x11, 0x22, 0x33 };

  (void) fd;
  (void) size;
  switch (call++)
    {
    case 0:
      memcpy (buffer, record, sizeof record);
      return sizeof record;
    case 1:
      return 0;
    default:
      errno = EIO;
      return -1;
    }
}
EOF

cat >"$tmp/verify-image.c" <<'EOF'
#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

static uint32_t
get32 (const unsigned char *p)
{
  return (uint32_t) p[0] | ((uint32_t) p[1] << 8)
    | ((uint32_t) p[2] << 16) | ((uint32_t) p[3] << 24);
}

int
main (int argc, char **argv)
{
  unsigned char image[100];
  ssize_t n;
  size_t offset = 0;
  int fd, i;

  if (argc != 2)
    return 2;
  fd = open (argv[1], O_RDONLY);
  if (fd < 0)
    return 2;
  n = read (fd, image, sizeof image);
  close (fd);
  if (n != 99)
    return 1;
  if (get32 (image + offset) != 3)
    return 1;
  offset += 4;
  if (image[offset] != 0x11 || image[offset + 1] != 0x22
      || image[offset + 2] != 0x33)
    return 1;
  offset += 3;
  if (get32 (image + offset) != 3)
    return 1;
  offset += 4;
  if (get32 (image + offset) != 0)
    return 1;
  offset += 4;
  for (i = 0; i < 20; i++)
    {
      if (get32 (image + offset) != (0x80000000U | (EIO & 0x00ffffffU)))
        return 1;
      offset += 4;
    }
  return get32 (image + offset) == 0xffffffffU ? 0 : 1;
}
EOF

cat >"$tmp/write-shim.c" <<'EOF'
#define _GNU_SOURCE
#include <dlfcn.h>
#include <errno.h>
#include <stdlib.h>
#include <unistd.h>

typedef ssize_t (*write_fn) (int, const void *, size_t);
typedef int (*close_fn) (int);

ssize_t
write (int fd, const void *buffer, size_t count)
{
  static write_fn real_write;
  static int handled;
  const char *mode;

  if (real_write == NULL)
    real_write = (write_fn) dlsym (RTLD_NEXT, "write");
  mode = getenv ("IMAGE_TAPE_TEST_WRITE");
  if (fd == STDOUT_FILENO && !handled && mode != NULL)
    {
      handled = 1;
      if (mode[0] == 'e')
        {
          errno = ENOSPC;
          return -1;
        }
      if (mode[0] == 's' && count > 1)
        return real_write (fd, buffer, 1);
    }
  return real_write (fd, buffer, count);
}

int
close (int fd)
{
  static close_fn real_close;
  const char *mode;

  if (real_close == NULL)
    real_close = (close_fn) dlsym (RTLD_NEXT, "close");
  mode = getenv ("IMAGE_TAPE_TEST_WRITE");
  if (fd == STDOUT_FILENO && mode != NULL && mode[0] == 'c')
    {
      errno = ENOSPC;
      return -1;
    }
  return real_close (fd);
}
EOF

compile -I"$source" -o "$tmp/image-tape" "$source/main.c" "$source/image.c" \
  "$tmp/tape-shim.c"
compile -o "$tmp/verify-image" "$tmp/verify-image.c"
compile -shared -fPIC -o "$tmp/write-shim.so" "$tmp/write-shim.c" -ldl

"$tmp/image-tape" fake-tape "$tmp/fresh.img"
"$tmp/verify-image" "$tmp/fresh.img"

"$dd" if=/dev/zero of="$tmp/existing.img" bs=1 count=4096 status=none
"$tmp/image-tape" fake-tape "$tmp/existing.img"
"$tmp/verify-image" "$tmp/existing.img"

IMAGE_TAPE_TEST_WRITE=short LD_PRELOAD="$tmp/write-shim.so" \
  "$tmp/image-tape" fake-tape "$tmp/short.img"
"$tmp/verify-image" "$tmp/short.img"

if IMAGE_TAPE_TEST_WRITE=error LD_PRELOAD="$tmp/write-shim.so" \
    "$tmp/image-tape" fake-tape "$tmp/error.img"; then
  echo "image-tape unexpectedly succeeded after an injected write failure" >&2
  exit 1
fi

if IMAGE_TAPE_TEST_WRITE=close LD_PRELOAD="$tmp/write-shim.so" \
    "$tmp/image-tape" fake-tape "$tmp/close.img"; then
  echo "image-tape unexpectedly succeeded after an injected close failure" >&2
  exit 1
fi
"$tmp/verify-image" "$tmp/close.img"

echo "image-tape output regression passed"
