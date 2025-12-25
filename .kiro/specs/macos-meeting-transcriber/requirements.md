# Requirements Document

## Introduction

This document specifies the requirements for a macOS native application that replicates the functionality of the existing Windows Meeting Transcriber application. The macOS version will provide real-time audio transcription using AWS Transcribe Streaming, capture audio from both microphone and system audio simultaneously, and support batch transcription with speaker diarization.

**Implementation Guidelines:**
- The Windows implementation (located at `meetingtranscriber.net/`) serves as the functional reference and architectural guideline
- All macOS implementations MUST use native macOS frameworks and follow Apple's latest standards and best practices
- Research MUST be conducted using Apple documentation, Tavily web search, and Context7 library documentation to ensure modern, idiomatic Swift and macOS development patterns
- The design phase will identify macOS-specific equivalents for Windows technologies (e.g., CoreAudio/AVFoundation instead of WASAPI, Keychain instead of Windows Credential Manager)

## Glossary

- **System**: The macOS Meeting Transcriber application
- **Audio_Capture_Service**: Service responsible for capturing audio from input and output devices
- **Streaming_Transcription_Service**: Service that provides real-time transcription via AWS Transcribe Streaming
- **Batch_Transcription_Service**: Service that provides high-quality offline transcription via AWS Transcribe Batch
- **Authentication_Service**: Service that handles AWS Cognito authentication with OAuth 2.0 and PKCE
- **Audio_Device**: A physical or virtual audio input/output device on macOS
- **Session**: A recording session with associated audio files and transcription data
- **Speaker_Diarization**: The process of identifying and labeling different speakers in audio
- **ScreenCaptureKit**: macOS framework for capturing screen content and system audio (macOS 13+)
- **AVFoundation**: macOS framework for audio/video capture and processing
- **S3_Service**: Service for uploading and downloading files to/from AWS S3
- **Credential_Manager**: Service for securely storing authentication tokens (Keychain on macOS)
- **Calendar_Service**: Service for querying macOS Calendar app for meeting information
- **Meeting_Info**: Data structure containing meeting details (subject, time, participants)
- **Session_History_Service**: Service for managing and querying past recording sessions

## Requirements

### Requirement 1: Audio Device Management

**User Story:** As a user, I want to select audio input and output devices, so that I can capture audio from my microphone and system audio simultaneously.

#### Acceptance Criteria

1. WHEN the application starts, THE System SHALL enumerate all available audio input devices using AVFoundation
2. WHEN the application starts, THE System SHALL enumerate all available audio output devices using ScreenCaptureKit
3. WHEN a user selects an input device, THE System SHALL validate that the device is available and accessible
4. WHEN a user selects an output device, THE System SHALL validate that the device is available and accessible
5. THE System SHALL identify and mark the default input device
6. THE System SHALL identify and mark the default output device
7. WHEN audio devices change (connected/disconnected), THE System SHALL update the device list
8. THE System SHALL persist the user's device selections across application restarts

### Requirement 2: Dual Audio Capture

**User Story:** As a user, I want to record audio from both my microphone and system audio on separate channels, so that I can capture both my voice and the audio from video conferencing applications.

#### Acceptance Criteria

1. WHEN a recording starts, THE System SHALL capture audio from the selected input device (microphone) using AVFoundation
2. WHEN a recording starts, THE System SHALL capture audio from the selected output device (system audio/loopback) using ScreenCaptureKit
3. THE System SHALL convert captured audio to PCM 16-bit signed little-endian format
4. THE System SHALL resample captured audio to 16kHz sample rate
5. THE System SHALL convert captured audio to mono (1 channel)
6. WHEN audio is captured from both devices, THE System SHALL mix the two audio streams into a single mono stream
7. THE System SHALL maintain audio synchronization between input and output streams
8. WHEN audio capture encounters an error, THE System SHALL log the error and notify the user
9. THE System SHALL support pausing and resuming audio capture
10. WHEN audio capture is stopped, THE System SHALL properly release all audio device resources

### Requirement 3: Local Audio File Storage

**User Story:** As a user, I want my recordings saved to local files, so that I have a permanent record of my meetings even if cloud services are unavailable.

#### Acceptance Criteria

