import AppKit
import CoreGraphics
import AVFoundation

class PermissionManager {
    static let shared = PermissionManager()
    
    func checkAndRequestPermissions() {
        // Completely disabled automatic startup checks to prevent annoying the user.
        // Mac apps should request permissions only when a specific feature is triggered.
    }
    
    func isAccessibilityEnabled() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : false]
        return AXIsProcessTrustedWithOptions(options)
    }
}
