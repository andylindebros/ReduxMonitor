# ReduxMonitor for your ReSwift project

ReduxMonitor offers monitoring your [ReSwift](https://github.com/ReSwift/ReSwift) actions and state together with `redux-dev-tools`

![Demo](https://github.com/lindebrothers/ReduxMonitor/blob/main/Example/ReduxMonitorDemo.gif)

## Dependencies
Start and run [remotedev-server docker](https://github.com/jhen0409/docker-remotedev-server) image :
```
docker run -d -p 8000:8000 jhen0409/remotedev-server
```

## Implementation
Add ReduxMonitor middleware
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
        let store = Store<AppState>(reducer: AppState.reducer, state: initState, middleware: [
            MonitorMiddleware.create(monitor: ReduxMonitor())
        ])

        return store
    }
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
You should now be able to see your monitor your state on [http://localhost:8000](http://localhost:8000)
