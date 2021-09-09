import ReduxMonitor
import ReSwift
import SwiftUI

class AppState: ObservableObject, Codable {
    @Published fileprivate(set) var name = "Andy"

    init() {}
    required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
    }

    enum CodingKeys: CodingKey {
        case name
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }

    static func reducer(action: Action, state: AppState?) -> AppState {
        let state = state ?? AppState()
        switch action {
        case let a as SomeAction:
            state.name = a.payload
#if DEBUG
        case let a as SetState:
            state.name = a.payload.name
#endif
        default:
            break
        }
        return state
    }

    static func createStore(
        initState: AppState? = nil
    ) -> Store<AppState> {
        var middlewares = [Middleware<AppState>]()
#if DEBUG
        middlewares.append(AppState.createReduxMontitorMiddleware(monitor: ReduxMonitor()))
#endif
        let store = Store<AppState>(reducer: AppState.reducer, state: initState, middleware: middlewares)

        return store
    }

#if DEBUG
    private static func createReduxMontitorMiddleware(monitor: ReduxMonitorProvider) -> Middleware<Any> {
        return { dispatch, state in
            var monitor = monitor
            monitor.connect()

            monitor.monitorAction = { monitorAction in
                let decoder = JSONDecoder()
                switch monitorAction.type {
                case let .jumpToState(_, stateDataString):

                    guard
                        let stateData = stateDataString.data(using: .utf8),
                        let newState = try? decoder.decode(AppState.self, from: stateData)
                    else {
                        return
                    }

                    dispatch(SetState(payload: newState))

                case let .action(actionString):
                    guard
                        let actionRawData = actionString.data(using: .utf8)

                    else {
                        return print("Didn't work out")
                    }
                    do {
                        dispatch(try decoder.decode(SomeAction.self, from: actionRawData))
                    } catch let e {
                        return print("It didn't work out with error", e)
                    }
                }
            }
            return { next in
                { action in
                    let newAction: Void = next(action)
                    let newState = state()
                    if let encodableAction = action as? Encodable, let encodableState = newState as? Encodable {
                        monitor.publish(action: AnyEncodable(encodableAction), state: AnyEncodable(encodableState))
                    } else {
                        print("Could not monitor action because either state or action does not conform to encodable", action)
                    }
                    return newAction
                }
            }
        }
    }
#endif
}

extension ReSwiftInit: Encodable {
    enum CodingKeys: CodingKey {
        case name
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode("\(type(of: self))", forKey: .name)
    }
}

struct SomeAction: Action, Codable {
    var payload: String
}

struct SetState: Action {
    var payload: AppState
}

struct ContentView: View {
    let store: Store<AppState>

    init() {
        store = AppState.createStore()
    }

    var body: some View {
        HelloWorldView(state: store.state, dispatch: store.dispatch)
    }
}

struct HelloWorldView: View {
    @ObservedObject var state: AppState
    var dispatch: DispatchFunction
    var randomStrings = ["Andy", "Hanna", "Moa", "Peter", "Ruby", "Tom", "Marcus", "Simon", "Jenny", "Mary", "Zlatan"]
    var body: some View {
        Button(action: {
            dispatch(SomeAction(payload: randomStrings.filter { $0 != state.name }.randomElement()!))
        }) {
            Text("Hello \(state.name)!").font(.system(size: 40))
        }
    }
}