1. WHEN a recording session starts, THE System SHALL create a unique session identifier
2. WHEN a recording session starts, THE System SHALL create a session directory with format "YYYY-MM-DD-HH-MM-SessionName"
3. WHEN audio data is captured, THE System SHALL write it to a WAV file in real-time
4. WHEN a recording session completes, THE System SHALL save the final WAV file with proper WAV headers
5. THE System SHALL save audio files in a user-configurable base directory
6. THE System SHALL create the base directory if it does not exist
7. WHEN disk space is insufficient, THE System SHALL notify the user and stop recording
8. THE System SHALL validate that audio files are not corrupted after recording completes
9. WHEN a session name contains invalid filesystem characters, THE System SHALL sanitize the name
10. THE System SHALL support session names with Unicode characters

### Requirement 4: Real-Time Streaming Transcription

**User Story:** As a user, I want to see live transcription of my meeting as it happens, so that I can follow along and verify the transcription quality in real-time.

#### Acceptance Criteria

1. WHEN a user has valid AWS credentials, THE System SHALL establish a connection to AWS Transcribe Streaming
2. WHEN audio is captured, THE System SHALL send audio chunks to AWS Transcribe Streaming in 100ms intervals
3. WHEN AWS returns partial transcription results, THE System SHALL display them in the UI
4. WHEN AWS returns final transcription results, THE System SHALL replace partial results with final results
5. WHEN speaker diarization is enabled, THE System SHALL display speaker labels with transcription results
6. WHEN streaming transcription encounters an error, THE System SHALL log the error and display it to the user
7. THE System SHALL support automatic reconnection when AWS credentials are refreshed
8. WHEN credentials are refreshed during an active stream, THE System SHALL reconnect the stream with new credentials
9. WHEN stream reconnection fails after 3 attempts, THE System SHALL display a manual reconnect option
10. THE System SHALL preserve timestamp continuity across stream reconnections
11. WHEN AWS credentials are not available, THE System SHALL allow recording to continue without transcription
12. THE System SHALL display connection status (connected, reconnecting, offline) in the UI

### Requirement 5: Batch Transcription Processing

**User Story:** As a user, I want to submit completed recordings for high-quality batch transcription, so that I can get more accurate transcriptions with automatic language detection.

#### Acceptance Criteria

1. WHEN a recording session completes, THE System SHALL offer the option to submit for batch transcription
2. WHEN batch transcription is requested, THE System SHALL upload the audio file to S3 with user-specific prefix
3. WHEN the audio file is uploaded, THE System SHALL submit a transcription job to AWS Transcribe Batch
4. WHEN automatic language detection is enabled, THE System SHALL configure the job for language identification
5. WHEN automatic language detection is disabled, THE System SHALL use the configured default language
6. WHEN speaker diarization is enabled, THE System SHALL configure the job with speaker labels
7. THE System SHALL poll AWS for job status every 30 seconds
8. WHEN a batch job completes, THE System SHALL download the transcription result from S3
9. WHEN a batch job completes, THE System SHALL parse the JSON result and extract transcription text
10. WHEN a batch job completes, THE System SHALL save the formatted transcription to a text file
11. WHEN a batch job fails, THE System SHALL display the error message to the user
12. THE System SHALL support retrying failed batch jobs
13. THE System SHALL display batch job status (pending, processing, completed, failed) in the UI
14. THE System SHALL support selecting multiple jobs via checkboxes
15. WHEN jobs are selected, THE System SHALL enable "Remove from List" and "Delete Permanently" actions
16. WHEN "Remove from List" is clicked, THE System SHALL remove selected jobs from the UI without deleting files
17. WHEN "Delete Permanently" is clicked, THE System SHALL delete selected jobs and their associated files after confirmation

### Requirement 6: AWS Cognito Authentication

**User Story:** As a user, I want to authenticate securely with my corporate credentials, so that I can access AWS services without managing AWS keys directly.

#### Acceptance Criteria

1. WHEN a user clicks login, THE System SHALL open the default browser to the Cognito hosted UI
2. WHEN the user authenticates successfully, THE System SHALL receive an authorization code via localhost callback
3. WHEN an authorization code is received, THE System SHALL exchange it for ID, access, and refresh tokens
4. WHEN tokens are received, THE System SHALL store them securely in macOS Keychain
5. WHEN ID token is received, THE System SHALL call AWS STS AssumeRoleWithWebIdentity to get temporary credentials
6. WHEN temporary credentials are received, THE System SHALL update all AWS service clients
7. THE System SHALL monitor credential expiration and refresh 5 minutes before expiry
8. WHEN credentials need refresh, THE System SHALL use the refresh token to get new tokens
9. WHEN refresh token is invalid or expired, THE System SHALL prompt the user to re-authenticate
10. WHEN the application restarts, THE System SHALL attempt to restore the session using stored refresh token
11. WHEN a user logs out, THE System SHALL delete all stored tokens from Keychain
12. WHEN a user logs out, THE System SHALL clear all temporary AWS credentials
13. THE System SHALL implement OAuth 2.0 Authorization Code Flow with PKCE for security

