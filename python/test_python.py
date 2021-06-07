import os
import sys
import unittest

LIB_FOLDER = os.path.join(os.path.dirname(os.path.realpath(__file__)),
                          '../build/Products/python/')
sys.path.append(LIB_FOLDER)

import mylib

class TestStringMethods(unittest.TestCase):

    def test_encoding(self):
        test_string = "模型"
        m = mylib.Model(test_string)
        name_string = m.getName()
        self.assertEqual(test_string, name_string)
