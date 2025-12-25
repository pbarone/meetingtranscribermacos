//
//  ContentView.swift
//  meetingTrascriberMacOS
//
//  Created by Paolo Barone on 12/24/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated: Bool = false
    @State private var userName: String = "Paolo Barone"
    @State private var userEmail: String = "pbarone@amazon.com"
    
    var body: some View {
        VStack(spacing: 0) {
            // Top bar with authentication
            HStack {
                // Tab buttons would go here (handled by TabView)
                Spacer()
                
                // Authentication area with fixed height
                HStack(spacing: 12) {
                    if isAuthenticated {
                        // User info
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(userName)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Text(userEmail)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(height: 32) // Fixed height
                        
                        // Logout button
                        Button(action: {
                            isAuthenticated = false
                        }) {
                            Text("Logout")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    } else {
                        // Login button with spacer to maintain width
                        Spacer()
                            .frame(height: 32) // Fixed height matching authenticated state
                        
                        Button(action: {
                            isAuthenticated = true
                        }) {
                            Label("Login", systemImage: "person.circle")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
                .frame(height: 40) // Fixed container height
                .padding(.trailing)
            }
            .frame(height: 48) // Fixed top bar height
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Tab view
            TabView {
                LiveTranscriptionView()
                    .tabItem {
                        Label("Live Transcription", systemImage: "waveform.circle.fill")
                    }
                
                BatchJobsView()
                    .tabItem {
                        Label("Batch Jobs", systemImage: "list.bullet.rectangle")
                    }
                
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
}

#Preview {
    ContentView()
}
