// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import AVFoundation
import XCTest

@testable import camera_avfoundation

final class AvailableCamerasTest: XCTestCase {
  private func createCameraPlugin(with deviceDiscoverer: MockCameraDeviceDiscoverer) -> CameraPlugin
  {
    return CameraPlugin(
      registry: MockFlutterTextureRegistry(),
      messenger: MockFlutterBinaryMessenger(),
      globalAPI: MockGlobalEventApi(),
      deviceDiscoverer: deviceDiscoverer,
      permissionManager: MockCameraPermissionManager(),
      deviceFactory: { _ in MockCaptureDevice() },
      captureSessionFactory: { MockCaptureSession() },
      captureDeviceInputFactory: MockCaptureDeviceInputFactory(),
      captureSessionQueue: DispatchQueue(label: "io.flutter.camera.captureSessionQueue")
    )
  }

  func testAvailableCamerasShouldReturnAllCamerasOnMultiCameraIPhone() {
    let mockDeviceDiscoverer = MockCameraDeviceDiscoverer()
    let cameraPlugin = createCameraPlugin(with: mockDeviceDiscoverer)
    let expectation = self.expectation(description: "Result finished")

    mockDeviceDiscoverer.discoverySessionStub = { deviceTypes, mediaType, position in
      // iPhone 13 Cameras:
      let wideAngleCamera = MockCaptureDevice()
      wideAngleCamera.uniqueID = "0"
      wideAngleCamera.position = .back

      let frontFacingCamera = MockCaptureDevice()
      frontFacingCamera.uniqueID = "1"
      frontFacingCamera.position = .front

      let ultraWideCamera = MockCaptureDevice()
      ultraWideCamera.uniqueID = "2"
      ultraWideCamera.position = .back

      let telephotoCamera = MockCaptureDevice()
      telephotoCamera.uniqueID = "3"
      telephotoCamera.position = .back

      let requiredTypes: [AVCaptureDevice.DeviceType] = [
        .builtInTripleCamera,
        .builtInDualWideCamera,
        .builtInDualCamera,
        .builtInWideAngleCamera,
        .builtInTelephotoCamera,
        .builtInUltraWideCamera,
      ]
      let cameras = [wideAngleCamera, frontFacingCamera, telephotoCamera, ultraWideCamera]

      XCTAssertEqual(deviceTypes, requiredTypes)
      XCTAssertEqual(mediaType, .video)
      XCTAssertEqual(position, .unspecified)
      return cameras
    }

    var resultValue: [PlatformCameraDescription]?
    cameraPlugin.getAvailableCameras { result in
      resultValue = self.assertSuccess(result)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 30, handler: nil)

    // Verify the result.
    XCTAssertEqual(resultValue?.count, 4)
  }

  func testAvailableCamerasShouldReturnTwoCamerasOnDualCameraIPhone() {
    let mockDeviceDiscoverer = MockCameraDeviceDiscoverer()
    let cameraPlugin = createCameraPlugin(with: mockDeviceDiscoverer)
    let expectation = self.expectation(description: "Result finished")

    mockDeviceDiscoverer.discoverySessionStub = { deviceTypes, mediaType, position in
      // iPhone 8 Cameras:
      let wideAngleCamera = MockCaptureDevice()
      wideAngleCamera.uniqueID = "0"
      wideAngleCamera.position = .back

      let frontFacingCamera = MockCaptureDevice()
      frontFacingCamera.uniqueID = "1"
      frontFacingCamera.position = .front

      let requiredTypes: [AVCaptureDevice.DeviceType] = [
        .builtInTripleCamera,
        .builtInDualWideCamera,
        .builtInDualCamera,
        .builtInWideAngleCamera,
        .builtInTelephotoCamera,
        .builtInUltraWideCamera,
      ]
      let cameras = [wideAngleCamera, frontFacingCamera]

      XCTAssertEqual(deviceTypes, requiredTypes)
      XCTAssertEqual(mediaType, .video)
      XCTAssertEqual(position, .unspecified)
      return cameras
    }

    var resultValue: [PlatformCameraDescription]?
    cameraPlugin.getAvailableCameras { result in
      resultValue = self.assertSuccess(result)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 30, handler: nil)

    // Verify the result.
    XCTAssertEqual(resultValue?.count, 2)
  }

