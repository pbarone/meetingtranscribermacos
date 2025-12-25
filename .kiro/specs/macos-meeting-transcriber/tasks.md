# Implementation Plan: macOS Meeting Transcriber

## Overview

This implementation plan breaks down the macOS Meeting Transcriber into incremental phases that can be developed, tested, and reviewed independently. Each phase builds upon the previous one, allowing for early feedback and troubleshooting.

## Tasks

### Phase 1: Mock UI and Project Setup

**Phase Guidelines:**
- Reuse existing app structure (meetingTrascriberMacOSApp.swift, ContentView.swift)
- Build and verify after each task - fix all errors and warnings
- Remove any placeholder/demo code that becomes obsolete

- [x] 1. Set up project dependencies and configuration
  - Reuse existing SwiftUI app structure (meetingTrascriberMacOSApp.swift, ContentView.swift)
  - Add AWS SDK for Swift package dependency
  - Configure project settings for macOS 15.0+ target
  - Set up required entitlements (microphone, screen recording, network)
  - Add Info.plist privacy descriptions
  - Build and verify no errors or warnings
  - _Requirements: 8.1, 8.2, 10.1_

- [x] 2. Create mock UI with navigation structure
  - [x] 2.1 Implement main window with tab navigation
    - Repurpose ContentView.swift to include TabView
    - Create TabView with Live Transcription, Batch Jobs, Session History, and Settings tabs
    - Add placeholder views for each tab
    - Build and fix any errors/warnings
    - _Requirements: 8.3_
  
  - [x] 2.2 Design Live Transcription view mock
    - Add recording controls (Start, Stop, Pause buttons)
    - Add session name input field
    - Add placeholder transcription display area with speaker labels
    - Add audio level meters (mock visualization)
    - Add connection status indicator
    - Build and fix any errors/warnings
    - _Requirements: 8.4, 8.9, 8.10, 8.12_
  
  - [x] 2.3 Design Batch Jobs view mock
    - refer to screeenshot in /Volumes/backup/Amazon/meetingtranscriber.net/screenshots/batch.png
    - Add job list with status indicators
    - Add action buttons (Retry, Open Transcript)
    - Add job details display
    - _Requirements: 8.5_
  
  - [x] 2.4 Design Settings view mock
    - refer to screeenshot in /Volumes/backup/Amazon/meetingtranscriber.net/screenshots/settings.png
    - Add audio device selection dropdowns (placeholder)
    - Add AWS configuration section (placeholder)
    - Add S3 configuration section (placeholder)
    - Add transcription settings (language, speaker diarization)
    - Add authentication status display
    - _Requirements: 8.7_

- [x] 3. Checkpoint - UI Review
  - Build and run the application
  - Verify all three tabs are accessible (Live Transcription, Batch Jobs, Settings)
  - Verify UI follows macOS Human Interface Guidelines
  - Get user feedback on layout and design

### Phase 2: Audio Device Selection

**Phase Guidelines:**
- Build and verify after each task - fix all errors and warnings
- Reuse models and services where possible
- Remove mock data as real implementations are added

- [x] 4. Implement audio device enumeration
  - [x] 4.1 Create AudioDevice model
    - Define AudioDevice struct with id, name, type, isDefault, isAvailable
    - Implement Identifiable and Codable conformance
    - _Requirements: 1.1, 1.2_
  
  - [x] 4.2 Create AudioDeviceManager service
    - Implement getInputDevices() using AVFoundation
    - Implement getOutputDevices() using ScreenCaptureKit
    - Handle device enumeration errors gracefully
    - _Requirements: 1.1, 1.2_
  
  - [x] 4.3 Implement default device identification
    - Mark default input device in enumeration
    - Mark default output device in enumeration
    - _Requirements: 1.5, 1.6_
  
  - [x] 4.4 Add device change notifications
    - Subscribe to AVCaptureDevice notifications for input devices
    - Subscribe to ScreenCaptureKit notifications for output devices
    - Update device list when devices connect/disconnect
    - _Requirements: 1.7_

