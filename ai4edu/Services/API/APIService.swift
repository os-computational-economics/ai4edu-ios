//
//  APIService.swift
//  ai4edu
//
//  Created by Sam Jin on 3/24/25.
//

import Foundation
import SwiftUI

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
            
            return true
        }
        
        return false
    }
    
    // MARK: - Token Management
    
    func ping(completion: @escaping (Result<Bool, Error>) -> Void) {
        let endpoint = "/admin/ping"
        
        guard let url = URL(string: baseURL + endpoint) else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let refreshToken = TokenManager.shared.getRefreshToken() {
            request.addValue("Bearer refresh=\(refreshToken)", forHTTPHeaderField: "Authorization")
        } else {
            completion(.failure(APIError.networkError))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📱 PING-API - HTTP Status Code: \(httpResponse.statusCode)")
                
                if 200...299 ~= httpResponse.statusCode {
                    // If we have a successful response, check for new tokens in the response
                    if let data = data, 
                       let responseDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let access = responseDict["access"] as? String {
                        // Update the access token
                        if let refresh = TokenManager.shared.getRefreshToken() {
                            TokenManager.shared.saveTokens(refresh: refresh, access: access)
                        }
                    }
                    completion(.success(true))
                } else {
                    completion(.failure(APIError.networkError))
                }
            } else {
                completion(.failure(APIError.networkError))
            }
        }.resume()
    }
    
    func checkToken(completion: @escaping (Result<Bool, Error>) -> Void) {
        if TokenManager.shared.getAccessToken() == nil && TokenManager.shared.getRefreshToken() != nil {
            ping { result in
                switch result {
                case .success:
                    completion(.success(true))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else if TokenManager.shared.getAccessToken() == nil && TokenManager.shared.getRefreshToken() == nil {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name("LogoutRequired"), object: nil)
            }
            completion(.failure(APIError.networkError))
        } else {
            completion(.success(true))
        }
    }
    
    // MARK: - Fetch Agents
    
    func fetchAgents(page: Int, pageSize: Int, workspaceId: String, completion: @escaping (Result<AgentsListResponse, Error>) -> Void) {
        // First check token validity
        checkToken { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success:
                self.performFetchAgents(page: page, pageSize: pageSize, workspaceId: workspaceId, completion: completion)
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func performFetchAgents(page: Int, pageSize: Int, workspaceId: String, completion: @escaping (Result<AgentsListResponse, Error>) -> Void) {
        let endpoint = "/admin/agents/agents"
        
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
            URLQueryItem(name: "workspace_id", value: workspaceId)
        ]
        
        guard let url = urlComponents?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let accessToken = TokenManager.shared.getAccessToken() {
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            print("📱 AGENTS-API - WARNING: No access token available for authorization")
        }
        
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                
                httpResponse.allHeaderFields.forEach { key, value in
                    print("📱 AGENTS-API -   \(key): \(value)")
                }
                
                // Check for 401 Unauthorized error which might indicate token expired
                if httpResponse.statusCode == 401 {
                    print("📱 AGENTS-API - Received 401 Unauthorized, trying to refresh token")
                    self?.checkToken { result in
                        switch result {
                        case .success:
                            // Token refreshed, retry the request
                            self?.performFetchAgents(page: page, pageSize: pageSize, workspaceId: workspaceId, completion: completion)
                        case .failure(let error):
                            completion(.failure(error))
                        }
                    }
                    return
                }
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(AgentsListResponse.self, from: data)
                completion(.success(decodedResponse))
            } catch {
                
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
        
        var urlComponents = URLComponents(string: baseURL + endpoint)
        urlComponents?.queryItems = [
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "page_size", value: "\(pageSize)"),
            URLQueryItem(name: "workspace_id", value: workspaceId)
        ]
        
        guard let url = urlComponents?.url else {
            completion(.failure(APIError.invalidURL))
            return
        }
        
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        if let accessToken = TokenManager.shared.getAccessToken() {
            request.addValue("Bearer access=\(accessToken)", forHTTPHeaderField: "Authorization")
        } else {
            print("📱 USERS-API - WARNING: No access token available for authorization")
        }
        
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                httpResponse.allHeaderFields.forEach { key, value in
                    print("📱 USERS-API -   \(key): \(value)")
                }
            }
            
            guard let data = data else {
                completion(.failure(APIError.noData))
                return
            }
            
            
            if let responseString = String(data: data, encoding: .utf8) {
                print("📱 USERS-API - Raw Response: \(responseString)")
            }
            
            do {
                let decodedResponse = try JSONDecoder().decode(UserListResponse.self, from: data)
                completion(.success(decodedResponse))
            } catch {
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
