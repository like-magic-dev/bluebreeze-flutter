# 1.1.0

**Breaking changes**

- Every observable property is now a `BBObservable` instead of a plain value + `...Stream` getter:
  - `value` returns the current value (previously the property itself).
  - `values` emits the current value, then new values.
  - `updates` emits only new values, like the previous `...Stream` getters.
- Removed all stream accessors. Use `updates` on the matching property instead.
- Renamed `BBCharacteristic.notifyEnabled` to `isNotifying`, matching the native libraries.

# 1.0.1

Add informative error messages for all native errors.

# 1.0.0

BlueBreeze's first stable release. This version focuses on correctness of the platform bridge,
full public API documentation, and a clean, idiomatic Dart API surface.