### Requirement 7: Session Management and Naming

**User Story:** As a user, I want my recording sessions organized with meaningful names and integrated with my Outlook calendar, so that I can easily find and identify past recordings and automatically capture meeting context.

#### Acceptance Criteria

1. WHEN a recording starts, THE System SHALL generate a session name with timestamp format "YYYY-MM-DD-HH-MM-SS-randomid"
2. WHEN a user provides a custom session name, THE System SHALL use it instead of the random ID suffix
3. WHEN a session name contains invalid characters, THE System SHALL replace them with underscores
4. THE System SHALL support renaming completed sessions by clicking an edit icon
5. WHEN a session is renamed, THE System SHALL rename the session directory and all contained files
6. THE System SHALL maintain a list of all recording sessions
7. THE System SHALL display session information in the Batch Jobs view with status (recording, completed, failed)
8. WHEN a user clicks on a session in the Batch Jobs view, THE System SHALL allow opening the audio file or transcription file
9. THE System SHALL support filtering sessions by date range in the Batch Jobs view
10. THE System SHALL support searching sessions by name in the Batch Jobs view
11. THE System SHALL display recording duration for each completed session
12. THE System SHALL display submission timestamp for each batch job
13. WHEN a recording is about to start, THE System SHALL query the user's Outlook calendar for current meetings
14. WHEN exactly one meeting is found, THE System SHALL automatically use the meeting subject as the session name
15. WHEN multiple meetings are found, THE System SHALL display a badge indicator and allow the user to select which meeting to use
16. WHEN Outlook is not available, THE System SHALL use the default timestamp-based session name
17. WHEN a meeting is selected, THE System SHALL capture meeting participants for potential speaker identification
18. THE System SHALL display a loading indicator while querying Outlook calendar
19. THE System SHALL allow editing the session name during recording via an "Edit Session Name" button

### Requirement 8: User Interface Design

**User Story:** As a user, I want a clean and intuitive macOS-native interface, so that I can easily control recording and view transcriptions.

#### Acceptance Criteria

1. THE System SHALL use SwiftUI for the user interface
2. THE System SHALL follow macOS Human Interface Guidelines
3. THE System SHALL provide a main window with tabs for Live Transcription, Batch Jobs, and Settings
4. WHEN in the Live Transcription tab, THE System SHALL display real-time transcription results with speaker labels
5. WHEN in the Batch Jobs tab, THE System SHALL display all batch transcription jobs with status and session information
6. WHEN in the Settings tab, THE System SHALL allow configuring audio devices, AWS settings, and S3 settings
7. THE System SHALL display recording status (idle, recording, paused) prominently with a colored status indicator
8. THE System SHALL display authentication status (logged in, logged out) prominently
9. THE System SHALL provide Start Recording, Stop Recording, and Pause Recording buttons
10. THE System SHALL disable recording controls when not authenticated (optional - can allow offline recording)
11. THE System SHALL display audio level meters for input and output devices during recording
12. THE System SHALL display a session name control showing the current session name with edit capability
13. THE System SHALL display a loading indicator when querying calendar for meetings
14. THE System SHALL display a badge indicator when multiple meetings are available
15. THE System SHALL separate partial transcription results from final transcription results in the UI
16. THE System SHALL provide checkboxes for showing timestamps and enabling auto-scroll in transcription view
17. THE System SHALL display recording duration in HH:MM:SS format during active recording

### Requirement 9: Error Handling and Resilience

**User Story:** As a system architect, I want comprehensive error handling, so that the application gracefully handles failures and provides useful feedback to users.

#### Acceptance Criteria

1. WHEN an audio device becomes unavailable during recording, THE System SHALL notify the user and stop recording
2. WHEN network connectivity is lost, THE System SHALL continue recording audio locally
3. WHEN AWS credentials expire during streaming, THE System SHALL attempt automatic reconnection
4. WHEN S3 upload fails, THE System SHALL retry with exponential backoff up to 3 times
5. WHEN batch transcription job submission fails, THE System SHALL display the error and allow retry
6. WHEN the application crashes, THE System SHALL preserve all recorded audio data
7. WHEN disk space is low, THE System SHALL warn the user before starting a recording
8. WHEN an error occurs, THE System SHALL log detailed error information for debugging
9. THE System SHALL display user-friendly error messages without exposing technical details
10. WHEN authentication fails, THE System SHALL provide troubleshooting guidance

