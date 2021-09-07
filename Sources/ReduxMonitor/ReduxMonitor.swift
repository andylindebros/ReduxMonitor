import Foundation
import Logger
import ReSwift

public protocol ReduxMonitorProvider {
    var url: URL? { get }
    var logger: LoggerProvider? { get }
    func connect()
    func sendAction<S: Encodable>(action: AnyEncodable, state: S)

    func log(_ message: String, _ obj: Any, _ level: LogLevel)
}

public class ReduxMonitor: NSObject, ReduxMonitorProvider {
    public var url: URL?
    public var logger: LoggerProvider?

    private var urlSession: URLSession!
    private var websocketTask: URLSessionWebSocketTask!
    private(set) var socketId: String = ""
    private var counter = AtomicInteger(value: 0)
    public init(url: URL? = URL(string: "ws://0.0.0.0:8000/socketcluster/?transport=websocket"), logger: LoggerProvider? = nil) {
        self.url = url
        self.logger = logger

        super.init()
        guard let url = url else {
            fatalError()
        }

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())

        websocketTask = session.webSocketTask(with: url)
    }

    public func connect() {
        listen()
        websocketTask.resume()
    }

    public func log(_ message: String, _ obj: Any = "", _ level: LogLevel = .debug) {
        logger?.publish(message: "🔌 \(message)", obj: obj, level: level)
    }

    private func send<Model: Encodable>(_ model: Model) {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(model)
            sendString(String(data: jsonData, encoding: .utf8))
        } catch let e {
            log("Failed to send with error", e.localizedDescription, .error)
        }
    }

    private func sendString(_ str: String?, log: Bool = true) {
        guard let str = str else { return }

        let textMessage = URLSessionWebSocketTask.Message.string(str)

        websocketTask.send(textMessage) { [weak self] error in
            if let error = error {
                self?.log("Could not send string with error", error.localizedDescription, .error)
            }
        }
    }

    public func sendAction<S: Encodable>(action: AnyEncodable, state: S) {
        if socketId != "" {
            send(EmitObject(monitorEvent: MonitorEvent(action: ActionObject(action: action), payload: state, id: socketId)))
        }
    }

    private func listen() {
        websocketTask.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .failure(error):
                self.cancel()
                return self.log("receive message with error", error.localizedDescription, .error)

            case let .success(message):
                switch message {
                case let .string(text):
                    if text == "#1" {
                        self.sendString("#2", log: false)
                        return self.listen()
                    }

                    self.identifySession(from: text)

                case .data:
                    break
                default:
                    fatalError()
                }
            }
            self.listen()
        }
    }

    private func identifySession(from str: String) {
        guard let data = str.data(using: .utf8) else { return }
        do {
            let decoder = JSONDecoder()
            let session = try decoder.decode(SessionRaw.self, from: data)
            socketId = session.data.id

        } catch {}
    }

    private func cancel() {
        socketId = ""
        websocketTask.cancel(with: .goingAway, reason: nil)
    }
}

extension ReduxMonitor: URLSessionWebSocketDelegate {
    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        log("Redux monitor did connect")
        send(Handshake(data: [:], cid: counter.incrementAndGet()))
    }

    public func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        log("Redux monitor did disconnect")
    }
}

#if DEBUG
public struct ReduxMonitorMock: ReduxMonitorProvider {
    public var url: URL?

    public var logger: LoggerProvider?

    public func connect() {}

    public init() {}

    public func sendAction<S: Encodable>(action: AnyEncodable, state: S) {}

    public func log(_ message: String, _ obj: Any, _ level: LogLevel) {}
}
#endif
