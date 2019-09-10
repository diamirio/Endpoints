import Foundation

public class FakeHTTPURLResponse: HTTPURLResponse {
    public init(status code: Int = 200, header: Parameters? = nil) {
        super.init(url: URL(string: "http://127.0.0.1")!, statusCode: code, httpVersion: nil, headerFields: header)!
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
