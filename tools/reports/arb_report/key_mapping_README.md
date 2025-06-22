# Key Mapping YAML File

This YAML file shows all ARB keys with their values after optimization.

## Format

The file is organized into two sections:

1. **Keys that replace other keys** - These are keys that are replacing one or more other keys.
   - The main key is shown with its value and a comment indicating which keys it replaces
   - The old keys are indented and show their original values

2. **Keys that don't replace others** - These are keys that remain unchanged

## How to Edit

You can edit this file to:

1. Change which keys should replace others
2. Modify the replacement relationships
3. Keep more keys if needed
4. Change key values

## Using Your Changes

After editing this file, run the following command to apply your changes:

```
python apply_yaml_mapping.py
```

This will:
1. Read your edited YAML file
2. Update the key_mapping.json file
3. Apply the changes to the ARB files
4. Update code references in your Dart files
