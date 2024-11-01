//
//  AuthService.swift
//  ios-app
//
//  Created by aristarh on 25.10.2024.
//

import Foundation
import Dependencies
import KeychainAccess
import Combine

// MARK: - Protocol

public protocol IAuthService {
    
    var isLoggedInPublisher: CurrentValueSubject<Bool, Never> { get set }
    
    func register(user: User.Parameters.Create) async throws -> User.Responses.Full
    
    func auth(user: User.Parameters.Retrieve) async throws -> Token
    
    func logout()
}

// MARK: - Dependency Values

public extension DependencyValues {
    
    var authService: any IAuthService {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
    
    enum AuthServiceKey: DependencyKey {
        public static let liveValue: IAuthService = AuthService()
    }
}

// MARK: - Live

struct AuthService: IAuthService {
    
    var isLoggedInPublisher = CurrentValueSubject<Bool, Never>(false)
    
    // MARK: - Dependencies
    
    @Dependency(\.requestsService) var requestsService
    @Dependency(\.coderService) var coderService
    @Dependency(\.secureStorageService) var secureStorageService
    
    // MARK: - Methods
    
    func register(user: User.Parameters.Create) async throws -> User.Responses.Full {
        
        let response = try await requestsService
            .request(
                path: "/register",
                method: .post,
                parameters: user,
                requestType: .session
            )
            .serializingDecodable(User.Responses.Full.self, decoder: coderService.decoder)
            .value
        
        return response
    }
    
    func auth(user: User.Parameters.Retrieve) async throws -> Token {
        
        let response = try await requestsService
            .request(
                path: "/token-json",
                method: .post,
                parameters: user,
                requestType: .session
            )
            .serializingDecodable(Token.self, decoder: coderService.decoder)
            .value
        
        UserDefaults().set(response.accessToken, forKey: "token")
        secureStorageService.isLoggedInPublisher.send(true)
        
//        secureStorageService.setAccess(token: response)
        isLoggedInPublisher.send(true)
        
        return response
    }
    
    func logout() {
        UserDefaults().set(nil, forKey: "token")
        UserDefaults().removeObject(forKey: "token")
//        secureStorageService.setAccess(token: nil)
        isLoggedInPublisher.send(false)
    }
}
