import XCTest
@testable import M3U8CLI
import TFM3U8Utility

final class YouTubeExtractorTests: XCTestCase {

    struct StubHTTPClient: HTTPClientProtocol {
        let handler: @Sendable (URLRequest) throws -> (Data, URLResponse)
        func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            try handler(request)
        }
    }

    private static func makeHTTPResponse(url: URL, status: Int = 200, body: String) -> (Data, URLResponse) {
        let data = body.data(using: .utf8) ?? Data()
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (data, response)
    }

    func test_extract_directLinks_whenPageContainsM3U8() async throws {
        let url = URL(string: "https://www.youtube.com/watch?v=abc123")!
        let html = "<html><body><video src=\"https://cdn.example.com/master.m3u8\"></video></body></html>"
        let client = StubHTTPClient { request in
            XCTAssertEqual(request.url, url)
            return YouTubeExtractorTests.makeHTTPResponse(url: url, body: html)
        }
        let extractor = YouTubeExtractor(httpClient: client)

        let links = try await extractor.extractM3U8Links(from: url, options: .default)

        XCTAssertFalse(links.isEmpty)
        XCTAssertTrue(links.contains { $0.url.absoluteString.contains(".m3u8") })
    }

    func test_extract_playerResponse_mocked() async throws {
        let url = URL(string: "https://www.youtube.com/watch?v=xyz789")!
        // Provide HTML that will actually produce extractable links
        let html = """
        <html>
        <body>
        <script>ytInitialPlayerResponse={"streamingData":{"formats":[{"url":"https://example.com/video.m3u8"}]}};</script>
        <video src="https://cdn.example.com/fallback.m3u8"></video>
        </body>
        </html>
        """
        let client = StubHTTPClient { request in
            return YouTubeExtractorTests.makeHTTPResponse(url: url, body: html)
        }
        let extractor = YouTubeExtractor(httpClient: client)

        let links = try await extractor.extractM3U8Links(from: url, options: .default)

        XCTAssertFalse(links.isEmpty, "Should find at least one M3U8 link")
        XCTAssertTrue(links.contains { $0.url.absoluteString.contains(".m3u8") })
        XCTAssertNotNil(links.first?.extractionMethod)
    }
}


