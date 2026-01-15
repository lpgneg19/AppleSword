import Foundation

struct DownloadTask: Identifiable, Codable {
    var gid: String
    var status: TaskStatus
    var totalLength: Int64
    var completedLength: Int64
    var uploadLength: Int64
    var downloadSpeed: Int64
    var uploadSpeed: Int64
    var infoHash: String?
    var numSeeders: Int?
    var connections: Int
    var errorCode: String?
    var followedBy: String?
    var belongsTo: String?
    var dir: String
    var files: [DownloadFile]
    var bittorrent: BittorrentInfo?

    var id: String { gid }

    enum CodingKeys: String, CodingKey {
        case gid, status, totalLength, completedLength, uploadLength
        case downloadSpeed, uploadSpeed, infoHash, numSeeders, connections
        case errorCode, followedBy, belongsTo, dir, files, bittorrent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        gid = try container.decode(String.self, forKey: .gid)
        status = try container.decode(TaskStatus.self, forKey: .status)

        // Helper to decode string as Int64
        func decodeInt64(_ key: CodingKeys) -> Int64 {
            if let str = try? container.decode(String.self, forKey: key) {
                return Int64(str) ?? 0
            }
            return (try? container.decode(Int64.self, forKey: key)) ?? 0
        }

        func decodeInt(_ key: CodingKeys) -> Int {
            if let str = try? container.decode(String.self, forKey: key) {
                return Int(str) ?? 0
            }
            return (try? container.decode(Int.self, forKey: key)) ?? 0
        }

        totalLength = decodeInt64(.totalLength)
        completedLength = decodeInt64(.completedLength)
        uploadLength = decodeInt64(.uploadLength)
        downloadSpeed = decodeInt64(.downloadSpeed)
        uploadSpeed = decodeInt64(.uploadSpeed)
        connections = decodeInt(.connections)

        infoHash = try container.decodeIfPresent(String.self, forKey: .infoHash)
        numSeeders = try? container.decodeIfPresent(Int.self, forKey: .numSeeders)
        errorCode = try container.decodeIfPresent(String.self, forKey: .errorCode)
        followedBy = try container.decodeIfPresent(String.self, forKey: .followedBy)
        belongsTo = try container.decodeIfPresent(String.self, forKey: .belongsTo)
        dir = try container.decode(String.self, forKey: .dir)
        files = try container.decode([DownloadFile].self, forKey: .files)
        bittorrent = try container.decodeIfPresent(BittorrentInfo.self, forKey: .bittorrent)
    }

    enum TaskStatus: String, Codable {
        case active
        case waiting
        case paused
        case error
        case complete
        case removed
    }
}

struct DownloadFile: Codable {
    let index: String
    let path: String
    let length: Int64
    let completedLength: Int64
    let selected: String
    let uris: [DownloadURI]

    enum CodingKeys: String, CodingKey {
        case index, path, length, completedLength, selected, uris
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        index = try container.decode(String.self, forKey: .index)
        path = try container.decode(String.self, forKey: .path)
        selected = try container.decode(String.self, forKey: .selected)
        uris = try container.decode([DownloadURI].self, forKey: .uris)

        if let lengthStr = try? container.decode(String.self, forKey: .length) {
            length = Int64(lengthStr) ?? 0
        } else {
            length = try container.decode(Int64.self, forKey: .length)
        }

        if let compStr = try? container.decode(String.self, forKey: .completedLength) {
            completedLength = Int64(compStr) ?? 0
        } else {
            completedLength = try container.decode(Int64.self, forKey: .completedLength)
        }
    }
}

struct DownloadURI: Codable {
    let uri: String
    let status: String
}

struct BittorrentInfo: Codable {
    let announceList: [[String]]?
    let comment: String?
    let creationDate: Int64?
    let mode: String?
    let info: BittorrentDetail?
}

struct BittorrentDetail: Codable {
    let name: String?
}