  func testAvailableCamerasShouldReturnExternalLensDirectionForUnspecifiedCameraPosition() {
    let mockDeviceDiscoverer = MockCameraDeviceDiscoverer()
    let cameraPlugin = createCameraPlugin(with: mockDeviceDiscoverer)
    let expectation = self.expectation(description: "Result finished")

    mockDeviceDiscoverer.discoverySessionStub = { deviceTypes, mediaType, position in
      let unspecifiedCamera = MockCaptureDevice()
      unspecifiedCamera.uniqueID = "0"
      unspecifiedCamera.position = .unspecified

      let requiredTypes: [AVCaptureDevice.DeviceType] = [
        .builtInTripleCamera,
        .builtInDualWideCamera,
        .builtInDualCamera,
        .builtInWideAngleCamera,
        .builtInTelephotoCamera,
        .builtInUltraWideCamera,
      ]
      let cameras = [unspecifiedCamera]

      XCTAssertEqual(deviceTypes, requiredTypes)
      XCTAssertEqual(mediaType, .video)
      XCTAssertEqual(position, .unspecified)
      return cameras
    }

    var resultValue: [PlatformCameraDescription]?
    cameraPlugin.getAvailableCameras { result in
      resultValue = self.assertSuccess(result)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 30, handler: nil)

    XCTAssertEqual(resultValue?.first?.lensDirection, .external)
  }

  func testAvailableCamerasShouldPreferVirtualBackCamerasBeforePhysicalAndFront() {
    let mockDeviceDiscoverer = MockCameraDeviceDiscoverer()
    let cameraPlugin = createCameraPlugin(with: mockDeviceDiscoverer)
    let expectation = self.expectation(description: "Result finished")

    mockDeviceDiscoverer.discoverySessionStub = { _, _, _ in
      let backWide = MockCaptureDevice()
      backWide.uniqueID = "wide"
      backWide.position = .back
      backWide.deviceType = .builtInWideAngleCamera

      let frontWide = MockCaptureDevice()
      frontWide.uniqueID = "front"
      frontWide.position = .front
      frontWide.deviceType = .builtInWideAngleCamera

      let backTele = MockCaptureDevice()
      backTele.uniqueID = "tele"
      backTele.position = .back
      backTele.deviceType = .builtInTelephotoCamera

      let backUltra = MockCaptureDevice()
      backUltra.uniqueID = "ultra"
      backUltra.position = .back
      backUltra.deviceType = .builtInUltraWideCamera

      let backDual = MockCaptureDevice()
      backDual.uniqueID = "dual"
      backDual.position = .back
      backDual.deviceType = .builtInDualCamera

      let backDualWide = MockCaptureDevice()
      backDualWide.uniqueID = "dualWide"
      backDualWide.position = .back
      backDualWide.deviceType = .builtInDualWideCamera

      let backTriple = MockCaptureDevice()
      backTriple.uniqueID = "triple"
      backTriple.position = .back
      backTriple.deviceType = .builtInTripleCamera

      return [backWide, frontWide, backTele, backUltra, backDual, backDualWide, backTriple]
    }

    var resultValue: [PlatformCameraDescription]?
    cameraPlugin.getAvailableCameras { result in
      resultValue = self.assertSuccess(result)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 30, handler: nil)

    XCTAssertEqual(
      resultValue?.map { $0.name },
      ["triple", "dualWide", "dual", "wide", "ultra", "tele", "front"])
  }

  func testAvailableCamerasShouldMapVirtualLensTypesToWide() {
    let mockDeviceDiscoverer = MockCameraDeviceDiscoverer()
    let cameraPlugin = createCameraPlugin(with: mockDeviceDiscoverer)
    let expectation = self.expectation(description: "Result finished")

    mockDeviceDiscoverer.discoverySessionStub = { _, _, _ in
      let dual = MockCaptureDevice()
      dual.uniqueID = "dual"
      dual.position = .back
      dual.deviceType = .builtInDualCamera

      let dualWide = MockCaptureDevice()
      dualWide.uniqueID = "dualWide"
      dualWide.position = .back
      dualWide.deviceType = .builtInDualWideCamera

      let triple = MockCaptureDevice()
      triple.uniqueID = "triple"
      triple.position = .back
      triple.deviceType = .builtInTripleCamera

      return [dual, dualWide, triple]
    }

    var resultValue: [PlatformCameraDescription]?
    cameraPlugin.getAvailableCameras { result in
      resultValue = self.assertSuccess(result)
      expectation.fulfill()
    }
    waitForExpectations(timeout: 30, handler: nil)

    XCTAssertEqual(resultValue?.map { $0.lensType }, [.wide, .wide, .wide])
  }
}
