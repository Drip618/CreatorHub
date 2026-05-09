import Cocoa
import Carbon

class HotkeyManager {
    static let shared = HotkeyManager()
    private var hotkeys: [UInt32: () -> Void] = [:]
    
    init() {
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyReleased)
        
        let ptr = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(theEvent, 
                                          EventParamName(kEventParamDirectObject), 
                                          EventParamType(typeEventHotKeyID), 
                                          nil, 
                                          MemoryLayout<EventHotKeyID>.size, 
                                          nil, 
                                          &hotKeyID)
            
            if status == noErr {
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData!).takeUnretainedValue()
                if let block = manager.hotkeys[hotKeyID.id] {
                    block()
                    return noErr
                }
            }
            return OSStatus(eventNotHandledErr)
        }, 1, &eventType, ptr, nil)
    }
    
    func register(keyCode: Int, modifiers: UInt32, block: @escaping () -> Void) {
        let id = UInt32(keyCode + Int(modifiers))
        hotkeys[id] = block
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x4d434842) // 'MCHB'
        hotKeyID.id = id
        
        var hotKey: EventHotKeyRef?
        RegisterEventHotKey(UInt32(keyCode), modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKey)
    }
}
