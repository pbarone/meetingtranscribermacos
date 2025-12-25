//
//  LiveTranscriptionView.swift
//  meetingTrascriberMacOS
//
//  Created by Kiro on 12/24/25.
//

import SwiftUI

struct LiveTranscriptionView: View {
    @State private var selectedMicrophone: String = "Default Microphone"
    @State private var selectedSpeaker: String = "Default Speaker"
    @State private var sessionName: String = "2025-12-25-10-30-45-abc123"
    @State private var isRecording: Bool = false
    @State private var isPaused: Bool = false
    @State private var recordingTime: String = "00:00:00"
    @State private var connectionStatus: ConnectionStatus = .ready
    @State private var inputLevel: Double = 0.0
    @State private var outputLevel: Double = 0.0
    @State private var showTimestamps: Bool = true
    @State private var autoScroll: Bool = true
    @State private var partialTranscriptionResults: [TranscriptionItem] = []
    @State private var finalTranscriptionResults: [TranscriptionItem] = []
    @State private var isLoadingMeetings: Bool = false
    @State private var meetingCount: Int = 0
    @State private var showReconnectButton: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Live Transcription")
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text("Real-time audio capture and transcription with speaker diarization")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            
            Divider()
            
            // Main content area - Two columns
            HStack(spacing: 0) {
                // Left column - Controls
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Audio Device Selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Audio Device Selection")
                                .font(.headline)
                            
                            // Microphone selection
                            HStack(alignment: .center, spacing: 8) {
                                Text("Microphone")
                                    .font(.subheadline)
                                    .frame(width: 90, alignment: .leading)
                                
                                Picker("", selection: $selectedMicrophone) {
                                    Text("Default Microphone").tag("Default Microphone")
                                    Text("Echo Cancelling Speakerphone (Jabra Speak 710)").tag("Jabra")
                                }
                                .labelsHidden()
                                
                                Button(action: {
                                    // Refresh devices
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                }
                                .buttonStyle(.borderless)
                                .help("Refresh microphone devices")
                            }
                            
                            // Speaker selection
                            HStack(alignment: .center, spacing: 8) {
                                Text("Speakers")
                                    .font(.subheadline)
                                    .frame(width: 90, alignment: .leading)
                                
                                Picker("", selection: $selectedSpeaker) {
                                    Text("Default Speaker").tag("Default Speaker")
                                    Text("Echo Cancelling Speakerphone (Jabra Speak 710)").tag("Jabra Loopback")
                                }
                                .labelsHidden()
                                
                                Button(action: {
                                    // Refresh devices
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                }
                                .buttonStyle(.borderless)
                                .help("Refresh speaker devices")
                            }
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                        
                        // Recording Controls
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recording Controls")
                                .font(.headline)
                            
                            HStack(spacing: 8) {
                                Button(action: {
                                    if isRecording {
                                        isRecording = false
                                        isPaused = false
                                    } else {
                                        isRecording = true
                                        isPaused = false
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: isRecording ? "stop.fill" : "play.fill")
                                        Text(isRecording ? "Stop" : "Start")
                                    }
                                    .frame(minWidth: 100)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(isRecording ? .red : .blue)
                                .controlSize(.large)
                                
                                Button(action: {
                                    isPaused.toggle()
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                        Text(isPaused ? "Resume" : "Pause")
                                    }
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.large)
                                .disabled(!isRecording)
                                
                                if showReconnectButton {
                                    Button(action: {
                                        // Reconnect stream
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                            Text("Reconnect")
                                        }
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.large)
                                    .help("Retry stream reconnection")
                                }
                            }
                            
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(connectionStatus.color)
                                    .frame(width: 12, height: 12)
                                
                                Text(connectionStatus.displayText)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text(recordingTime)
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                        
                        // Audio Levels
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Audio Levels")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
                                HStack {
                                    Text("Mic:")
                                        .font(.subheadline)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    AudioLevelMeter(level: inputLevel, color: .blue)
                                    
                                    Text("\(Int(inputLevel * 100))%")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 40, alignment: .trailing)
                                        .monospacedDigit()
                                }
                                
                                HStack {
                                    Text("System:")
                                        .font(.subheadline)
                                        .frame(width: 60, alignment: .leading)
                                    
                                    AudioLevelMeter(level: outputLevel, color: .orange)
                                    
                                    Text("\(Int(outputLevel * 100))%")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 40, alignment: .trailing)
                                        .monospacedDigit()
                                }
                            }
                        }
                        .padding()
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(8)
                        
