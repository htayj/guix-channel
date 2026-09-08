/*
 * Small PTY driver used only by the package-owned Hellcrawl --smoke mode.
 * It is built from source by the Guix package and is not a replacement for
 * the upstream game executable.
 */

#define _GNU_SOURCE

#include <errno.h>
#include <pty.h>
#include <signal.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/select.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <time.h>
#include <unistd.h>

static double
monotonic_seconds (void)
{
  struct timespec value;

  if (clock_gettime (CLOCK_MONOTONIC, &value) != 0)
    return 0.0;
  return (double) value.tv_sec + (double) value.tv_nsec / 1000000000.0;
}

static int
contains (const unsigned char *haystack, size_t haystack_length,
          const char *needle)
{
  size_t needle_length = strlen (needle);
  size_t offset;

  if (needle_length == 0 || needle_length > haystack_length)
    return 0;
  for (offset = 0; offset + needle_length <= haystack_length; offset++)
    if (memcmp (haystack + offset, needle, needle_length) == 0)
      return 1;
  return 0;
}

static int
write_all (int fd, const void *buffer, size_t length)
{
  const unsigned char *bytes = buffer;

  while (length != 0)
    {
      ssize_t written = write (fd, bytes, length);
      if (written < 0)
        {
          if (errno == EINTR)
            continue;
          return 0;
        }
      bytes += written;
      length -= (size_t) written;
    }
  return 1;
}

static void
remember (unsigned char *seen, size_t *seen_length,
          const unsigned char *data, size_t length)
{
  const size_t capacity = 65536;

  if (length >= capacity)
    {
      memcpy (seen, data + length - capacity, capacity);
      *seen_length = capacity;
      return;
    }
  if (*seen_length + length > capacity)
    {
      size_t drop = *seen_length + length - capacity;
      memmove (seen, seen + drop, *seen_length - drop);
      *seen_length -= drop;
    }
  memcpy (seen + *seen_length, data, length);
  *seen_length += length;
}

static int
send_keys (int master, const char *keys)
{
  return write_all (master, keys, strlen (keys));
}

int
main (int argc, char **argv)
{
  struct winsize window = { 24, 80, 0, 0 };
  unsigned char seen[65536];
  size_t seen_length = 0;
  int master;
  int sent_weapon = 0;
  int sent_begin = 0;
  int sent_play = 0;
  int sent_quit = 0;
  int sent_more = 0;
  int sent_inventory = 0;
  int sent_goodbye = 0;
  int timed_out = 0;
  double quit_after = -1.0;
  const double deadline = monotonic_seconds () + 30.0;
  pid_t child;
  int status;

  if (argc < 2)
    {
      fprintf (stderr, "usage: hellcrawl-smoke-pty PROGRAM [ARG ...]\n");
      return 64;
    }

  child = forkpty (&master, NULL, NULL, &window);
  if (child < 0)
    {
      perror ("forkpty");
      return 1;
    }
  if (child == 0)
    {
      execv (argv[1], argv + 1);
      _exit (127);
    }

  for (;;)
    {
      fd_set readable;
      struct timeval timeout;
      double now = monotonic_seconds ();
      double remaining = deadline - now;
      int selected;

      if (remaining <= 0.0)
        {
          timed_out = 1;
          (void) kill (child, SIGTERM);
          break;
        }
      if (sent_play && !sent_quit && quit_after >= 0.0 && now >= quit_after)
        {
          if (!send_keys (master, "\021yes\r"))
            break;
          sent_quit = 1;
        }
      if (sent_quit && !sent_more && contains (seen, seen_length, "--more--"))
        {
          if (!send_keys (master, " "))
            break;
          sent_more = 1;
        }
      if (sent_more && !sent_inventory
          && contains (seen, seen_length, "Inventory:"))
        {
          if (!send_keys (master, "\033"))
            break;
          sent_inventory = 1;
        }
      if (sent_inventory && !sent_goodbye
          && contains (seen, seen_length, "Goodbye, Goocastle."))
        {
          if (!send_keys (master, "\r"))
            break;
          sent_goodbye = 1;
        }

      FD_ZERO (&readable);
      FD_SET (master, &readable);
      timeout.tv_sec = 0;
      timeout.tv_usec = 250000;
      selected = select (master + 1, &readable, NULL, NULL, &timeout);
      if (selected < 0)
        {
          if (errno == EINTR)
            continue;
          break;
        }
      if (selected == 0)
        continue;
      if (FD_ISSET (master, &readable))
        {
          unsigned char data[4096];
          ssize_t length = read (master, data, sizeof data);

          if (length == 0 || (length < 0 && errno == EIO))
            break;
          if (length < 0)
            {
              if (errno == EINTR)
                continue;
              break;
            }
          if (!write_all (STDOUT_FILENO, data, (size_t) length))
            break;
          remember (seen, &seen_length, data, (size_t) length);

          if (!sent_weapon && contains (seen, seen_length, "choice of weapons"))
            {
              if (!send_keys (master, "a"))
                break;
              sent_weapon = 1;
            }
          if (sent_weapon && !sent_begin
              && contains (seen, seen_length, "[Enter] Begin!"))
            {
              if (!send_keys (master, "\r"))
                break;
              sent_begin = 1;
            }
          if (sent_begin && !sent_play && contains (seen, seen_length, "Health:"))
            {
              if (!send_keys (master, ".l"))
                break;
              sent_play = 1;
              quit_after = monotonic_seconds () + 0.25;
            }
        }
    }

  if (timed_out)
    (void) waitpid (child, &status, 0);
  else if (waitpid (child, &status, 0) < 0)
    return 1;

  close (master);
  if (!sent_weapon || !sent_begin || !sent_play || !sent_quit
      || !sent_more || !sent_inventory || !sent_goodbye || timed_out)
    return 1;
  if (!WIFEXITED (status) || WEXITSTATUS (status) != 0)
    return 1;
  return 0;
}
