import Cocoa
import Carbon.HIToolbox

enum ResizeEdge {
    case topLeft, top, topRight
    case left, right
    case bottomLeft, bottom, bottomRight
}

// Borderless NSPanel can't become key by default — keyboard input breaks without this
class NotePanel: NSPanel {
    override var canBecomeKey: Bool { return true }

    let edgeSize: CGFloat = 6
    let cornerSize: CGFloat = 12
    let minPanelSize: CGFloat = 200

    // Private Apple cursors (same ones the system uses for native window resize)
    var nwseCursor: NSCursor {   // ↖↘
        NSCursor.perform(Selector(("_windowResizeNorthWestSouthEastCursor")))?
            .takeUnretainedValue() as? NSCursor ?? NSCursor.crosshair
    }
    var neswCursor: NSCursor {   // ↗↙
        NSCursor.perform(Selector(("_windowResizeNorthEastSouthWestCursor")))?
            .takeUnretainedValue() as? NSCursor ?? NSCursor.crosshair
    }
    var nsCursor: NSCursor {     // ↕
        NSCursor.perform(Selector(("_windowResizeNorthSouthCursor")))?
            .takeUnretainedValue() as? NSCursor ?? NSCursor.resizeUpDown
    }
    var ewCursor: NSCursor {     // ↔
        NSCursor.perform(Selector(("_windowResizeEastWestCursor")))?
            .takeUnretainedValue() as? NSCursor ?? NSCursor.resizeLeftRight
    }

    func resizeEdge(at loc: NSPoint) -> ResizeEdge? {
        let w = frame.width
        let h = frame.height
        let c = cornerSize

        let inLeft   = loc.x < c
        let inRight  = loc.x > w - c
        let inBottom = loc.y < c
        let inTop    = loc.y > h - c

        if inLeft  && inBottom { return .bottomLeft }
        if inRight && inBottom { return .bottomRight }
        if inLeft  && inTop    { return .topLeft }
        if inRight && inTop    { return .topRight }
        if loc.x < edgeSize     { return .left }
        if loc.x > w - edgeSize { return .right }
        if loc.y < edgeSize     { return .bottom }
        if loc.y > h - edgeSize { return .top }
        return nil
    }

    func cursor(for edge: ResizeEdge) -> NSCursor {
        switch edge {
        case .topLeft, .bottomRight: return nwseCursor
        case .topRight, .bottomLeft: return neswCursor
        case .left, .right:          return ewCursor
        case .top, .bottom:          return nsCursor
        }
    }

    override func mouseDown(with event: NSEvent) {
        if let edge = resizeEdge(at: event.locationInWindow) {
            performResize(edge: edge)
        } else {
            super.mouseDown(with: event)
        }
    }

    func performResize(edge: ResizeEdge) {
        let start    = frame
        let startLoc = NSEvent.mouseLocation

        cursor(for: edge).push()

        while true {
            guard let event = nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) else { break }
            if event.type == .leftMouseUp { break }

            let loc = NSEvent.mouseLocation
            let dx  = loc.x - startLoc.x
            let dy  = loc.y - startLoc.y

            var x = start.origin.x
            var y = start.origin.y
            var w = start.width
            var h = start.height

            switch edge {
            case .right:
                w = max(start.width + dx, minPanelSize)
            case .left:
                w = max(start.width - dx, minPanelSize)
                x = start.maxX - w
            case .top:
                h = max(start.height + dy, minPanelSize)
            case .bottom:
                h = max(start.height - dy, minPanelSize)
                y = start.maxY - h
            case .bottomRight:
                w = max(start.width + dx, minPanelSize)
                h = max(start.height - dy, minPanelSize)
                y = start.maxY - h
            case .bottomLeft:
                w = max(start.width - dx, minPanelSize)
                x = start.maxX - w
                h = max(start.height - dy, minPanelSize)
                y = start.maxY - h
            case .topRight:
                w = max(start.width + dx, minPanelSize)
                h = max(start.height + dy, minPanelSize)
            case .topLeft:
                w = max(start.width - dx, minPanelSize)
                x = start.maxX - w
                h = max(start.height + dy, minPanelSize)
            }

            setFrame(NSRect(x: x, y: y, width: w, height: h), display: true)
        }

        NSCursor.pop()
    }
}

// One tracking area per resize zone — AppKit resets the cursor automatically on exit
class ContainerView: NSView {
    weak var panel: NotePanel?

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        guard let panel = panel else { return }

        let e = panel.edgeSize
        let c = panel.cornerSize
        let w = bounds.width
        let h = bounds.height

