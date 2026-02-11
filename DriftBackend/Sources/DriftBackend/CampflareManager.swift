import Foundation

/// Errors that can occur when interacting with the Campflare API.
public enum CampflareError: Error, LocalizedError, Sendable {
    /// The URL could not be constructed.
    case invalidURL
    /// The server returned an invalid response.
    case invalidResponse
    /// Failed to decode the response data.
    case decodingError(Error)
    /// A network error occurred.
    case networkError(Error)
    /// The API key is invalid or missing.
    case unauthorized
    /// The server returned an error status code.
    case serverError(Int)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized - please check your API key"
        case .serverError(let code):
            return "Server error with status code: \(code)"
        }
    }
}

/// Manager for interacting with the Campflare API.
///
/// Use this manager to search campgrounds, fetch campground details,
/// retrieve campsites, and check availability.
///
/// ## Usage
///
/// ```swift
/// let manager = CampflareManager.shared
/// let campground = try await manager.fetchCampground(id: "campground-id")
/// ```
@MainActor
public class CampflareManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = CampflareManager()
    private let baseURL = "https://api.campflare.com/v2"
    private var apiKey: String {
        _BackendConfiguration.shared.campflareAPIKey
    }

    /// Cached campground details keyed by ID with fetch timestamps.
    private var campgroundCache: [String: (campground: Campground, fetchedAt: Date)] = [:]
    /// Cached search results keyed by request description.
    private var searchCache: [String: (response: CampgroundSearchResponse, fetchedAt: Date)] = [:]
    /// Cache entries are fresh for 5 minutes.
    private let cacheTTL: TimeInterval = 300

    private init() {}

    // MARK: - Campground

    /// Fetches a campground by its identifier.
    ///
    /// - Parameter id: The unique campground identifier.
    /// - Returns: The campground details.
    /// - Throws: `CampflareError` if the request fails.
    public func fetchCampground(id: String) async throws -> Campground {
        // Return cached campground if fresh
        if let cached = campgroundCache[id],
           Date().timeIntervalSince(cached.fetchedAt) < cacheTTL {
            return cached.campground
        }

        let urlString = "\(baseURL)/campground/\(id)"
        guard let url = URL(string: urlString) else {
            throw CampflareError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CampflareError.invalidResponse
            }
            try validateResponse(httpResponse)
            if data.isEmpty {
                throw CampflareError.decodingError(
                    NSError(
                        domain: "Campflare",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Empty response data"]
                    )
                )
            }
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            do {
                let campground = try decoder.decode(Campground.self, from: data)
                campgroundCache[id] = (campground: campground, fetchedAt: Date())
                return campground
            } catch {
                throw CampflareError.decodingError(error)
            }
        } catch let error as CampflareError {
            throw error
        } catch {
            throw CampflareError.networkError(error)
        }
    }

    // MARK: - Campsites

    /// Fetches all campsites for a campground.
    ///
    /// - Parameter campgroundId: The campground identifier.
    /// - Returns: Array of campsites at the campground.
    /// - Throws: `CampflareError` if the request fails.
    public func fetchCampsites(campgroundId: String) async throws -> [Campsite] {
        let urlString = "\(baseURL)/campground/\(campgroundId)/campsites"
        guard let url = URL(string: urlString) else {
            throw CampflareError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CampflareError.invalidResponse
            }
            try validateResponse(httpResponse)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode([Campsite].self, from: data)
        } catch let error as CampflareError {
            throw error
        } catch {
            throw CampflareError.networkError(error)
        }
    }

    // MARK: - Availability

    /// Fetches availability for a campground within a date range.
    ///
    /// - Parameters:
    ///   - campgroundId: The campground identifier.
    ///   - startDate: Start date in YYYY-MM-DD format.
    ///   - endDate: End date in YYYY-MM-DD format.
    /// - Returns: Array of availability records for each date.
    /// - Throws: `CampflareError` if the request fails.
    public func fetchAvailability(
        campgroundId: String,
        startDate: String? = nil,
        endDate: String? = nil
    ) async throws -> [Availability] {
        var urlString = "\(baseURL)/campground/\(campgroundId)/availability"
        var queryItems: [URLQueryItem] = []
        if let startDate = startDate {
            queryItems.append(URLQueryItem(name: "start_date", value: startDate))
        }
        if let endDate = endDate {
            queryItems.append(URLQueryItem(name: "end_date", value: endDate))
        }
        if !queryItems.isEmpty {
            var components = URLComponents(string: urlString)
            components?.queryItems = queryItems
            urlString = components?.url?.absoluteString ?? urlString
        }
        guard let url = URL(string: urlString) else {
            throw CampflareError.invalidURL
        }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CampflareError.invalidResponse
            }
            try validateResponse(httpResponse)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode([Availability].self, from: data)
        } catch let error as CampflareError {
            throw error
        } catch {
            throw CampflareError.networkError(error)
        }
    }

    // MARK: - Search

    /// Searches for campgrounds matching the specified criteria.
    ///
    /// - Parameter request: Search parameters including filters and location.
    /// - Returns: Search results with matching campgrounds.
    /// - Throws: `CampflareError` if the request fails.
    public func searchCampgrounds(request: CampgroundSearchRequest) async throws -> CampgroundSearchResponse {
        let urlString = "\(baseURL)/campgrounds/search"
        guard let url = URL(string: urlString) else {
            throw CampflareError.invalidURL
        }
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        urlRequest.httpBody = try encoder.encode(request)

        // Debug: Print the request body
        if let body = urlRequest.httpBody, let bodyString = String(data: body, encoding: .utf8) {
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CampflareError.invalidResponse
            }

            // Debug: Print response body on error
            if httpResponse.statusCode >= 400 {
                if let responseString = String(data: data, encoding: .utf8) {
                }
            }

            try validateResponse(httpResponse)
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(CampgroundSearchResponse.self, from: data)
        } catch let error as CampflareError {
            throw error
        } catch {
            throw CampflareError.networkError(error)
        }
    }

    // MARK: - Private

    private func validateResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw CampflareError.unauthorized
        case 400...499:
            throw CampflareError.serverError(response.statusCode)
        case 500...599:
            throw CampflareError.serverError(response.statusCode)
        default:
            throw CampflareError.serverError(response.statusCode)
        }
    }
}
