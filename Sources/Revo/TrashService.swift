import AppKit

/// The animation never decides whether a file operation succeeded.
final class TrashService {
    struct Receipt { let original: URL; let trashed: URL }
    private(set) var lastReceipt: Receipt?
    private var restoring = false
    var canUndo: Bool { lastReceipt != nil && !restoring }

    func recycle(_ url: URL, completion: @escaping (Result<Receipt, Error>) -> Void) {
        NSWorkspace.shared.recycle([url]) { mapping, error in
            DispatchQueue.main.async {
                if let error { completion(.failure(error)); return }
                guard let destination = mapping[url] else {
                    completion(.failure(NSError(domain: "Revo", code: 1, userInfo: [NSLocalizedDescriptionKey: "macOS did not return the location of the recycled file."])))
                    return
                }
                let receipt = Receipt(original: url, trashed: destination)
                self.lastReceipt = receipt
                completion(.success(receipt))
            }
        }
    }

    func undo(completion: @escaping (Result<URL, Error>) -> Void) {
        guard let receipt = lastReceipt, !restoring else { return }
        restoring = true
        DispatchQueue.global(qos: .userInitiated).async {
            let result = Result { () -> URL in
                // moveItem refuses to overwrite a file that now occupies the original path.
                try FileManager.default.moveItem(at: receipt.trashed, to: receipt.original)
                return receipt.original
            }
            DispatchQueue.main.async {
                self.restoring = false
                if case .success = result { self.lastReceipt = nil }
                completion(result)
            }
        }
    }
}
