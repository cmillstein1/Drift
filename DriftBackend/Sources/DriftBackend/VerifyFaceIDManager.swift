import Foundation

/// Errors that can occur when interacting with the VerifyFaceID API.
public enum VerifyFaceIDError: Error, LocalizedError, Sendable {
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
    case serverError(Int, String?)
    /// No face detected in image.
    case noFaceDetected
    /// Multiple faces detected.
    case multipleFaces
    /// Spoof detected in selfie.
    case spoofDetected
    /// Face match failed.
    case faceMismatch

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
        case .serverError(let code, let message):
            if let message = message {
                return "Server error (\(code)): \(message)"
            }
            return "Server error with status code: \(code)"
        case .noFaceDetected:
            return "No face detected in image"
        case .multipleFaces:
            return "Multiple faces detected - please use a photo with only one face"
        case .spoofDetected:
            return "Spoof detected - please use a real photo"
        case .faceMismatch:
            return "Face verification failed - photos do not match"
        }
    }
}

/// Response from VerifyFaceID verification API.
public struct VerifyFaceIDResponse: Codable, Sendable {
    public let match: Bool
    public let confidence: Double?
    public let message: String?
    public let isSpoof: Bool?
    public let selfieImage: String? // base64 encoded optimized selfie
    
    enum CodingKeys: String, CodingKey {
        case match
        case confidence
        case message
        case isSpoof = "is_spoof"
        case selfieImage = "selfie_image"
    }
}

/// Error response from VerifyFaceID API.
public struct VerifyFaceIDErrorResponse: Codable, Sendable {
    public let error: String
    public let message: String?
    public let status: Int?
}

/// Manager for interacting with the VerifyFaceID API.
///
/// Use this manager to verify user identity by comparing a reference photo
/// (profile photo) with a selfie.
///
/// ## Usage
///
/// ```swift
/// let manager = VerifyFaceIDManager.shared
/// let result = try await manager.verifyFace(
///     referenceURL: profilePhotoURL,
///     selfieImageData: capturedSelfieData
/// )
/// ```
@MainActor
public class VerifyFaceIDManager: ObservableObject {
    /// Shared singleton instance.
    public static let shared = VerifyFaceIDManager()
    
    private let baseURL = "https://www.verifyfaceid.com/api/v2"
    private var apiKey: String {
        _BackendConfiguration.shared.verifyFaceIDAPIKey
    }

    private init() {}

    /// Verifies a face by comparing a reference photo with a selfie.
    ///
    /// - Parameters:
    ///   - referenceURL: URL to the reference photo (must be publicly accessible).
    ///   - selfieImageData: The selfie image data (JPEG, PNG, GIF, or WebP).
    /// - Returns: Verification result with match status, confidence, and spoof detection.
    /// - Throws: `VerifyFaceIDError` if the request fails.
    public func verifyFace(
        referenceURL: String,
        selfieImageData: Data
    ) async throws -> VerifyFaceIDResponse {
        // Try with URL first, if that fails, download and use as file
        return try await verifyFaceWithURL(referenceURL: referenceURL, selfieImageData: selfieImageData)
    }
    
