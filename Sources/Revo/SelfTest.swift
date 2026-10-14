import AppKit

enum SelfTest {
    static func run() {
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
