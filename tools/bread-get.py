import re

# Read the Dart file
with open("breads.dart", "r", encoding="utf-8") as file:
    dart_code = file.read()

# Regex to find all name: '...'
bread_names = re.findall(r"name:\s*'([^']+)'", dart_code)

# Use a set to remove duplicates while preserving order
seen = set()
unique_names = []
for name in bread_names:
    if name not in seen:
        seen.add(name)
        unique_names.append(name)

# Output Python-style list
print("# List of all bread names from the expanded database")
print("bread_names = [")
for name in unique_names:
    print(f"    '{name}',")
print("]")
