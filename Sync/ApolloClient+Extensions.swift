// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import Apollo


extension ApolloClient {
    public static func createDefault(accessTokenProvider: AccessTokenProvider) -> ApolloClient {
        let urlStringFromEnvironment = ProcessInfo.processInfo.environment["POCKET_CLIENT_API_URL"]
        let urlString = urlStringFromEnvironment ?? "https://getpocket.com/graphql"
        let url = URL(string: urlString)!

        let store = ApolloStore()
        return ApolloClient(
            networkTransport: RequestChainNetworkTransport(
                interceptorProvider: PrependingInterceptorProvider(
                    prepend: AuthParamsInterceptor(tokenProvider: accessTokenProvider),
                    base: LegacyInterceptorProvider(store: store)
                ),
                endpointURL: url
            ),
            store: store
        )
    }
}

public protocol AccessTokenProvider {
    var accessToken: String? { get }
    var consumerKey: String { get }
}

private class AuthParamsInterceptor: ApolloInterceptor {
    private let tokenProvider: AccessTokenProvider

    init(tokenProvider: AccessTokenProvider) {
        self.tokenProvider = tokenProvider
    }

    func interceptAsync<Operation>(
        chain: RequestChain,
        request: HTTPRequest<Operation>,
        response: HTTPResponse<Operation>?,
        completion: @escaping (Result<GraphQLResult<Operation.Data>, Error>) -> Void
    ) where Operation : GraphQLOperation {
        request.graphQLEndpoint = appendAuthorizationQueryParameters(to: request.graphQLEndpoint)
        chain.proceedAsync(request: request, response: response, completion: completion)
    }

    private func appendAuthorizationQueryParameters(to url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        var items = components.queryItems ?? []
        items.append(contentsOf: [
            URLQueryItem(name: "consumer_key", value: tokenProvider.consumerKey),
            URLQueryItem(name: "access_token", value: tokenProvider.accessToken),
        ])
        components.queryItems = items

        return components.url ?? url
    }
}

private class PrependingInterceptorProvider: InterceptorProvider {
    private let prepend: ApolloInterceptor
    private let base: InterceptorProvider

    init(
        prepend: ApolloInterceptor,
        base: InterceptorProvider
    ) {
        self.prepend = prepend
        self.base = base
    }

    func interceptors<Operation>(for operation: Operation) -> [ApolloInterceptor] where Operation : GraphQLOperation {
        let base = base.interceptors(for: operation)
        return [prepend] + base
    }
}