import sys
import os
import unittest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "app"))
from main import tasks


class TestTasks(unittest.TestCase):
    def test_tasks_list(self):
        t = tasks()
        self.assertEqual(len(t), 3)
        self.assertIn("title", t[0])
        self.assertIsInstance(t[2]["done"], bool)


if __name__ == "__main__":
    unittest.main()
