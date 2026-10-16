import AppKit
import Carbon

enum SelfTest {
    private static func checkShortcuts() {
        let firstName = "Revo-shortcut-check-" + UUID().uuidString
        let secondName = "Revo-shortcut-check-" + UUID().uuidString
        let firstDefaults = UserDefaults(suiteName: firstName)!
        let secondDefaults = UserDefaults(suiteName: secondName)!
        defer {
            firstDefaults.removePersistentDomain(forName: firstName)
            secondDefaults.removePersistentDomain(forName: secondName)
        }
        let first = GlobalShortcut(defaults: firstDefaults)
        let candidate = KeyboardShortcut(keyCode: UInt32(kVK_F19), modifiers: UInt32(controlKey | optionKey | shiftKey))
        precondition(first.configure(candidate, enabled: true))
        let second = GlobalShortcut(defaults: secondDefaults)
        let old = second.shortcut, registered = second.isRegistered
        precondition(!second.configure(candidate, enabled: true), "A conflicting shortcut was accepted")
        precondition(second.shortcut == old && second.isRegistered == registered, "Conflict replaced the previous binding")
        first.suspend(); precondition(!first.isRegistered)
        precondition(first.resume() && first.isRegistered)
        precondition(first.configure(candidate, enabled: false) && !first.isRegistered)
        let restored = GlobalShortcut(defaults: firstDefaults)
        precondition(restored.shortcut == candidate && !restored.isEnabled && !restored.isRegistered)
        precondition(first.configure(nil, enabled: false))
        let cleared = GlobalShortcut(defaults: firstDefaults)
        precondition(cleared.shortcut == nil && !cleared.isEnabled)
        precondition(!KeyboardShortcut(keyCode: 15, modifiers: UInt32(shiftKey)).isValid)
        print("PASS: global shortcut conflicts, preserved binding, suspension, persistence, and clearing")
    }

    static func run() {
        checkShortcuts()
        // Compare gentle movement with a sharp shake, then verify bounded settling.
        func excursion(_ force: CGFloat) -> (height: CGFloat, travel: CGFloat, spin: CGFloat) {
            var paper = PaperMotion(variation: 1)
            paper.impulse(CGPoint(x: force, y: 0))
            var height: CGFloat = 0, travel: CGFloat = 0, spin: CGFloat = 0
            for _ in 0..<600 {
                paper.step(1.0 / 120, horizontalRange: -30...30)
                height = max(height, paper.offset.y)
                travel = max(travel, abs(paper.offset.x))
                spin = max(spin, abs(paper.angle))
            }
            precondition(paper.isSettled, "Paper did not settle after movement stopped")
            return (height, travel, spin)
        }
        let gentle = excursion(18), strong = excursion(180)
        precondition(strong.height > gentle.height * 2 && strong.travel > gentle.travel * 2)
        precondition(strong.spin > gentle.spin * 2)
        var shaken = PaperMotion(variation: 1.4)
        for tick in 0..<480 {
            if tick % 6 == 0 { shaken.impulse(CGPoint(x: tick % 12 == 0 ? 900 : -900, y: 500)) }
            shaken.step(1.0 / 120, horizontalRange: -22...22)
            precondition((-22...22).contains(shaken.offset.x) && (0...62).contains(shaken.offset.y))
            precondition(shaken.angle.isFinite && shaken.intensity.isFinite)
        }
        for _ in 0..<960 { shaken.step(1.0 / 120, horizontalRange: -22...22) }
        precondition(shaken.isSettled)
        print("PASS: shake strength response, fragment bounds, and natural settling")
        var gate = PowerQueue<Int>()
        precondition(!gate.isPoweredOn)
        precondition(!gate.append(contentsOf: [1]))
        precondition(gate.takeNext() == nil)
        gate.setPower(true)
        precondition(gate.append(contentsOf: [1, 2, 3]))
        precondition(gate.takeNext() == 1)
        gate.setPower(false)
        precondition(gate.isEmpty && gate.takeNext() == nil)
        precondition(!gate.append(contentsOf: [4]))
        gate.setPower(true)
        precondition(gate.takeNext() == nil)
        precondition(gate.append(contentsOf: [5]))
        precondition(gate.takeNext() == 5)
        precondition(!PowerQueue<Int>().isPoweredOn)
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("Revo-check-" + UUID().uuidString)
        let file = root.appendingPathComponent("sample.txt")
        let trash = TrashService()
        func fail(_ error: Error) { fputs("FAIL: \(error)\n", stderr); exit(1) }
        do {
            try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
            try Data("Revo verification fixture".utf8).write(to: file)
            let view = RevoView(frame: CGRect(origin: .zero, size: MachineArtwork.size))
            precondition(!view.isPoweredOn)
            precondition(!view.acceptFiles([file], at: CGPoint(x: 120, y: 192)))
            precondition(FileManager.default.fileExists(atPath: file.path))
            view.setPower(true)
            view.setPower(false)
            precondition(!view.acceptFiles([file], at: CGPoint(x: 120, y: 192)))
            precondition(FileManager.default.fileExists(atPath: file.path))
            precondition(ShredStyle.classify(file) == .document)
            precondition(ShredStyle.classify(root) == .folder)
            precondition(ShredStyle.classify(root.appendingPathComponent("test.png")) == .photo)
            precondition(ShredStyle.classify(root.appendingPathComponent("test.wav")) == .audio)
            precondition(ShredStyle.classify(root.appendingPathComponent("test.mov")) == .video)
        } catch { fail(error); return }
        trash.recycle(file) { result in
            switch result {
            case .failure(let error): fail(error)
            case .success(let receipt):
                precondition(!FileManager.default.fileExists(atPath: file.path))
                precondition(FileManager.default.fileExists(atPath: receipt.trashed.path))
                // Verify a conflicting new file is never overwritten by undo.
                do { try Data("new file".utf8).write(to: file) } catch { fail(error); return }
                trash.undo { conflict in
                    guard case .failure = conflict else { fatalError("Undo overwrote a conflicting file") }
                    precondition(trash.canUndo)
                    do { let content = try String(contentsOf: file); precondition(content == "new file"); try FileManager.default.removeItem(at: file) } catch { fail(error); return }
                    trash.undo { restored in
                        switch restored {
                        case .failure(let error): fail(error)
                        case .success:
                            do {
                                let content = try String(contentsOf: file); precondition(content == "Revo verification fixture")
                                precondition(!trash.canUndo)
                                try FileManager.default.removeItem(at: root)
                            } catch { fail(error); return }
                            trash.recycle(file) { missing in
                                guard case .failure = missing else { fatalError("Missing source reported success") }
                                print("PASS: default-off interlock, rejected drops, queue cancellation, classification, recycle, conflict protection, undo, and missing-file failure")
                                NSApp.terminate(nil)
                            }
                        }
                    }
                }
            }
        }
    }
}