    /// Verifies a face using reference URL.
    private func verifyFaceWithURL(
        referenceURL: String,
        selfieImageData: Data
    ) async throws -> VerifyFaceIDResponse {
        let urlString = "\(baseURL)/verify"
        guard let url = URL(string: urlString) else {
            throw VerifyFaceIDError.invalidURL
        }
        
        // Create multipart form data
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add reference URL
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"reference_url\"\r\n".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        body.append(referenceURL.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add selfie image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"selfie\"; filename=\"selfie.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        body.append(selfieImageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw VerifyFaceIDError.invalidResponse
            }
            
            // Handle error responses
            if httpResponse.statusCode >= 400 {
                // Try to decode as VerifyFaceIDResponse first (API returns 400 with match:false)
                if let response = try? JSONDecoder().decode(VerifyFaceIDResponse.self, from: data) {
                    // Check if it's a "no face detected" response
                    if let message = response.message, message.lowercased().contains("no face") {
                        throw VerifyFaceIDError.noFaceDetected
                    }
                    // If match is false, it's a face mismatch
                    if !response.match {
                        throw VerifyFaceIDError.faceMismatch
                    }
                }
                
                // Try to decode error response
                let errorMessage: String?
                if let errorResponse = try? JSONDecoder().decode(VerifyFaceIDErrorResponse.self, from: data) {
                    errorMessage = errorResponse.message ?? errorResponse.error
                } else if let response = try? JSONDecoder().decode(VerifyFaceIDResponse.self, from: data) {
                    errorMessage = response.message
                } else if let errorString = String(data: data, encoding: .utf8) {
                    errorMessage = errorString
                } else {
                    errorMessage = nil
                }
                
                // Log error for debugging
                print("❌ VerifyFaceID API Error (\(httpResponse.statusCode)): \(errorMessage ?? "Unknown error")")
                if let responseString = String(data: data, encoding: .utf8) {
                    print("Response body: \(responseString)")
                }
                
                // Check for specific error cases
                if let message = errorMessage {
                    if message.lowercased().contains("no face") || message.lowercased().contains("no face detected") {
                        throw VerifyFaceIDError.noFaceDetected
                    }
                    if message.lowercased().contains("multiple faces") {
                        throw VerifyFaceIDError.multipleFaces
                    }
                    if message.lowercased().contains("spoof") {
                        throw VerifyFaceIDError.spoofDetected
                    }
                }
                
                if httpResponse.statusCode == 401 {
                    throw VerifyFaceIDError.unauthorized
                }
                
                throw VerifyFaceIDError.serverError(httpResponse.statusCode, errorMessage)
            }
            
            // Decode success response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let result = try decoder.decode(VerifyFaceIDResponse.self, from: data)
            
            // Check for spoof detection
            if result.isSpoof == true {
                throw VerifyFaceIDError.spoofDetected
            }
            
            // Check for face mismatch
            if !result.match {
                throw VerifyFaceIDError.faceMismatch
            }
            
            return result
        } catch let error as VerifyFaceIDError {
            // If URL method fails with "no face detected", try downloading reference and using as file
            if case .noFaceDetected = error {
                print("⚠️ URL method failed, trying with downloaded reference image...")
                return try await verifyFaceWithFile(referenceURL: referenceURL, selfieImageData: selfieImageData)
            }
            throw error
        } catch {
            throw VerifyFaceIDError.networkError(error)
        }
    }
    
    /// Verifies a face by downloading the reference image and uploading both as files.
    private func verifyFaceWithFile(
        referenceURL: String,
        selfieImageData: Data
    ) async throws -> VerifyFaceIDResponse {
        guard let url = URL(string: referenceURL) else {
            throw VerifyFaceIDError.invalidURL
        }
        
        // Download reference image
        let (referenceData, _) = try await URLSession.shared.data(from: url)
        
        let urlString = "\(baseURL)/verify"
        guard let verifyURL = URL(string: urlString) else {
            throw VerifyFaceIDError.invalidURL
        }
        
        // Create multipart form data with both images as files
        var request = URLRequest(url: verifyURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add reference image as file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"reference\"; filename=\"reference.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        body.append(referenceData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add selfie image
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"selfie\"; filename=\"selfie.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n".data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        body.append(selfieImageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // End boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw VerifyFaceIDError.invalidResponse
            }
            
            // Handle error responses
            if httpResponse.statusCode >= 400 {
                let errorMessage: String?
                if let response = try? JSONDecoder().decode(VerifyFaceIDResponse.self, from: data) {
                    errorMessage = response.message
                    if let message = errorMessage, message.lowercased().contains("no face") {
                        throw VerifyFaceIDError.noFaceDetected
                    }
                    if !response.match {
                        throw VerifyFaceIDError.faceMismatch
                    }
                } else if let errorResponse = try? JSONDecoder().decode(VerifyFaceIDErrorResponse.self, from: data) {
                    errorMessage = errorResponse.message ?? errorResponse.error
                } else {
                    errorMessage = String(data: data, encoding: .utf8)
                }
                
                if httpResponse.statusCode == 401 {
                    throw VerifyFaceIDError.unauthorized
                }
                
                throw VerifyFaceIDError.serverError(httpResponse.statusCode, errorMessage)
            }
            
            // Decode success response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            let result = try decoder.decode(VerifyFaceIDResponse.self, from: data)
            
            if result.isSpoof == true {
                throw VerifyFaceIDError.spoofDetected
            }
            
            if !result.match {
                throw VerifyFaceIDError.faceMismatch
            }
            
            return result
        } catch let error as VerifyFaceIDError {
            throw error
        } catch {
            throw VerifyFaceIDError.networkError(error)
        }
    }
}
