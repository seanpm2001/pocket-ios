// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Foundation
import Apollo
@testable import Sync

class MockApolloClient: ApolloClientProtocol {
    var store: ApolloStore {
        fatalError("\(Self.self).\(#function) is not implemented")
    }
    
    var cacheKeyForObject: CacheKeyForObject? {
        get { fatalError("\(Self.self).\(#function) is not implemented") }
        set { fatalError("\(Self.self).\(#function) is not implemented") }
    }

    struct FetchCall<Query: GraphQLQuery> {
        let query: Query
        let cachePolicy: CachePolicy
        let contextIdentifier: UUID?
        let queue: DispatchQueue
    }

    typealias FetchImpl<Query: GraphQLQuery> = (
        Query,
        CachePolicy,
        UUID?,
        DispatchQueue,
        GraphQLResultHandler<Query.Data>?
    ) -> Cancellable

    var fetchCalls: [Any] = []
    var fetchImpl: Any?
    @discardableResult
    func fetch<Query: GraphQLQuery>(
        query: Query,
        cachePolicy: CachePolicy,
        contextIdentifier: UUID?,
        queue: DispatchQueue,
        resultHandler: GraphQLResultHandler<Query.Data>? = nil
    ) -> Cancellable {
        let call = FetchCall(
            query: query,
            cachePolicy: cachePolicy,
            contextIdentifier: contextIdentifier,
            queue: queue
        )
        fetchCalls.append(call)

        guard let anyImpl = fetchImpl else {
            fatalError("\(Self.self).\(#function) has not been stubbed")
        }

        guard let impl = anyImpl as? FetchImpl<Query> else {
            fatalError("Stub implementation for \(Self.self).\(#function) is incorrect type")
        }

        return impl(query, cachePolicy, contextIdentifier, queue, resultHandler)

//        if query is UserByTokenQuery,
//           let resultHandler = resultHandler as? GraphQLResultHandler<UserByTokenQuery.Data> {
//            let url = Bundle(for: Self.self).url(forResource: "list", withExtension: "json")!
//            let jsonData = try! Data(contentsOf: url)
//            let json = (try! JSONSerialization.jsonObject(with: jsonData, options: []) as! [String: Any])["data"] as! [String: Any]
//            let data = try! UserByTokenQuery.Data(jsonObject: json)
//            let result = GraphQLResult(data: data, extensions: nil, errors: nil, source: .cache, dependentKeys: nil)
//            resultHandler(.success(result))
//        }
//
//        return MockCancellable()
    }

    func stubFetch<Query: GraphQLQuery>(impl: @escaping FetchImpl<Query>) {
        fetchImpl = impl
    }

    func fetchCall<Query: GraphQLQuery>(at index: Int) -> FetchCall<Query> {
        let anyCall = fetchCalls[index]

        guard let call = anyCall as? MockApolloClient.FetchCall<Query> else {
            fatalError("Call is incorrect type: \(anyCall)")
        }

        return call
    }
    
    @discardableResult
    func watch<Query: GraphQLQuery>(
        query: Query,
        cachePolicy: CachePolicy,
        callbackQueue: DispatchQueue,
        resultHandler: @escaping GraphQLResultHandler<Query.Data>
    ) -> GraphQLQueryWatcher<Query> {
        fatalError("\(Self.self).\(#function) is not implemented")
    }
    
    @discardableResult
    func perform<Mutation: GraphQLMutation>(
        mutation: Mutation,
        publishResultToStore: Bool,
        queue: DispatchQueue,
        resultHandler: GraphQLResultHandler<Mutation.Data>?
    ) -> Cancellable {
        fatalError("\(Self.self).\(#function) is not implemented")
    }
    
    @discardableResult
    func upload<Operation: GraphQLOperation>(
        operation: Operation,
        files: [GraphQLFile],
        queue: DispatchQueue,
        resultHandler: GraphQLResultHandler<Operation.Data>?
    ) -> Cancellable {
        fatalError("\(Self.self).\(#function) is not implemented")
    }
    
    @discardableResult
    func subscribe<Subscription: GraphQLSubscription>(
        subscription: Subscription,
        queue: DispatchQueue,
        resultHandler: @escaping GraphQLResultHandler<Subscription.Data>
    ) -> Cancellable {
        fatalError("\(Self.self).\(#function) is not implemented")
    }

    func clearCache(callbackQueue: DispatchQueue, completion: ((Result<Void, Error>) -> Void)?) {
        fatalError("\(Self.self).\(#function) is not implemented")
    }
}