import Foundation

public enum IPAInspectionError: Error, LocalizedError, Equatable {
    case fileMissing
    case wrongExtension
    case invalidZip
    case unsupportedZipFormat
    case missingAppBundle
    case directoryTooLarge

    public var errorDescription: String? {
        switch self {
        case .fileMissing: return "The selected IPA file is unavailable. Choose it again from Files."
        case .wrongExtension: return "Choose an .ipa file, not a ZIP or another document."
        case .invalidZip: return "This file isn't a valid IPA archive."
        case .unsupportedZipFormat: return "This IPA uses a ZIP format this inspector can't validate."
        case .missingAppBundle: return "The IPA doesn't contain Payload/<App>.app/Info.plist."
        case .directoryTooLarge: return "The IPA's package index is unexpectedly large."
        }
    }
}

public struct IPAInspection: Sendable, Equatable {
    public let fileName: String
    public let fileSize: UInt64
    public let appBundleName: String
}

public enum IPAInspector {
    // Parses ZIP metadata without extracting or loading the entire IPA into memory.
    // This checks that an app bundle is present; it does NOT establish trust, signature validity,
    // provisioning compatibility, or safety of imported code.
    public static func inspect(_ url: URL) throws -> IPAInspection {
        guard url.pathExtension.lowercased() == "ipa" else { throw IPAInspectionError.wrongExtension }
        guard FileManager.default.fileExists(atPath: url.path) else { throw IPAInspectionError.fileMissing }

        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let length = try handle.seekToEnd()
        guard length >= 22 else { throw IPAInspectionError.invalidZip }

        let tailLength = Int(min(length, 65_557)) // 22-byte EOCD + 65,535-byte comment
        try handle.seek(toOffset: length - UInt64(tailLength))
        let tail = try handle.read(upToCount: tailLength) ?? Data()
        guard tail.count == tailLength else { throw IPAInspectionError.invalidZip }
        // Find final End-of-Central-Directory; signature may also occur in ZIP comments.
        let bytes = [UInt8](tail)
        var eocd: Int? = nil
        for idx in stride(from: bytes.count - 22, through: 0, by: -1) {
            guard le32(bytes, idx) == 0x06054b50 else { continue }
            let commentLength = Int(le16(bytes, idx + 20))
            if idx + 22 + commentLength == bytes.count { eocd = idx; break }
        }
        guard let index = eocd else { throw IPAInspectionError.invalidZip }

        let disk = le16(bytes, index + 4)
        let centralDisk = le16(bytes, index + 6)
        let entryCount = le16(bytes, index + 10)
        let cdSize = UInt64(le32(bytes, index + 12))
        let cdOffset = UInt64(le32(bytes, index + 16))
        guard disk == 0, centralDisk == 0,
              entryCount != UInt16.max, cdSize != UInt64(UInt32.max),
              cdOffset != UInt64(UInt32.max) else {
            throw IPAInspectionError.unsupportedZipFormat // ZIP64 or multi-disk
        }
        guard cdSize <= 64 * 1024 * 1024 else { throw IPAInspectionError.directoryTooLarge }
        guard cdOffset <= length, cdSize <= length - cdOffset else { throw IPAInspectionError.invalidZip }
        try handle.seek(toOffset: cdOffset)
        let dirData = try handle.read(upToCount: Int(cdSize)) ?? Data()
        guard dirData.count == Int(cdSize) else { throw IPAInspectionError.invalidZip }
        let dir = [UInt8](dirData)
        var cursor = 0
        var candidates: [String] = []
        for _ in 0..<entryCount {
            guard cursor + 46 <= dir.count, le32(dir, cursor) == 0x02014b50 else {
                throw IPAInspectionError.invalidZip
            }
            let nameLen = Int(le16(dir, cursor + 28))
            let extraLen = Int(le16(dir, cursor + 30))
            let commentLen = Int(le16(dir, cursor + 32))
            let end = cursor + 46 + nameLen + extraLen + commentLen
            guard end <= dir.count else { throw IPAInspectionError.invalidZip }
            let name = String(decoding: dir[(cursor + 46)..<(cursor + 46 + nameLen)], as: UTF8.self)
            let parts = name.split(separator: "/", omittingEmptySubsequences: false)
            if parts.count == 3,
               parts[0] == "Payload", parts[1].hasSuffix(".app"), parts[2] == "Info.plist" {
                candidates.append(String(parts[1]))
            }
            cursor = end
        }
        guard cursor == dir.count else { throw IPAInspectionError.invalidZip }
        guard let app = candidates.first else { throw IPAInspectionError.missingAppBundle }
        return IPAInspection(fileName: url.lastPathComponent, fileSize: length, appBundleName: app)
    }

    private static func le16(_ data: [UInt8], _ i: Int) -> UInt16 {
        UInt16(data[i]) | UInt16(data[i + 1]) << 8
    }
    private static func le32(_ data: [UInt8], _ i: Int) -> UInt32 {
        UInt32(data[i]) | UInt32(data[i + 1]) << 8 | UInt32(data[i + 2]) << 16 | UInt32(data[i + 3]) << 24
    }
}