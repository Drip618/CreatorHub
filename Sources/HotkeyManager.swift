import Cocoa
import Carbon

class HotkeyManager {
    static let shared = HotkeyManager()
    private var hotkeys: [UInt32: () -> Void] = [:]
    private var registeredRefs: [UInt32: EventHotKeyRef] = [:]
    
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
    
    func refreshCustomHotkeys() {
        // Unregister everything first
        for ref in registeredRefs.values {
            UnregisterEventHotKey(ref)
        }
        registeredRefs.removeAll()
        hotkeys.removeAll()
        
        let settings = SettingsManager.shared
        for hk in settings.customHotkeys {
            if let actionId = hk.actionId {
                register(keyCode: hk.keyCode, modifiers: hk.modifiers, id: UInt32(hk.id)) {
                    self.dispatchAction(actionId: actionId)
                }
            }
        }
    }
    
    private func dispatchAction(actionId: String) {
        DispatchQueue.main.async {
            switch actionId {
            case "screenshot": (NSApp.delegate as? AppDelegate)?.triggerScreenshot()
            case "ocr": OCRManager.shared.recognizeTextFromScreen { _ in }
            case "translate": (NSApp.delegate as? AppDelegate)?.translateSelectedText()
            case "speech_to_text": SpeechManager.shared.toggleRecording()
            case "pick_color": SettingsManager.shared.pickColor()
            case "anti_sleep": SettingsManager.shared.toggleAwake()
            case "json_format": _ = SettingsManager.shared.smartJSONConvert()
            case "science_calc": (NSApp.delegate as? AppDelegate)?.showSmartCalc(tab: 0)
            case "unit_calc": (NSApp.delegate as? AppDelegate)?.showSmartCalc(tab: 1)
            case "currency_calc": (NSApp.delegate as? AppDelegate)?.showSmartCalc(tab: 2)
            default: break
            }
        }
    }
    
    func register(keyCode: UInt32, modifiers: UInt32, id: UInt32, block: @escaping () -> Void) {
        if let oldRef = registeredRefs[id] { UnregisterEventHotKey(oldRef) }
        hotkeys[id] = block
        var hotKeyID = EventHotKeyID(); hotKeyID.signature = OSType(0x4d434842); hotKeyID.id = id
        var hotKey: EventHotKeyRef?
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKey)
        if status == noErr, let ref = hotKey { registeredRefs[id] = ref }
    }
}
