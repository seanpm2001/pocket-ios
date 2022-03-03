import Combine


enum SyncOperationResult {
    case retry
    case success
    case failure(Error)
}

protocol SyncOperation {
    func execute() async -> SyncOperationResult
}

class RetriableOperation: AsyncOperation {
    typealias RetrySignal = AnyPublisher<Void, Never>

    enum Status {
        case failed
        case retry
        case success
    }

    private let operation: SyncOperation
    private let retrySignal: RetrySignal
    private var retries = 0
    private var subscription: AnyCancellable?

    init(
        retrySignal: RetrySignal,
        operation: SyncOperation
    ) {
        self.retrySignal = retrySignal
        self.operation = operation
    }

    override func main() {
        Task {
            switch await operation.execute() {
            case .retry:
                retry()
            case .failure(_):
                finishOperation()
            case .success:
                finishOperation()
            }
        }
    }

    private func retry() {
        subscription = retrySignal.sink { [weak self] in
            self?._retry()
        }
    }

    private func _retry() {
        guard retries < 2 else {
            finishOperation()
            return
        }

        retries += 1
        main()
    }
}