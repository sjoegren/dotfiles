import textwrap
import sys
import pytest

if sys.version_info < (3, 8):
    pytest.skip("Only on Python 3.8+", allow_module_level=True)

import dotfiles


def test_get_functions(tmp_path):
    data = textwrap.dedent("""\
        # not of interest
        stuff
        #no space after #
        # help line 1
        # help line 2
        foo()

        # description of
        # special item
        # dotfiles-help: bar
        """)
    bash_file = tmp_path / "test.bash"
    bash_file.write_text(data)
    functions = dotfiles.get_functions(bash_file)
    assert next(functions) == ("foo", ["help line 1", "help line 2"], bash_file)
    assert next(functions) == ("bar", ["description of", "special item"], bash_file)
