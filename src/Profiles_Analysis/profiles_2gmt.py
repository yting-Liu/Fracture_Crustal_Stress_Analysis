import os
import re

directory = "/xxx/profiles"
output_file = "profiles.gmt"

pattern = re.compile(
    r"(\d{4})_"
    r"(-?\d+\.\d+)_(-?\d+\.\d+)_"
    r"(-?\d+\.\d+)_(-?\d+\.\d+)_"
    r"(-?\d+\.\d+)_(-?\d+\.\d+)_"
    r"(-?\d+\.\d+)_(-?\d+\.\d+)"
)


file_list = sorted([
    f for f in os.listdir(directory)
    if pattern.match(f)
])


with open(output_file, "w") as out:
    for filename in file_list:
        match = pattern.match(filename)
        if match:
            index = match.group(1)
            coords = list(map(float, match.groups()[1:]))
            out.write(f'> L"{index}"\n')
            for i in range(4, 8, 2):
                out.write(f"{coords[i]} {coords[i+1]}\n")