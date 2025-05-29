# Auto-Save Implementation for Character Editing Panel

## Overview

This implementation adds automatic saving functionality for threshold and noiseReduction parameters from the character editing panel sliders. When users adjust these sliders, the values are automatically saved to the database with proper debouncing to prevent excessive writes.

## Implementation Details

### 1. Auto-Save Mechanism

The auto-save functionality is implemented in `EraseStateNotifier` with the following components:

#### Debouncing Timer

```dart
Timer? _autoSaveTimer;
static const Duration _autoSaveDelay = Duration(milliseconds: 1000); // 1 second delay
```

#### Auto-Save Method

```dart
void _scheduleAutoSave() {
  // Cancel existing timer if any
  _autoSaveTimer?.cancel();

  // Start a new timer with debounce delay
  _autoSaveTimer = Timer(_autoSaveDelay, () async {
    try {
      final userPreferencesNotifier = _ref.read(userPreferencesNotifierProvider.notifier);
      
      // Save threshold
      await userPreferencesNotifier.updateDefaultThreshold(state.processingOptions.threshold);
      
      // Save noise reduction
      await userPreferencesNotifier.updateDefaultNoiseReduction(state.processingOptions.noiseReduction);
      
      AppLogger.debug('Auto-saved processing options to user preferences', data: {
        'threshold': state.processingOptions.threshold,
        'noiseReduction': state.processingOptions.noiseReduction,
      });
    } catch (e) {
      AppLogger.error('Failed to auto-save processing options', error: e);
    }
  });
}
```

### 2. Modified Slider Methods

Both optimized slider methods now call the auto-save functionality:

#### Threshold Slider

```dart
void setThresholdOptimized(double threshold) {
  // ... existing logic ...
  
  // Auto-save the new value to user preferences with debouncing
  _scheduleAutoSave();
}
```

#### Noise Reduction Slider

```dart
void setNoiseReductionOptimized(double value) {
  // ... existing logic ...
  
  // Auto-save the new value to user preferences with debouncing
  _scheduleAutoSave();
}
```

### 3. Resource Management

The timers are properly cleaned up in the dispose method:

```dart
@override
void dispose() {
  _delayedUpdateTimer?.cancel();
  _autoSaveTimer?.cancel();
  super.dispose();
}
```

## How It Works

### User Experience Flow

1. **User adjusts slider**: The slider `onChanged` callback is triggered
2. **Immediate UI update**: The slider value is immediately updated in the UI via `setThresholdOptimized()` or `setNoiseReductionOptimized()`
3. **Image processing**: A debounced image update is triggered for real-time preview
4. **Auto-save scheduling**: A 1-second debounced auto-save is scheduled
5. **Database save**: After 1 second of no further changes, the value is saved to the database
6. **Next session**: When the user opens the character editing panel again, the saved values are loaded as defaults

### Debouncing Benefits

- **Performance**: Prevents excessive database writes during continuous slider adjustments
- **User experience**: Immediate UI feedback while batching database operations
- **Resource efficiency**: Reduces database load and improves app responsiveness

### Load Process

The saved values are automatically loaded when the character editing panel initializes:

```dart
Future<void> _loadUserPreferencesAndInitialize() async {
  final userPreferencesService = ref.read(userPreferencesServiceProvider);
  final defaultProcessingOptions = await userPreferencesService.getDefaultProcessingOptions();
  
  // Apply default values to erase state
  final eraseNotifier = ref.read(erase.eraseStateProvider.notifier);
  eraseNotifier.setThreshold(defaultProcessingOptions.threshold, updateImage: false);
  eraseNotifier.setNoiseReduction(defaultProcessingOptions.noiseReduction, updateImage: false);
  // ...
}
```

## Technical Details

### Dependencies

- Uses existing `UserPreferencesNotifier` and `UserPreferencesService`
- Integrates with the existing Riverpod state management system
- Leverages the existing processing options model

### Database Integration

- Values are saved through the `UserPreferencesRepository` to the local database
- Uses the existing user preferences infrastructure
- Maintains consistency with the existing manual save functionality

### Error Handling

- Graceful error handling with logging
- Failed auto-saves don't affect the user experience
- Errors are logged for debugging purposes

## Future Enhancements

1. **Additional Parameters**: Could be extended to auto-save other parameters like brush size
2. **Configurable Delay**: The 1-second delay could be made configurable
3. **User Preference**: Could add a user setting to enable/disable auto-save
4. **Sync Indicator**: Could show a subtle indicator when auto-save occurs

## Testing

To test the auto-save functionality:

1. Open the character editing panel
2. Adjust the threshold or noise reduction sliders
3. Wait for 1 second after stopping adjustments
4. Check the logs for "Auto-saved processing options to user preferences"
5. Close and reopen the panel to verify the values are restored

The implementation is now complete and ready for use.
