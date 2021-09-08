import Foundation

#if DEBUG

class SendActionOperation: Operation {
    let action: AnyEncodable
    let state: AnyEncodable

    let client: ReduxMonitor

    init(action: AnyEncodable, state: AnyEncodable, client: ReduxMonitor) {
        self.action = action
        self.state = state
        self.client = client
    }

    override func main() {
        client.send(action: action, state: state)
    }
}

#endif
