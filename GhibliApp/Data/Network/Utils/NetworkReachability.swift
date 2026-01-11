import Foundation
import Network

public protocol NetworkReachability: Sendable {
	func isReachable() async -> Bool
}

public actor NetworkReachabilityAdapter: NetworkReachability {
	private let monitor: NWPathMonitor
	private let queue: DispatchQueue
	private var status: NWPath.Status

	public init(
		monitor: NWPathMonitor = NWPathMonitor(),
		queue: DispatchQueue = DispatchQueue(label: "NetworkReachabilityMonitor")
	) {
		self.monitor = monitor
		self.queue = queue
		self.status = monitor.currentPath.status

		monitor.pathUpdateHandler = { [weak self] path in
			Task.detached(priority: .utility) { [weak self] in
				guard !Task.isCancelled, let self else { return }
				await self.updateStatus(path.status)
			}
		}
		monitor.start(queue: queue)
	}

	deinit {
		monitor.cancel()
	}

	public func isReachable() async -> Bool {
		status == .satisfied
	}

	private func updateStatus(_ status: NWPath.Status) {
		self.status = status
	}
}
