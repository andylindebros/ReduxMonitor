import Foundation
import ReSwift

public struct AnyEncodable: Encodable {
    public var value: Encodable
    init(_ value: Encodable) {
        self.value = value
    }

    public func encode(to encoder: Encoder) throws {
        try value.encode(to: encoder)
    }
}

public enum MonitorMiddleware {
    public static func create(monitor: ReduxMonitorProvider) -> Middleware<Any> {
        return { dispatch, state in
            monitor.connect()
            return { next in
                { action in
                    let newAction: Void = next(action)
                    let newState = state()
                    if let encodableAction = action as? Encodable, let encodableState = newState as? Encodable {
                        monitor.addTask(action: AnyEncodable(encodableAction), state: AnyEncodable(encodableState))
                    } else {
                        monitor.log("Could not monitor action because either state or action does not conform to encodable", action, .warning)
                    }
                    return newAction
                }
            }
        }
    }
}
