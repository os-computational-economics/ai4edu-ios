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

// JWT token payload structure - can be expanded based on your specific JWT structure
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
    
    // Format payload as readable text
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
    
    // Format time interval for better readability
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
    
    // Decode JWT token using Auth0 JWTDecode package
    func decodeToken() -> JWTData? {
        guard let tokenString = getAccessToken() else {
            print("DEBUG: No access token found")
            return nil
        }
        
        print("DEBUG: Starting JWT decoding process...")
        
        do {
            // Step 1: Decode the JWT token
            print("DEBUG: Step 1 - Decoding JWT token")
            let jwt = try decode(jwt: tokenString)
            print("DEBUG: Token successfully decoded")
            
            // Step 2: Extract and print all claims
            print("DEBUG: Step 2 - Available claims:")
            print("DEBUG: Header claims: \(jwt.header)")
            print("DEBUG: Body claims: \(jwt.body)")
            
            // Step 3: Extract user data
            print("DEBUG: Step 3 - Extracting user data")
            
            // Extract user ID - could be integer or string
            var userId: String = "0"
            let userIdClaim = jwt.claim(name: "user_id")
            if let idInt = userIdClaim.rawValue as? Int {
                userId = String(idInt)
                print("DEBUG: User ID (int): \(idInt)")
            } else if let idString = userIdClaim.string {
                userId = idString
                print("DEBUG: User ID (string): \(idString)")
            } else {
                print("DEBUG: Unable to extract user_id, using default: 0")
            }
            let subject = "user:\(userId)"
            
            // Extract additional user information
            let firstName = jwt.claim(name: "first_name").string ?? "Unknown"
            let lastName = jwt.claim(name: "last_name").string ?? "Unknown"
            let email = jwt.claim(name: "email").string ?? ""
            let studentId = jwt.claim(name: "student_id").string ?? ""
            
            // Extract system admin status
            let systemAdminClaim = jwt.claim(name: "system_admin")
            var isSystemAdmin = false
            
            if let adminInt = systemAdminClaim.rawValue as? Int {
                isSystemAdmin = adminInt == 1
                print("DEBUG: System admin (int): \(adminInt)")
            } else if let adminBool = systemAdminClaim.rawValue as? Bool {
                isSystemAdmin = adminBool
                print("DEBUG: System admin (bool): \(adminBool)")
            } else if let adminString = systemAdminClaim.string?.lowercased() {
                isSystemAdmin = adminString == "true" || adminString == "1" || adminString == "yes"
                print("DEBUG: System admin (string): \(adminString)")
            }
            
            print("DEBUG: User data extracted - \(firstName) \(lastName), Admin: \(isSystemAdmin)")
            
            // Step 4: Extract dates
            print("DEBUG: Step 4 - Extracting dates")
            let expiresAt: Date
            if let exp = jwt.expiresAt {
                print("DEBUG: Expiration date found: \(exp)")
                expiresAt = exp
            } else if let expValue = jwt.claim(name: "exp").rawValue as? TimeInterval {
                expiresAt = Date(timeIntervalSince1970: expValue)
                print("DEBUG: Created expiration date from raw value: \(expiresAt)")
            } else {
                expiresAt = Date().addingTimeInterval(3600) // Default 1 hour
                print("DEBUG: Using default expiration date: \(expiresAt)")
            }
            
            let issuedAt: Date
            if let iat = jwt.issuedAt {
                print("DEBUG: Issued at date found: \(iat)")
                issuedAt = iat
            } else if let iatValue = jwt.claim(name: "iat").rawValue as? TimeInterval {
                issuedAt = Date(timeIntervalSince1970: iatValue)
                print("DEBUG: Created issued at date from raw value: \(issuedAt)")
            } else {
                issuedAt = Date() // Default to now
                print("DEBUG: Using default issued at date: \(issuedAt)")
            }
            
            // Step 5: Extract workspace roles
            print("DEBUG: Step 5 - Extracting workspace roles")
            var workspaceRoles: [String: String] = [:]
            
            // Try to get the claim as a dictionary
            let rolesClaim = jwt.claim(name: "workspace_role")
            print("DEBUG: Raw workspace_role claim: \(rolesClaim.rawValue)")
            
            if let rolesDict = rolesClaim.rawValue as? [String: String] {
                print("DEBUG: Successfully cast workspace_role to [String: String]")
                workspaceRoles = rolesDict
            } else if let rolesObject = rolesClaim.rawValue {
                // Handle Dictionary representation that might come in different formats
                print("DEBUG: workspace_role is type: \(type(of: rolesObject))")
                
                // Try to convert from JSON if needed
                if let rolesData = try? JSONSerialization.data(withJSONObject: rolesObject, options: []),
                   let rolesDict = try? JSONSerialization.jsonObject(with: rolesData, options: []) as? [String: String] {
                    print("DEBUG: Converted workspace_role via JSON serialization")
                    workspaceRoles = rolesDict
                } else if let rolesDict = rolesObject as? [String: Any] {
                    print("DEBUG: workspace_role is [String: Any], attempting to convert")
                    for (key, value) in rolesDict {
                        if let stringValue = value as? String {
                            workspaceRoles[key] = stringValue
                        } else {
                            print("DEBUG: Non-string value found for key \(key): \(value)")
                            workspaceRoles[key] = String(describing: value)
                        }
                    }
                }
            }
            
            print("DEBUG: Final workspace roles: \(workspaceRoles)")
            
            // Step 6: Create and return JWTData
            print("DEBUG: Step 6 - Creating JWTData")
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
            print("DEBUG: JWTData created successfully")
            return jwtData
            
        } catch {
            print("DEBUG: Failed to decode JWT: \(error)")
            
            // Try to print token parts for debugging
            print("DEBUG: Attempting to inspect token parts")
            let parts = tokenString.components(separatedBy: ".")
            print("DEBUG: Token has \(parts.count) parts")
            
            if parts.count >= 2 {
                let headerBase64 = parts[0]
                let payloadBase64 = parts[1]
                
                // Try to decode manually for debugging
                if let payloadData = decodeBase64URLEncoded(payloadBase64),
                   let payloadString = String(data: payloadData, encoding: .utf8) {
                    print("DEBUG: Decoded payload: \(payloadString)")
                    
                    // Try to parse as JSON
                    if let jsonData = payloadString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any] {
                        
                        // Create a basic JWTData from manually parsed JSON
                        let userId = json["user_id"] as? String ?? String(describing: json["user_id"] ?? "0")
                        let firstName = json["first_name"] as? String ?? "Unknown"
                        let lastName = json["last_name"] as? String ?? "Unknown"
                        let email = json["email"] as? String ?? ""
                        let studentId = json["student_id"] as? String ?? ""
                        
                        // Handle system_admin which could be in different formats
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
                        
                        // Handle dates
                        let exp = (json["exp"] as? TimeInterval) ?? 0
                        let iat = (json["iat"] as? TimeInterval) ?? 0
                        let expiresAt = Date(timeIntervalSince1970: exp)
                        let issuedAt = Date(timeIntervalSince1970: iat)
                        
                        // Handle workspace roles
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
    
    // Helper function to decode Base64URL encoded string
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
    
    // Decode JWT token to get workspace roles
    func getWorkspaceRoles() -> [String: String] {
        guard let tokenString = getAccessToken() else {
            print("DEBUG: No access token found for workspace roles")
            return [:]
        }
        
        print("DEBUG: Getting workspace roles from token")
        
        do {
            let jwt = try decode(jwt: tokenString)
            let rolesClaim = jwt.claim(name: "workspace_role")
            print("DEBUG: Workspace roles raw value: \(rolesClaim.rawValue)")
            print("DEBUG: Workspace roles raw value type: \(type(of: rolesClaim.rawValue))")
            
            if let rolesDict = rolesClaim.rawValue as? [String: String] {
                print("DEBUG: Successfully cast to [String: String]: \(rolesDict)")
                return rolesDict
            } else if let rolesDict = rolesClaim.rawValue as? [String: Any] {
                print("DEBUG: Workspace roles is [String: Any], attempting to convert")
                var convertedRoles: [String: String] = [:]
                for (key, value) in rolesDict {
                    if let stringValue = value as? String {
                        convertedRoles[key] = stringValue
                    } else {
                        print("DEBUG: Non-string value found for key \(key): \(value)")
                        convertedRoles[key] = String(describing: value)
                    }
                }
                print("DEBUG: Converted workspace roles: \(convertedRoles)")
                return convertedRoles
            } else {
                print("DEBUG: Failed to extract workspace_role")
                return [:]
            }
        } catch {
            print("DEBUG: Failed to decode workspace roles: \(error)")
            return [:]
        }
    }
    
    // Debug print token with all information
    func debugPrintToken() {
        print("\n=== JWT TOKEN DEBUG INFO ===")
        
        guard let token = getAccessToken() else {
            print("No access token found.")
            return
        }
        
        print("Token length: \(token.count) characters")
        
        guard let decoded = decodeToken() else {
            print("Failed to decode token.")
            return
        }
        
        print("\nUSER INFO:")
        print("  Subject: \(decoded.subject)")
        print("  Name: \(decoded.firstName) \(decoded.lastName)")
        if !decoded.email.isEmpty {
            print("  Email: \(decoded.email)")
        }
        if !decoded.studentId.isEmpty {
            print("  Student ID: \(decoded.studentId)")
        }
        print("  System Admin: \(decoded.isSystemAdmin ? "Yes" : "No")")
        
        print("\nTIME INFO:")
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .medium
        
        print("  Issued: \(dateFormatter.string(from: decoded.issuedAt))")
        print("  Expires: \(dateFormatter.string(from: decoded.expiresAt))")
        
        let now = Date()
        if now > decoded.expiresAt {
            print("  Status: EXPIRED (token expired \(formatTimeInterval(now.timeIntervalSince(decoded.expiresAt))) ago)")
        } else {
            print("  Status: VALID (expires in \(formatTimeInterval(decoded.expiresAt.timeIntervalSince(now))))")
        }
        
        print("\nWORKSPACE ROLES:")
        if decoded.workspaceRoles.isEmpty {
            print("  No workspace roles found")
        } else {
            for (workspace, role) in decoded.workspaceRoles.sorted(by: { $0.key < $1.key }) {
                print("  Workspace: \(workspace), Role: \(role.capitalized)")
            }
        }
        
        print("\n==========================\n")
    }
    
    // Helper to format time intervals for better readability
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
    
    // Get formatted workspace roles for display
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
}
