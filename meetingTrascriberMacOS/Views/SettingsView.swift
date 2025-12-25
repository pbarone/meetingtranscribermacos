//
//  SettingsView.swift
//  meetingTrascriberMacOS
//
//  Created by Kiro on 12/24/25.
//

import SwiftUI

struct SettingsView: View {
    // Authentication Status
    @State private var isAuthenticated: Bool = true
    @State private var tokenExpiration: String = "Valid"
    @State private var credentialExpiration: String = "2025-12-24 19:39:42"
    
    // AWS Configuration
    @State private var awsRegion: String = "us-east-1"
    @State private var enableAutoLanguageDetection: Bool = true
    @State private var defaultLanguage: String = "en-US"
    @State private var enableSpeakerDiarization: Bool = false
    @State private var maxSpeakerLabels: Double = 10
    @State private var chunkSize: Double = 125
    
    // Storage Settings
    @State private var storageLocation: String = "C:\\Users\\paobar\\Documents\\AudioTranscriptionApp\\paobar\\Audio"
    
    private let awsRegions = [
        "us-east-1": "US East 1 (N. Virginia)",
        "us-east-2": "US East 2 (Ohio)",
        "us-west-1": "US West 1 (N. California)",
        "us-west-2": "US West 2 (Oregon)",
        "eu-west-1": "Europe (Ireland)",
        "eu-central-1": "Europe (Frankfurt)",
        "ap-southeast-1": "Asia Pacific (Singapore)",
        "ap-northeast-1": "Asia Pacific (Tokyo)"
    ]
    
    private let availableLanguages = [
        "en-US": "English (US)",
        "en-GB": "English (UK)",
        "es-ES": "Spanish (Spain)",
        "es-US": "Spanish (US)",
        "fr-FR": "French",
        "de-DE": "German",
        "it-IT": "Italian",
        "pt-BR": "Portuguese (Brazil)",
        "ja-JP": "Japanese",
        "ko-KR": "Korean",
        "zh-CN": "Chinese (Simplified)"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Application Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Configure AWS, storage, and application preferences")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Main content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // AWS Configuration Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("AWS Configuration")
                            .font(.headline)
                        
                        // Status
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Status:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 160, alignment: .leading)
                                
                                Text(isAuthenticated ? "Authenticated" : "Not Authenticated")
                                    .font(.subheadline)
                                    .foregroundStyle(isAuthenticated ? .green : .secondary)
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Token Expiration:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 160, alignment: .leading)
                                
                                Text(tokenExpiration)
                                    .font(.subheadline)
                                    .foregroundStyle(.green)
                            }
                            
                            HStack {
                                Text("Credential Expiration:")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 160, alignment: .leading)
                                
                                Text(credentialExpiration)
                                    .font(.subheadline)
                                    .foregroundStyle(.green)
                            }
                        }
                        
                        // Action buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                // Re-authenticate action
                            }) {
                                Label("Re-authenticate", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.borderedProminent)
                            
                            Button(action: {
                                // Force refresh action
                            }) {
                                Label("Force Refresh", systemImage: "arrow.triangle.2.circlepath")
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                // Logout action
                            }) {
                                Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Divider()
                        
                        // AWS Region
                        HStack {
                            Text("AWS Region")
                                .font(.subheadline)
                                .frame(width: 160, alignment: .leading)
                            
                            Picker("", selection: $awsRegion) {
                                ForEach(Array(awsRegions.keys.sorted()), id: \.self) { key in
                                    Text(awsRegions[key] ?? key).tag(key)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                        }
                        
                        // Enable automatic language detection
                        Toggle(isOn: $enableAutoLanguageDetection) {
                            Text("Enable automatic language detection")
                                .font(.subheadline)
                        }
                        
                        // Default Language (disabled when auto-detection is on)
                        HStack {
                            Text("Default Language")
                                .font(.subheadline)
                                .foregroundStyle(enableAutoLanguageDetection ? .tertiary : .primary)
                                .frame(width: 160, alignment: .leading)
                            
                            Picker("", selection: $defaultLanguage) {
                                ForEach(Array(availableLanguages.keys.sorted()), id: \.self) { key in
                                    Text(availableLanguages[key] ?? key).tag(key)
                                }
                            }
                            .labelsHidden()
                            .frame(maxWidth: .infinity)
                            .disabled(enableAutoLanguageDetection)
                        }
                        
                        // Enable speaker identification
                        Toggle(isOn: $enableSpeakerDiarization) {
                            Text("Enable speaker identification")
                                .font(.subheadline)
                        }
                        
                        // Max Speakers slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Max Speakers")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(Int(maxSpeakerLabels))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            
                            Slider(value: $maxSpeakerLabels, in: 2...10, step: 1)
                        }
                        
                        // Chunk Size slider
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Chunk Size")
                                    .font(.subheadline)
                                
                                Spacer()
                                
                                Text("\(Int(chunkSize)) ms")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                            
                            Slider(value: $chunkSize, in: 50...200, step: 25)
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // File Storage Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("File Storage")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Storage location")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                TextField("", text: $storageLocation)
                                    .textFieldStyle(.plain)
                                    .padding(8)
                                    .background(Color(nsColor: .textBackgroundColor))
                                    .cornerRadius(4)
                                    .disabled(true)
                                
                                Button(action: {
                                    // Browse for folder
                                }) {
                                    Image(systemName: "folder")
                                }
                                .buttonStyle(.bordered)
                            }
                            
                            Button("Reset to Default") {
                                // Reset to default location
                            }
                            .buttonStyle(.link)
                            .controlSize(.small)
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // Save button
                    HStack {
                        Spacer()
                        
                        Button("Save Settings") {
                            // Save settings action
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    SettingsView()
        .frame(width: 900, height: 700)
}
