import ReSwift
import ReduxMonitor
import SwiftUI
import Logger

class AppState: ObservableObject {
    @Published fileprivate(set) var name = "Some string"

    static func reducer(action: Action, state: AppState?) -> AppState {
        let state = state ?? AppState()
        switch action {
        case let a as SomeAction:
            state.name = a.payload
        default:
            break
        }
        return state
    }

    static func createStore(
        initState: AppState? = nil
    ) -> Store<AppState> {
        let store = Store<AppState>(reducer: AppState.reducer, state: initState, middleware: [
            MonitorMiddleware.create(monitor: ReduxMonitor(logger: Logger.shared))
        ])

        return store
    }
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

extension AppState: Encodable {
    enum CodingKeys: CodingKey {
        case name
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
    }
}

struct SomeAction: Action, Encodable {
    var payload: String
}

struct ContentView: View {
    let store: Store<AppState>
    @ObservedObject var state: AppState
    init() {
        store = AppState.createStore()
        state = store.state
    }
    
    var body: some View {
        Button(action: {
            store.dispatch(SomeAction(payload: "Awesome!"))
        }) {
            Text(state.name)
        }
    }
}

