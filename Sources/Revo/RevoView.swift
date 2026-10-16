import AppKit
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
    private let powerSwitch = PowerSwitch(frame: MachineArtwork.switchFrame)
    private let counter = CALayer()
    private let shutter = CALayer()
    private let backdrop = GlassBackdrop(frame: MachineArtwork.glassFrame)
    private let glow = CALayer()
    private let caption = CATextLayer()
    private var pile: [CALayer] = []
    private let soundPlayer = SoundPlayer()
    private struct MovingFragment {
        let layer: CALayer
        let anchor: CGPoint
        let transform: CATransform3D
        var motion: PaperMotion
    }
    private var movingFragments: [ObjectIdentifier: MovingFragment] = [:]
    private var motionTimer: Timer?
    private var previousOrigin: CGPoint?
    private var previousMoveTime: TimeInterval = 0
    private var previousVelocity = CGPoint.zero
    private var motionTime: TimeInterval = 0
    private var rustleTime: TimeInterval = 0
    private var dragOrigin: CGPoint?
    private var dragPointer = CGPoint.zero
    private var hovered = false
    private var dragActive = false
    private var messageVersion = 0
    private var currentMessage: (key: L10n.Key, arguments: [CVarArg])?
    private var mute: Bool {
        get { UserDefaults.standard.bool(forKey: "muted") }
        set { UserDefaults.standard.set(newValue, forKey: "muted") }
    }
    private var reducedMotion: Bool { NSWorkspace.shared.accessibilityDisplayShouldReduceMotion }

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
        NotificationCenter.default.addObserver(self, selector: #selector(updateLocalizedText), name: L10n.didChange, object: nil)
        updateLocalizedText()
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
        feeder.frame = CGRect(x: 40, y: MachineArtwork.slotY, width: 160, height: MachineArtwork.size.height - MachineArtwork.slotY)
        feeder.masksToBounds = true; machine.addSublayer(feeder)
        scraps.frame = MachineArtwork.window; scraps.cornerRadius = 10; scraps.masksToBounds = true; machine.addSublayer(scraps)
        let glass = CALayer(); glass.frame = bounds; glass.contents = MachineArtwork.image(glass: true); machine.addSublayer(glass)
        glow.frame = CGRect(x: 50, y: MachineArtwork.inlet.minY - 1, width: 140, height: 0.65); glow.cornerRadius = 0.325
        glow.backgroundColor = MachineArtwork.color(0xDCEBFF).cgColor; glow.opacity = 0
        glow.shadowColor = MachineArtwork.color(0xBFD9FF).cgColor; glow.shadowRadius = 2; glow.shadowOpacity = 0.35; machine.addSublayer(glow)
        shutter.frame = MachineArtwork.inlet
        shutter.contents = MachineArtwork.shutter(); machine.addSublayer(shutter)
        counter.frame = MachineArtwork.counterFrame
        machine.addSublayer(counter)
        powerSwitch.target = self; powerSwitch.action = #selector(togglePower)
        powerSwitch.appearance = NSAppearance(named: .aqua)
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
    }
    override func mouseExited(with event: NSEvent) {
        hovered = false
        if state == .idle { caption.opacity = 0 }
    }
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func mouseDown(with event: NSEvent) {
        dragOrigin = window?.frame.origin
        dragPointer = window?.convertPoint(toScreen: event.locationInWindow) ?? .zero
        previousOrigin = dragOrigin
        previousMoveTime = ProcessInfo.processInfo.systemUptime
        previousVelocity = .zero
    }
    override func mouseDragged(with event: NSEvent) {
        guard let dragOrigin, let window else { return }
        let pointer = window.convertPoint(toScreen: event.locationInWindow)
        let origin = CGPoint(x: dragOrigin.x + pointer.x - dragPointer.x,
                             y: dragOrigin.y + pointer.y - dragPointer.y)
        window.setFrameOrigin(origin)
        machineMoved(to: window.frame.origin)
    }
    override func mouseUp(with event: NSEvent) {
        guard dragOrigin != nil else { return }
        dragOrigin = nil
        // Stopping the enclosure gives the loose paper one final inertial impulse.
        let stopEnergy = exp(-max(0, ProcessInfo.processInfo.systemUptime - previousMoveTime) * 16)
        kickPaper(CGPoint(x: previousVelocity.x * 0.1 * stopEnergy, y: previousVelocity.y * 0.07 * stopEnergy))
        previousVelocity = .zero
        previousOrigin = nil
        (window as? RevoPanel)?.savePosition()
    }

    deinit {
        motionTimer?.invalidate()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
    }

    private func machineMoved(to origin: CGPoint) {
        let now = ProcessInfo.processInfo.systemUptime
        defer { previousOrigin = origin; previousMoveTime = now }
        guard let previousOrigin else { return }
        let dt = max(1.0 / 120, min(0.1, now - previousMoveTime))
        let delta = CGPoint(x: origin.x - previousOrigin.x, y: origin.y - previousOrigin.y)
        let velocity = CGPoint(x: max(-1800, min(1800, delta.x / dt)),
                               y: max(-1800, min(1800, delta.y / dt)))
        let impulse = CGPoint(x: (previousVelocity.x - velocity.x) * 0.11 - delta.x * 0.32,
                              y: (previousVelocity.y - velocity.y) * 0.08 - delta.y * 0.22)
        previousVelocity = velocity
        kickPaper(impulse)
    }

    /// The documentation renderer uses the same inertia as a desktop drag, without moving a window.
    func previewMovement(to origin: CGPoint) {
        machineMoved(to: origin)
    }

    private func kickPaper(_ impulse: CGPoint) {
        guard !reducedMotion, !pile.isEmpty, hypot(impulse.x, impulse.y) > 0.3 else { return }
        for (index, fragment) in pile.enumerated() where fragment.animation(forKey: "cut") == nil {
            let id = ObjectIdentifier(fragment)
            if movingFragments[id] == nil {
                movingFragments[id] = MovingFragment(layer: fragment, anchor: fragment.position,
                    transform: fragment.transform, motion: PaperMotion(variation: 0.65 + CGFloat((index * 17) % 23) / 24))
            }
            movingFragments[id]?.motion.impulse(impulse)
        }
        guard !movingFragments.isEmpty, motionTimer == nil else { return }
        motionTime = ProcessInfo.processInfo.systemUptime
        let timer = Timer(timeInterval: 1.0 / 60, repeats: true) { [weak self] _ in self?.stepPaperMotion() }
        timer.tolerance = 0.002
        motionTimer = timer
        // Keep fragment integration responsive during mouse tracking and open menus.
        RunLoop.main.add(timer, forMode: .common)
    }

    private func stepPaperMotion() {
        let now = ProcessInfo.processInfo.systemUptime
        let dt = CGFloat(max(1.0 / 240, min(1.0 / 30, now - motionTime)))
        motionTime = now
        let live = Set(pile.map(ObjectIdentifier.init))
        var active = false
        var intensity: CGFloat = 0
        var pan: CGFloat = 0
        CATransaction.begin(); CATransaction.setDisableActions(true)
        for id in Array(movingFragments.keys) {
            guard var fragment = movingFragments[id], live.contains(id), !reducedMotion else {
                if let fragment = movingFragments.removeValue(forKey: id) {
                    fragment.layer.position = fragment.anchor; fragment.layer.transform = fragment.transform
                }
                continue
            }
            let halfWidth = max(8, fragment.layer.bounds.width / 2)
            let range = (halfWidth - fragment.anchor.x)...(scraps.bounds.width - halfWidth - fragment.anchor.x)
            fragment.motion.step(dt, horizontalRange: range)
            fragment.layer.position = CGPoint(x: fragment.anchor.x + fragment.motion.offset.x,
                                               y: fragment.anchor.y + fragment.motion.offset.y)
            let tilt = CATransform3DMakeRotation(fragment.motion.angle, 0, 0, 1)
            let lift = CATransform3DMakeScale(1, 1 + min(1.1, fragment.motion.offset.y / 25), 1)
            fragment.layer.transform = CATransform3DConcat(fragment.transform, CATransform3DConcat(tilt, lift))
            active = active || !fragment.motion.isSettled
            intensity += fragment.motion.intensity
            pan += fragment.motion.velocity.x
            movingFragments[id] = fragment
        }
        CATransaction.commit()
        if now - rustleTime > 0.065 || !active {
            rustleTime = now
            let count = CGFloat(max(1, movingFragments.count))
            let amount = min(1, intensity / count * min(1, count / 12))
            soundPlayer.rustle(intensity: mute || !active ? 0 : Float(amount),
                               pan: Float(max(-0.4, min(0.4, pan / count / 250))))
        }
        if !active {
            motionTimer?.invalidate(); motionTimer = nil
            movingFragments.removeAll()
        }
    }

    @objc private func updateTransparency() {
        let reduce = NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        // A light native diffusion sits under the clear meniscus and edge reflections.
        backdrop.alphaValue = reduce ? 1 : 0.22
        backdrop.layer?.backgroundColor = reduce ? MachineArtwork.color(0xE6EBF1).cgColor : NSColor.clear.cgColor
    }

    @objc private func togglePower() {
        let enabled = !isPoweredOn
        setPower(enabled)
        play(enabled ? .switchOn : .switchOff, volume: 0.45)
    }

    func setPower(_ enabled: Bool) {
        queue.setPower(enabled)
        dragActive = false
        if state == .ready {
            setState(.idle)
            spring(machine, key: "transform.translation.y", from: 3, to: 0)
        }
        updatePowerPresentation()
        if state == .idle { hideMessage() }
    }

    private func updatePowerPresentation() {
        powerSwitch.setPower(isPoweredOn, animated: !reducedMotion)
        updateCounter()
        toolTip = L10n.text(isPoweredOn ? .onHelp : .offHelp)
        CATransaction.begin(); CATransaction.setAnimationDuration(reducedMotion ? 0 : 0.22)
        shutter.opacity = isPoweredOn ? 0 : 1
        shutter.transform = CATransform3DMakeScale(1, isPoweredOn ? 0.08 : 1, 1)
        glow.opacity = isPoweredOn && state != .idle ? 1 : 0
        CATransaction.commit()
    }

    private func updateCounter() {
        CATransaction.begin(); CATransaction.setDisableActions(true)
        counter.contents = MachineArtwork.counter(count: Stats.todayCount, powered: isPoweredOn)
        CATransaction.commit()
        powerSwitch.toolTip = L10n.text(.powerCount, Stats.todayCount)
        powerSwitch.setAccessibilityHelp(L10n.text(.powerHelp, Stats.todayCount))
    }

    private func spring(_ target: CALayer, key: String, from: CGFloat, to: CGFloat) {
        CATransaction.begin(); CATransaction.setDisableActions(true); target.setValue(to, forKeyPath: key); CATransaction.commit()
        guard !reducedMotion else { return }
        let animation = CASpringAnimation(keyPath: key); animation.fromValue = from; animation.toValue = to
        animation.mass = 0.7; animation.stiffness = 260; animation.damping = 22; animation.duration = animation.settlingDuration
        target.add(animation, forKey: key)
    }
    @objc private func updateLocalizedText() {
        setAccessibilityHelp(L10n.text(.bodyHelp))
        powerSwitch.setAccessibilityLabel(L10n.text(.power))
        toolTip = L10n.text(isPoweredOn ? .onHelp : .offHelp)
        updateCounter()
        if let currentMessage { caption.string = L10n.text(currentMessage.key, arguments: currentMessage.arguments) }
    }

    private func showMessage(_ key: L10n.Key, _ arguments: CVarArg..., persistent: Bool = false) {
        messageVersion += 1; let version = messageVersion
        currentMessage = (key, arguments)
        caption.string = L10n.text(key, arguments: arguments); caption.opacity = 1
        if !persistent {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self, self.messageVersion == version, self.state == .idle else { return }
                self.caption.opacity = 0
            }
        }
    }
    private func hideMessage() {
        messageVersion += 1
        currentMessage = nil
        caption.string = nil
        caption.opacity = 0
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
            showMessage(.turnOnBeforeDrop)
            return []
        }
        let operation = dragOperation(sender); guard !operation.isEmpty else { return [] }
        dragActive = true
        if state != .working { setState(.ready); spring(machine, key: "transform.translation.y", from: 0, to: 3) }
        hideMessage()
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
        queue.append(contentsOf: [Job(url: URL(fileURLWithPath: "/demo-paper.txt"), style: style, point: CGPoint(x: 120, y: MachineArtwork.slotY + 54), demo: true)])
        next()
    }
    private func next() {
        guard state != .working, let job = queue.takeNext() else { return }
        setState(.working)
        spring(machine, key: "transform.translation.y", from: 3, to: 0)
        hideMessage()
        // Build the preview before recycling, while the original still exists.
        let sprite = PaperSprite.make(for: job.url, style: job.style)
        if job.demo { animate(job, image: sprite); return }
        trash.recycle(job.url) { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                Stats.increment(); self.updateCounter(); self.animate(job, image: sprite)
            case .failure(let error):
                self.setState(.idle)
                self.showMessage(.recycleFailed)
                self.toolTip = error.localizedDescription
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in self?.next() }
            }
        }
    }

    private func animate(_ job: Job, image: CGImage?) {
        guard let image else { finish(job); return }
        let timing = PaperFeed.Timing(style: job.style, reducedMotion: reducedMotion)
        let count = job.style == .folder ? 3 : 1
        for index in 0..<count {
            let dx = CGFloat(index) * 3
            let margin = MachineArtwork.paperWidth / 2 + 4
            let sourceX = max(margin, min(feeder.bounds.width - margin - dx, job.point.x - feeder.frame.minX))
            let sheet = PaperFeed.sheet(image: image, sourceX: sourceX + dx, targetX: 80 + dx,
                                         index: index, timing: timing, reducedMotion: reducedMotion)
            feeder.addSublayer(sheet)
            DispatchQueue.main.asyncAfter(deadline: .now() + timing.duration + Double(index) * timing.stagger) {
                sheet.removeFromSuperlayer()
            }
        }
        if !reducedMotion {
            DispatchQueue.main.asyncAfter(deadline: .now() + timing.approach) { [weak self] in
                self?.play(.grip, volume: 0.24)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + timing.lead) { [weak self] in
                guard let self else { return }
                let vibration = CAKeyframeAnimation(keyPath: "transform.translation.x")
                vibration.values = [0, 0.18, -0.18, 0.1, 0]; vibration.duration = 0.18; vibration.repeatCount = .infinity
                self.machine.add(vibration, forKey: "motor")
                self.play(.motor, volume: 0.14)
            }
        }
        emit(image, style: job.style, duration: timing.pull, delay: timing.lead + 0.12)
        let stackDelay = Double(count - 1) * timing.stagger
        DispatchQueue.main.asyncAfter(deadline: .now() + timing.duration + stackDelay + 0.6) { [weak self] in self?.finish(job) }
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
                strip.bounds = CGRect(x: 0, y: 0, width: MachineArtwork.paperWidth / CGFloat(columns) - 1, height: height)
                let x = (scraps.bounds.width - MachineArtwork.paperWidth) / 2 + (CGFloat(col) + 0.5) * MachineArtwork.paperWidth / CGFloat(columns)
                let start = CGPoint(x: x, y: scraps.bounds.height + height / 2)
                let pileHeight = min(6, CGFloat(pile.count) * 0.07)
                let landingX = scraps.frame.minX + x + CGFloat.random(in: -19...19)
                let floor = MachineArtwork.floorPoint(horizontal: (landingX - 31) / 178, depth: CGFloat.random(in: 0.08...0.55))
                let end = CGPoint(x: floor.x - scraps.frame.minX, y: floor.y - scraps.frame.minY + pileHeight + 3)
                strip.position = end
                strip.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat.random(in: -0.9...0.9)).scaledBy(x: 1, y: 0.35))
                scraps.addSublayer(strip); pile.append(strip)
                let fall = CAKeyframeAnimation(keyPath: "position")
                fall.values = [NSValue(point: start), NSValue(point: CGPoint(x: (x + end.x) / 2, y: (start.y + end.y) / 2)), NSValue(point: end)]
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
        soundPlayer.stopAll()
        play(.finish, volume: 0.12)
        setState(.idle)
        if !reducedMotion { spring(machine, key: "transform.translation.y", from: -1.2, to: 0) }
        hideMessage()
        if !queue.isEmpty { next() }
        else if dragActive && isPoweredOn { setState(.ready) }
    }
    private func play(_ effect: SoundPlayer.Effect, volume: Float) {
        guard !mute else { return }
        soundPlayer.play(effect, volume: volume)
    }

    override func menu(for event: NSEvent) -> NSMenu? { makeMenu() }
    func makeMenu() -> NSMenu {
        let menu = NSMenu(); menu.autoenablesItems = false
        func item(_ title: String, _ action: Selector, enabled: Bool = true) -> NSMenuItem {
            let item = NSMenuItem(title: title, action: action, keyEquivalent: ""); item.target = self; item.isEnabled = enabled; menu.addItem(item); return item
        }
        let power = item(L10n.text(isPoweredOn ? .turnOff : .turnOn), #selector(togglePower))
        power.state = isPoweredOn ? .on : .off
        menu.addItem(.separator())
        let count = NSMenuItem(title: L10n.text(.recycledToday, Stats.todayCount), action: nil, keyEquivalent: ""); count.isEnabled = false; menu.addItem(count)
        menu.addItem(.separator())
        _ = item(L10n.text(.undo), #selector(undo), enabled: trash.canUndo && state != .working)
        _ = item(L10n.text(.openTrash), #selector(openTrash))
        let demos = NSMenuItem(title: L10n.text(.tryIt), action: nil, keyEquivalent: ""); let submenu = NSMenu()
        for (index, key) in [L10n.Key.demoDocument, .demoPhoto, .demoAudio, .demoVideo, .demoFolder].enumerated() {
            let option = NSMenuItem(title: L10n.text(key), action: #selector(demoMenu(_:)), keyEquivalent: ""); option.tag = index; option.target = self; submenu.addItem(option)
        }
        demos.submenu = submenu; demos.isEnabled = isPoweredOn && state != .working; menu.addItem(demos)
        _ = item(L10n.text(.clearScraps), #selector(clearScraps), enabled: state != .working)
        menu.addItem(.separator())
        let sound = item(L10n.text(.sound), #selector(toggleSound)); sound.state = mute ? .off : .on
        let language = NSMenuItem(title: L10n.text(.language), action: nil, keyEquivalent: "")
        let languages = NSMenu()
        for (index, choice) in AppLanguage.allCases.enumerated() {
            let option = NSMenuItem(title: choice.displayName, action: #selector(changeLanguage(_:)), keyEquivalent: "")
            option.target = self; option.tag = index
            option.state = L10n.language == choice ? .on : .off
            languages.addItem(option)
        }
        language.submenu = languages; menu.addItem(language)
        _ = item(L10n.text(.shortcutTitle), #selector(configureShortcut))
        _ = item(L10n.text(.hide), #selector(hidePanel))
        _ = item(L10n.text(.quit), #selector(quit))
        Self.fitMenu(menu)
        return menu
    }

    /// Leave room for the full localized title, checkmarks, and submenu arrows.
    static func fitMenu(_ menu: NSMenu) {
        let font = NSFont.menuFont(ofSize: 0)
        let longest = menu.items.filter { !$0.isSeparatorItem }.map {
            ($0.title as NSString).size(withAttributes: [.font: font]).width
        }.max() ?? 0
        menu.minimumWidth = ceil(longest + 64)
        for item in menu.items {
            if let submenu = item.submenu { fitMenu(submenu) }
        }
    }

    @objc private func configureShortcut() { (NSApp.delegate as? AppDelegate)?.showShortcutSettings() }
    @objc private func changeLanguage(_ sender: NSMenuItem) {
        guard AppLanguage.allCases.indices.contains(sender.tag) else { return }
        L10n.language = AppLanguage.allCases[sender.tag]
    }
    @objc private func demoMenu(_ sender: NSMenuItem) { demo([.document, .photo, .audio, .video, .folder][sender.tag]) }
    @objc private func toggleSound() { mute.toggle(); if mute { soundPlayer.stopAll() } }
    @objc private func clearScraps() {
        let old = pile; pile.removeAll()
        CATransaction.begin(); CATransaction.setAnimationDuration(reducedMotion ? 0 : 0.3)
        CATransaction.setCompletionBlock { old.forEach { $0.removeFromSuperlayer() } }
        old.forEach { $0.opacity = 0; $0.position.y -= 12 }; CATransaction.commit()
        showMessage(.scrapsCleared)
    }
    @objc private func undo() {
        guard state != .working, trash.canUndo else { return }
        setState(.working); showMessage(.restoring, persistent: true)
        trash.undo { [weak self] result in
            guard let self else { return }; self.setState(.idle)
            switch result {
            case .success: Stats.decrement(); self.updateCounter(); self.showMessage(.restored)
            case .failure(let error): self.showMessage(.restoreFailed); self.toolTip = error.localizedDescription
            }
            self.next()
        }
    }
    @objc private func openTrash() { NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent(".Trash")) }
    @objc private func hidePanel() { window?.orderOut(nil) }
    @objc private func quit() { NSApp.terminate(nil) }
}
