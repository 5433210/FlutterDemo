# Code Generation Guide

This project uses code generation for several features:

- **Freezed**: For immutable data classes
- **JSON Serializable**: For JSON serialization/deserialization
- **Riverpod Generator**: For generating provider code

## Setting Up

Make sure you have the following dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  # Other dependencies...
  freezed_annotation: ^2.2.0
  json_annotation: ^4.8.0

dev_dependencies:
  # Other dev dependencies...
  build_runner: ^2.3.3
  freezed: ^2.3.2
  json_serializable: ^6.6.1
```

## Generating Code

After modifying or creating any model classes that use `@freezed` or `@JsonSerializable` annotations, you need to run the build_runner to generate the corresponding code files.

### Using the Terminal

Run the following command in your project root:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

For continuous generation during development:

```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Using the Helper Script

This project includes a helper script for code generation. Run it with:

```bash
dart run lib/tools/generate_code.dart
```

## Common Issues and Solutions

### Missing Implementation Errors

If you see errors like:

```
Missing concrete implementations of '_$CharacterEntity.toJson', etc.
```

It means the generated code is either missing or outdated. Run the build_runner commands above to fix it.

### Conflicting Outputs

If you get errors about conflicting outputs, use the `--delete-conflicting-outputs` flag which is included in the commands above.

### Parts Not Found

If you see errors about parts not found, make sure:

1. You have the correct part statements in your files, e.g.:
   ```dart
   part 'my_file.freezed.dart';
   part 'my_file.g.dart';
   ```

2. Your file names match the part statements exactly (case sensitive)

3. You've run the build_runner command

## File Structure

When using Freezed and JSON Serializable, each model file typically has three associated files:

1. **YourFile.dart**: The original file with your class definition
2. **YourFile.freezed.dart**: The generated code for immutable features (created by build_runner)
3. **YourFile.g.dart**: The generated code for JSON serialization (created by build_runner)

Only edit the original `.dart` file - the others are generated automatically.
