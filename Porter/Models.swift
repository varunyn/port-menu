import Foundation

// MARK: - Port Model

struct ActivePort: Identifiable, Equatable, Hashable, Sendable {
    let id: String
    let port: UInt16
    let pid: Int32
    let projectName: String
    let branch: String
    let startTime: Date?
    /// True when this port is published by a container runtime (Docker/OrbStack).
    /// Used to distinguish container services from local git projects in the UI.
    let isContainer: Bool
    let imageName: String
    let cpuUsage: String
    let memoryUsage: String

    var url: URL {
        URL(string: "http://localhost:\(port)")!
    }

    init(port: UInt16, pid: Int32, projectName: String, branch: String, startTime: Date?, isContainer: Bool = false, imageName: String = "", cpuUsage: String = "", memoryUsage: String = "") {
        self.id = "\(port)-\(pid)"
        self.port = port
        self.pid = pid
        self.projectName = projectName
        self.branch = branch
        self.startTime = startTime
        self.isContainer = isContainer
        self.imageName = imageName
        self.cpuUsage = cpuUsage
        self.memoryUsage = memoryUsage
    }
}

enum PortSortOption: String, CaseIterable, Sendable {
    case port
    case cpu
    case memory
    case started

    var title: String {
        switch self {
        case .port: return "Port"
        case .cpu: return "CPU usage"
        case .memory: return "Memory usage"
        case .started: return "Started"
        }
    }

    func sorted(_ entries: [ActivePort]) -> [ActivePort] {
        entries.sorted { lhs, rhs in
            let result: Bool
            switch self {
            case .port:
                result = lhs.port < rhs.port
            case .cpu:
                result = cpuValue(lhs.cpuUsage) > cpuValue(rhs.cpuUsage)
            case .memory:
                result = memoryValue(lhs.memoryUsage) > memoryValue(rhs.memoryUsage)
            case .started:
                result = (lhs.startTime ?? .distantPast) > (rhs.startTime ?? .distantPast)
            }

            if result { return true }
            if self == .port {
                return lhs.port == rhs.port && lhs.id < rhs.id
            }
            return lhs.port < rhs.port
        }
    }

    private func cpuValue(_ value: String) -> Double {
        Double(value.replacingOccurrences(of: "%", with: "")) ?? 0
    }

    private func memoryValue(_ value: String) -> Double {
        guard let token = value.split(separator: " ").first else { return 0 }
        let amount = Double(token.prefix { $0.isNumber || $0 == "." }) ?? 0
        let unit = String(token.drop { $0.isNumber || $0 == "." }).lowercased()
        let multiplier: Double
        switch unit {
        case "b": multiplier = 1
        case "kb": multiplier = 1_000
        case "kib": multiplier = 1_024
        case "mb": multiplier = 1_000_000
        case "mib": multiplier = 1_048_576
        case "gb": multiplier = 1_000_000_000
        case "gib": multiplier = 1_073_741_824
        case "tb": multiplier = 1_000_000_000_000
        case "tib": multiplier = 1_099_511_627_776
        default: multiplier = 1
        }
        return amount * multiplier
    }
}

// MARK: - Scan Result

enum ScanResult: Sendable {
    case success([ActivePort], ScanDiagnostics)
    case failure(ScanError, [ActivePort])
}

struct ScanDiagnostics: Sendable {
    let duration: TimeInterval
    let portsFound: Int
    let dataSource: String
    let timestamp: Date

    var summary: String {
        let ms = (duration * 1000).formatted(.number.precision(.fractionLength(1)))
        let time = timestamp.formatted(date: .omitted, time: .standard)
        return "Scan: \(ms)ms | \(portsFound) ports | source: \(dataSource) | \(time)"
    }
}

enum ScanError: Error, Sendable, LocalizedError {
    case lsofFailed(String)
    case lsofTimeout

    var errorDescription: String? {
        switch self {
        case .lsofFailed(let msg): return "Port scan failed: \(msg)"
        case .lsofTimeout: return "Port scan timed out"
        }
    }
}

// MARK: - Refresh Interval

enum RefreshInterval: Double, CaseIterable, Sendable {
    case fast = 2
    case normal = 5
    case relaxed = 10
    case slow = 30

    static let defaultInterval: RefreshInterval = .normal
}
