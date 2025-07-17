#!/bin/bash

import sys
import ruamel.yaml

if len(sys.argv) != 3:
    print("Usage: {sys.argv[0]} <url> <sha256>")
    sys.exit(1)

url = sys.argv[1]
hash = sys.argv[2]
fn = "com.nitrokey.nitrokey-app2.yml"

ym = ruamel.yaml.YAML()
ym.preserve_quotes = True
ym.width = 1024
with open(fn) as fd:
    data = ym.load(fd)

for item in data["modules"]:
    if "name" in item:
        item["sources"][0]["url"] = url
        item["sources"][0]["sha256"] = hash
           
with open(fn, "w") as fd:
    ym.dump(data, fd)
                

