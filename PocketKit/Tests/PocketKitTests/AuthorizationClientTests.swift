// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/.

import XCTest
@testable import PocketKit


class AuthorizationServiceTests: XCTestCase {
    var session: MockURLSession!
    var client: AuthorizationClient!

    override func setUp() {
        session = MockURLSession()
        client = AuthorizationClient(consumerKey: "the-consumer-key", session: session)

    }
}

// MARK: - Authorize
extension AuthorizationServiceTests {
    func test_authorize_sendsPostRequestWithCorrectParameters() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            return (Data(), .ok!)
        }

        _ = try? await authorize()
        let calls = self.session.dataTaskCalls
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls[0].request.url?.path, "/v3/oauth/authorize")
        XCTAssertEqual(calls[0].request.httpMethod, "POST")
        XCTAssertEqual(calls[0].request.value(forHTTPHeaderField: "X-Accept"), "application/json")
        XCTAssertEqual(calls[0].request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let body = try! decoder.decode(
            AuthorizeRequest.self,
            from: calls[0].request.httpBody!
        )

        XCTAssertEqual(body, AuthorizeRequest(
            guid: "sample-guid",
            username: "test@example.com",
            password: "super-secret-password",
            consumerKey: "the-consumer-key",
            grantType: "credentials",
            account: true
        ))
    }

    func test_authorize_whenServerRespondsWith200_invokesCompletionWithAccessToken() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "1.1",
                headerFields: ["X-Source": "Pocket"]
            )!

            let responseBody = """
            {
                "access_token":"the-access-token",
                "username":"test@example.com",
                "account": {
                    "first_name":"test",
                    "last_name":"user",
                    "user_id": "<the-user-id>"
                }
            }
            """.data(using: .utf8)!

            return (responseBody, response)
        }

        do {
            let response = try await authorize()
            XCTAssertEqual(response.accessToken, "the-access-token")
            XCTAssertEqual(response.account.userID, "<the-user-id>")
        } catch {
            XCTFail("authorize() should not throw an error in this context: \(error)")
        }
    }

    func test_authorize_when200AndDataIsEmpty_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "1.1",
                headerFields: ["X-Source": "Pocket"]
            )!

            return (Data(), response)
        }

        do {
            _ = try await authorize()
        } catch {
            guard case AuthorizationClient.Error.invalidResponse = error else {
                XCTFail("Unexpected error: \(error). Expected an invalid response")
                return
            }
        }
    }

    func test_authorize_when200AndResponseDoesNotContainAccessToken_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "1.1",
                headerFields: ["X-Source": "Pocket"]
            )!

            return (Data(), response)
        }

        do {
            _ = try await authorize()
        } catch {
            guard case AuthorizationClient.Error.invalidResponse = error else {
                XCTFail("Unexpected error: \(error). Expected an invalid response")
                return
            }
        }
    }

    func test_authorize_whenStatusIs300_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(url: request.url, statusCode: 300)!
            return (Data(), response)
        }

        do {
            _ = try await authorize()
        } catch {
            guard case AuthorizationClient.Error.unexpectedRedirect = error else {
                XCTFail("Unexpected error: \(error). Expected an unexpected redirect")
                return
            }
        }
    }

    func test_authorize_whenErrorIsNotNil_invokesCompletionWithError() async {
        session.stubData { _ throws -> (Data, URLResponse) in
            throw ExampleError.anError
        }
        
        do {
            _ = try await authorize()
        } catch {
            guard case AuthorizationClient.Error.generic(let internalError) = error else {
                XCTFail("Unexpected error: \(error). Expected a generic error")
                return
            }
            
            XCTAssertEqual(internalError as? ExampleError, ExampleError.anError)
        }
    }

    func test_authorize_whenStatusIs400_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(url: request.url, statusCode: 400)!
            return (Data(), response)
        }
        
        do {
            _ = try await authorize()
        } catch {
            guard case AuthorizationClient.Error.badRequest = error else {
                XCTFail("Unexpected error: \(error). Expected a bad request")
                return
            }
        }
    }

    func test_authorize_whenStatusIs401_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(url: request.url, statusCode: 401)!
            return (Data(), response)
        }

        do {
            _ = try await authorize()
        } catch {
            guard case AuthorizationClient.Error.invalidCredentials = error else {
                XCTFail("Unexpected error: \(error). Expected invalid credentials")
                return
            }
        }
    }

    func test_authorize_whenStatusIs500_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(url: request.url, statusCode: 500)!
            return (Data(), response)
        }

        do {
            _ = try await authorize()
        } catch {
            guard case AuthorizationClient.Error.serverError = error else {
                XCTFail("Unexpected error: \(error). Expected a server error")
                return
            }
        }
    }

    func test_authorize_whenStatusIs9001_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(url: request.url!, statusCode: 9001)!
            return (Data(), response)
        }

        do {
            _ = try await authorize()
        } catch {
            guard case AuthorizationClient.Error.unexpectedError = error else {
                XCTFail("Unexpected error: \(error). Expected an unexpected error")
                return
            }
        }
    }

    func test_authorize_whenSourceHeaderIsInvalid_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "1.1",
                headerFields: ["X-Source": "not-Pocket"]
            )!
            
            return (Data(), response)
        }

        do {
            _ = try await authorize()
        } catch {
            guard case AuthorizationClient.Error.invalidSource = error else {
                XCTFail("Unexpected error: \(error). Expected an invalid source")
                return
            }
        }
    }

    private func authorize() async throws -> AuthorizeResponse {
        return try await client.authorize(
            guid: "sample-guid",
            username: "test@example.com",
            password: "super-secret-password"
        )
    }
}

