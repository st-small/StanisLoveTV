import Foundation

struct Endpoint {
    let url: URL
    var headers: [String: String]

    init(url: URL, headers: [String: String] = [:]) {
        self.url = url
        self.headers = headers
    }
}
