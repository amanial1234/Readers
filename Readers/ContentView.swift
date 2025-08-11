//
//  ContentView.swift
//  Readers
//
//  Created by Aman Abraham on 8/11/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        Group {
            if appState.isAuthenticated {
                MainTabView()
            } else {
                LoginView(appState: appState)
            }
        }
        .environmentObject(appState)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            appState.refreshFavorites()
        }
    }
}

#Preview {
    ContentView()
}