- [ ] 5. Implement device selection UI
  - [ ] 5.1 Create device selection view model
    - Add @Published properties for device lists
    - Add @Published properties for selected devices
    - Implement device validation logic
    - _Requirements: 1.3, 1.4_
  
  - [ ] 5.2 Connect device dropdowns to real data
    - Populate input device dropdown with enumerated devices
    - Populate output device dropdown with enumerated devices
    - Highlight default devices
    - Show device availability status
    - _Requirements: 1.1, 1.2, 1.5, 1.6_
  
  - [ ] 5.3 Implement device selection persistence
    - Save selected device IDs to UserDefaults
    - Load saved device selections on app start
    - Validate saved devices are still available
    - _Requirements: 1.8_

- [ ] 6. Request audio permissions
  - [ ] 6.1 Implement microphone permission request
    - Request AVCaptureDevice audio permission
    - Handle permission granted/denied states
    - Display permission status in UI
    - _Requirements: 12.10_
  
  - [ ] 6.2 Implement screen recording permission request
    - Request screen recording permission for ScreenCaptureKit
    - Handle permission granted/denied states
    - Display permission status in UI
    - _Requirements: 12.10_

- [ ] 7. Checkpoint - Device Selection Testing
  - Build and run the application
  - Verify all audio devices are listed correctly
  - Verify device selection works
  - Verify permissions are requested properly
  - Test with different device configurations (USB headsets, Bluetooth, etc.)

### Phase 3: Audio Recording and Local Storage

**Phase Guidelines:**
- Build and verify after each task - fix all errors and warnings
- Replace mock audio level meters with real data
- Remove placeholder recording logic as real implementation is added

- [ ] 8. Implement audio capture service
  - [ ] 8.1 Create AudioFormat model
    - Define AudioFormat struct with sampleRate, bitsPerSample, channels
    - Implement isValidForTranscription() validation
    - _Requirements: 2.3, 2.4, 2.5_
  
  - [ ] 8.2 Create AudioCaptureService protocol and implementation
    - Define AudioCaptureServiceProtocol interface
    - Implement startCapture() using AVFoundation for microphone
    - Implement startCapture() using ScreenCaptureKit for system audio
    - Implement stopCapture() with proper resource cleanup
    - Implement pauseCapture() and resumeCapture()
    - _Requirements: 2.1, 2.2, 2.9, 2.10_
  
  - [ ] 8.3 Implement audio format conversion
    - Convert captured audio to PCM 16-bit signed little-endian
    - Resample audio to 16kHz
    - Convert stereo to mono
    - _Requirements: 2.3, 2.4, 2.5_
  
  - [ ] 8.4 Implement audio stream mixing
    - Create AVAudioMixerNode for combining streams
    - Mix microphone and system audio into single mono stream
    - Maintain audio synchronization
    - _Requirements: 2.6, 2.7_
  
  - [ ] 8.5 Add audio level calculation
    - Calculate RMS audio level from PCM data
    - Publish audio levels via Combine
    - _Requirements: 8.12_
  
  - [ ] 8.6 Implement error handling
    - Handle device unavailable errors
    - Handle permission denied errors
    - Handle format conversion errors
    - Log errors and notify user
    - _Requirements: 2.8, 9.1_

- [ ] 9. Implement session management
  - [ ] 9.1 Create RecordingSession model
    - Define RecordingSession struct with id, name, paths, dates, status
    - Implement Identifiable and Codable conformance
    - _Requirements: 3.1, 3.2_
  
  - [ ] 9.2 Create SessionManagementService
    - Implement createSession() with unique ID generation
    - Implement session directory creation with YYYY-MM-DD-HH-MM-Name format
    - Implement session name sanitization for filesystem
    - Support Unicode characters in session names
    - _Requirements: 3.1, 3.2, 3.9, 3.10_
  
  - [ ] 9.3 Implement session persistence
    - Save session metadata to JSON files
    - Load all sessions on app start
    - Implement getAllSessions() and getSession()
    - _Requirements: 7.6_

- [ ] 10. Implement audio file recording
  - [ ] 10.1 Create AudioFileManager service
    - Implement real-time WAV file writing
    - Write audio data as it's captured
    - Handle disk space errors
    - _Requirements: 3.3, 3.7_
  
  - [ ] 10.2 Implement WAV file finalization
    - Write proper WAV headers on recording completion
    - Validate file integrity after recording
    - _Requirements: 3.4, 3.8_
  
  - [ ] 10.3 Implement configurable storage location
    - Allow user to configure base directory
    - Create base directory if it doesn't exist
    - Save files in user-configured location
    - _Requirements: 3.5, 3.6_

