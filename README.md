# ReduxMonitor
*Monitors the state and actions of your Swift Redux Project*

ReduxMonitor is a monitoring tool that communicates with `redux-dev-tools`.  Use it to monitor your Redux State in your app. It's easy to integrate with just a few lines of code.

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
import ReSwift
import ReduxMonitor
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
            monitor.connect()
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
            store.dispatch(SomeAction(payload: randomStrings.filter{ $0 != state.name }.randomElement()!))
        }) {
            Text("Hello \(state.name)!")
        }
    }
}

```
## Monitor your state
Make sure your state object and actions conforms to `Encodable`

``` Swift
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
```
You should now be able to monitor your state and actions on [http://localhost:8000](http://localhost:8000)
