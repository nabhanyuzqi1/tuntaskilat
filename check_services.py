import json

schema_path = "/Users/nabhan/tkapps/packages/tk_core/lib/models/service_model.dart"
with open(schema_path, "r") as f:
    for line in f:
        if "id" in line or "name" in line or "harga" in line:
            pass # just read to understand if there is a list of default services