- [ ] 11. Connect recording to UI
  - [ ] 11.1 Create recording view model
    - Add @Published properties for recording state
    - Implement start/stop/pause recording actions
    - Connect to AudioCaptureService
    - Connect to SessionManagementService
    - Connect to AudioFileManager
    - _Requirements: 8.9, 8.10_
  
  - [ ] 11.2 Update Live Transcription view
    - Connect Start Recording button to view model
    - Connect Stop Recording button to view model
    - Connect Pause Recording button to view model
    - Display recording status (idle, recording, paused)
    - Update audio level meters with real data
    - _Requirements: 8.9, 8.10, 8.12_
  
  - [ ] 11.3 Implement session naming UI
    - Add session name input field
    - Generate default timestamp-based name
    - Allow custom name entry
    - Validate and sanitize session names
    - _Requirements: 7.1, 7.2, 7.3_

- [ ] 12. Checkpoint - Recording Testing
  - Build and run the application
  - Start a recording and verify audio is captured
  - Verify WAV file is created and valid
  - Verify audio level meters work
  - Test pause/resume functionality
  - Test with different device combinations
  - Verify session directory structure is correct

### Phase 4: Live Transcription with AWS Transcribe

**Phase Guidelines:**
- Build and verify after each task - fix all errors and warnings
- Replace placeholder transcription display with real AWS data
- Remove mock connection status as real authentication is implemented

- [ ] 13. Implement AWS Cognito authentication
  - [ ] 13.1 Create CognitoConfiguration model
    - Define configuration struct with userPoolId, appClientId, domain, etc.
    - Load configuration from appsettings.json or UserDefaults
    - _Requirements: 10.2_
  
  - [ ] 13.2 Implement PKCE generator
    - Generate cryptographically secure code verifier
    - Generate SHA-256 code challenge
    - _Requirements: 6.13_
  
  - [ ] 13.3 Implement OAuth callback listener
    - Create localhost HTTP server on port 8080
    - Listen for OAuth callback with authorization code
    - Parse authorization code from callback URL
    - _Requirements: 6.2_
  
  - [ ] 13.4 Create CognitoAuthenticationService
    - Implement login() - open browser to Cognito hosted UI
    - Implement token exchange with authorization code
    - Implement logout() - clear all tokens
    - _Requirements: 6.1, 6.3, 6.11_
  
  - [ ] 13.5 Implement Keychain token storage
    - Create KeychainService for secure storage
    - Implement save/load/delete for tokens
    - Use Security framework with proper access controls
    - _Requirements: 6.4, 12.1_
  
  - [ ] 13.6 Implement AWS STS credential acquisition
    - Call AWS STS AssumeRoleWithWebIdentity with ID token
    - Parse temporary credentials (access key, secret key, session token)
    - Store credentials with expiration time
    - _Requirements: 6.5_
  
  - [ ] 13.7 Implement automatic credential refresh
    - Monitor credential expiration (check every 60 seconds)
    - Trigger refresh 5 minutes before expiry
    - Use refresh token to get new ID token
    - Call STS again for new temporary credentials
    - _Requirements: 6.7, 6.8_
  
  - [ ] 13.8 Implement session restoration
    - Load refresh token from Keychain on app start
    - Attempt to refresh session automatically
    - Handle invalid/expired refresh tokens
    - _Requirements: 6.9, 6.10_

- [ ] 14. Implement authentication UI
  - [ ] 14.1 Create authentication view model
    - Add @Published authentication state
    - Implement login/logout actions
    - Subscribe to authentication events
    - _Requirements: 8.9_
  
  - [ ] 14.2 Add login/logout UI to Settings
    - Add Login button when not authenticated
    - Add Logout button when authenticated
    - Display current user info when authenticated
    - Display authentication status
    - _Requirements: 8.9_
  
  - [ ] 14.3 Handle authentication errors
    - Display user-friendly error messages
    - Provide troubleshooting guidance
    - _Requirements: 9.10_

