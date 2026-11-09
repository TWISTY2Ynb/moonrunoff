"""Reject older compilers; record exact reproducible reference version."""
import re, subprocess
text = subprocess.check_output(['moonc','-v'],text=True)
m = re.search(r'v(\d+)\.(\d+)\.(\d+)', text)
assert m and tuple(map(int,m.groups())) >= (0,10,18), text
print(text.strip())
