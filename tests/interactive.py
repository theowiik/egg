"""Exercise idle redraws and directory hooks inside an actual terminal."""
import errno
import fcntl
import os
from pathlib import Path
import pty
import re
import select
import struct
import termios
import time

root = Path(os.environ["PREVIEW_ROOT"])
clock = re.compile(r"\d{2}:\d{2}:\d{2}")

pid, fd = pty.fork()
if pid == 0:
    env = dict(os.environ, TERM="xterm-256color", LAZYSHELL_NO_WELCOME="1")
    os.execve(os.environ["PREVIEW"], [os.environ["PREVIEW"]], env)

fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", 30, 120, 0, 0))


def read_for(seconds):
    result = bytearray()
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        ready, _, _ = select.select([fd], [], [], max(0, min(0.1, deadline - time.monotonic())))
        if ready:
            try:
                chunk = os.read(fd, 65536)
            except OSError as exc:
                if exc.errno == errno.EIO:
                    break
                raise
            if not chunk:
                break
            result.extend(chunk)
    return result.decode(errors="replace")


def send(command):
    os.write(fd, command.encode())


try:
    output = ""
    deadline = time.monotonic() + 30
    while not clock.search(output) and time.monotonic() < deadline:
        output += read_for(0.2)
    assert clock.search(output), "live prompt did not start: " + output

    output = read_for(2.3)
    assert len(set(clock.findall(output))) >= 2, "clock did not tick while idle: " + output

    # Count expensive prompt renders, then leave a partially typed command idle.
    send('typeset -gi render_count=0; functions[_lazyshell_clock_cache]="(( ++render_count )); ${functions[_lazyshell_clock_cache]}"\n')
    read_for(0.7)
    send('print -r -- "BUFFER_SURVIVES:$render_count"')
    output = read_for(2.3)
    assert len(set(clock.findall(output))) >= 2, "clock stopped with a partial input buffer"
    send('\n')
    output = read_for(0.7)
    assert "BUFFER_SURVIVES:1" in output, "redraw changed input or rerendered Starship: " + output

    # A directory listing should come from the hook, not echoed command text.
    destination = root / "home" / "enter-me"
    destination.mkdir()
    (destination / "AUTO_LIST_TOKEN").touch()
    send('cd "$HOME/enter-me"\n')
    output = read_for(0.7)
    assert "AUTO_LIST_TOKEN" in output, "directory contents were not listed: " + output
    send('cd "$HOME/missing-directory"\n')
    output = read_for(0.7)
    assert "AUTO_LIST_TOKEN" not in output, "failed cd triggered a listing"
    send('cd "$HOME"; cd "$HOME/enter-me" > "$HOME/redirected"\n')
    read_for(0.7)
    assert (root / "home" / "redirected").read_bytes() == b"", "listing polluted redirected output"
    send('captured=$(cd "$HOME/enter-me"; print CAPTURE_TOKEN); print -r -- "$captured"\n')
    output = read_for(0.7)
    assert "AUTO_LIST_TOKEN" not in output, "listing polluted command substitution"
    send('LAZYSHELL_NO_AUTO_LS=1; cd "$HOME/enter-me"\n')
    output = read_for(0.7)
    assert "AUTO_LIST_TOKEN" not in output, "directory listing opt-out did not work"

    # No redraws should run over a foreground command's output.
    send('touch "$HOME/foreground-started"; sleep 2\n')
    deadline = time.monotonic() + 10
    while not (root / "home" / "foreground-started").exists():
        read_for(0.1)
        assert time.monotonic() < deadline, "foreground command did not start"
    output = read_for(1.2)
    assert not clock.search(output), "clock repainted during a foreground command: " + output
    output = read_for(2)
    assert clock.search(output), "clock did not resume after a command"
    send('false\n')
    read_for(2.2)
    send('print -r -- "LAST_STATUS:$?"\n')
    output = read_for(0.7)
    assert "LAST_STATUS:1" in output, "clock changed the last command status: " + output
    send('exit\n')
    read_for(0.5)
    _, status = os.waitpid(pid, 0)
    pid = None
    assert os.waitstatus_to_exitcode(status) == 0
    assert not root.exists(), "interactive preview did not clean up"
finally:
    if pid is not None:
        send('\x03exit\n')
        read_for(0.5)
        os.waitpid(pid, 0)
    os.close(fd)

print("Interactive directory listing and live clock checks passed")
