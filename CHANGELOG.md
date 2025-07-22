## 1.0.5
Refactor: Improve notifier initialization and error handling

This commit refactors the `PlatformNotifier` class to improve initialization and error handling:

- Added an `_isInitialized` flag to track initialization status.
- Made `appName` and `data` private with public getters that throw a `StateError` if accessed before initialization.
- Added safe getters `appNameSafe` and `dataSafe` that return null if not initialized.
- Wrapped initialization logic in a try-catch block to handle potential errors.
- Added null checks and error handling throughout the class, particularly in methods that interact with platform-specific notification plugins.
- Added debug prints for errors and warnings.
- Ensured `close()` method correctly updates the initialization status.
- Updated version to 1.0.4.
## 1.0.4
- make the context optional

## 1.0.3
- upgrade packages version

## 1.0.2
Support flutter v 3.24.+
## 1.0.0
- stable release all platforms supported now!
## 0.1.0

update packages

## 0.0.4

support dart 3

## 0.0.3

* Lazy ask for ios notifications permission

## 0.0.2

* add payload to ```PluginNotificationMarkRead``` class

## 0.0.1

* initial release.