        let rects = [
            NSRect(x: 0,   y: h-c, width: c,     height: c),     // top-left
            NSRect(x: c,   y: h-e, width: w-2*c, height: e),     // top
            NSRect(x: w-c, y: h-c, width: c,     height: c),     // top-right
            NSRect(x: 0,   y: c,   width: e,     height: h-2*c), // left
            NSRect(x: w-e, y: c,   width: e,     height: h-2*c), // right
            NSRect(x: 0,   y: 0,   width: c,     height: c),     // bottom-left
            NSRect(x: c,   y: 0,   width: w-2*c, height: e),     // bottom
            NSRect(x: w-c, y: 0,   width: c,     height: c),     // bottom-right
        ]
        for rect in rects {
            addTrackingArea(NSTrackingArea(rect: rect, options: [.activeAlways, .cursorUpdate], owner: self))
        }
    }

    override func cursorUpdate(with event: NSEvent) {
        guard let panel = panel else { return }
        if let edge = panel.resizeEdge(at: event.locationInWindow) {
            panel.cursor(for: edge).set()
        }
    }
}

// MARK: - Draggable header

class DraggableHeaderView: NSView {
    weak var panel: NotePanel?

    override func resetCursorRects() {
        addCursorRect(bounds, cursor: .openHand)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach { removeTrackingArea($0) }
        addTrackingArea(NSTrackingArea(
            rect: bounds,
            options: [.activeAlways, .inVisibleRect, .cursorUpdate],
            owner: self
        ))
    }

    override func cursorUpdate(with event: NSEvent) {
        NSCursor.openHand.set()
    }

    override func mouseDown(with event: NSEvent) {
        guard let panel = panel else { return }

        // Top edge/corner — forward to panel resize
        if panel.resizeEdge(at: event.locationInWindow) != nil {
            panel.mouseDown(with: event)
            return
        }

        NSCursor.closedHand.push()

        let startMouse  = NSEvent.mouseLocation
        let startOrigin = panel.frame.origin

        while true {
            guard let e = window?.nextEvent(matching: [.leftMouseDragged, .leftMouseUp]) else { break }
            if e.type == .leftMouseUp { break }
            let loc = NSEvent.mouseLocation
            panel.setFrameOrigin(NSPoint(
                x: startOrigin.x + loc.x - startMouse.x,
                y: startOrigin.y + loc.y - startMouse.y
            ))
        }

        NSCursor.pop()
        NSCursor.openHand.set()
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {

    var statusItem: NSStatusItem!
    var panel: NotePanel!
    var textView: NSTextView!

    var globalClickMonitor: Any?
    var localClickMonitor: Any?

    // Prevents the global click monitor from closing the panel right as togglePanel reopens it
    var lastCloseTime: Date = .distantPast
    var hasBeenPositioned: Bool = false

    let saveURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".notty.txt")

    var isPinned: Bool = false
    var titleButton: NSButton!
    var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {

        // 1. Menu bar icon
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "folder", accessibilityDescription: "Notty")
            button.action = #selector(togglePanel)
            button.target = self
        }