- [ ] 15. Implement streaming transcription service
  - [ ] 15.1 Create TranscriptionResult model
    - Define struct with text, isPartial, confidence, timestamps, speakerLabel
    - _Requirements: 4.3, 4.4, 4.5_
  
  - [ ] 15.2 Create StreamingTranscriptionService
    - Implement startStreaming() with AWS Transcribe Streaming client
    - Configure for PCM 16-bit, 16kHz, mono
    - Enable speaker diarization
    - Set language code from configuration
    - _Requirements: 4.1, 4.5_
  
  - [ ] 15.3 Implement audio streaming to AWS
    - Send audio chunks in 100ms intervals
    - Queue audio data for streaming
    - Handle backpressure and buffering
    - _Requirements: 4.2_
  
  - [ ] 15.4 Implement transcription result processing
    - Parse partial results from AWS
    - Parse final results from AWS
    - Extract speaker labels
    - Extract timestamps
    - _Requirements: 4.3, 4.4, 4.5_
  
  - [ ] 15.5 Implement credential updates
    - Update AWS client when credentials refresh
    - _Requirements: 6.6_
  
  - [ ] 15.6 Implement stream reconnection
    - Detect credential refresh during active stream
    - Cancel old stream gracefully (500ms delay)
    - Calculate timestamp offset for continuity
    - Retry reconnection with exponential backoff (1s, 2s, 4s)
    - Preserve timestamp continuity across reconnections
    - _Requirements: 4.7, 4.8, 4.10_
  
  - [ ] 15.7 Handle reconnection failures
    - Emit reconnection failed event after 3 attempts
    - Provide manual reconnect option in UI
    - _Requirements: 4.9_
  
  - [ ] 15.8 Implement offline mode
    - Allow recording without AWS credentials
    - Display offline status in UI
    - Continue recording audio locally
    - _Requirements: 4.11, 11.1, 11.2_
  
  - [ ] 15.9 Implement error handling
    - Handle network errors
    - Handle authentication errors
    - Handle AWS service errors
    - Log errors appropriately
    - Display user-friendly error messages
    - _Requirements: 4.6, 9.8, 9.9_

- [ ] 16. Connect live transcription to UI
  - [ ] 16.1 Create transcription view model
    - Add @Published transcription results list
    - Subscribe to partial result events
    - Subscribe to final result events
    - Subscribe to error events
    - Subscribe to reconnection events
    - _Requirements: 4.3, 4.4_
  
  - [ ] 16.2 Update Live Transcription view
    - Display transcription results in scrollable list
    - Show speaker labels with color coding
    - Show timestamps for each result
    - Replace partial results with final results
    - Auto-scroll to latest result
    - _Requirements: 4.3, 4.4, 4.5_
  
  - [ ] 16.3 Display connection status
    - Show "Connected" when streaming active
    - Show "Reconnecting..." during reconnection
    - Show "Offline" when no credentials
    - Show "Recording (offline)" when recording without AWS
    - _Requirements: 4.12, 11.8_
  
  - [ ] 16.4 Add manual reconnect button
    - Show button when reconnection fails
    - Trigger manual reconnection attempt
    - _Requirements: 4.9_
  
  - [ ] 16.5 Disable recording controls when not authenticated
    - Disable Start Recording when offline (optional)
    - Show authentication prompt
    - _Requirements: 8.11_

- [ ] 17. Checkpoint - Live Transcription Testing
  - Build and run the application
  - Authenticate with AWS Cognito
  - Start a recording with live transcription
  - Verify transcription appears in real-time
  - Verify speaker labels are displayed
  - Test credential refresh during recording
  - Test stream reconnection
  - Test offline recording mode
  - Verify audio file is still saved during transcription

### Phase 5: Batch Transcription

**Phase Guidelines:**
- Build and verify after each task - fix all errors and warnings
- Replace mock batch job data with real AWS job tracking
- Remove placeholder job status displays as real implementation is added

