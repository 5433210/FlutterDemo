# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**CharAsGem (字字珠玑)** is a Flutter desktop application for Chinese calligraphy practice and management. It's a comprehensive tool that helps users:
- Import and manage calligraphy works with multi-image support
- Extract and collect Chinese characters from images
- Create and export practice worksheets
- Organize calligraphy content with tagging and categorization

## Common Development Commands

### Build Commands
```bash
# Build for Windows (primary platform)
flutter build windows

# Build for other platforms
flutter build web
flutter build apk
flutter build appbundle

# Clean build artifacts
flutter clean && flutter pub get
```

### Testing Commands
```bash
# Run all tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run specific test file
flutter test test/path/to/specific_test.dart

# Run widget tests
flutter test test/presentation/widgets/

# Run integration tests
flutter test test/integration/
```

### Development Commands
```bash
# Install dependencies
flutter pub get

# Generate code (for freezed, json_serializable)
flutter packages pub run build_runner build

# Watch for changes and rebuild
flutter packages pub run build_runner watch

# Run app in debug mode
flutter run -d windows

# Run with verbose logging
flutter run -v
```

### Code Quality
```bash
# Check for linting issues
flutter analyze

# Format code
flutter format .

# Check Flutter setup
flutter doctor
```

## Architecture Overview

The application follows Clean Architecture with clear separation of concerns:

### Layer Structure
```
lib/
├── domain/              # Business logic and entities
│   ├── entities/        # Core business objects
│   ├── repositories/    # Repository interfaces
│   └── services/        # Domain services
├── application/         # Application services and use cases
│   ├── services/        # Application services
│   ├── providers/       # Riverpod providers
│   └── repositories/    # Repository implementations
├── infrastructure/      # External concerns
│   ├── persistence/     # Database implementations
│   ├── image/          # Image processing
│   ├── storage/        # File system operations
│   └── logging/        # Logging system
└── presentation/        # UI layer
    ├── pages/          # Main application screens
    ├── widgets/        # Reusable UI components
    ├── providers/      # UI state management
    └── dialogs/        # Modal dialogs
```

### Key Technologies
- **Framework**: Flutter 3.29.2
- **State Management**: Riverpod 2.6.1
- **Database**: SQLite with sqflite
- **Serialization**: json_serializable + freezed
- **Internationalization**: flutter_localizations (Chinese/English)
- **Desktop Support**: window_manager for native window control

## Core Modules

### 1. Work Management (`lib/application/services/work/`)
- **WorkService**: Main business logic for calligraphy works
- **WorkImageService**: Handles multi-image support per work
- **WorkRepository**: Data access layer for works
- Supports importing, organizing, and exporting calligraphy works

### 2. Character Collection (`lib/application/services/character/`)
- **CharacterService**: Manages extracted characters
- **CharacterImageService**: Processes character images
- **CharacterRepository**: Storage and retrieval of characters
- Enables character extraction from works for reuse

### 3. Practice Worksheets (`lib/application/services/practice/`)
- **PracticeService**: Creates practice templates
- **PracticeStorageService**: Manages practice data
- Generates printable practice sheets with characters

### 4. Backup System (`lib/application/services/backup*.dart`)
- **BackupService**: Handles data backup/restore
- **BackupRegistryManager**: Manages backup locations
- **DataPathSwitchManager**: Manages data directory switching
- Provides comprehensive backup and data migration features

## Storage Architecture

### Database Schema (SQLite)
- `works` - Calligraphy work metadata
- `characters` - Extracted character data
- `practices` - Practice worksheet definitions
- `library_categories` - Organization categories
- `library_items` - Categorized content items

### File System Structure
```
{data_path}/
├── works/              # Work image files
│   └── {work_id}/
│       ├── thumbnail.jpg
│       └── images/
├── characters/         # Character image files
├── practices/         # Practice worksheet resources
├── backup/            # Backup files
└── temp/             # Temporary files
```

## Development Guidelines

### State Management Patterns
- Use Riverpod providers for dependency injection
- Implement proper provider disposal
- Use AsyncNotifier for async state
- Follow provider naming conventions (e.g., `workServiceProvider`)

### Database Operations
- Always use transactions for multi-table operations
- Implement proper error handling with try-catch
- Use parameterized queries to prevent SQL injection
- Handle database migration in `data_migration_service.dart`

### Image Processing
- Use `image_processor.dart` for image operations
- Implement proper memory management for large images
- Cache processed images when appropriate
- Support multiple image formats (JPG, PNG, etc.)

### Logging
- Use `AppLogger` from `infrastructure/logging/`
- Include appropriate tags for log filtering
- Use different log levels: debug, info, warning, error, fatal
- Configure logging levels per environment

### Internationalization
- All user-facing strings must be in `lib/l10n/app_*.arb`
- Use `AppLocalizations.of(context)` for translations
- Support Chinese (primary) and English
- Update both `app_zh.arb` and `app_en.arb` files

## Testing Strategy

### Unit Tests
- Test business logic in `application/services/`
- Mock external dependencies using `mockito`
- Focus on edge cases and error conditions

### Widget Tests
- Test UI components in isolation
- Verify user interactions and state changes
- Use `flutter_test` framework

### Integration Tests
- Test complete user workflows
- Verify data persistence and retrieval
- Test backup and restore functionality

## Platform-Specific Notes

### Windows (Primary Target)
- Uses `window_manager` for native window control
- Supports file system operations via `path_provider`
- Implements proper file associations

### Multi-Platform Support
- Web build available with limited file system access
- Android build configured but secondary priority
- Cross-platform file handling considerations

## Performance Considerations

### Image Handling
- Implement lazy loading for large image collections
- Use image caching strategies
- Process images in background isolates when possible

### Database Performance
- Use indexes for frequently queried columns
- Batch operations when possible
- Implement connection pooling

### Memory Management
- Dispose of resources properly
- Monitor memory usage in image-heavy operations
- Use weak references where appropriate

## Common Issues and Solutions

### Build Issues
- Run `flutter clean && flutter pub get` for dependency issues
- Check `flutter doctor` for platform-specific setup problems
- Ensure SQLite FFI is properly configured for desktop

### Database Issues
- Check database migration status in logs
- Verify file permissions for database files
- Use backup/restore functionality for data recovery

### Performance Issues
- Monitor logging output for performance bottlenecks
- Use Flutter DevTools for UI performance analysis
- Check memory usage in image processing operations

## Contributing Guidelines

### Code Style
- Follow Dart style guide and use `flutter format`
- Use meaningful variable and function names
- Write clear comments for complex logic
- Follow the established architecture patterns

### Pull Request Process
- Ensure all tests pass before submitting
- Update documentation for new features
- Include appropriate logging for debugging
- Test on Windows platform (primary target)

## Development Environment Setup

### Prerequisites
- Flutter 3.29.2 or later
- Visual Studio (for Windows builds)
- Git for version control

### Initial Setup
1. Clone the repository
2. Run `flutter pub get`
3. Run `flutter doctor` to verify setup
4. Build and run: `flutter run -d windows`

### IDE Configuration
- VS Code with Flutter extension recommended
- Configure Dart analysis options per `analysis_options.yaml`
- Enable format on save for consistent code style