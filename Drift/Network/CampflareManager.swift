//
//  CampflareManager.swift
//  Drift
//
//  Created by Casey Millstein on 1/15/26.
//

import Foundation
import Combine

enum CampflareError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case decodingError(Error)
    case networkError(Error)
    case unauthorized
    case serverError(Int)
    
    var errorDescription: String? {
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

@MainActor
class CampflareManager: ObservableObject {
    static let shared = CampflareManager()
    
    private let baseURL = "https://api.campflare.com/v2"
    private let apiKey: String
    
    private init() {
        self.apiKey = CampflareConfig.apiKey
        // Debug: Verify API key is loaded (print first 20 chars only)
        print("🔑 Campflare API Key loaded: \(apiKey.prefix(20))...")
    }
    
    // MARK: - Get Campground
    
    func getCampground(id: String) async throws -> Campground {
        let urlString = "\(baseURL)/campground/\(id)"
        guard let url = URL(string: urlString) else {
            throw CampflareError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            // Debug logging
            let separator = String(repeating: "=", count: 80)
            print(separator)
            print("CAMPFLARE GET CAMPGROUND REQUEST")
            print(separator)
            print("URL: \(urlString)")
            print("Method: GET")
            print("Authorization: \(apiKey.prefix(30))...")
            print(String(repeating: "-", count: 80))
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("ERROR: Invalid response type")
                throw CampflareError.invalidResponse
            }
            
            print("Response Status: \(httpResponse.statusCode)")
            print("Response Headers:")
            for (key, value) in httpResponse.allHeaderFields {
                print("  - \(key): \(value)")
            }
            
            print("Response Data Length: \(data.count) bytes")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response Body:")
                print(responseString)
            } else {
                print("Response Body: (unable to decode as UTF-8)")
            }
            print(separator)
            
            try validateResponse(httpResponse)
            
            // Check if data is empty
            if data.isEmpty {
                print("⚠️ WARNING: Response data is empty")
                throw CampflareError.decodingError(NSError(domain: "Campflare", code: -1, userInfo: [NSLocalizedDescriptionKey: "Empty response data"]))
            }
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            
            do {
                return try decoder.decode(Campground.self, from: data)
            } catch {
                print("❌ Decoding Error: \(error)")
                if let decodingError = error as? DecodingError {
                    print("Decoding Error Details:")
                    switch decodingError {
                    case .typeMismatch(let type, let context):
                        print("  Type Mismatch: Expected \(type), at \(context.codingPath)")
                    case .valueNotFound(let type, let context):
                        print("  Value Not Found: \(type), at \(context.codingPath)")
                    case .keyNotFound(let key, let context):
                        print("  Key Not Found: \(key), at \(context.codingPath)")
                    case .dataCorrupted(let context):
                        print("  Data Corrupted: \(context)")
                    @unknown default:
                        print("  Unknown decoding error")
                    }
                }
                throw CampflareError.decodingError(error)
            }
        } catch let error as CampflareError {
            throw error
        } catch {
            print("❌ Network Error: \(error.localizedDescription)")
            throw CampflareError.networkError(error)
        }
    }
    
    // MARK: - Get Campsites
    
    func getCampsites(campgroundId: String) async throws -> [Campsite] {
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
    
    // MARK: - Get Availability
    
    func getAvailability(campgroundId: String, startDate: String? = nil, endDate: String? = nil) async throws -> [Availability] {
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
    
    // MARK: - Search Campgrounds
    
    // NOTE: Search endpoint uses POST with JSON body (not GET with query parameters)
    // Endpoint: POST /campgrounds/search
    func searchCampgrounds(request: CampgroundSearchRequest) async throws -> CampgroundSearchResponse {
        let urlString = "\(baseURL)/campgrounds/search"
        guard let url = URL(string: urlString) else {
            throw CampflareError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Encode request as JSON body
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        urlRequest.httpBody = try encoder.encode(request)
        
        do {
            // Detailed logging for Campflare support
            let separator = String(repeating: "=", count: 80)
            print(separator)
            print("CAMPFLARE API REQUEST DEBUG LOG")
            print(separator)
            print("Timestamp: \(Date())")
            print("Endpoint: SEARCH CAMPGROUNDS")
            print("Base URL: \(baseURL)")
            print("Full Request URL: \(urlString)")
            print("HTTP Method: POST")
            print("Request Headers:")
            print("  - Authorization: \(apiKey.prefix(30))... (truncated for security)")
            print("  - Content-Type: application/json")
            print("  - Accept: application/json")
            if let httpBody = urlRequest.httpBody,
               let bodyString = String(data: httpBody, encoding: .utf8) {
                print("Request Body:")
                print(bodyString)
            }
            print(String(repeating: "-", count: 80))
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("ERROR: Invalid response type")
                throw CampflareError.invalidResponse
            }
            
            print("Response Status Code: \(httpResponse.statusCode)")
            print("Response Headers:")
            for (key, value) in httpResponse.allHeaderFields {
                print("  - \(key): \(value)")
            }
            
            let responseString = String(data: data, encoding: .utf8) ?? "(unable to decode)"
            print("Response Body:")
            print(responseString)
            
            // Check for 405 specifically
            if httpResponse.statusCode == 405 {
                print(separator)
                print("⚠️ 405 METHOD NOT ALLOWED ERROR")
                print(separator)
                print("The endpoint returned 405, indicating the HTTP method is not allowed.")
                print("Request Details:")
                print("  - URL: \(url.absoluteString)")
                print("  - Method: GET")
                print("  - Expected: The search endpoint should accept GET requests")
                print("  - Issue: Either the endpoint doesn't exist, or it requires a different method")
                print(separator)
            }
            
            print(separator)
            
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
    
    // MARK: - Helper Methods
    
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
