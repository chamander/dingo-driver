
import Foundation

final class ConnectionListDiskPersistence: ConnectionListPersistence {

    private let fileManager: FileManager

    private let baseURL: URL!
    private var basePath: String { return self.baseURL.path }

    private let fileURL: URL!
    private var filePath: String { return self.fileURL.path }

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.baseURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        self.fileURL = self.baseURL
            .appendingPathComponent("connections")
            .appendingPathExtension("json")
    }

    func saveConnection(_ connection: Connection, completion: (() -> Void)? = nil) {

        if !self.fileManager.fileExists(atPath: self.filePath) {
            self.fileManager.createFile(atPath: self.filePath, contents: nil, attributes: nil)
        }

        let decoder = JSONDecoder()
        let data: Data! = try? Data(contentsOf: self.fileURL)

        var connectionsToPersist: [Connection]

        if let persistedConnections = try? decoder.decode(Array<Connection>.self, from: data) {
            connectionsToPersist = persistedConnections
            connectionsToPersist.append(connection)
        } else {
            connectionsToPersist = [connection]
        }

        let encoder = JSONEncoder()
        if let dataToPersist = try? encoder.encode(connectionsToPersist) {
            try? dataToPersist.write(to: self.fileURL)
        }

        completion?()
    }
}

final class ConnectionListDiskProvider: ConnectionListProvider {

    private let fileManager: FileManager

    private let baseURL: URL!
    private var basePath: String { return self.baseURL.path }

    private let fileURL: URL!
    private var filePath: String { return self.fileURL.path }

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.baseURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first
        self.fileURL = self.baseURL
            .appendingPathComponent("connections")
            .appendingPathExtension("json")
    }

    func withConnectionList(perform handler: @escaping ([Connection]) -> Void) {

        guard self.fileManager.fileExists(atPath: self.filePath) else {
            handler(Array())
            return
        }

        let decoder = JSONDecoder()
        let data: Data! = try? Data(contentsOf: self.fileURL)

        if let persistedConnections = try? decoder.decode(Array<Connection>.self, from: data) {
            handler(persistedConnections)
        } else {
            handler(Array())
        }
    }
}
