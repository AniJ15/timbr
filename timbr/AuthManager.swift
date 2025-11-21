//
//  AuthManager.swift
//  timbr
//
//  Created by Ani Jain on 11/15/25.
//

import Foundation
import Combine
import FirebaseCore
import FirebaseAuth
import GoogleSignIn
import UIKit

@MainActor
class AuthManager: ObservableObject {
    @Published var isSignedIn = false
    @Published var user: User?
    @Published var errorMessage: String?
    
    init() {
        // Check if user is already signed in
        if let currentUser = Auth.auth().currentUser {
            self.user = currentUser
            self.isSignedIn = true
        }
    }
    
    func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            errorMessage = "Firebase configuration error"
            return
        }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            errorMessage = "Could not find root view controller"
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get ID token"
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                         accessToken: result.user.accessToken.tokenString)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            self.user = authResult.user
            self.isSignedIn = true
            self.errorMessage = nil
            
            print("✅ Successfully signed in: \(authResult.user.email ?? "No email")")
            
        } catch {
            self.errorMessage = error.localizedDescription
            print("❌ Sign in error: \(error.localizedDescription)")
        }
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            GIDSignIn.sharedInstance.signOut()
            self.isSignedIn = false
            self.user = nil
            self.errorMessage = nil
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}

