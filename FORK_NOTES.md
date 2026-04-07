# Fork Notes

## Upstream base

- Repository: `flutter/packages` fork (`ynnob/flutter_packages`)
- Branch: `camera-avfoundation-virtual-device`
- Base package target: `camera_avfoundation` `0.10.1`
- Base commit used for this fork work: `722c8816d2b5bf30f2425c30076c830b6b6bf512`

## Rationale

- Prefer AVFoundation virtual back camera devices on supported iPhones.
- Normalize virtual-device zoom so UI `1.0x` maps to wide-angle baseline on iOS.
- Preserve API compatibility with `camera` and `camera_platform_interface`.
- Keep the fork diff small and easy to rebase.

## Files touched

- `packages/camera/camera_avfoundation/ios/camera_avfoundation/Sources/camera_avfoundation/CameraPlugin.swift`
- `packages/camera/camera_avfoundation/ios/camera_avfoundation/Sources/camera_avfoundation/CaptureDevice.swift`
- `packages/camera/camera_avfoundation/ios/camera_avfoundation/Sources/camera_avfoundation/DefaultCamera.swift`
- `packages/camera/camera_avfoundation/example/ios/RunnerTests/AvailableCamerasTests.swift`
- `packages/camera/camera_avfoundation/example/ios/RunnerTests/CameraZoomTests.swift`
- `packages/camera/camera_avfoundation/example/ios/RunnerTests/Mocks/MockCaptureDevice.swift`

## Rebase checklist

- Rebase branch onto latest `flutter/packages` camera updates.
- Verify `getAvailableCameras` still includes virtual + physical discovery types.
- Verify deterministic ranking still prefers back virtual devices first.
- Verify `platformLensType(for:)` still maps virtual device types to `.wide`.
- Verify virtual-device zoom baseline uses switch-over factors on iOS back cameras with ultra-wide.
- Run iOS example tests for `camera_avfoundation` and smoke test on real device.
