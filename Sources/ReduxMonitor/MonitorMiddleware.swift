import ReSwift
import Foundation

public struct AnyEncodable: Encodable {
    public var value: Encodable
      init(_ value: Encodable) {
        self.value = value
      }

    public func encode(to encoder: Encoder) throws {
        try self.value.encode(to: encoder)
    }
}

public struct MonitorMiddleware {
    public static func create(monitor: ReduxMonitorProvider) -> Middleware<Any> {
       
        return { dispatch, state in
            monitor.connect()
            return { next in
                { action in
                    
                    let newState = state()
                    if let encodableAction = action as? Encodable, let encodableState = newState as? Encodable {
                        monitor.sendAction(action: AnyEncodable(encodableAction), state: AnyEncodable(encodableState))
                    }else{
                        monitor.log("Could not monitor action because either state or action does not conform to encodable", action, .warning)
                    }
                    return next(action)
                }
            }
        }
    }
}
