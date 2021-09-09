# ReduxMonitor
*Monitors the state and actions of your Swift Redux Project*

ReduxMonitor is a monitoring tool that communicates with `redux-dev-tools`.  Use it to monitor your Redux State in your app. It's easy to integrate with just a few lines of code.

ReduxMonitor Supports:
- action, diff and state logging
- `Jump to state` from monitor
- Dispatch from monitor

![Demo](https://github.com/lindebrothers/ReduxMonitor/blob/main/Example/ReduxMonitorDemo.gif)

## Dependencies
Start and run [remotedev-server docker](https://github.com/jhen0409/docker-remotedev-server) image :
```
docker run -d -p 8000:8000 jhen0409/remotedev-server
```

## Installation
Install ReduxMonitor using Swift Package Manager
```Swift
dependencies: [
    .package(url: "https://github.com/lindebrothers/ReduxMonitor", from: "1.0.0"),
]
```
## Implementation
Add ReduxMonitor middleware. This example below shows an implementation for a [ReSwift](https://github.com/ReSwift/ReSwift) app but you can use any Redux app you want.
``` Swift
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
            Text("Hello \(state.name)!")
        }
    }
}
```
## Monitor your state
Make sure your state object and actions conforms to `Encodable`. That's the protocol that is used to convert the data to json when sending it to remotedev-server. 

You should now be able to monitor your state and actions on [http://localhost:8000](http://localhost:8000)


## Test dispatching from the monitor
With the example code above you should be able to test the dispatch feature in the monitor. Click on the dispatch button at the bottom left and paste following test JSON representation of SomeAction:
```
{"type": "SomeAction", "payload": "Awesome"}
```



