import sys
from pathlib import Path
import json

LIB_FOLDER = Path(__file__).resolve().parent.parent / 'build/Products/python'
EXPECTED_JSON = Path(__file__).resolve().parent.parent / 'tests/expected.json'

sys.path.append(str(LIB_FOLDER))

import mylib

def test_encoding():
    test_string = "模型"
    m = mylib.Model(test_string)
    name_string = m.getName()
    assert test_string == name_string

def test_json():
    m = mylib.Model("John")
    expected = json.loads(EXPECTED_JSON.read_text())
    d = m.toJSON()
    assert d == expected
