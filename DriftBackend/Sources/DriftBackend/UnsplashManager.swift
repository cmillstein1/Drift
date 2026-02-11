import Foundation

/// Fetches a header image URL from Unsplash for a given search query (e.g. event title).
/// Uses public Authentication: Client-ID access key.
/// See https://unsplash.com/documentation#search-photos
public enum UnsplashManager {
    private static let baseURL = "https://api.unsplash.com"
    private static let acceptVersion = "v1"

    /// Fetches the first search result image URL for the given query.
    /// - Parameters:
    ///   - query: Search term (e.g. event title).
    ///   - accessKey: Unsplash API Access Key (Client ID).
    /// - Returns: First photo's `regular` URL (1080px) suitable for headers, or nil if none.
    public static func fetchFirstImageURL(query: String, accessKey: String) async -> String? {
        let result = await fetchFirstImageWithAttribution(query: query, accessKey: accessKey)
        return result?.imageUrl
    }

    /// Fetches the first search result image URL and photographer attribution for the given query.
    /// - Parameters:
    ///   - query: Search term (e.g. event title).
    ///   - accessKey: Unsplash API Access Key (Client ID).
    /// - Returns: Image URL plus photographer name and Unsplash profile URL, or nil if none.
    public static func fetchFirstImageWithAttribution(query: String, accessKey: String) async -> (imageUrl: String, photographerName: String, photographerUrl: String)? {
        guard !accessKey.isEmpty, !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            #if DEBUG
            if !query.trimmingCharacters(in: .whitespaces).isEmpty {
            }
            #endif
            return nil
        }
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search/photos?query=\(encoded)&per_page=1") else {
            return nil
        }
        var request = URLRequest(url: url)
        request.setValue("Client-ID \(accessKey)", forHTTPHeaderField: "Authorization")
        request.setValue(acceptVersion, forHTTPHeaderField: "Accept-Version")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                return nil
            }
            guard (200...299).contains(http.statusCode) else {
                #if DEBUG
                let body = String(data: data, encoding: .utf8)
                #endif
                return nil
            }
            let decoded = try JSONDecoder().decode(UnsplashSearchResponse.self, from: data)
            guard let photo = decoded.results.first,
                  let imageUrl = photo.urls.regular else {
                #if DEBUG
                #endif
                return nil
            }
            let name = photo.user.name ?? photo.user.username ?? "Unsplash"
            let profileUrl = photo.user.links?.html ?? "https://unsplash.com"
            return (imageUrl, name, profileUrl)
        } catch {
            #if DEBUG
            #endif
            return nil
        }
    }
}

// MARK: - Response DTOs

private struct UnsplashSearchResponse: Decodable {
    let results: [UnsplashPhoto]
}

private struct UnsplashPhoto: Decodable {
    let urls: UnsplashPhotoUrls
    let user: UnsplashUser
}

private struct UnsplashPhotoUrls: Decodable {
    let raw: String?
    let full: String?
    let regular: String?
    let small: String?
    let thumb: String?
}

private struct UnsplashUser: Decodable {
    let name: String?
    let username: String?
    let links: UnsplashUserLinks?
}

private struct UnsplashUserLinks: Decodable {
    let html: String?
}
