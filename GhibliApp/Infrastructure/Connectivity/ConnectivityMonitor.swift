import Foundation
import Network

final class ConnectivityMonitor: ConnectivityRepository {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "dev.ghibliapp.connectivity")
    private let continuationLock = NSLock()
    private var continuation: AsyncStream<Bool>.Continuation?

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.continuation?.yield(path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
        continuation?.finish()
    }

    var connectivityStream: AsyncStream<Bool> {
        AsyncStream { continuation in
            continuationLock.lock()
            self.continuation = continuation
            continuationLock.unlock()
        }
    }
}