- [ ] 18. Implement S3 service
  - [ ] 18.1 Create S3Configuration model
    - Define configuration struct with bucketName, isEnabled, autoUpload, etc.
    - Load configuration from settings
    - _Requirements: 10.3_
  
  - [ ] 18.2 Create S3Service
    - Implement uploadAudioFile() with user-specific prefix
    - Implement downloadTranscriptionResult()
    - Implement deleteFile()
    - Use AWS SDK for Swift S3 client
    - _Requirements: 5.2, 12.7_
  
  - [ ] 18.3 Implement retry logic
    - Retry failed uploads with exponential backoff
    - Maximum 3 retry attempts
    - _Requirements: 9.4_
  
  - [ ] 18.4 Implement credential updates
    - Update S3 client when credentials refresh
    - _Requirements: 6.6_

- [ ] 19. Implement batch transcription service
  - [ ] 19.1 Create BatchTranscriptionJob model
    - Define struct with jobId, jobName, paths, status, dates, etc.
    - Implement Identifiable and Codable conformance
    - _Requirements: 5.1_
  
  - [ ] 19.2 Create BatchTranscriptionService
    - Implement submitTranscriptionJob()
    - Upload audio file to S3
    - Submit job to AWS Transcribe Batch
    - Configure language detection or specific language
    - Configure speaker diarization
    - _Requirements: 5.2, 5.3, 5.4, 5.5, 5.6_
  
  - [ ] 19.3 Implement job status polling
    - Poll AWS for job status every 30 seconds
    - Update job status in memory
    - Emit status change events
    - _Requirements: 5.7_
  
  - [ ] 19.4 Implement result retrieval
    - Download transcription result from S3 when complete
    - Parse JSON result
    - Extract transcription text
    - Extract speaker-labeled segments
    - Save formatted transcription to text file
    - _Requirements: 5.8, 5.9, 5.10_
  
  - [ ] 19.5 Implement job management
    - Implement getJobStatus()
    - Implement cancelJob()
    - Implement retryJob()
    - Implement getActiveJobs()
    - _Requirements: 5.12_
  
  - [ ] 19.6 Implement job persistence
    - Save job metadata to local database (SQLite or JSON)
    - Load pending jobs on app start
    - Resume monitoring for pending jobs
    - _Requirements: 5.1_
  
  - [ ] 19.7 Implement error handling
    - Handle upload failures
    - Handle job submission failures
    - Handle job processing failures
    - Display error messages to user
    - _Requirements: 5.11, 9.5_

- [ ] 20. Implement batch jobs UI
  - [ ] 20.1 Create batch jobs view model
    - Add @Published job list
    - Subscribe to job status events
    - Implement retry action
    - Implement open transcript action
    - _Requirements: 5.13_
  
  - [ ] 20.2 Update Batch Jobs view
    - Display job list with real data
    - Show job status (pending, processing, completed, failed)
    - Show progress indicators
    - Add Retry button for failed jobs
    - Add Open Transcript button for completed jobs
    - _Requirements: 5.13, 8.5_
  
  - [ ] 20.3 Add batch transcription option after recording
    - Show "Submit for Batch Transcription" option after recording stops
    - Submit job when user confirms
    - Navigate to Batch Jobs tab
    - _Requirements: 5.1_

- [ ] 21. Implement session history
  - [ ] 21.1 Create session history view model
    - Add @Published session list
    - Implement filtering by status
    - Implement filtering by date range
    - Implement search by name
    - _Requirements: 7.7, 7.9, 7.10_
  
  - [ ] 21.2 Update Session History view
    - Display session list with real data
    - Add status filter dropdown
    - Add date range picker
    - Add search bar
    - Add Open Audio button
    - Add Open Transcript button
    - _Requirements: 7.8, 8.6_
  
  - [ ] 21.3 Implement session rename
    - Add rename button/action
    - Show rename dialog
    - Rename session directory and files
    - Update session metadata
    - _Requirements: 7.4, 7.5_

- [ ] 22. Checkpoint - Batch Transcription Testing
  - Build and run the application
  - Complete a recording
  - Submit for batch transcription
  - Verify job appears in Batch Jobs tab
  - Verify job status updates
  - Wait for job completion
  - Verify transcription file is downloaded and saved
  - Open transcription file and verify content
  - Test retry for failed jobs
  - Test session history filtering and search

