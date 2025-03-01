//
//  Harmony_HavenApp.swift
//  Harmony Haven
//
//  Created by Serhat Erdem on 27.02.2025.
//

import SwiftUI

@main
struct Harmony_HavenApp: App {
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some Scene {
        WindowGroup {
            AuthenticationContainerView()
                .environmentObject(authViewModel)
                .environmentObject(AppNavigationCoordinator())
        }
    }
}

// Container view to handle authentication state
struct AuthenticationContainerView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .onAppear {
            // Check if user is already authenticated
            authViewModel.checkAuthentication()
        }
    }
}
