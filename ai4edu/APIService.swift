//
//  APIService.swift
//  ai4edu
//
//  Created by Sam Jin on 3/24/25.
//

import Foundation

// MARK: - User Models

struct UserListResponse: Codable {
    let data: UserData
    let message: String
    let success: Bool
}

struct UserData: Codable {
    let items: [User]
    let total: Int
}

struct User: Identifiable, Codable {
    let userId: Int
    let email: String
    let firstName: String
    let lastName: String
    let studentId: String
    let workspaceRole: [String: String]
    
    var id: Int { userId }
    var fullName: String { "\(firstName) \(lastName)" }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case email
        case firstName = "first_name"
        case lastName = "last_name"
        case studentId = "student_id"
        case workspaceRole = "workspace_role"
    }
}

class APIService {
    static let shared = APIService()
    
    private let baseURL = "https://ai4edu-api.jerryang.org/v1/prod"
    
    private init() {}
    
    // MARK: - SSO Methods
    
    func getSSOURL(returnURL: String) -> URL? {
        let baseSSO = "https://login.case.edu/cas/login"
        let ssoVerifyURL = "\(APIEnvironment.onlineBaseURL)\(APIEnvironment.prodPath)/user/sso"
        
        let urlString = "\(baseSSO)?service=\(ssoVerifyURL)?came_from=\(returnURL)"
        return URL(string: urlString)
    }
    
    func handleSSOCallback(url: URL) -> Bool {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems else {
            return false
        }
        
        let refreshToken = queryItems.first(where: { $0.name == "refresh" })?.value
        let accessToken = queryItems.first(where: { $0.name == "access" })?.value
        
        if let refresh = refreshToken, let access = accessToken {
            TokenManager.shared.saveTokens(refresh: refresh, access: access)
            
            // Print login information and tokens
            print("=== Login Successful ===")
            print("Refresh Token: \(refresh)")
            print("Access Token: \(access)")
            print("======================")
            
            return true
        }
        
        return false
    }
    
    // MARK: - Fetch Agents
    
    func fetchAgents(page: Int, pageSize: Int, workspaceId: String, completion: @escaping (Result<AgentResponse, Error>) -> Void) {
        let endpoint = "/admin/agents/agents"
        
        // Add query parameters to the URL
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
            URLQueryItem(name: "workspace_id", value: workspaceId)
        ]
        
        guard let url = urlComponents?.url else {
            print("📱 AGENTS-API - Error: Invalid URL constructed")
            completion(.failure(APIError.invalidURL))
            return
        }
        
        print("📱 AGENTS-API - Making request to URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authorization header if token is available - Fix the format to match working example
        if let accessToken = TokenManager.shared.getAccessToken() {
            // Format should be "Bearer access=<token>" not just "Bearer <token>"
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
            print("📱 AGENTS-API - Added authorization header with token format: Bearer access=TOKEN")
        } else {
            print("📱 AGENTS-API - WARNING: No access token available for authorization")
        }
        
        print("📱 AGENTS-API - Starting network request...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("📱 AGENTS-API - Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 AGENTS-API - HTTP Status Code: \(httpResponse.statusCode)")
                
                // Print headers for debugging
                print("📱 AGENTS-API - Response Headers:")
                httpResponse.allHeaderFields.forEach { key, value in
                    print("📱 AGENTS-API -   \(key): \(value)")
                }
            }
            
            guard let data = data else {
                print("📱 AGENTS-API - Error: No data received from server")
                completion(.failure(APIError.noData))
                return
            }
            
            print("📱 AGENTS-API - Received \(data.count) bytes of data")
            
            // Print raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📱 AGENTS-API - Raw Response: \(responseString)")
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(AgentResponse.self, from: data)
                print("📱 AGENTS-API - Successfully decoded response")
                completion(.success(decodedResponse))
            } catch {
                print("📱 AGENTS-API - JSON Decoding error: \(error)")
                
                // Try to extract error message if available
                if let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = responseDict["message"] as? String {
                    print("📱 AGENTS-API - Server message: \(message)")
                }
                
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Fetch User List
    
    func fetchUserList(page: Int, pageSize: Int, workspaceId: String, completion: @escaping (Result<UserListResponse, Error>) -> Void) {
        let endpoint = "/admin/access/get_user_list"
        
        // Add query parameters to the URL
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
            URLQueryItem(name: "workspace_id", value: workspaceId)
        ]
        
        guard let url = urlComponents?.url else {
            print("📱 USERS-API - Error: Invalid URL constructed")
            completion(.failure(APIError.invalidURL))
            return
        }
        
        print("📱 USERS-API - Making request to URL: \(url)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        // Add authorization header with correct format
        if let accessToken = TokenManager.shared.getAccessToken() {
            // Format should be "Bearer access=<token>" not just "Bearer <token>"
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
            print("📱 USERS-API - Added authorization header with token format: Bearer access=TOKEN")
        } else {
            print("📱 USERS-API - WARNING: No access token available for authorization")
        }
        
        print("📱 USERS-API - Starting network request...")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("📱 USERS-API - Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 USERS-API - HTTP Status Code: \(httpResponse.statusCode)")
                
                // Print headers for debugging
                print("📱 USERS-API - Response Headers:")
                httpResponse.allHeaderFields.forEach { key, value in
                    print("📱 USERS-API -   \(key): \(value)")
                }
            }
            
            guard let data = data else {
                print("📱 USERS-API - Error: No data received from server")
                completion(.failure(APIError.noData))
                return
            }
            
            print("📱 USERS-API - Received \(data.count) bytes of data")
            
            // Print raw response for debugging
            if let responseString = String(data: data, encoding: .utf8) {
                print("📱 USERS-API - Raw Response: \(responseString)")
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(UserListResponse.self, from: data)
                print("📱 USERS-API - Successfully decoded response")
                completion(.success(decodedResponse))
            } catch {
                print("📱 USERS-API - JSON Decoding error: \(error)")
                
                // Try to extract error message if available
                if let responseDict = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = responseDict["message"] as? String {
                    print("📱 USERS-API - Server message: \(message)")
                }
                
                completion(.failure(error))
            }
        }.resume()
    }
}

// API Environment configuration
enum APIEnvironment {
    static let onlineBaseURL = "https://ai4edu-api.jerryang.org"
    static let prodPath = "/v1/prod"
}

// MARK: - API Errors

enum APIError: Error {
    case invalidURL
    case noData
    case decodingError
    case networkError
}

extension APIError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received from server"
        case .decodingError:
            return "Error decoding response"
        case .networkError:
            return "Network error"
        }
    }
}
