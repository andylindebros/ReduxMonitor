import Foundation
import Logger
import ReSwift

public protocol ReduxMonitorProvider {
    var url: URL? { get }
    var logger: LoggerProvider? { get }
    func connect()
    func log(_ message: String, _ obj: Any, _ level: LogLevel)
    func addTask(action: AnyEncodable, state: AnyEncodable)
}

public class ReduxMonitor: NSObject, ReduxMonitorProvider {
    public private(set) var url: URL?
    public private(set) var logger: LoggerProvider?

    private var socketId: String?
    private var urlSession: URLSession!
    private var websocketTask: URLSessionWebSocketTask!
    private var counter = AtomicInteger(value: 0)
    private var queue: OperationQueue

    public init(url: URL? = URL(string: "ws://0.0.0.0:8000/socketcluster/?transport=websocket"), logger: LoggerProvider? = nil) {
        self.url = url
        self.logger = logger

        queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .default
        queue.isSuspended = true

        super.init()
        guard let url = url else {
            fatalError()
        }

        let session = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())

        websocketTask = session.webSocketTask(with: url)
    }
}

// MARK: Public methods

public extension ReduxMonitor {
    func connect() {
        listen()
        websocketTask.resume()
    }

    func log(_ message: String, _ obj: Any = "", _ level: LogLevel = .debug) {
        logger?.publish(message: "🔌 \(message)", obj: obj, level: level)
    }

    func addTask(action: AnyEncodable, state: AnyEncodable) {
        queue.addOperation(
            SendActionOperation(action: action, state: state, client: self)
        )
    }
}

// MARK: Internal methods

extension ReduxMonitor {
    func send(action: AnyEncodable, state: AnyEncodable) {
        send(createEmitObject(action: action, state: state))
    }
}

// MARK: Private methods

extension ReduxMonitor {
    private func send<Model: Encodable>(_ model: Model) {
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(model)
            sendString(String(data: jsonData, encoding: .utf8))
        } catch let e {
            log("Failed to send with error", e.localizedDescription, .error)
        }
    }

    private func sendString(_ str: String?) {
        guard let str = str else { return }

        let textMessage = URLSessionWebSocketTask.Message.string(str)

        websocketTask.send(textMessage) { [weak self] error in
            if let error = error {
                self?.log("Could not send string with error", error.localizedDescription, .error)
            }
        }
    }

    private func createEmitObject(action: AnyEncodable, state: AnyEncodable) -> EmitObject {
        let monitorEvent = MonitorEvent(action: ActionObject(action: action), payload: state, id: socketId ?? "add later")

        return EmitObject(monitorEvent: monitorEvent)
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
                        self.sendString("#2")
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
            queue.isSuspended = false
        } catch {}
    }

    private func cancel() {
        socketId = nil
        websocketTask.cancel(with: .goingAway, reason: nil)
        queue.isSuspended = true
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

    public func log(_ message: String, _ obj: Any, _ level: LogLevel) {}

    public func addTask(action: AnyEncodable, state: AnyEncodable) {}
}

struct Empty: Codable {}
#endif