// enable-electron-a11y.swift
//
// Turn on an Electron/Chromium app's full macOS accessibility tree so
// agent-desktop can see it. Chromium keeps its a11y tree OFF until it detects
// assistive technology; until then agent-desktop gets only a ~3-ref stub.
// Electron's documented third-party opt-in is to set the AXManualAccessibility
// attribute on the app's AX element:
//   https://electronjs.org/docs/latest/tutorial/accessibility
//   https://www.chromium.org/developers/design-documents/accessibility
//
// We set ONLY AXManualAccessibility (the documented, side-effect-free path).
// AXEnhancedUserInterface is the native-app analog but can trigger window-resize
// bugs in some AppKit apps, and Electron reports it unsupported on the app root,
// so we deliberately do not touch it.
//
// Usage: swift enable-electron-a11y.swift <app-name|bundle-id|pid>
// Emits a single JSON line; exit 0 on success, 1 if not applied, 2 on bad args.

import Cocoa
import ApplicationServices

func axErrName(_ e: AXError) -> String {
    switch e {
    case .success:           return "success"
    case .attributeUnsupported: return "attributeUnsupported"
    case .apiDisabled:       return "apiDisabled (grant Accessibility to your terminal)"
    case .invalidUIElement:  return "invalidUIElement"
    case .cannotComplete:    return "cannotComplete"
    case .notImplemented:    return "notImplemented"
    default:                 return "error(\(e.rawValue))"
    }
}

// Minimal JSON string escape for app/bundle names.
func j(_ s: String) -> String {
    var out = ""
    for c in s {
        switch c {
        case "\\": out += "\\\\"
        case "\"": out += "\\\""
        case "\n": out += "\\n"
        default:   out.append(c)
        }
    }
    return out
}

let args = Array(CommandLine.arguments.dropFirst())
guard let ident = args.first, !ident.isEmpty else {
    print("{\"ok\":false,\"error\":\"usage: enable-electron-a11y <app-name|bundle-id|pid>\"}")
    exit(2)
}

let running = NSWorkspace.shared.runningApplications
let app: NSRunningApplication? = {
    if let pid = Int32(ident) { return running.first { $0.processIdentifier == pid } }
    if let byBundle = running.first(where: { $0.bundleIdentifier == ident }) { return byBundle }
    return running.first { $0.localizedName == ident }
}()

guard let app = app else {
    print("{\"ok\":false,\"error\":\"app not running: \(j(ident))\"}")
    exit(1)
}

let pid = app.processIdentifier
let appEl = AXUIElementCreateApplication(pid)
let manual = AXUIElementSetAttributeValue(appEl, "AXManualAccessibility" as CFString, kCFBooleanTrue)

let name = app.localizedName ?? ""
let bundle = app.bundleIdentifier ?? ""
let ok = (manual == .success)
print("{\"ok\":\(ok),\"app\":\"\(j(name))\",\"bundle_id\":\"\(j(bundle))\",\"pid\":\(pid),\"manual\":\"\(axErrName(manual))\"}")
exit(ok ? 0 : 1)
