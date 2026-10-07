import sys
import os
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "app"))
from main import message


class TestMessage(unittest.TestCase):
    def test_message_content(self):
        self.assertIn("Hello World", message())
        self.assertIn("DevSecOps", message())


if __name__ == "__main__":
    unittest.main()
