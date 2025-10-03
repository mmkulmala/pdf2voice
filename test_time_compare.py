# test_time_compare.py
"""
Test script to compare execution time of Python and Mojo PDF-to-audiobook scripts.
Requires: test_files/test.pdf
"""
import subprocess
import time
import os

def run_and_time(cmd):
    start = time.time()
    result = subprocess.run(cmd, shell=True)
    end = time.time()
    return end - start, result.returncode

TEST_PDF = "test_files/test.pdf"
PYTHON_OUT = "test_files/test_py.mp3"
MOJO_OUT = "test_files/test_mojo.mp3"

python_cmd = f"python3 pdf_to_audiobook.py {TEST_PDF} {PYTHON_OUT} --chunk-size 4000 --language en"
mojo_cmd = f"mojo pdf_to_audiobook_mojo.mojo {TEST_PDF} {MOJO_OUT} --chunk-size 4000 --language en"

print("Testing Python version...")
py_time, py_code = run_and_time(python_cmd)
print(f"Python version finished in {py_time:.2f} seconds (exit code {py_code})")

print("Testing Mojo version...")
mojo_time, mojo_code = run_and_time(mojo_cmd)
print(f"Mojo version finished in {mojo_time:.2f} seconds (exit code {mojo_code})")

# Clean up output files if needed
for f in [PYTHON_OUT, MOJO_OUT]:
    if os.path.exists(f):
        os.remove(f)
