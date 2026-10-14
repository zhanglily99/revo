import AppKit
import AVFoundation
import QuartzCore

final class RevoView: NSView {
    private enum State { case idle, ready, working }
    private struct Job { let url: URL; let style: ShredStyle; let point: CGPoint; let demo: Bool }
    private var state = State.idle
    private var queue = PowerQueue<Job>()
    var isPoweredOn: Bool { queue.isPoweredOn }
    private let trash = TrashService()
    private let machine = CALayer()
    private let feeder = CALayer()
    private let scraps = CALayer()
    private let powerSwitch = NSSwitch(frame: MachineArtwork.switchFrame)
    private let powerLabel = CATextLayer()
    private let shutter = CALayer()
    private let backdrop = GlassBackdrop(frame: MachineArtwork.shell)
    private let led = CALayer()
    private let glow = CALayer()
    private let caption = CATextLayer()
    private var pile: [CALayer] = []
    private var players: [AVAudioPlayer] = []
    private var hovered = false
    private var dragActive = false
    private var messageVersion = 0
    private var mute: Bool {
        get { UserDefaults.standard.bool(forKey: "muted") }
        set { UserDefaults.standard.set(newValue, forKey: "muted") }
    }
    private var reducedMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }
    private lazy var motorSound = SoundSynth.shredData()
    private lazy var finishSound = SoundSynth.thudData()
    private lazy var switchOnSound = SoundSynth.switchData(powerOn: true)
    private lazy var switchOffSound = SoundSynth.switchData(powerOn: false)

    override init(frame: NSRect) {
        super.init(frame: frame)
        // Keep one design coordinate system while AppKit scales rendering and hit testing.
        bounds = CGRect(origin: .zero, size: MachineArtwork.size)
        wantsLayer = true
        layer?.masksToBounds = false
        registerForDraggedTypes([.fileURL])
        setupLayers()
        setAccessibilityElement(false)
        setAccessibilityRole(.group)
        setAccessibilityLabel("Revo")
        setAccessibilityHelp("Turn on the power switch before dropping files. Revo starts off each time it opens. Right-click for undo and settings.")
        toolTip = "Revo is off. Turn on the switch to accept files."
        NSWorkspace.shared.notificationCenter.addObserver(self, selector: #selector(updateTransparency), name: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil)
        updateTransparency()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }
    override var mouseDownCanMoveWindow: Bool { false }

    private func setupLayers() {
        addSubview(backdrop)
        let artwork = ArtworkHost(frame: bounds)
        artwork.wantsLayer = true
        addSubview(artwork)
        guard let layer = artwork.layer else { return }
        machine.frame = bounds; layer.addSublayer(machine)
        let body = CALayer(); body.frame = bounds; body.contents = MachineArtwork.image(); machine.addSublayer(body)
        // The feed is clipped above the physical opening, not hidden by a full image.
        feeder.frame = CGRect(x: 40, y: MachineArtwork.slotY, width: 160, height: 87)
        feeder.masksToBounds = true; machine.addSublayer(feeder)
        scraps.frame = MachineArtwork.window; scraps.cornerRadius = 10; scraps.masksToBounds = true; machine.addSublayer(scraps)
        let glass = CALayer(); glass.frame = bounds; glass.contents = MachineArtwork.image(glass: true); machine.addSublayer(glass)
        glow.frame = CGRect(x: 50, y: 188, width: 140, height: 1.5); glow.cornerRadius = 0.75
        glow.backgroundColor = MachineArtwork.color(0xDCEBFF).cgColor; glow.opacity = 0
        glow.shadowColor = MachineArtwork.color(0xBFD9FF).cgColor; glow.shadowRadius = 4; glow.shadowOpacity = 0.6; machine.addSublayer(glow)
        shutter.frame = CGRect(x: 47, y: 189, width: 146, height: 7)
        shutter.contents = MachineArtwork.shutter(); machine.addSublayer(shutter)
        led.frame = CGRect(x: 48, y: 70, width: 4, height: 4); led.cornerRadius = 2
        machine.addSublayer(led)
        powerLabel.frame = CGRect(x: 59, y: 65, width: 84, height: 15)
        powerLabel.font = NSFont.systemFont(ofSize: 8, weight: .semibold); powerLabel.fontSize = 8
        powerLabel.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        powerLabel.foregroundColor = MachineArtwork.color(0x465361).cgColor
        machine.addSublayer(powerLabel)
        powerSwitch.target = self; powerSwitch.action = #selector(togglePower)
        powerSwitch.appearance = NSAppearance(named: .aqua)
        powerSwitch.setAccessibilityLabel("Revo power")
        powerSwitch.setAccessibilityHelp("Off rejects file drops. On allows files to move to Trash.")
        powerSwitch.toolTip = "Turn on to accept files"
        addSubview(powerSwitch)
        updatePowerPresentation()
        caption.frame = CGRect(x: 8, y: 20, width: 224, height: 19)
        caption.font = NSFont.systemFont(ofSize: 10, weight: .medium); caption.fontSize = 10
        caption.alignmentMode = .center; caption.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
        caption.foregroundColor = NSColor.labelColor.cgColor
        caption.shadowColor = NSColor.windowBackgroundColor.cgColor; caption.shadowOpacity = 0.9; caption.shadowRadius = 3
        caption.opacity = 0; layer.addSublayer(caption)
    }

    override func updateTrackingAreas() {
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect], owner: self))
        super.updateTrackingAreas()
    }
    override func mouseEntered(with event: NSEvent) {
        hovered = true
        if state == .idle { showMessage(isPoweredOn ? "On · Drop a file to let it go." : "Off · Turn on to accept files.", persistent: true) }
    }
    override func mouseExited(with event: NSEvent) {
        hovered = false
        if state == .idle { caption.opacity = 0 }
    }
    override func mouseDown(with event: NSEvent) {
        window?.performDrag(with: event)
        (window as? RevoPanel)?.savePosition()
    }

    deinit { NSWorkspace.shared.notificationCenter.removeObserver(self) }

    @objc private func updateTransparency() {
        let reduce = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        backdrop.alphaValue = reduce ? 1 : 0.68
        backdrop.layer?.backgroundColor = reduce ? MachineArtwork.color(0xE6EBF1).cgColor : NSColor.clear.cgColor
    }

    @objc private func togglePower() {
        let enabled = !isPoweredOn
        setPower(enabled)
        play(enabled ? switchOnSound : switchOffSound, volume: 0.45)
    }

    func setPower(_ enabled: Bool) {
        queue.setPower(enabled)
        dragActive = false
        if state == .ready {
            setState(.idle)
            spring(machine, key: "transform.translation.y", from: 3, to: 0)
        }
        updatePowerPresentation()
        showMessage(enabled ? "On · Drop a file to let it go." : state == .working ? "Turning off · Finishing current file." : "Off · File drops are disabled.")
    }

    private func updatePowerPresentation() {
        powerSwitch.state = isPoweredOn ? .on : .off
        powerLabel.string = isPoweredOn ? "ON" : "OFF"
        toolTip = isPoweredOn ? "Drop a file to move it to Trash. Right-click to undo." : "Revo is off. Turn on the switch to accept files."
        CATransaction.begin(); CATransaction.setAnimationDuration(reducedMotion ? 0 : 0.22)
        shutter.opacity = isPoweredOn ? 0 : 1
        shutter.transform = CATransform3DMakeScale(1, isPoweredOn ? 0.08 : 1, 1)
        glow.opacity = isPoweredOn && state != .idle ? 1 : 0
        led.backgroundColor = MachineArtwork.color(isPoweredOn ? (state == .working ? 0x5A9CD9 : 0x519382) : 0x8E99A6).cgColor
        CATransaction.commit()
    }

    private func spring(_ target: CALayer, key: String, from: CGFloat, to: CGFloat) {
        CATransaction.begin(); CATransaction.setDisableActions(true); target.setValue(to, forKeyPath: key); CATransaction.commit()
        guard !reducedMotion else { return }
        let animation = CASpringAnimation(keyPath: key); animation.fromValue = from; animation.toValue = to
        animation.mass = 0.7; animation.stiffness = 260; animation.damping = 22; animation.duration = animation.settlingDuration
        target.add(animation, forKey: key)
    }
    private func showMessage(_ text: String, persistent: Bool = false) {
        messageVersion += 1; let version = messageVersion
        caption.string = text; caption.opacity = 1
        if !persistent {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self, self.messageVersion == version, self.state == .idle else { return }
                self.caption.opacity = 0
            }
        }
    }
    private func setState(_ next: State) {
        state = next
        updatePowerPresentation()
    }

    private func urls(_ info: NSDraggingInfo) -> [URL] {
        let values = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        // A parent folder already includes its descendants. Never queue them twice.
        let unique = Array(Set(values.map { $0.standardizedFileURL })).sorted { $0.path < $1.path }
        return unique.filter { candidate in !unique.contains { parent in parent != candidate && candidate.path.hasPrefix(parent.path + "/") } }
    }
    private func dragOperation(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard isPoweredOn, !urls(sender).isEmpty else { return [] }
        let allowed = sender.draggingSourceOperationMask
        // Generic is appropriate for a destination that performs its own filesystem action.
        if allowed.contains(.generic) { return .generic }
        if allowed.contains(.move) { return .move }
        return []
    }
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard isPoweredOn else {
            showMessage("Off · Turn on before dropping files.")
            return []
        }
        let operation = dragOperation(sender); guard !operation.isEmpty else { return [] }
        dragActive = true
        if state != .working { setState(.ready); spring(machine, key: "transform.translation.y", from: 0, to: 3) }
        showMessage("Release to move to Trash · \(urls(sender).count) items", persistent: true)
        return operation
    }
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation { dragOperation(sender) }
    override func draggingExited(_ sender: NSDraggingInfo?) {
        dragActive = false
        if state == .ready { setState(.idle); spring(machine, key: "transform.translation.y", from: 3, to: 0); caption.opacity = 0 }
    }
    override func draggingEnded(_ sender: NSDraggingInfo) { dragActive = false }
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let files = urls(sender); guard !files.isEmpty, !dragOperation(sender).isEmpty else { return false }
        dragActive = false
        let p = convert(sender.draggingLocation, from: nil)
        return acceptFiles(files, at: p)
    }

    /// Both the drop handler and the integration check enter through this interlock.
    @discardableResult
    func acceptFiles(_ files: [URL], at point: CGPoint) -> Bool {
        guard isPoweredOn, !files.isEmpty else { return false }
        let jobs = files.map { Job(url: $0, style: ShredStyle.classify($0), point: point, demo: false) }
        guard queue.append(contentsOf: jobs) else { return false }
        next()
        return true
    }

    func demo(_ style: ShredStyle) {
        guard isPoweredOn, state != .working else { return }
        queue.append(contentsOf: [Job(url: URL(fileURLWithPath: "/demo-paper.txt"), style: style, point: CGPoint(x: 120, y: 246), demo: true)])
        next()
    }
    private func next() {
        guard state != .working, let job = queue.takeNext() else { return }
        setState(.working)
        spring(machine, key: "transform.translation.y", from: 3, to: 0)
        showMessage(job.demo ? "Try a sheet. Let it go." : "Moving to Trash…", persistent: true)
        // Build the preview before recycling, while the original still exists.
        let sprite = PaperSprite.make(for: job.url, style: job.style)
        if job.demo { animate(job, image: sprite); return }
        trash.recycle(job.url) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                Stats.increment(); self.animate(job, image: sprite)
            case .failure(let error):
                self.setState(.idle)
                self.showMessage("Could not move to Trash")
                self.toolTip = error.localizedDescription
                self.led.backgroundColor = MachineArtwork.color(0xC47657).cgColor
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.next() }
            }
        }
    }

    private func animate(_ job: Job, image: CGImage?) {
        guard let image else { finish(job); return }
        let duration: Double = reducedMotion ? 0.18 : job.style == .heavy ? 1.7 : job.style == .folder ? 1.35 : 1.05
        let approach = reducedMotion ? 0 : 0.28
        let count = job.style == .folder ? 3 : 1
        for i in 0..<count {
            let sheet = CALayer(); sheet.contents = image
            sheet.bounds = CGRect(x: 0, y: 0, width: 66, height: 80)
            let dx = CGFloat(i) * 4
            let start = CGPoint(x: 80 + dx, y: 43 + CGFloat(i) * 6)
            let end = CGPoint(x: 80 + dx, y: -41)
            sheet.position = end; feeder.addSublayer(sheet)
            let position = CAKeyframeAnimation(keyPath: "position")
            let sourceX = max(43, min(117, job.point.x - feeder.frame.minX))
            position.values = [NSValue(point: CGPoint(x: sourceX + dx, y: 58 + CGFloat(i) * 6)), NSValue(point: start), NSValue(point: end)]
            position.keyTimes = [0, NSNumber(value: approach / (duration + approach)), 1]
            position.timingFunctions = [CAMediaTimingFunction(controlPoints: 0.2, 0.8, 0.2, 1), CAMediaTimingFunction(name: .linear)]
            position.duration = duration + approach; position.beginTime = CACurrentMediaTime() + Double(i) * 0.15
            position.fillMode = .backwards; sheet.add(position, forKey: "feed")
            let rotate = CABasicAnimation(keyPath: "transform.rotation.z"); rotate.fromValue = i == 1 ? 0.08 : -0.055; rotate.toValue = 0; rotate.duration = max(0.01, approach)
            sheet.add(rotate, forKey: "align")
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + approach + Double(i) * 0.15) { sheet.removeFromSuperlayer() }
        }
        if !reducedMotion {
            let vibration = CAKeyframeAnimation(keyPath: "transform.translation.x")
            vibration.values = [0, 0.35, -0.35, 0.2, 0]; vibration.duration = 0.16; vibration.repeatCount = .infinity
            machine.add(vibration, forKey: "motor")
            play(motorSound, volume: 0.16)
        }
        emit(image, style: job.style, duration: duration, delay: approach + 0.17)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + approach + 0.55) { [weak self] in self?.finish(job) }
    }

    private func emit(_ image: CGImage, style: ShredStyle, duration: Double, delay: Double) {
        let columns = style == .video ? 6 : style == .audio ? 12 : 11
        let rows = style == .photo ? 5 : 1
        for row in 0..<rows {
            for col in 0..<columns {
                let crop = CGRect(x: CGFloat(col) * CGFloat(image.width) / CGFloat(columns), y: CGFloat(row) * CGFloat(image.height) / CGFloat(rows), width: CGFloat(image.width) / CGFloat(columns), height: CGFloat(image.height) / CGFloat(rows)).integral
                guard let piece = image.cropping(to: crop) else { continue }
                let strip = CALayer(); strip.contents = piece
                let height: CGFloat = style == .photo ? 6 : style == .video ? 24 : 28
                strip.bounds = CGRect(x: 0, y: 0, width: 66 / CGFloat(columns) - 1, height: height)
                let x = 44 + CGFloat(col) * 66 / CGFloat(columns)
                let start = CGPoint(x: x, y: 79 + height / 2)
                let pileHeight = min(15, CGFloat(pile.count) * 0.15)
                let end = CGPoint(x: x + CGFloat.random(in: -19...19), y: 5 + pileHeight + CGFloat.random(in: 0...5))
                strip.position = end
                strip.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat.random(in: -0.9...0.9)).scaledBy(x: 1, y: 0.35))
                scraps.addSublayer(strip); pile.append(strip)
                let fall = CAKeyframeAnimation(keyPath: "position")
                fall.values = [NSValue(point: start), NSValue(point: CGPoint(x: x, y: 35)), NSValue(point: end)]
                fall.keyTimes = [0, 0.65, 1]; fall.timingFunctions = [CAMediaTimingFunction(name: .linear), CAMediaTimingFunction(name: .easeIn)]
                let curl = CABasicAnimation(keyPath: "transform"); curl.fromValue = CATransform3DIdentity; curl.toValue = strip.transform
                let group = CAAnimationGroup(); group.animations = [fall, curl]
                group.duration = reducedMotion ? 0.12 : duration * 0.62
                group.beginTime = CACurrentMediaTime() + delay + Double(row) * duration / Double(rows) * 0.7 + Double(col) * 0.012
                group.fillMode = .backwards; strip.add(group, forKey: "cut")
            }
        }
        // Keep a bounded physical pile without leaving animations running while idle.
        while pile.count > 90 { pile.removeFirst().removeFromSuperlayer() }
    }
    private func finish(_ job: Job) {
        machine.removeAnimation(forKey: "motor")
        players.forEach { $0.stop() }; players.removeAll()
        play(finishSound, volume: 0.12)
        setState(.idle)
        if !reducedMotion { spring(machine, key: "transform.translation.y", from: -1.2, to: 0) }
        showMessage(isPoweredOn ? (job.demo ? "Demo only. No files moved." : "Moved to Trash · Right-click to undo") : "Off · File drops are disabled.")
        if !queue.isEmpty { next() }
        else if dragActive && isPoweredOn { setState(.ready) }
    }
    private func play(_ data: Data, volume: Float) {
        guard !mute, let player = try? AVAudioPlayer(data: data) else { return }
        players.removeAll { !$0.isPlaying }; player.volume = volume; players.append(player); player.play()
    }

    override func menu(for event: NSEvent) -> NSMenu? { makeMenu() }
    func makeMenu() -> NSMenu {
        let menu = NSMenu(); menu.autoenablesItems = false
        func item(_ title: String, _ action: Selector, enabled: Bool = true) -> NSMenuItem {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: ""); item.target = self; item.isEnabled = enabled; menu.addItem(item); return item
        }
        let power = item(isPoweredOn ? "Turn Off" : "Turn On", #selector(togglePower))
        power.state = isPoweredOn ? .on : .off
        menu.addItem(.separator())
        let count = NSMenuItem(title: "Recycled today: \(Stats.todayCount)", action: nil, keyEquivalent: ""); count.isEnabled = false; menu.addItem(count)
        menu.addItem(.separator())
        _ = item("Undo Last File", #selector(undo), enabled: trash.canUndo && state != .working)
        _ = item("Open Trash", #selector(openTrash))
        let demos = NSMenuItem(title: "Try It", action: nil, keyEquivalent: ""); let submenu = NSMenu()
        for (index, title) in ["Document · Paper Strips", "Photo · Confetti", "Audio · Waveform", "Video · Film Strips", "Folder · Stacked Sheets"].enumerated() {
            let option = NSMenuItem(title: title, action: #selector(demoMenu(_:)), keyEquivalent: ""); option.tag = index; option.target = self; submenu.addItem(option)
        }
        demos.submenu = submenu; demos.isEnabled = isPoweredOn && state != .working; menu.addItem(demos)
        _ = item("Clear Paper Scraps", #selector(clearScraps), enabled: state != .working)
        menu.addItem(.separator())
        let sound = item("Sound", #selector(toggleSound)); sound.state = mute ? .off : .on
        _ = item("Hide Revo", #selector(hidePanel))
        _ = item("Quit Revo", #selector(quit))
        return menu
    }
    @objc private func demoMenu(_ sender: NSMenuItem) { demo([.document, .photo, .audio, .video, .folder][sender.tag]) }
    @objc private func toggleSound() { mute.toggle(); if mute { players.forEach { $0.stop() } } }
    @objc private func clearScraps() {
        let old = pile; pile.removeAll()
        CATransaction.begin(); CATransaction.setAnimationDuration(reducedMotion ? 0 : 0.3)
        CATransaction.setCompletionBlock { old.forEach { $0.removeFromSuperlayer() } }
        old.forEach { $0.opacity = 0; $0.position.y -= 12 }; CATransaction.commit()
        showMessage("Paper scraps cleared.")
    }
    @objc private func undo() {
        guard state != .working, trash.canUndo else { return }
        setState(.working); showMessage("Restoring the last file…", persistent: true)
        trash.undo { [weak self] result in
            guard let self else { return }; self.setState(.idle)
            switch result {
            case .success: Stats.decrement(); self.showMessage("Restored to its original location.")
            case .failure(let error): self.showMessage("Could not restore · Open Trash"); self.toolTip = error.localizedDescription
            }
            self.next()
        }
    }
    @objc private func openTrash() { NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".Trash")) }
    @objc private func hidePanel() { window?.orderOut(nil) }
    @objc private func quit() { NSApp.terminate(nil) }
}
