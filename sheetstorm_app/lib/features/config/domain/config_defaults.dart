/// Intelligent defaults per device type — Issue #35
///
/// Sets sensible initial values based on device class.
/// Reference: docs/feature-specs/konfigurationssystem-spec.md § 4.5

import 'package:flutter/foundation.dart';
import 'package:sheetstorm/features/config/data/services/config_local_storage.dart';

/// Device class detection and intelligent default initialization.
abstract final class ConfigDefaults {
  /// Detect device class and apply intelligent defaults on first launch.
  static Future<void> applyIntelligentDefaults(
    ConfigLocalStorage storage,
  ) async {
    // Check if defaults have already been applied
    final existing = await storage.getDeviceConfig('_defaults_applied');
    if (existing == true) return;

    final deviceClass = _detectDeviceClass();
    final defaults = _defaultsFor(deviceClass);

    for (final entry in defaults.entries) {
      final existingValue = await storage.getDeviceConfig(entry.key);
      if (existingValue == null) {
        await storage.setDeviceConfig(entry.key, entry.value);
      }
    }

    await storage.setDeviceConfig('_defaults_applied', true);
  }

  static _DeviceClass _detectDeviceClass() {
    // Platform-based heuristic
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.android:
        // Will be refined at runtime using MediaQuery
        return _DeviceClass.phone;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return _DeviceClass.desktop;
      case TargetPlatform.fuchsia:
        return _DeviceClass.phone;
    }
  }

  /// Refine device class based on screen size (call from widget layer).
  static _DeviceClass detectWithScreenSize(double shortestSide) {
    if (shortestSide >= 900) return _DeviceClass.desktopTablet;
    if (shortestSide >= 600) return _DeviceClass.tablet;
    return _DeviceClass.phone;
  }

  static Map<String, dynamic> _defaultsFor(_DeviceClass deviceClass) {
    switch (deviceClass) {
      case _DeviceClass.phone:
        return {
          'device.touch.zones': 0.35,
          'device.display.font_size': 'mittel',
          'device.display.brightness': 1.0,
          'device.touch.sensitivity': 'mittel',
        };
      case _DeviceClass.tablet:
        return {
          'device.touch.zones': 0.40,
          'device.display.font_size': 'gross',
          'device.display.brightness': 1.0,
          'device.touch.sensitivity': 'mittel',
        };
      case _DeviceClass.desktopTablet:
        return {
          'device.touch.zones': 0.45,
          'device.display.font_size': 'sehr_gross',
          'device.display.brightness': 1.0,
          'device.touch.sensitivity': 'gering',
        };
      case _DeviceClass.desktop:
        return {
          'device.touch.zones': 0.45,
          'device.display.font_size': 'mittel',
          'device.display.brightness': 1.0,
          'device.touch.sensitivity': 'gering',
        };
    }
  }
}

enum _DeviceClass {
  phone,
  tablet,
  desktopTablet,
  desktop,
}