        // 2. Panel
        // No .nonactivatingPanel — it breaks keyboard input and foreground activation
        panel = NotePanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 400),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .popUpMenu
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hidesOnDeactivate = false
        panel.isReleasedWhenClosed = false
        panel.isFloatingPanel = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // 3. Container
        let container = ContainerView(frame: NSRect(x: 0, y: 0, width: 320, height: 400))
        container.panel = panel
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor(white: 0.3000, alpha: 0.95).cgColor
        container.layer?.cornerRadius = 12
        container.layer?.borderWidth = 1
        container.layer?.borderColor = NSColor(white: 1.0, alpha: 0.0000009).cgColor
        container.autoresizingMask = [.width, .height]

        // 4. Header
        let header = DraggableHeaderView(frame: NSRect(x: 0, y: 350, width: 320, height: 50))
        header.panel = panel
        header.autoresizingMask = [.width, .minYMargin]

        let title = NSTextField(labelWithString: "Notty")
        title.frame = NSRect(x: 16, y: 15, width: 200, height: 24)
        title.font = NSFont(name: "Space Mono", size: 14)
            ?? NSFont.monospacedSystemFont(ofSize: 14, weight: .bold)
        title.textColor = NSColor(white: 1.0, alpha: 0.5)
        header.addSubview(title)

        titleButton = NSButton(frame: NSRect(x: 288, y: 14, width: 22, height: 22))
        titleButton.bezelStyle = .inline
        titleButton.isBordered = false
        titleButton.image = NSImage(systemSymbolName: "pin", accessibilityDescription: "Pin")
        titleButton.contentTintColor = NSColor(white: 1.0, alpha: 0.2)
        titleButton.autoresizingMask = [.minXMargin]
        titleButton.target = self
        titleButton.action = #selector(togglePinned)
        header.addSubview(titleButton)

        container.addSubview(header)

        // 5. Text editor
        let scrollView = NSScrollView(frame: NSRect(x: 12, y: 12, width: 296, height: 345))
        scrollView.autoresizingMask = [.width, .height]
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        textView = NSTextView(frame: scrollView.bounds)
        textView.isEditable = true
        textView.isRichText = false
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.insertionPointColor = .white
        textView.textColor = NSColor(white: 1.0, alpha: 0.9)
        textView.font = NSFont(name: "Space Mono", size: 13)
            ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        container.addSubview(scrollView)

        panel.contentView = container

        // 6. Load saved notes
        if let saved = try? String(contentsOf: saveURL, encoding: .utf8) {
            textView.string = saved
        }

        // 7. Global hotkey ⌘+Control+N
        registerHotKey()

        // 8. Auto-save
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(textDidChange),
            name: NSText.didChangeNotification,
            object: textView
        )
    }

    func registerHotKey() {
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = OSType(0x6E6F7479)  // 'noty'
        hotKeyID.id = 1

        // kVK_ANSI_N = 45
        RegisterEventHotKey(45, UInt32(cmdKey | controlKey), hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData -> OSStatus in
            let delegate = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
            delegate.togglePanel()
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), nil)
    }

    @objc func togglePinned() {
        isPinned.toggle()
        let icon = isPinned ? "pin.fill" : "pin"
        titleButton.image = NSImage(systemSymbolName: icon, accessibilityDescription: "Pin")
        titleButton.contentTintColor = isPinned
            ? NSColor(white: 1.0, alpha: 0.8)
            : NSColor(white: 1.0, alpha: 0.2)
    }

    @objc func togglePanel() {
        if panel.isVisible {
            closePanel(force: true)
        } else {
            if Date().timeIntervalSince(lastCloseTime) < 0.3 { return }
            openPanel()
        }
    }

    func openPanel() {
        if let saved = try? String(contentsOf: saveURL, encoding: .utf8) {
            textView.string = saved
        }

        // Position under the icon on first open only; keep user-set position after that
        if !hasBeenPositioned {
            if let button = statusItem.button, let btnWindow = button.window {
                let buttonRect = btnWindow.convertToScreen(button.frame)
                let x = buttonRect.midX - panel.frame.width / 2
                let y = buttonRect.minY - panel.frame.height - 4
                panel.setFrameOrigin(NSPoint(x: x, y: y))
            }
            hasBeenPositioned = true
        }

        statusItem.button?.image = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: "Notty")

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(textView)

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.closePanel()
        }

        localClickMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            guard let self = self else { return event }
            if event.window === self.panel { return event }
            self.closePanel()
            return event
        }
    }

    func closePanel(force: Bool = false) {
        if isPinned && !force { return }

        statusItem.button?.image = NSImage(systemSymbolName: "folder", accessibilityDescription: "Notty")

        panel.orderOut(nil)
        lastCloseTime = Date()

        if let monitor = globalClickMonitor { NSEvent.removeMonitor(monitor); globalClickMonitor = nil }
        if let monitor = localClickMonitor  { NSEvent.removeMonitor(monitor); localClickMonitor  = nil }
    }

    @objc func textDidChange(_ notification: Notification) {
        try? textView.string.write(to: saveURL, atomically: true, encoding: .utf8)
    }
}

// CLI or GUI depending on arguments
let saveURL = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent(".notty.txt")

let args = CommandLine.arguments

if args.count > 1 {
    let command = args[1]

    switch command {

    case "list", "ls":
        if let content = try? String(contentsOf: saveURL, encoding: .utf8) {
            print(content.isEmpty ? "(empty)" : content)
        } else {
            print("(no notes)")
        }

    case "clear":
        print("Are you sure? (yes/no) ", terminator: "")
        if let answer = readLine()?.lowercased(), answer == "yes" || answer == "y" {
            try? "".write(to: saveURL, atomically: true, encoding: .utf8)
            print("Notes cleared.")
        } else {
            print("Cancelled.")
        }

    case "help", "--help", "-h":
        print("""
        nt — Notty CLI

        Usage:
          nt / notty            Launch the menu bar app
          nt <text>             Add a note
          nt list               Display all notes
          nt clear              Clear all notes
          nt help               Show this help
        """)

    default:
        let note = args.dropFirst().joined(separator: " ")
        var current = (try? String(contentsOf: saveURL, encoding: .utf8)) ?? ""
        if !current.isEmpty && !current.hasSuffix("\n") { current += "\n" }
        current += note + "\n"
        try? current.write(to: saveURL, atomically: true, encoding: .utf8)
        print("+ \(note)")
    }

} else {
    let app = NSApplication.shared
    app.setActivationPolicy(.accessory)
    let delegate = AppDelegate()
    app.delegate = delegate
    app.run()
}
