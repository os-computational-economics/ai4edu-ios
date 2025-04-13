//
//  TokenModel.swift
//  ai4edu
//
//  Created by Sam Jin on 3/24/25.
//

import Foundation
import JWTDecode

struct TokenResponse: Codable {
    let refreshToken: String
    let accessToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh"
        case accessToken = "access"
    }
}

struct JWTData {
    let subject: String
    let firstName: String
    let lastName: String
    let email: String
    let studentId: String
    let isSystemAdmin: Bool
    let expiresAt: Date
    let issuedAt: Date
    let workspaceRoles: [String: String]
    
    func formattedString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        let now = Date()
        let isExpired = now > expiresAt
        let timeUntilExpiry = formatTimeInterval(expiresAt.timeIntervalSince(now))
        let expiryStatus = isExpired ? 
            "EXPIRED (\(formatTimeInterval(now.timeIntervalSince(expiresAt))) ago)" : 
            "VALID (expires in \(timeUntilExpiry))"
        
        var result = "===== User Information =====\n"
        result += "Subject: \(subject)\n"
        result += "Name: \(firstName) \(lastName)\n"
        if !email.isEmpty {
            result += "Email: \(email)\n"
        }
        if !studentId.isEmpty {
            result += "Student ID: \(studentId)\n"
        }
        result += "System Admin: \(isSystemAdmin ? "Yes" : "No")\n"
        
        result += "\n===== Time Information =====\n"
        result += "Issued: \(dateFormatter.string(from: issuedAt))\n"
        result += "Expires: \(dateFormatter.string(from: expiresAt))\n"
        result += "Status: \(expiryStatus)"
        
        return result
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let secondsTotal = Int(abs(interval))
        let days = secondsTotal / (60 * 60 * 24)
        let hours = (secondsTotal % (60 * 60 * 24)) / (60 * 60)
        let minutes = (secondsTotal % (60 * 60)) / 60
        let seconds = secondsTotal % 60
        
        var result = ""
        if days > 0 {
            result += "\(days)d "
        }
        if hours > 0 || days > 0 {
            result += "\(hours)h "
        }
        if minutes > 0 || hours > 0 || days > 0 {
            result += "\(minutes)m "
        }
        result += "\(seconds)s"
        
        return result
    }
}

class TokenManager {
    static let shared = TokenManager()
    
    private let refreshTokenKey = "refresh_token"
    private let accessTokenKey = "access_token"
    private let userDefaults = UserDefaults.standard
    
    func saveTokens(refresh: String, access: String) {
        userDefaults.set(refresh, forKey: refreshTokenKey)
        userDefaults.set(access, forKey: accessTokenKey)
    }
    
    func getRefreshToken() -> String? {
        return userDefaults.string(forKey: refreshTokenKey)
    }
    
    func getAccessToken() -> String? {
        return userDefaults.string(forKey: accessTokenKey)
    }
    
    func clearTokens() {
        userDefaults.removeObject(forKey: refreshTokenKey)
        userDefaults.removeObject(forKey: accessTokenKey)
    }
    
    func isLoggedIn() -> Bool {
        return getRefreshToken() != nil
    }
    