                        // Session Name Control
                        SessionNameControlView(
                            sessionName: $sessionName,
                            isLoadingMeetings: $isLoadingMeetings,
                            meetingCount: $meetingCount,
                            isRecording: isRecording
                        )
                    }
                    .padding()
                }
                .frame(width: 400)
                .background(Color(nsColor: .windowBackgroundColor))
                
                Divider()
                
                // Right column - Transcription
                VStack(spacing: 0) {
                    // Transcription header with options
                    HStack {
                        Text("Transcription")
                            .font(.headline)
                        
                        Spacer()
                        
                        Toggle(isOn: $showTimestamps) {
                            Text("Show Timestamps")
                                .font(.caption)
                        }
                        .toggleStyle(.checkbox)
                        
                        Toggle(isOn: $autoScroll) {
                            Text("Auto Scroll")
                                .font(.caption)
                        }
                        .toggleStyle(.checkbox)
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    
                    Divider()
                    
                    // Transcription content
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            // Partial results section (fixed height)
                            VStack(alignment: .leading, spacing: 8) {
                                if partialTranscriptionResults.isEmpty {
                                    Text("Partial results will appear here as you speak...")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .italic()
                                } else {
                                    ForEach(partialTranscriptionResults) { item in
                                        TranscriptionItemView(item: item, showTimestamp: showTimestamps)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .frame(height: 90)
                            .padding()
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                            .cornerRadius(8)
                            
                            // Final results section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Complete Transcription (Final Results)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.secondary)
                                
                                if finalTranscriptionResults.isEmpty {
                                    Text("Final transcription results will appear here...")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .italic()
                                } else {
                                    ForEach(finalTranscriptionResults) { item in
                                        TranscriptionItemView(item: item, showTimestamp: showTimestamps)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                            .cornerRadius(8)
                        }
                        .padding()
                    }
                }
            }
            
            Divider()
            
            // Status bar
            HStack {
                HStack(spacing: 8) {
                    Text("AWS:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(connectionStatus == .connected ? "Connected" : "Not Connected")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                Text(isRecording ? "Recording in progress" : "No active session")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Session Name Control

struct SessionNameControlView: View {
    @Binding var sessionName: String
    @Binding var isLoadingMeetings: Bool
    @Binding var meetingCount: Int
    let isRecording: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                Text("Session Name:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Text(sessionName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                
                Spacer()
                
                // Loading indicator
                if isLoadingMeetings {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.7)
                            .controlSize(.small)
                        
                        Text("retrieving current meetings list from calendar")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .italic()
                    }
                }
                
                // Multiple meetings badge
                if !isLoadingMeetings && meetingCount > 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption)
                        Text("\(meetingCount)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .foregroundStyle(.blue)
                    .cornerRadius(4)
                    .help("Multiple meetings available - click Edit to select")
                }
                
                // Edit button
                Button(action: {
                    // Edit session name
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "pencil")
                        Text("Edit Session Name")
                    }
                    .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(!isRecording)
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Supporting Views

struct AudioLevelMeter: View {
    let level: Double
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                    )
                
                // Level indicator
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.gradient)
                    .frame(width: geometry.size.width * level)
            }
        }
        .frame(height: 20)
    }
}

struct TranscriptionItemView: View {
    let item: TranscriptionItem
    let showTimestamp: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if showTimestamp {
                HStack(spacing: 8) {
                    // Speaker label with color
                    if let speaker = item.speakerLabel {
                        Text(speaker)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(item.speakerColor)
                            .cornerRadius(4)
                    }
                    
                    // Timestamp
                    if let timestamp = item.timestamp {
                        Text(timestamp)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    // Partial indicator
                    if item.isPartial {
                        Text("...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Transcription text
            Text(item.text)
                .font(.body)
                .textSelection(.enabled)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Models

enum ConnectionStatus {
    case connected
    case reconnecting
    case ready
    case offline
    
    var displayText: String {
        switch self {
        case .connected: return "Connected"
        case .reconnecting: return "Reconnecting..."
        case .ready: return "Ready"
        case .offline: return "Offline"
        }
    }
    
    var color: Color {
        switch self {
        case .connected: return .green
        case .reconnecting: return .orange
        case .ready: return .green
        case .offline: return .gray
        }
    }
}

struct TranscriptionItem: Identifiable {
    let id = UUID()
    let speakerLabel: String?
    let timestamp: String?
    let text: String
    let isPartial: Bool
    let speakerColor: Color
}

#Preview {
    LiveTranscriptionView()
}