// MARK: - GUID
extension AuthorizationServiceTests {
    func test_guid_sendsGETRequestWithCorrectParameters() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let data = "sample-guid".data(using: .utf8)!
            return (data, .ok!)
        }

        _ = try? await client.requestGUID()
        let calls = self.session.dataTaskCalls
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls[0].request.url?.path, "/v3/guid")
        XCTAssertEqual(calls[0].request.httpMethod, "GET")
    }

    func test_guid_whenServerRespondsWith200_invokesCompletionWithGUID() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "1.1",
                headerFields: ["X-Source": "Pocket"]
            )!

            let responseBody = """
            {
                "guid": "sample-guid"
            }
            """.data(using: .utf8)!

            return (responseBody, response)
        }

        do {
            let guid = try await client.requestGUID()
            XCTAssertEqual(guid, "sample-guid")
        } catch {
            XCTFail("requestGUID() should not throw an error in this context: \(error)")
        }
    }

    func test_guid_when200AndDataIsEmpty_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "1.1",
                headerFields: ["X-Source": "Pocket"]
            )!

            return (Data(), response)
        }

        do {
            _ = try await client.requestGUID()
        } catch {
            guard case AuthorizationClient.Error.invalidResponse = error else {
                XCTFail("Unexpected error: \(error). Expected an invalid response")
                return
            }
        }
    }

    func test_guid_when200AndResponseDoesNotContainAccessToken_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "1.1",
                headerFields: ["X-Source": "Pocket"]
            )!

            return (Data(), response)
        }

        do {
            _ = try await client.requestGUID()
        } catch {
            guard case AuthorizationClient.Error.invalidResponse = error else {
                XCTFail("Unexpected error: \(error). Expected an invalid response")
                return
            }
        }
    }

    func test_guid_whenStatusIs300_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(url: request.url, statusCode: 300)!
            return (Data(), response)
        }

        do {
            _ = try await client.requestGUID()
        } catch {
            guard case AuthorizationClient.Error.unexpectedRedirect = error else {
                XCTFail("Unexpected error: \(error). Expected an unexpected redirect")
                return
            }
        }
    }

    func test_guid_whenErrorIsNotNil_invokesCompletionWithError() async {
        session.stubData { _ throws -> (Data, URLResponse) in
            throw ExampleError.anError
        }
        
        do {
            _ = try await client.requestGUID()
        } catch {
            guard case AuthorizationClient.Error.generic(let internalError) = error else {
                XCTFail("Unexpected error: \(error). Expected a generic error")
                return
            }
            
            XCTAssertEqual(internalError as? ExampleError, ExampleError.anError)
        }
    }

    func test_guid_whenStatusIs400_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(url: request.url, statusCode: 400)!
            return (Data(), response)
        }
        
        do {
            _ = try await client.requestGUID()
        } catch {
            guard case AuthorizationClient.Error.badRequest = error else {
                XCTFail("Unexpected error: \(error). Expected a bad request")
                return
            }
        }
    }

    func test_guid_whenStatusIs401_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(url: request.url, statusCode: 401)!
            return (Data(), response)
        }

        do {
            _ = try await client.requestGUID()
        } catch {
            guard case AuthorizationClient.Error.invalidCredentials = error else {
                XCTFail("Unexpected error: \(error). Expected invalid credentials")
                return
            }
        }
    }

    func test_guid_whenStatusIs500_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(url: request.url, statusCode: 500)!
            return (Data(), response)
        }

        do {
            _ = try await client.requestGUID()
        } catch {
            guard case AuthorizationClient.Error.serverError = error else {
                XCTFail("Unexpected error: \(error). Expected a server error")
                return
            }
        }
    }

    func test_guid_whenStatusIs9001_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(url: request.url!, statusCode: 9001)!
            return (Data(), response)
        }

        do {
            _ = try await client.requestGUID()
        } catch {
            guard case AuthorizationClient.Error.unexpectedError = error else {
                XCTFail("Unexpected error: \(error). Expected an unexpected error")
                return
            }
        }
    }

    func test_guid_whenSourceHeaderIsInvalid_invokesCompletionWithError() async {
        session.stubData { (request) throws -> (Data, URLResponse) in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: "1.1",
                headerFields: ["X-Source": "not-Pocket"]
            )!
            
            return (Data(), response)
        }

        do {
            _ = try await client.requestGUID()
        } catch {
            guard case AuthorizationClient.Error.invalidSource = error else {
                XCTFail("Unexpected error: \(error). Expected an invalid source")
                return
            }
        }
    }
}

extension HTTPURLResponse {
    convenience init?(url: URL?, statusCode: Int) {
        self.init(
            url: url ?? URL(string: "http://example.com")!,
            statusCode: statusCode,
            httpVersion: "1.1",
            headerFields: [:]
        )
    }
}

extension URLResponse {
    class var ok: HTTPURLResponse? {
        return HTTPURLResponse(url: nil, statusCode: 200)
    }
}

enum ExampleError: Error {
    case anError
}
