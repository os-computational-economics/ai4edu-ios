//
//  Environment.swift
//  ai4edu
//
//  Created by Sam Jin on 4/16/25.
//

import Foundation

// Define a simple config class that can be referenced globally
final class AppConfig {
    enum EnvironmentType {
        case dev
        case prod
    }
    
    // Change this value to switch between environments
    static let environment: EnvironmentType = .prod
    
    // Base URLs
    static var baseURL: String {
        switch environment {
        case .dev:
            return "https://ai4edu-api.jerryang.org"
        case .prod:
            return "https://ai4edu-api.jerryang.org"
        }
    }
    
    // API paths
    static var apiPath: String {
        switch environment {
        case .dev:
            return "/v1/dev"
        case .prod:
            return "/v1/prod"
        }
    }
    
    // Full API URL
    static var apiBaseURL: String {
        return baseURL + apiPath
    }
    
    // SSO Base URL
    static var ssoBaseURL: String {
        return "https://login.case.edu/cas/login"
    }
} 