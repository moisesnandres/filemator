import Foundation

final class FolderWatcher {
    private let folderURL: URL
    private let ignoredExtensions: Set<String>
    private let debounceInterval: TimeInterval
    private let onNewFile: (URL) -> Void

    private var fileDescriptor: CInt = -1
    private var source: DispatchSourceFileSystemObject?
    private var knownFiles: Set<String> = []
    private var debounceWorkItems: [String: DispatchWorkItem] = [:]

    init(
        folderURL: URL,
        ignoredExtensions: Set<String> = ["crdownload", "download", "part", "tmp"],
        debounceInterval: TimeInterval = 0.3,
        onNewFile: @escaping (URL) -> Void
    ) {
        self.folderURL = folderURL
        self.ignoredExtensions = ignoredExtensions
        self.debounceInterval = debounceInterval
        self.onNewFile = onNewFile
    }

    func start() {
        knownFiles = Set(currentFilenames())

        fileDescriptor = open(folderURL.path, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let fd = fileDescriptor
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: .write,
            queue: DispatchQueue.global(qos: .utility)
        )
        source.setEventHandler { [weak self] in
            self?.handleDirectoryChange()
        }
        source.setCancelHandler {
            close(fd)
        }
        source.resume()
        self.source = source
    }

    func stop() {
        source?.cancel()
        source = nil
        debounceWorkItems.values.forEach { $0.cancel() }
        debounceWorkItems.removeAll()
    }

    private func currentFilenames() -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: folderURL.path)) ?? []
    }

    private func handleDirectoryChange() {
        let current = Set(currentFilenames())
        let added = current.subtracting(knownFiles)
        knownFiles = current

        for filename in added {
            scheduleEvaluation(of: filename)
        }
    }

    private func scheduleEvaluation(of filename: String) {
        debounceWorkItems[filename]?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.evaluate(filename: filename)
        }
        debounceWorkItems[filename] = workItem
        DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }

    private func evaluate(filename: String) {
        let fileURL = folderURL.appendingPathComponent(filename)
        let ext = fileURL.pathExtension.lowercased()

        guard !ignoredExtensions.contains(ext) else { return }
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        onNewFile(fileURL)
    }
}
