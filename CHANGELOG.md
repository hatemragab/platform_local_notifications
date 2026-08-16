# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.2.0] - 2026-08-17

### Changed

- Updated `v_platform` to `^2.2.0` for its current cross-platform file APIs and WebAssembly-compatible implementation.
- Replaced the deprecated `VPlatforms.isDeskTop` alias with `VPlatforms.isDesktop`.
- Aligned the declared minimums with `v_platform` 2.2.0: Dart 3.4 and Flutter 3.22.

### Fixed

- Made the example package path portable and replaced its stale counter test with notification-demo coverage.

### Maintenance

- Removed generated Flutter plugin metadata from version control.

## [2.1.0] - 2024-12-XX

### 🚀 New Features

#### Enhanced Notification Models
- **`NotificationConfiguration`** - New dedicated configuration class for better initialization settings management
- **Improved model architecture** - Separated configuration from data models for better organization
- **Enhanced `ChatNotificationModel`** - Better inheritance structure and improved copyWith methods

#### Background Notification Handling
- **Enhanced isolate communication** - Improved background notification action handling with better error recovery
- **Automatic notification cancellation** - Notifications are now automatically cancelled after user actions (reply/mark as read)
- **Better action response handling** - Improved foreground and background action processing with proper data structure

#### Service Architecture Improvements  
- **Improved initialization flow** - Better error handling and state management during service initialization
- **Enhanced platform detection** - More robust platform-specific feature detection and handling
- **Better resource management** - Improved cleanup and disposal of service resources

### 🔧 Technical Improvements

#### Code Quality & Organization
- **Separated concerns** - Split configuration models from notification models for better maintainability
- **Improved naming conventions** - Better class and method names following Dart/Flutter best practices
- **Enhanced documentation** - Better inline documentation and code comments
- **Type safety improvements** - Better null safety handling and type annotations

#### Bug Fixes
- **Fixed background notification actions** - Resolved issues with reply and mark-as-read actions not working properly in background
- **Improved isolate port handling** - Better port registration and cleanup to prevent memory leaks
- **Enhanced error handling** - Better error messages and exception handling throughout the service
- **Fixed notification cancellation** - Proper notification cleanup after user interactions

#### Platform Enhancements
- **Android manifest configuration** - Added proper receiver configuration for notification actions
- **Better action handling** - Improved reply and mark-as-read functionality with proper data flow
- **Enhanced messaging style** - Better chat notification styling and user experience

### 📱 Example App Improvements
- **Updated example app** - Comprehensive demonstration of all new features
- **Better UI/UX** - Improved user interface with better status tracking and action feedback
- **Launch details tracking** - Added functionality to check how the app was launched
- **Real-time action monitoring** - Live display of notification actions and responses

### 🛠️ Developer Experience
- **Improved testing** - Enhanced test coverage with better model validation
- **Better error messages** - More descriptive error messages for debugging
- **Enhanced debugging** - Better logging and debug information throughout the service
- **Documentation updates** - Updated inline documentation and code examples

### ⚠️ Important Configuration Changes
- **Android Manifest Requirement** - Developers must add the following receiver to their Android manifest for notification actions to work properly:
  ```xml
  <receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver" />
  ```

### 🔄 Breaking Changes
- **`NotificationData`** - Moved to separate file for better organization (import path changed)
- **Configuration structure** - Some default configuration values have been updated for better defaults

## [2.0.0] - 2024-01-XX

### 🚀 Major Improvements

#### Code Quality & Architecture

- **Complete code refactoring** with improved architecture and organization
- **Separation of concerns** with dedicated files for models, services, constants, and types
- **Clean code principles** implementation throughout the codebase
- **Better error handling** with specific exception types and meaningful error messages
- **Enhanced type safety** with proper null safety and type annotations
- **Improved naming conventions** following Dart/Flutter best practices

#### API Design

- **Simplified API** with cleaner method signatures
- **Better method organization** with logical grouping of related functionality
- **Consistent naming** across all public APIs
- **Improved parameter validation** with automatic model validation
- **Better default values** and configuration options

#### Documentation

- **Comprehensive README** with detailed examples and best practices
- **API documentation** with proper DartDoc comments
- **Code examples** for all major use cases
- **Troubleshooting guide** for common issues
- **Platform-specific documentation** explaining capabilities and limitations

### ✨ New Features

#### Enhanced Models

- **`NotificationModel`** - Immutable model for standard notifications with validation
- **`ChatNotificationModel`** - Extended model for chat-style notifications
- **`NotificationData`** - Configuration model for plugin initialization
- **`BaseNotificationAction`** - Base class for all notification actions
- **`NotificationClickAction`** - Action for notification clicks
- **`NotificationReplyAction`** - Action for notification replies
- **`NotificationMarkReadAction`** - Action for mark-as-read functionality

