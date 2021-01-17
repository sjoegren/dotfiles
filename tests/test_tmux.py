import os
import subprocess
import pytest

import _tmux_find_pane as tmux

in_tmux = pytest.mark.skipif(
    os.environ.get("TMUX_PANE") is None, reason="must run within tmux"
)


def test_Pids():
    pids = tmux.Pids(1)
    assert len(pids.pids) > 100
    assert pids.exists(os.getpid())
    assert pids.exists(os.getppid())


@in_tmux
def test_Panes():
    """Test getting tmux pane of the test process id."""
    pids = tmux.Panes(1)
    assert pids.get_tmux_pane(os.getpid()) == os.environ["TMUX_PANE"]
    assert pids.get_tmux_pane(os.getppid()) == os.environ["TMUX_PANE"]


def test_script_smoke():
    subprocess.run(["_tmux_find_pane.py", "--help"], check=True)


@in_tmux
def test_tmux_find_pane_pid():
    p = subprocess.run(
        ["_tmux_find_pane.py", "--pid", str(os.getpid())],
        check=True,
        universal_newlines=True,
        stdout=subprocess.PIPE,
    )
    assert p.stdout.strip() == os.environ['TMUX_PANE']
