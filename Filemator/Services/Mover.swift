import Foundation

enum MoverError: Error, LocalizedError {
    case underlying(Error)

    var errorDescription: String? {
        switch self {
        case .underlying(let error):
            return error.localizedDescription
        }
    }
}

enum Mover {
    static func move(from sourceURL: URL, toDirectory destinationDirectory: URL, fileManager: FileManager = .default) throws -> URL {
        if !fileManager.fileExists(atPath: destinationDirectory.path) {
            try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        }

        let destinationURL = uniqueDestinationURL(for: sourceURL, in: destinationDirectory, fileManager: fileManager)

        do {
            try fileManager.moveItem(at: sourceURL, to: destinationURL)
        } catch {
            throw MoverError.underlying(error)
        }

        return destinationURL
    }

    static func uniqueDestinationURL(for sourceURL: URL, in directory: URL, fileManager: FileManager = .default) -> URL {
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension

        var candidate = directory.appendingPathComponent(sourceURL.lastPathComponent)
        var counter = 2

        while fileManager.fileExists(atPath: candidate.path) {
            let candidateName = ext.isEmpty ? "\(baseName) (\(counter))" : "\(baseName) (\(counter)).\(ext)"
            candidate = directory.appendingPathComponent(candidateName)
            counter += 1
        }

        return candidate
    }
}
