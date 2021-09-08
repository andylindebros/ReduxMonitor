import Foundation
import ReSwift

struct Handshake: Codable {
    var event: String = "#handshake"
    var data: [String: String]
    var cid: Int
}

public final class AtomicInteger {
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

public struct EmitObject: Encodable {
    public init(cid: Int = 0, monitorEvent: MonitorEvent) {
        self.cid = cid
        data = monitorEvent
    }

    public var event: String = "log"
    public var cid: Int
    public var data: MonitorEvent
}

public struct MonitorEvent: Encodable {
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

public struct ActionObject: Encodable {
    public init(action: AnyEncodable, timeStamp: TimeInterval = Date().timeIntervalSinceReferenceDate) {
        self.action = ReduxAction(action: action)
        self.timeStamp = timeStamp
    }

    public var action: ReduxAction
    public var timeStamp = Date().timeIntervalSinceReferenceDate
}

public struct ReduxAction: Encodable {
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
