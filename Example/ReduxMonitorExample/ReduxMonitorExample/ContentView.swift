import Logger
import ReduxMonitor
import ReSwift
import SwiftUI

class AppState: ObservableObject {
    @Published fileprivate(set) var name = "Andy"

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
            MonitorMiddleware.create(monitor: ReduxMonitor(logger: Logger.shared)),
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

    var randomStrings = ["Andy", "Hanna", "Moa", "Peter", "Ruby", "Tom", "Marcus", "Simon", "Jenny", "Mary", "Zlatan"]
    var body: some View {
        Button(action: {
            store.dispatch(SomeAction(payload: randomStrings.filter { $0 != state.name }.randomElement()!))
        }) {
            Text("Hello \(state.name)!")
        }
    }
}