### Requirement 10: Configuration Management

**User Story:** As a user, I want to configure application settings, so that I can customize the behavior to my needs.

#### Acceptance Criteria

1. THE System SHALL store configuration in UserDefaults or a configuration file
2. THE System SHALL support configuring AWS Cognito settings (User Pool ID, App Client ID, Domain, IAM Role ARN)
3. THE System SHALL support configuring S3 settings (Bucket Name, Auto Upload, Keep Local Copies)
4. THE System SHALL support configuring default language for transcription
5. THE System SHALL support enabling/disabling automatic language detection
6. THE System SHALL support enabling/disabling speaker diarization
7. THE System SHALL support configuring maximum speaker labels (2-10)
8. THE System SHALL support configuring local storage directory for recordings
9. THE System SHALL validate configuration values before saving
10. WHEN configuration is invalid, THE System SHALL display validation errors to the user
11. THE System SHALL provide default values for all configuration settings
12. THE System SHALL support exporting and importing configuration
13. THE System SHALL support configuring audio chunk size for streaming (50-200ms)
14. THE System SHALL display current authentication status including token and credential expiration times
15. THE System SHALL provide a "Force Refresh" button for testing credential refresh during active recording
16. THE System SHALL allow resetting storage location to default value

### Requirement 11: Offline Recording Support

**User Story:** As a user, I want to record audio even when offline or not authenticated, so that I never miss capturing important meetings.

#### Acceptance Criteria

1. WHEN AWS credentials are not available, THE System SHALL allow starting a recording
2. WHEN recording offline, THE System SHALL display "Recording (offline)" status
3. WHEN recording offline, THE System SHALL save audio to local files normally
4. WHEN recording offline, THE System SHALL not attempt to send audio to AWS Transcribe Streaming
5. WHEN a user logs in during an offline recording, THE System SHALL automatically start streaming transcription
6. WHEN a user logs out during a recording, THE System SHALL stop streaming but continue audio recording
7. WHEN an offline recording completes, THE System SHALL allow submitting it for batch transcription
8. THE System SHALL clearly indicate when transcription features are unavailable due to offline status

### Requirement 12: Data Privacy and Security

**User Story:** As a user, I want my data handled securely, so that my meeting recordings and credentials are protected.

#### Acceptance Criteria

1. THE System SHALL store all authentication tokens in macOS Keychain with appropriate access controls
2. THE System SHALL never log or display AWS credentials in plain text
3. THE System SHALL use HTTPS for all network communication
4. THE System SHALL validate SSL certificates for all AWS API calls
5. THE System SHALL implement OAuth 2.0 with PKCE to prevent authorization code interception
6. THE System SHALL use temporary AWS credentials that expire after 1 hour
7. THE System SHALL organize S3 files with user-specific prefixes to prevent cross-user access
8. WHEN the application is uninstalled, THE System SHALL provide instructions for removing stored credentials
9. THE System SHALL not transmit audio data to any service other than AWS Transcribe
10. THE System SHALL comply with macOS security and privacy requirements for microphone and screen recording access

### Requirement 13: Calendar Integration

**User Story:** As a user, I want the application to automatically detect my current meetings from my calendar, so that I can easily name sessions with meeting context and capture participant information.

#### Acceptance Criteria

1. THE System SHALL integrate with macOS Calendar app to query current meetings
2. WHEN a recording is about to start, THE System SHALL query for meetings within a 30-minute window (15 minutes before to 15 minutes after current time)
3. WHEN exactly one meeting is found, THE System SHALL automatically use the meeting subject as the session name
4. WHEN multiple meetings are found, THE System SHALL display a badge with the count and allow user selection
5. WHEN no meetings are found, THE System SHALL use the default timestamp-based session name
6. THE System SHALL display a loading indicator while querying the calendar
7. WHEN calendar access is denied, THE System SHALL gracefully fall back to timestamp-based naming
8. THE System SHALL capture meeting participant information (name and email) when available
9. THE System SHALL store meeting participant information with the session for potential speaker identification
10. THE System SHALL support manual session name editing even when a meeting is selected
11. THE System SHALL handle calendar query timeouts gracefully (maximum 5 seconds)
12. THE System SHALL cache calendar query results to avoid repeated queries during the same time window
