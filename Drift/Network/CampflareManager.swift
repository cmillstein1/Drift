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
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CampflareError.invalidResponse
            }
            
            try validateResponse(httpResponse)
            
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            return try decoder.decode(Campground.self, from: data)
        } catch let error as CampflareError {
            throw error
        } catch {
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
    
    // NOTE: Search endpoint uses plural /campgrounds/search (unlike other endpoints which are singular)
    // This endpoint is used to find corresponding V2 campground IDs from V1 listings
    func searchCampgrounds(request: CampgroundSearchRequest) async throws -> CampgroundSearchResponse {
        // Build query parameters
        // Search endpoint uses plural /campgrounds/search
        var components = URLComponents(string: "\(baseURL)/campgrounds/search")
        var queryItems: [URLQueryItem] = []
        
        if let latitude = request.latitude {
            queryItems.append(URLQueryItem(name: "latitude", value: String(latitude)))
        }
        if let longitude = request.longitude {
            queryItems.append(URLQueryItem(name: "longitude", value: String(longitude)))
        }
        if let radius = request.radius {
            queryItems.append(URLQueryItem(name: "radius", value: String(radius)))
        }
        if let state = request.state {
            queryItems.append(URLQueryItem(name: "state", value: state))
        }
        if let stateCode = request.stateCode {
            queryItems.append(URLQueryItem(name: "state_code", value: stateCode))
        }
        if let kind = request.kind {
            queryItems.append(URLQueryItem(name: "kind", value: kind))
        }
        if let amenities = request.amenities, !amenities.isEmpty {
            queryItems.append(URLQueryItem(name: "amenities", value: amenities.joined(separator: ",")))
        }
        if let limit = request.limit {
            queryItems.append(URLQueryItem(name: "limit", value: String(limit)))
        }
        if let offset = request.offset {
            queryItems.append(URLQueryItem(name: "offset", value: String(offset)))
        }
        
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        
        guard let url = components?.url else {
            throw CampflareError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue(apiKey, forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            // Debug: Print request details
            print("🔍 Campflare Search Request URL: \(url.absoluteString)")
            print("🔍 Campflare Authorization Header: \(apiKey.prefix(20))...") // Print first 20 chars for debugging
            
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CampflareError.invalidResponse
            }
            
            // Debug: Print response details
            print("🔍 Campflare Response Status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("🔍 Campflare Response Body: \(responseString)")
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