    func decodeToken() -> JWTData? {
        guard let tokenString = getAccessToken() else {
            return nil
        }
        
        
        do {
            let jwt = try decode(jwt: tokenString)
  
            var userId: String = "0"
            let userIdClaim = jwt.claim(name: "user_id")
            if let idInt = userIdClaim.rawValue as? Int {
                userId = String(idInt)
            } else if let idString = userIdClaim.string {
                userId = idString
            } else {
                // Unable to extract user_id, using default
            }
            let subject = "user:\(userId)"
            
            let firstName = jwt.claim(name: "first_name").string ?? "Unknown"
            let lastName = jwt.claim(name: "last_name").string ?? "Unknown"
            let email = jwt.claim(name: "email").string ?? ""
            let studentId = jwt.claim(name: "student_id").string ?? ""
            
            let systemAdminClaim = jwt.claim(name: "system_admin")
            var isSystemAdmin = false
            
            if let adminInt = systemAdminClaim.rawValue as? Int {
                isSystemAdmin = adminInt == 1
            } else if let adminBool = systemAdminClaim.rawValue as? Bool {
                isSystemAdmin = adminBool
            } else if let adminString = systemAdminClaim.string?.lowercased() {
                isSystemAdmin = adminString == "true" || adminString == "1" || adminString == "yes"
            }
            
            let expiresAt: Date
            if let exp = jwt.expiresAt {
                expiresAt = exp
            } else if let expValue = jwt.claim(name: "exp").rawValue as? TimeInterval {
                expiresAt = Date(timeIntervalSince1970: expValue)
            } else {
                expiresAt = Date().addingTimeInterval(3600) // Default 1 hour
            }
            
            let issuedAt: Date
            if let iat = jwt.issuedAt {
                issuedAt = iat
            } else if let iatValue = jwt.claim(name: "iat").rawValue as? TimeInterval {
                issuedAt = Date(timeIntervalSince1970: iatValue)
            } else {
                issuedAt = Date() // Default to now
            }
            
            var workspaceRoles: [String: String] = [:]
            
            let rolesClaim = jwt.claim(name: "workspace_role")
            
            if let rolesDict = rolesClaim.rawValue as? [String: String] {
                workspaceRoles = rolesDict
            } else if let rolesObject = rolesClaim.rawValue {
                if let rolesData = try? JSONSerialization.data(withJSONObject: rolesObject, options: []),
                   let rolesDict = try? JSONSerialization.jsonObject(with: rolesData, options: []) as? [String: String] {
                    workspaceRoles = rolesDict
                } else if let rolesDict = rolesObject as? [String: Any] {
                    for (key, value) in rolesDict {
                        if let stringValue = value as? String {
                            workspaceRoles[key] = stringValue
                        } else {
                            workspaceRoles[key] = String(describing: value)
                        }
                    }
                }
            }
            
            let jwtData = JWTData(
                subject: subject,
                firstName: firstName,
                lastName: lastName,
                email: email,
                studentId: studentId,
                isSystemAdmin: isSystemAdmin,
                expiresAt: expiresAt,
                issuedAt: issuedAt,
                workspaceRoles: workspaceRoles
            )
            return jwtData
            
        } catch {
            let parts = tokenString.components(separatedBy: ".")
            
            if parts.count >= 2 {
                let payloadBase64 = parts[1]
                
                if let payloadData = decodeBase64URLEncoded(payloadBase64),
                   let payloadString = String(data: payloadData, encoding: .utf8) {
                    
                    if let jsonData = payloadString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                        
                        let userId = json["user_id"] as? String ?? String(describing: json["user_id"] ?? "0")
                        let firstName = json["first_name"] as? String ?? "Unknown"
                        let lastName = json["last_name"] as? String ?? "Unknown"
                        let email = json["email"] as? String ?? ""
                        let studentId = json["student_id"] as? String ?? ""
                        
                        var isSystemAdmin = false
                        if let adminValue = json["system_admin"] {
                            if let adminBool = adminValue as? Bool {
                                isSystemAdmin = adminBool
                            } else if let adminInt = adminValue as? Int {
                                isSystemAdmin = adminInt == 1
                            } else if let adminString = adminValue as? String {
                                isSystemAdmin = adminString.lowercased() == "true" || adminString == "1"
                            }
                        }
                        
                        let exp = (json["exp"] as? TimeInterval) ?? 0
                        let iat = (json["iat"] as? TimeInterval) ?? 0
                        let expiresAt = Date(timeIntervalSince1970: exp)
                        let issuedAt = Date(timeIntervalSince1970: iat)
                        
                        var workspaceRoles: [String: String] = [:]
                        if let roles = json["workspace_role"] as? [String: String] {
                            workspaceRoles = roles
                        } else if let roles = json["workspace_role"] as? [String: Any] {
                            for (key, value) in roles {
                                workspaceRoles[key] = String(describing: value)
                            }
                        }
                        
                        return JWTData(
                            subject: "user:\(userId)",
                            firstName: firstName,
                            lastName: lastName,
                            email: email,
                            studentId: studentId,
                            isSystemAdmin: isSystemAdmin,
                            expiresAt: expiresAt,
                            issuedAt: issuedAt,
                            workspaceRoles: workspaceRoles
                        )
                    }
                }
            }
            
            return nil
        }
    }
    
    private func decodeBase64URLEncoded(_ string: String) -> Data? {
        var base64 = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        
        let length = Double(base64.count)
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = Int(requiredLength - length)
        if paddingLength > 0 {
            let padding = String(repeating: "=", count: paddingLength)
            base64 = base64 + padding
        }
        
        return Data(base64Encoded: base64)
    }
    
    func getWorkspaceRoles() -> [String: String] {
        guard let tokenString = getAccessToken() else {
            return [:]
        }
        
        do {
            let jwt = try decode(jwt: tokenString)
            let rolesClaim = jwt.claim(name: "workspace_role")
            
            if let rolesDict = rolesClaim.rawValue as? [String: String] {
                return rolesDict
            } else if let rolesDict = rolesClaim.rawValue as? [String: Any] {
                var convertedRoles: [String: String] = [:]
                for (key, value) in rolesDict {
                    if let stringValue = value as? String {
                        convertedRoles[key] = stringValue
                    } else {
                        convertedRoles[key] = String(describing: value)
                    }
                }
                return convertedRoles
            } else {
                return [:]
            }
        } catch {
            return [:]
        }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let secondsTotal = Int(abs(interval))
        let days = secondsTotal / (60 * 60 * 24)
        let hours = (secondsTotal % (60 * 60 * 24)) / (60 * 60)
        let minutes = (secondsTotal % (60 * 60)) / 60
        let seconds = secondsTotal % 60
        
        var result = ""
        if days > 0 {
            result += "\(days)d "
        }
        if hours > 0 || days > 0 {
            result += "\(hours)h "
        }
        if minutes > 0 || hours > 0 || days > 0 {
            result += "\(minutes)m "
        }
        result += "\(seconds)s"
        
        return result
    }
    
    func getFormattedWorkspaceRoles() -> String {
        guard let jwtData = decodeToken() else {
            return "No workspace information available"
        }
        
        if jwtData.workspaceRoles.isEmpty {
            return "No workspace roles found"
        }
        
        var result = ""
        let sortedRoles = jwtData.workspaceRoles.sorted(by: { $0.key < $1.key })
        for (workspace, role) in sortedRoles {
            result += "• Workspace: \(workspace), Role: \(role.capitalized)\n"
        }
        
        return result
    }
    
    func getUserID() -> String {
        guard let tokenString = getAccessToken() else {
            return "-1"
        }
        
        do {
            let jwt = try decode(jwt: tokenString)
            
            let userIdClaim = jwt.claim(name: "user_id")
            if let idInt = userIdClaim.rawValue as? Int {
                return String(idInt)
            } else if let idString = userIdClaim.string {
                return idString
            }
        } catch {
            // Failed to decode JWT for user_id
            
            let parts = tokenString.components(separatedBy: ".")
            if parts.count >= 2 {
                let payloadBase64 = parts[1]
                if let payloadData = decodeBase64URLEncoded(payloadBase64),
                   let payloadString = String(data: payloadData, encoding: .utf8),
                   let jsonData = payloadString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                    if let userId = json["user_id"] {
                        return String(describing: userId)
                    }
                }
            }
        }
        
        return "-1"
    }
}
