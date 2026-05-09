import AppKit
import CoreGraphics
import AVFoundation

class PermissionManager {
    static let shared = PermissionManager()
    
    func checkAndRequestPermissions() {
        // Just check, don't force prompt unless needed
        if !isAccessibilityEnabled() {
            // Optional: You could show a custom one-time alert here instead of the system one
            // requestAccessibility(force: true)
        }
        requestScreenRecording()
    }
    
    func isAccessibilityEnabled() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : false]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    private func requestAccessibility(force: Bool) {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : force]
        AXIsProcessTrustedWithOptions(options)
    }
    
    private func requestScreenRecording() {
        if #available(macOS 10.15, *) {
            // Check if we can capture screen
            let canCapture = CGPreflightScreenCaptureAccess()
            if !canCapture {
                // This will trigger the system prompt if not granted
                CGRequestScreenCaptureAccess()
            }
        }
    }
}
