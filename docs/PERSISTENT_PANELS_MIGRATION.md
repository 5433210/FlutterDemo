# Persistent Panel Components Migration Guide

This guide explains how to use the new persistent panel components that remember their state across app sessions.

## Overview

The persistent panel system provides:

- **ResizablePanel**: Remembers panel width across sessions
- **SidebarToggle**: Remembers open/close state across sessions

## Components

### 1. PersistentResizablePanel

A resizable panel that automatically saves and restores its width.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/common/persistent_resizable_panel.dart';

// Basic usage
PersistentResizablePanel(
  panelId: 'my_filter_panel',  // Unique ID for persistence
  initialWidth: 300,            // Default width
  minWidth: 200,
  maxWidth: 500,
  child: MyPanelContent(),
)
```

### 2. PersistentSidebarToggle

A sidebar toggle that automatically saves and restores its open/close state.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/common/persistent_sidebar_toggle.dart';

// Basic usage
PersistentSidebarToggle(
  sidebarId: 'my_sidebar',     // Unique ID for persistence
  defaultIsOpen: true,          // Default state
  alignRight: false,
  onToggle: (isOpen) {
    print('Sidebar is now: $isOpen');
  },
)
```

### 3. Enhanced Original Components (Backward Compatible)

The original `ResizablePanel` and `SidebarToggle` now support optional persistence:

```dart
// ResizablePanel with optional persistence
ResizablePanel(
  persistentId: 'my_panel',    // Optional: Makes it persistent
  initialWidth: 300,
  child: MyContent(),
)

// SidebarToggle with optional persistence
SidebarToggle(
  persistentId: 'my_sidebar',  // Optional: Makes it persistent
  isOpen: isOpen,
  onToggle: onToggle,
)
```

## Migration Strategies

### Strategy 1: Direct Migration (Recommended)

Replace existing components with persistent versions:

**Before:**

```dart
ResizablePanel(
  initialWidth: 300,
  child: FilterPanel(),
)
```

**After:**

```dart
PersistentResizablePanel(
  panelId: 'filter_panel',     // Add unique ID
  initialWidth: 300,
  child: FilterPanel(),
)
```

### Strategy 2: Gradual Migration

Add persistence to existing components:

**Before:**

```dart
ResizablePanel(
  initialWidth: 300,
  child: FilterPanel(),
)
```

**After:**

```dart
ResizablePanel(
  persistentId: 'filter_panel',  // Add this line
  initialWidth: 300,
  child: FilterPanel(),
)
```

## Important Notes

### Panel IDs

- Must be unique across your application
- Use descriptive names like `'library_filter_panel'` or `'character_details_sidebar'`
- Consider adding prefixes for different screens: `'library_filter'`, `'practice_sidebar'`

### Provider Setup

Ensure your app is wrapped with Riverpod providers:

```dart
void main() {
  runApp(
    ProviderScope(    // Required for persistence
      child: MyApp(),
    ),
  );
}
```

### Data Persistence

- State is automatically saved to `SharedPreferences`
- No additional setup required
- State survives app restarts and updates

### Performance

- State is loaded asynchronously on app start
- Minimal performance impact
- Automatic cleanup of unused states

## Examples

### Complete Example with Multiple Panels

```dart
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Left filter panel
        PersistentResizablePanel(
          panelId: 'left_filter_panel',
          initialWidth: 300,
          child: FilterPanel(),
        ),
        
        // Toggle for left panel
        PersistentSidebarToggle(
          sidebarId: 'left_filter_sidebar',
          defaultIsOpen: true,
        ),
        
        // Main content
        Expanded(child: MainContent()),
        
        // Toggle for right panel  
        PersistentSidebarToggle(
          sidebarId: 'right_details_sidebar',
          defaultIsOpen: false,
          alignRight: true,
        ),
        
        // Right details panel
        PersistentResizablePanel(
          panelId: 'right_details_panel',
          initialWidth: 250,
          isLeftPanel: false,
          child: DetailsPanel(),
        ),
      ],
    );
  }
}
```

### Accessing State Programmatically

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Read current panel width
    final panelWidth = ref.watch(panelWidthProvider((
      panelId: 'my_panel',
      defaultWidth: 300.0,
    )));
    
    // Read current sidebar state
    final sidebarOpen = ref.watch(sidebarStateProvider((
      sidebarId: 'my_sidebar',
      defaultState: false,
    )));
    
    // Programmatically change states
    return ElevatedButton(
      onPressed: () {
        // Set panel width
        ref.read(persistentPanelProvider.notifier)
           .setPanelWidth('my_panel', 400);
           
        // Toggle sidebar
        ref.read(persistentPanelProvider.notifier)
           .toggleSidebar('my_sidebar');
      },
      child: Text('Update States'),
    );
  }
}
```

## Troubleshooting

### State Not Persisting

1. Ensure `ProviderScope` wraps your app
2. Check that panel IDs are unique
3. Verify you're using `ConsumerWidget` or `Consumer`

### Performance Issues

1. Avoid too many persistent panels on one screen
2. Use descriptive but short panel IDs
3. Consider lazy loading for complex panels

### State Conflicts

1. Use screen-specific prefixes for panel IDs
2. Clear old states if changing panel structure:

```dart
// Clear all persistent states (use with caution)
ref.read(persistentPanelProvider.notifier).clearAll();

// Remove specific states
ref.read(persistentPanelProvider.notifier).removePanelWidth('old_panel_id');
ref.read(persistentPanelProvider.notifier).removeSidebarState('old_sidebar_id');
```