### Phase 6: Configuration and Polish

**Phase Guidelines:**
- Build and verify after each task - fix all errors and warnings
- Remove any remaining mock/placeholder code
- Ensure all features are fully integrated and working

- [ ] 23. Implement configuration management
  - [ ] 23.1 Create AppConfiguration model
    - Define comprehensive configuration struct
    - Include Cognito, S3, Transcription, Storage settings
    - _Requirements: 10.1_
  
  - [ ] 23.2 Implement configuration persistence
    - Save configuration to UserDefaults or JSON file
    - Load configuration on app start
    - Provide default values for all settings
    - _Requirements: 10.1, 10.11_
  
  - [ ] 23.3 Implement configuration validation
    - Validate bucket names, regions, etc.
    - Display validation errors
    - Prevent saving invalid configuration
    - _Requirements: 10.9, 10.10_
  
  - [ ] 23.4 Implement configuration export/import
    - Export configuration to JSON file
    - Import configuration from JSON file
    - _Requirements: 10.12_

- [ ] 24. Complete Settings UI
  - [ ] 24.1 Connect AWS configuration fields
    - Add text fields for Cognito settings
    - Add text fields for S3 settings
    - Save/load from configuration
    - _Requirements: 10.2, 10.3_
  
  - [ ] 24.2 Connect transcription settings
    - Add language selection dropdown
    - Add automatic language detection toggle
    - Add speaker diarization toggle
    - Add max speaker labels slider
    - _Requirements: 10.4, 10.5, 10.6, 10.7_
  
  - [ ] 24.3 Connect storage settings
    - Add directory picker for base directory
    - Display current storage location
    - _Requirements: 10.8_

- [ ] 25. Implement error handling and logging
  - [ ] 25.1 Set up structured logging
    - Use os.log for structured logging
    - Create log categories (audio, auth, transcription, etc.)
    - Log to ~/Library/Logs/MeetingTranscriber/
    - _Requirements: 9.8_
  
  - [ ] 25.2 Implement error message formatting
    - Redact credentials from error messages
    - Provide user-friendly error descriptions
    - Add troubleshooting guidance
    - _Requirements: 9.9, 12.2_
  
  - [ ] 25.3 Implement error recovery
    - Handle device disconnection during recording
    - Handle network loss during streaming
    - Handle disk space errors
    - _Requirements: 9.1, 9.2, 9.7_

- [ ] 26. Final polish and testing
  - [ ] 26.1 Implement app icon and branding
    - Add app icon
    - Add launch screen
    - Polish UI colors and styling
  
  - [ ] 26.2 Add keyboard shortcuts
    - Cmd+R for Start/Stop Recording
    - Cmd+P for Pause/Resume
    - Cmd+, for Settings
  
  - [ ] 26.3 Implement window state persistence
    - Save window size and position
    - Save selected tab
    - Restore on app launch
  
  - [ ] 26.4 Add tooltips and help text
    - Add tooltips to buttons and controls
    - Add help text for configuration fields
  
  - [ ] 26.5 Performance optimization
    - Optimize audio processing
    - Optimize UI updates
    - Reduce memory usage

- [ ] 27. Final Checkpoint - Complete Application Testing
  - Build and run the complete application
  - Test full workflow: authenticate → select devices → record → transcribe live → submit batch → view results
  - Test all error scenarios
  - Test with different audio devices
  - Test with different AWS configurations
  - Test offline mode
  - Test credential refresh during long recordings
  - Verify all files are saved correctly
  - Verify all UI elements work as expected
  - Get final user approval

## Notes

- **Code Reuse**: Always reuse and repurpose existing code. Minimize clutter in the codebase.
- **Build Verification**: At the end of each task, build the app and fix any errors and warnings before marking complete.
- **Dead Code Removal**: If any code becomes useless or obsolete, remove it immediately. Keep the codebase clean.
- Each checkpoint is a natural break point for review and feedback
- Tasks are ordered to build incrementally on previous work
- Early phases focus on visible progress (UI, audio) before complex AWS integration
- Testing is integrated throughout rather than saved for the end
- Optional tasks are not marked with `*` as all tasks are essential for the MVP
- Property-based tests will be added in a future enhancement phase
