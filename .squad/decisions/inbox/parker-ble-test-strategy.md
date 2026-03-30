# Parker — BLE Test Strategy Decision

**Date:** 2026-03-30  
**Author:** Parker (QA)  
**Branch:** squad/ble-spec  
**Status:** Draft — pending Romanoff implementation

---

## Context

Romanoff (Full-Stack Engineer) is building the BLE core layer per spec
`docs/specs/2026-03-30-ble-broadcast-dirigent.md`. This document records
the test strategy decisions made while writing tests in parallel.

---

## Decision: Test Pure Logic First, Hardware Last

**Chosen:** Test codec, crypto, replay protection, and transport-detection
logic as pure Dart — no BLE hardware, no Flutter widget harness.

**Rationale:**
- BLE hardware tests require physical devices and are non-deterministic
  (signal strength, device pairing, OS permissions).
- The spec isolates all testable logic into classes that have no hardware
  dependency: `BleMessageCodec`, `BleSecurityService`, `ReplayProtection`,
  `TransportDetector`, and the model layer.
- Pure logic tests run in CI without any mobile device.

---

## Decision: Import `flutter_test` for Consistency

**Chosen:** Use `package:flutter_test/flutter_test.dart` for all BLE test
files (consistent with existing project test pattern).

**Alternatives considered:**
- `package:test/test.dart` directly — works but `flutter_test` is already
  a declared dev dependency and the rest of the test suite uses it.

---

## Decision: TDD Red-Phase Tests Only

**Chosen:** Write all tests referencing the target APIs before Romanoff
creates the implementation files. Tests will fail to compile until
implementation is provided — this is the expected RED state.

**APIs defined through tests:**

| File | Class | Key Methods |
|------|-------|-------------|
| `ble_message_codec.dart` | `BleMessageCodec` | `encode()`, `decode()`, `encodeSongChanged()`, `encodeMetronomeBeat()`, `encodeAnnotationInvalidation()` |
| `ble_message_codec.dart` | `BleDecodedMessage` | `messageType`, `sequenceNumber`, `flags`, `timestamp`, `payload`, `signature` |
| `ble_security_service.dart` | `BleSecurityService` | `signMessage()`, `verifySignature()`, `isAuthorizedSender()`, `validateMessage()`, `createChallenge()`, `respondToChallenge()`, `verifyChallenge()` |
| `ble_security_service.dart` | `ReplayProtection` | `isValid(senderId, seq, timestamp)` |
| `ble_models.dart` | `BleSessionInfo` | `fromJson()`, `toJson()`, `isExpired` getter |
| `ble_models.dart` | `MetronomeBeatPayload` | constructor with assert validation |
| `ble_models.dart` | `AnnotationInvalidationPayload` | `fromJson()`, `toJson()` |
| `ble_models.dart` | `AnnotationUpdateType` | enum: `created`, `modified`, `deleted` |
| `ble_models.dart` | `TransportType` | enum: `ble`, `signalR`, `none` |
| `transport_detector.dart` | `TransportDetector` | `detectBestTransport({scanTimeout})` with injectable callbacks |

---

## Decision: No Mocktail — Use Function Injection

**Chosen:** `TransportDetector` accepts `Future<bool> Function()` callbacks
instead of interface mocks. This eliminates the need for `mocktail` and
makes tests self-contained.

```dart
// Test usage
final detector = TransportDetector(
  checkBleAvailable: () async => true,
  scanForSession: (_) async => _fakeBleSession(),
  checkServerReachable: () async => false,
);
```

**Rationale:**
- Project convention explicitly says "no mocktail" for these tests.
- Function injection is idiomatic Dart and needs no code generation.
- Callback signatures precisely match the production usage pattern.

---

## Decision: Binary Codec Contract

**Encode returns unsigned bytes; sign separately.**

```
encode/encodeSongChanged/etc → unsigned bytes (4+4+payload)
BleSecurityService.signMessage(unsigned, key) → unsigned + HMAC(32)
BleMessageCodec.decode(signed) → BleDecodedMessage with all fields
```

This separation means:
- Codec has zero crypto dependency
- Security service is agnostic to message formats
- Both can be unit-tested independently

**Minimum valid message for `decode()`:** 40 bytes (4 header + 4 timestamp + 32 HMAC, empty payload).

---

## Decision: Validation Result Enum (not bool/throws)

**Chosen:** `validateMessage()` returns `BleValidationResult` enum:
```dart
enum BleValidationResult {
  valid,
  invalidSignature,
  unauthorizedSender,
  replayDetected,
  timestampExpired,
}
```

**Rationale:**
- Callers need to distinguish between rejection reasons (e.g., log replay
  attacks differently from signature failures).
- Throwing exceptions for expected invalid-input cases is poor practice.
- A bool would lose the reason for rejection.

---

## Test Coverage Summary

| File | Tests | Focus |
|------|-------|-------|
| `ble_message_codec_test.dart` | 23 | Binary encoding, decoding, round-trips |
| `ble_security_service_test.dart` | 26 | HMAC, trust model, replay, challenge-response |
| `transport_detector_test.dart` | 7 | Transport priority, fallback, scan timeout |
| `ble_models_test.dart` | 17 | Serialization, validation, enum coverage |
| **Total** | **73** | |

---

## What is NOT Tested Here (and Why)

| Area | Reason |
|------|--------|
| `BleBroadcastService` (Central/Peripheral) | Requires BLE hardware |
| `flutter_ble_peripheral` advertising | Platform-only, needs physical device |
| GATT characteristic R/W | Hardware-dependent |
| MTU negotiation | Hardware-dependent |
| Reconnect timing (< 2 sec) | Integration test scope |

These should be covered in manual QA / E2E tests on physical devices.
