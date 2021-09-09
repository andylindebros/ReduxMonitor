import Foundation

#if DEBUG

public struct AnyEncodable: Encodable {
    public var value: Encodable
    public init(_ value: Encodable) {
        self.value = value
    }

    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

struct Handshake: Codable {
    var event: String = "#handshake"
    var data: [String: String]
    var cid: Int
}

struct Login: Codable {
    var event: String = "login"
    var data = "master"
}

public struct ActionFromMonitor: Decodable {
    public var event: String
    public var data: MonitorAction
    public var cid: Int?
}

public struct MonitorAction: Decodable {
    public var type: MonitorActionType
    public var instanceId: Int?

    enum CodingKeys: String, CodingKey {
        case type
        case action
        case state
        case instanceId
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MonitorActionTypeIdentifier.self, forKey: .type)

        switch type {
        case .jumpToState:
            let action = try container.decode([String: Any].self, forKey: .action)
            let state = try container.decode(String.self, forKey: .state)
            self.type = MonitorActionType.jumpToState(action: action, state: state)

        case .action:
            let actionString = try container.decode(String.self, forKey: .action)
            self.type = MonitorActionType.action(action: actionString)
        }
    }
}

enum MonitorActionTypeIdentifier: String, Decodable {
    case jumpToState = "DISPATCH"
    case action = "ACTION"
}

public enum MonitorActionType {
    case jumpToState(action: [String: Any], state: String)
    case action(action: String)
}

final class AtomicInteger {
    private let lock = DispatchSemaphore(value: 1)
    private var _value: Int

    public init(value initialValue: Int = 0) {
        _value = initialValue
    }

    public var value: Int {
        get {
            lock.wait()
            defer { lock.signal() }
            return _value
        }
        set {
            lock.wait()
            defer { lock.signal() }
            _value = newValue
        }
    }

    public func decrementAndGet() -> Int {
        lock.wait()
        defer { lock.signal() }
        _value -= 1
        return _value
    }

    public func incrementAndGet() -> Int {
        lock.wait()
        defer { lock.signal() }
        _value += 1
        return _value
    }
}

struct EmitObject: Encodable {
    public init(cid: Int = 0, monitorEvent: MonitorEvent) {
        self.cid = cid
        data = monitorEvent
    }

    public var event: String = "log"
    public var cid: Int
    public var data: MonitorEvent
}

struct MonitorEvent: Encodable {
    public init(action: ActionObject, payload: AnyEncodable, id: String, type: String = "ACTION") {
        self.action = action
        self.payload = payload
        self.id = id
        self.type = type
    }

    public var action: ActionObject
    public var payload: AnyEncodable
    public var id: String
    public var type: String
}

struct ActionObject: Encodable {
    public init(action: AnyEncodable, timeStamp: TimeInterval = Date().timeIntervalSinceReferenceDate) {
        self.action = ReduxAction(action: action)
        self.timeStamp = timeStamp
    }

    public var action: ReduxAction
    public var timeStamp = Date().timeIntervalSinceReferenceDate
}

struct ReduxAction: Encodable {
    public init(action: AnyEncodable) {
        self.action = action
    }

    public var action: AnyEncodable
    public var type: String { "\(action.value.self)" }

    enum CodingKeys: String, CodingKey {
        case type, action
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(action, forKey: .action)
        try container.encode(type, forKey: .type)
    }
}

struct SessionRaw: Codable {
    var rid: Int
    var data: SessionModel
}

struct SessionModel: Codable {
    var id: String
    var isAuthenticated: Bool
    var pingTimeout: Int
}

#endif
