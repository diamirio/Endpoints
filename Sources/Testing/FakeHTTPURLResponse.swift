import Foundation

public class FakeHTTPURLResponse: HTTPURLResponse {
    public init(
        status code: Int = 200,
        url: URL = URL(string: "http://127.0.0.1")!,
        httpVersion: String = "HTTP/1.1",
        header: Parameters? = nil) {
        super.init(
            url: url,
            statusCode: code,
            httpVersion: httpVersion,
            headerFields: header
        )!
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