#### App Launch Detection

- **`appLaunchNotification`** - Get details about how the app was launched (e.g., from notification click)
- **Launch details tracking** - Detect if app was opened from notification with payload and action information

#### Platform Detection

- **`PlatformUtils`** - Utility class for platform detection
- **`SupportedPlatform`** - Enum for supported platforms
- **Platform-specific feature detection** for better feature availability checking

#### Constants Management

- **`NotificationConstants`** - Centralized constants for all magic values
- **Configurable action IDs** and labels
- **Validation limits** for notification content

### 🔧 Technical Improvements

#### Service Architecture

- **Singleton pattern** implementation with proper lifecycle management
- **Initialization state tracking** to prevent usage before initialization
- **Resource cleanup** with proper dispose methods
- **Isolate communication** improvements for better reliability
- **Background notification handling** enhancements

#### Error Handling

- **State validation** to ensure service is initialized before use
- **Model validation** with automatic checks for required fields
- **Platform-specific error handling** for different notification systems
- **Graceful degradation** when features are not supported

#### Performance Optimizations

- **Lazy initialization** of platform-specific components
- **Image caching** improvements with better error handling
- **Memory management** with proper resource disposal
- **Efficient stream management** for notification actions

### 📱 Platform Enhancements

#### Android

- **Improved notification channels** with better configuration options
- **Enhanced messaging style** notifications with better image handling
- **Better action button** configuration and handling

#### iOS

- **Enhanced permission handling** with more granular control
- **Improved badge management** and sound configuration
- **Better critical notification** support

#### Web

- **Improved browser notification** handling
- **Better permission management** for web platforms
- **Enhanced error handling** for unsupported features

#### Desktop (Windows/macOS/Linux)

- **Better system integration** for desktop notifications
- **Improved notification styling** and configuration
- **Enhanced error handling** for desktop platforms

### 🛠️ Developer Experience

#### Better Examples

- **Updated example app** with comprehensive demonstration
- **Real-world usage patterns** showing best practices
- **Error handling examples** for common scenarios
- **Platform-specific examples** for different use cases

#### Code Quality

- **Linting compliance** with Flutter/Dart best practices
- **Consistent code formatting** throughout the codebase
- **Proper documentation** for all public APIs
- **Type safety** improvements with better null handling

### 🔄 Breaking Changes

#### API Changes

- **Renamed classes** for better clarity:
  - `ShowPluginNotificationModel` → `NotificationModel`
  - `PluginNotificationClickAction` → `NotificationClickAction`
  - `PluginNotificationReplyAction` → `NotificationReplyAction`
  - `PluginNotificationMarkRead` → `NotificationMarkReadAction`
  - `NotifierData` → `NotificationData`

#### Method Changes

- **Updated method signatures** for better consistency:
  - `PlatformNotifier.I.init()` → `PlatformNotifier.initialize()`
  - `PlatformNotifier.I.showPluginNotification()` → `PlatformNotifier.showNotification()`
  - `PlatformNotifier.I.showChatNotification()` → `PlatformNotifier.showChatNotification()`
  - `PlatformNotifier.I.requestPermissions()` → `PlatformNotifier.requestPermissions()`

#### Stream Changes

- **Renamed stream** for better clarity:
  - `platformNotifierStream` → `actionStream`

### 🐛 Bug Fixes

- **Fixed initialization issues** on some platforms
- **Resolved memory leaks** in isolate communication
- **Fixed image loading** errors in chat notifications
- **Corrected permission handling** on iOS and Android
- **Fixed notification cancellation** issues
- **Resolved background notification** handling problems

### 📚 Documentation

- **Complete API reference** with all methods and classes
- **Comprehensive examples** for all major use cases
- **Best practices guide** for optimal usage
- **Troubleshooting section** for common issues
- **Platform-specific guides** for different platforms
- **Migration guide** from version 1.x to 2.0

### 🔧 Dependencies

- **Updated Flutter SDK** requirement to 3.10.0+
- **Updated Dart SDK** requirement to 3.0.0+
- **Maintained compatibility** with existing dependencies
- **No breaking changes** in underlying notification libraries

## [1.0.5] - 2023-XX-XX

### Added

- Initial release with basic cross-platform notification support
- Support for Android, iOS, Web, Windows, macOS, and Linux
- Chat-style notifications with reply functionality
- Basic permission handling
- Simple notification actions

### Known Issues

- Limited error handling
- Basic documentation
- Inconsistent API design
- Platform-specific limitations not well documented

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

- Lazy ask for ios notifications permission

## 0.0.2

- add payload to `PluginNotificationMarkRead` class

## 0.0.1

- initial release.
