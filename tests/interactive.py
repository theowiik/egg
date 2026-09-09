"""Exercise idle prompt redraws inside an actual terminal."""
import errno
import fcntl
import os
from pathlib import Path
import pty
import re
import select
import signal
import struct
import termios
import time

root = Path(os.environ["PREVIEW_ROOT"])
clock = re.compile(r"\d{2}:\d{2}:\d{2}")

pid, fd = pty.fork()
if pid == 0:
    env = dict(os.environ, TERM="xterm-256color", EGG_NO_WELCOME="")
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
    assert "egg help" in output, "compact welcome missing: " + output
    assert " tools" in output, "welcome context missing: " + output
    assert not any(label in output for label in ("Memory", "Kernel", "Machine", "CPU")), "startup still displays hardware information: " + output

    output = read_for(2.3)
    assert len(set(clock.findall(output))) >= 2, "clock did not tick while idle: " + output

    # Count expensive prompt renders, then leave a partially typed command idle.
    send('typeset -gi render_count=0; functions[_egg_clock_cache]="(( ++render_count )); ${functions[_egg_clock_cache]}"\n')
    read_for(0.7)
    send('print -r -- "BUFFER_SURVIVES:$render_count"')
    output = read_for(2.3)
    assert len(set(clock.findall(output))) >= 2, "clock stopped with a partial input buffer"
    send('\n')
    output = read_for(0.7)
    assert "BUFFER_SURVIVES:1" in output, "redraw changed input or rerendered Starship: " + output

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
    # Exercise real Git output as well as the gated worker below. A literal
    # marker in the path must survive insertion, and Git must remain inline.
    send('mkdir "$HOME/EGG_GIT_CONTEXT"; cd "$HOME/EGG_GIT_CONTEXT"; git init -q; git -c user.name=Test -c user.email=test@example.invalid commit --allow-empty -qm initial; git checkout -qb egg-speed-test; touch changed\n')
    deadline = time.monotonic() + 10
    while True:
        read_for(0.3)
        send('print -r -- "$_egg_git_context" > "$HOME/real-git"; print -r -- "$_egg_clock_left" > "$HOME/real-prompt"\n')
        read_for(0.3)
        context = (root / "home/real-git").read_text().rstrip('\n')
        if "egg-speed-test" in context:
            break
        assert time.monotonic() < deadline, "real Git context did not arrive"
    assert '\n' not in context and '?1' in context, "Git split the prompt or lost status: " + repr(context)
    assert 'EGG_GIT_CONTEXT' in (root / "home/real-prompt").read_text(), "Git insertion overwrote the path"

    # Inspect the prompt as data rather than typing Unicode into the terminal;
    # minimal build environments may not have the requested UTF-8 locale.
    send('print -r -- "$RPROMPT" > "$HOME/clock-style"\n')
    read_for(0.7)
    clock_style = (root / "home/clock-style").read_text()
    assert "%F{#ff7a26}" in clock_style and "" not in clock_style and "%K{" not in clock_style, clock_style

    # Hold a Git scan behind a gate: typing and commands must work before the
    # worker is released, regardless of how slow the filesystem or Git is.
    send('saved_git_renderer=$functions[_egg_git_render]; _egg_git_render() { print started > "$HOME/git-worker-started"; while [[ ! -f "$HOME/release-git" ]]; do sleep 0.05; done; print STALE_GIT_RESULT; }\n')
    deadline = time.monotonic() + 10
    while not (root / "home/git-worker-started").exists():
        read_for(0.05)
        assert time.monotonic() < deadline, "Git worker did not start"
    send('print accepted > "$HOME/async-input"\n')
    deadline = time.monotonic() + 5
    while not (root / "home/async-input").exists():
        read_for(0.05)
        assert time.monotonic() < deadline, "slow Git blocked the input prompt"

    # Change directories while that scan is still pending. Its old result
    # must never appear, and the replacement must retain partially typed input.
    send('_egg_git_render() { print -r -- "FRESH_GIT:$PWD"; }; mkdir -p "$HOME/next-directory"; cd "$HOME/next-directory"; print ready > "$HOME/directory-ready"\n')
    deadline = time.monotonic() + 5
    while not (root / "home/directory-ready").exists():
        read_for(0.05)
        assert time.monotonic() < deadline, "directory change blocked on stale Git"
    read_for(0.1)
    send('print ASYNC_BUFFER_SURVIVES > "$HOME/async-buffer"')
    (root / "home/release-git").touch()
    output = read_for(0.8)
    assert "STALE_GIT_RESULT" not in output, "old directory Git leaked into the prompt: " + output
    assert "FRESH_GIT:" in output and "next-directory" in output, "fresh Git context did not arrive: " + output
    send('\n')
    output = read_for(0.7)
    assert (root / "home/async-buffer").read_text().strip() == "ASYNC_BUFFER_SURVIVES", "Git redraw lost the input buffer: " + output

    # Empty Enter must neither start another scan nor regenerate the base UI.
    send('_egg_git_render() { print scan >> "$HOME/git-scans"; }; _egg_clock_template=\'$(print render >> "$HOME/base-renders"; print -r -- "FAST_BASE EGG_GIT_CONTEXT")\'\n')
    read_for(0.7)
    send('\n')  # Clear the previous command's status/duration once.
    read_for(0.3)
    scans = (root / "home/git-scans").read_text()
    renders = (root / "home/base-renders").read_text()
    send('\n\n\n')
    read_for(0.5)
    assert (root / "home/git-scans").read_text() == scans, "empty Enter rescanned Git"
    assert (root / "home/base-renders").read_text() == renders, "empty Enter rerendered Starship"

    send('exit\n')
    read_for(0.5)
    _, status = os.waitpid(pid, 0)
    pid = None
    assert os.waitstatus_to_exitcode(status) == 0
    assert not root.exists(), "interactive preview did not clean up"
finally:
    if pid is not None:
        send('\x03')
        read_for(0.2)
        send('exit\n')
        read_for(0.5)
        deadline = time.monotonic() + 3
        while os.waitpid(pid, os.WNOHANG)[0] == 0:
            if time.monotonic() >= deadline:
                os.killpg(pid, signal.SIGKILL)
                os.waitpid(pid, 0)
                break
            read_for(0.1)
    os.close(fd)

print("Interactive live clock checks passed")
