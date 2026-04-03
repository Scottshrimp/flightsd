import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum DeviceClass: String {
    case phone
    case pad
    case mac
    case other
}

enum TargetSystemProfile: String {
    case iOS18
    case iOS26
    case iPadOS18
    case iPadOS26
    case other
}

struct PlatformProfile: Equatable {
    let deviceClass: DeviceClass
    let osMajorVersion: Int

    // Collapse raw device/version combinations into the smaller set of supported layouts.
    var targetSystemProfile: TargetSystemProfile {
        switch (deviceClass, osMajorVersion) {
        case (.phone, 18):
            return .iOS18
        case (.phone, 26):
            return .iOS26
        case (.pad, 18):
            return .iPadOS18
        case (.pad, 26):
            return .iPadOS26
        default:
            return .other
        }
    }

    var isPhone: Bool { deviceClass == .phone }
    var isPad: Bool { deviceClass == .pad }
    var isRelease18Family: Bool { osMajorVersion >= 18 && osMajorVersion < 26 }
    var isRelease26Family: Bool { osMajorVersion >= 26 }
    var isTargetedSystem: Bool { targetSystemProfile != .other }

    static var current: PlatformProfile {
        // Resolve this once from the host environment and inject it through SwiftUI.
        PlatformProfile(
            deviceClass: currentDeviceClass,
            osMajorVersion: ProcessInfo.processInfo.operatingSystemVersion.majorVersion
        )
    }

    private static var currentDeviceClass: DeviceClass {
#if os(iOS)
        switch UIDevice.current.userInterfaceIdiom {
        case .phone:
            return .phone
        case .pad:
            return .pad
        default:
            return .other
        }
#elseif os(macOS)
        return .mac
#else
        return .other
#endif
    }
}

private struct PlatformProfileKey: EnvironmentKey {
    static let defaultValue = PlatformProfile.current
}

extension EnvironmentValues {
    var platformProfile: PlatformProfile {
        get { self[PlatformProfileKey.self] }
        set { self[PlatformProfileKey.self] = newValue }
    }
}
