import re
import pytest


def test_version_helpers(cea_module):
    version = cea_module.lib_version()
    assert re.match(r"^\d+\.\d+\.\d+$", version)
    assert isinstance(cea_module.lib_version_major(), int)
    assert isinstance(cea_module.lib_version_minor(), int)
    assert isinstance(cea_module.lib_version_patch(), int)


def test_init_rejects_non_string_path(cea_module):
    with pytest.raises(TypeError):
        cea_module.init(path=123)
