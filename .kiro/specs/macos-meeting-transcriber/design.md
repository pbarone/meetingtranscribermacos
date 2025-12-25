# Design Document: macOS Meeting Transcriber

## Overview

This document provides the technical design for a macOS native application that replicates the functionality of the Windows Meeting Transcriber. The application will be built using Swift and SwiftUI, leveraging native macOS frameworks for audio capture, secure storage, and UI. The design follows the architectural patterns established in the Windows implementation while adapting to macOS-specific technologies and best practices.

**Key Design Principles:**
- Use native macOS frameworks (AVFoundation, CoreAudio, Security framework)
- Follow Apple Human Interface Guidelines for macOS
- Implement modern Swift patterns (async/await, Combine, structured concurrency)
- Maintain architectural parity with Windows implementation where appropriate
- Prioritize security and user privacy

## Architecture

### High-Level Architecture

The application follows a layered architecture similar to the Windows implementation:

```
┌─────────────────────────────────────────────────────────┐
│                    SwiftUI Views                        │
│  (MainWindow, LiveTranscriptionView, BatchJobsView,    │
│   SettingsView)                                         │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                  View Models                            │
│  (Observable objects managing UI state and business     │
│   logic coordination)                                   │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                  Service Layer                          │
│  - AudioCaptureService (AVFoundation/CoreAudio)         │
│  - StreamingTranscriptionService (AWS SDK)              │
│  - BatchTranscriptionService (AWS SDK)                  │
│  - CognitoAuthenticationService (OAuth 2.0 + PKCE)      │
│  - S3Service (AWS SDK)                                  │
│  - SessionManagementService                             │
│  - KeychainService (Security framework)                 │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│              External Dependencies                      │
│  - AWS SDK for Swift                                    │
│  - AVFoundation / CoreAudio                             │
│  - Security framework (Keychain)                        │
│  - FileManager (local storage)                          │
└─────────────────────────────────────────────────────────┘
```

### Technology Mapping (Windows → macOS)

| Windows Technology | macOS Equivalent | Purpose |
|-------------------|------------------|---------|
| WASAPI (NAudio) | ScreenCaptureKit + AVFoundation | Audio capture |
| Windows Credential Manager | Security framework (Keychain) | Secure token storage |
| WPF | SwiftUI | User interface |
| .NET Dependency Injection | Swift protocols + property wrappers | Service management |
| SQLite (System.Data.SQLite) | SQLite (GRDB.swift or native) | Local persistence |
| AWS SDK for .NET | AWS SDK for Swift | AWS service integration |

## Components and Interfaces

### 1. Audio Capture Service

**Purpose:** Capture audio from microphone and system audio simultaneously, mix streams, and provide audio data for transcription and recording.

**macOS Implementation:**
- Use `AVFoundation` for microphone capture (`AVCaptureDevice`, `AVCaptureSession`)
- Use `ScreenCaptureKit` (macOS 13+) for system audio capture (loopback)
- Audio format: PCM 16-bit signed little-endian, 16kHz, mono

**Interface:**
```swift
protocol AudioCaptureServiceProtocol {
    // Device enumeration
    func getInputDevices() async throws -> [AudioDevice]
    func getOutputDevices() async throws -> [AudioDevice]
    
    // Capture control
    func startCapture(inputDevice: AudioDevice, 
                     outputDevice: AudioDevice, 
                     format: AudioFormat) async throws
    func stopCapture() async throws
    func pauseCapture() async throws
    func resumeCapture() async throws
    
    // State
    var isCapturing: Bool { get }
    var isPaused: Bool { get }
    var currentFormat: AudioFormat? { get }
    
    // Events (using Combine)
    var audioDataPublisher: AnyPublisher<AudioData, Never> { get }
    var audioLevelPublisher: AnyPublisher<Float, Never> { get }
}

struct AudioDevice: Identifiable, Codable {
    let id: String
    let name: String
    let type: AudioDeviceType
    let isDefault: Bool
    let isAvailable: Bool
}

enum AudioDeviceType {
    case input
    case output
}

struct AudioFormat {
    let sampleRate: Int  // 16000 for AWS Transcribe
    let bitsPerSample: Int  // 16
    let channels: Int  // 1 (mono)
    
    func isValidForTranscription() -> Bool {
        return sampleRate == 16000 && bitsPerSample == 16 && channels == 1
    }
}

struct AudioData {
    let data: Data
    let format: AudioFormat
    let timestamp: Date
}
```

**Implementation Notes:**
- `ScreenCaptureKit` requires macOS 13+ and specific entitlements
- Request microphone permission using `AVCaptureDevice.requestAccess(for: .audio)`
- Request screen recording permission for system audio capture
- Use `AVAudioEngine` for audio processing and format conversion
- Implement audio mixing using `AVAudioMixerNode`

### 2. Streaming Transcription Service

**Purpose:** Provide real-time transcription using AWS Transcribe Streaming with automatic reconnection and credential refresh support.

**Interface:**
```swift
protocol StreamingTranscriptionServiceProtocol {
    // Session management
    func startStreaming(format: AudioFormat, 
                       enableSpeakerDiarization: Bool,
                       languageCode: String?) async throws -> String
    func stopStreaming(sessionId: String) async throws
    func sendAudioData(sessionId: String, audioData: Data) async throws
    
    // Credential management
    func updateCredentials(_ credentials: AWSCredentials) async
    func validateConnection() async throws -> Bool
    func retryReconnection(sessionId: String) async throws
    
    // State
    var isStreaming: Bool { get }
    var activeSessions: [String] { get }
    
    // Events (using Combine)
    var partialResultPublisher: AnyPublisher<PartialTranscriptionResult, Never> { get }
    var finalResultPublisher: AnyPublisher<FinalTranscriptionResult, Never> { get }
    var errorPublisher: AnyPublisher<TranscriptionError, Never> { get }
    var reconnectingPublisher: AnyPublisher<String, Never> { get }
    var reconnectedPublisher: AnyPublisher<String, Never> { get }
    var reconnectionFailedPublisher: AnyPublisher<String, Never> { get }
}

struct TranscriptionResult {
    let text: String
    let isPartial: Bool
    let confidence: Double
    let startTime: TimeInterval?
    let endTime: TimeInterval?
    let speakerLabel: String?
    let detectedLanguage: String?
}

struct TranscriptionError: Error {
    let message: String
    let sessionId: String?
    let underlyingError: Error?
}
```

**Implementation Notes:**
- Use AWS SDK for Swift (`AWSTranscribeStreaming`)
- Implement automatic reconnection with exponential backoff (3 retries: 1s, 2s, 4s)
- Preserve timestamp offset across reconnections
- Discard audio data during reconnection (audio still recorded locally)
- Support offline mode (no AWS credentials)

### 3. Batch Transcription Service

**Purpose:** Submit completed recordings for high-quality batch transcription with automatic language detection.

**Interface:**
```swift
protocol BatchTranscriptionServiceProtocol {
    // Job submission
    func submitTranscriptionJob(audioFilePath: String,
                               outputDirectory: String,
                               enableSpeakerDiarization: Bool,
                               languageCode: String?,
                               maxSpeakerLabels: Int) async throws -> BatchTranscriptionJob
    
    // Job management
    func getJobStatus(jobId: String) async throws -> BatchTranscriptionJob
    func waitForCompletion(jobId: String) async throws -> BatchTranscriptionJob
    func getTranscriptionResult(jobId: String) async throws -> (String, [TranscriptionResult])
    func cancelJob(jobId: String) async throws
    func deleteJob(jobId: String) async throws
    func getActiveJobs() async throws -> [BatchTranscriptionJob]
    
    // Credential management
    func updateCredentials(_ credentials: AWSCredentials) async
    func validateConnection() async throws -> Bool
    
    // Events (using Combine)
    var jobStatusPublisher: AnyPublisher<BatchTranscriptionJob, Never> { get }
    var jobCompletedPublisher: AnyPublisher<BatchTranscriptionJob, Never> { get }
    var jobErrorPublisher: AnyPublisher<(BatchTranscriptionJob, Error), Never> { get }
}

struct BatchTranscriptionJob: Identifiable, Codable {
    let id: String
    let jobName: String
    let localAudioFilePath: String
    let localTranscriptionFilePath: String
    let s3AudioUri: String?
    let s3TranscriptUri: String?
    let languageCode: String?
    let detectedLanguageCode: String?
    let enableSpeakerDiarization: Bool
    let maxSpeakerLabels: Int
    var status: BatchTranscriptionStatus
    let createdAt: Date
    var submittedAt: Date?
    var completedAt: Date?
    var errorMessage: String?
}

enum BatchTranscriptionStatus: String, Codable {
    case notStarted
    case uploadingToS3
    case submittedToAWS
    case inProgress
    case completed
    case failed
}
```

**Implementation Notes:**
- Use AWS SDK for Swift (`AWSTranscribeService`, `AWSS3`)
- Poll job status every 30 seconds
- Support automatic language detection (13+ languages)
- Parse JSON transcription results from S3
- Handle audio_segments for speaker diarization

### 4. Cognito Authentication Service

**Purpose:** Handle AWS Cognito authentication with OAuth 2.0 + PKCE, manage temporary credentials, and automatic refresh.

**Interface:**
```swift
protocol CognitoAuthenticationServiceProtocol {
    // Authentication
    func login() async throws -> AuthenticationResult
    func logout() async throws
    func refreshSession() async throws -> AuthenticationResult
    
    // Credential management
    func getTemporaryCredentials() async throws -> AWSCredentials
    func updateAllServiceCredentials() async
    
    // State
    var authenticationState: AuthenticationState { get }
    var isAuthenticated: Bool { get }
    var currentUser: CognitoUserInfo? { get }
    
    // Events (using Combine)
    var authenticationStatePublisher: AnyPublisher<AuthenticationState, Never> { get }
    var credentialsRefreshedPublisher: AnyPublisher<AWSCredentials, Never> { get }
    var authenticationErrorPublisher: AnyPublisher<AuthenticationError, Never> { get }
}

enum AuthenticationState {
    case notAuthenticated
    case authenticating
    case authenticated
    case refreshing
    case error(AuthenticationError)
}

struct AuthenticationResult {
    let idToken: String
    let accessToken: String
    let refreshToken: String
    let expiresIn: TimeInterval
}

struct AWSCredentials {
    let accessKeyId: String
    let secretAccessKey: String
    let sessionToken: String
    let expiration: Date
}

struct CognitoUserInfo {
    let username: String
    let email: String?
    let sub: String
}
```

**Implementation Notes:**
- Implement OAuth 2.0 Authorization Code Flow with PKCE
- Open default browser for Cognito hosted UI
- Use localhost HTTP server for OAuth callback (port 8080)
- Generate PKCE code verifier and challenge (SHA-256)
- Store tokens in macOS Keychain using Security framework
- Call AWS STS `AssumeRoleWithWebIdentity` for temporary credentials
- Monitor credential expiration, refresh 5 minutes before expiry
- Implement automatic session restoration on app restart

### 5. Keychain Service

**Purpose:** Securely store and retrieve authentication tokens using macOS Keychain.

**Interface:**
```swift
protocol KeychainServiceProtocol {
    func save(key: String, data: Data) throws
    func load(key: String) throws -> Data?
    func delete(key: String) throws
    func deleteAll() throws
}
```

**Implementation Notes:**
- Use Security framework (`SecItemAdd`, `SecItemCopyMatching`, `SecItemDelete`)
- Store tokens with `kSecClassGenericPassword`
- Use app bundle identifier as service name
- Set `kSecAttrAccessible` to `kSecAttrAccessibleAfterFirstUnlock`
- Implement proper error handling for keychain operations

### 6. S3 Service

**Purpose:** Upload audio files and download transcription results from AWS S3 with user-specific prefixes.

**Interface:**
```swift
protocol S3ServiceProtocol {
    func uploadAudioFile(localPath: String, 
                        bucketName: String, 
                        keyPrefix: String) async throws -> String
    func downloadTranscriptionResult(s3Uri: String, 
                                    localPath: String) async throws
    func deleteFile(s3Uri: String) async throws
    func validateS3Access() async throws -> Bool
    
    // Credential management
    func updateCredentials(_ credentials: AWSCredentials) async
}
```

**Implementation Notes:**
- Use AWS SDK for Swift (`AWSS3`)
- Automatically add user-specific prefix: `users/{username}/`
- Support multipart upload for large files
- Implement retry logic with exponential backoff
- Parse S3 URIs (format: `s3://bucket-name/key`)

### 7. Session Management Service

**Purpose:** Manage recording sessions, generate session names, and organize local file storage.

**Interface:**
```swift
protocol SessionManagementServiceProtocol {
    // Session creation
    func createSession(customName: String?) async throws -> RecordingSession
    func completeSession(sessionId: String) async throws
    func renameSession(sessionId: String, newName: String) async throws
    
    // Session retrieval
    func getAllSessions() async throws -> [RecordingSession]
    func getSession(sessionId: String) async throws -> RecordingSession?
    func filterSessions(status: SessionStatus?, 
                       dateRange: DateInterval?) async throws -> [RecordingSession]
    
    // File management
    func getSessionDirectory(sessionId: String) -> URL
    func getAudioFilePath(sessionId: String) -> URL
    func getTranscriptionFilePath(sessionId: String) -> URL
}

struct RecordingSession: Identifiable, Codable {
    let id: String
    let name: String
    let directoryPath: URL
    let audioFilePath: URL
    let transcriptionFilePath: URL?
    let createdAt: Date
    var completedAt: Date?
    var status: SessionStatus
    var batchJobId: String?
}

enum SessionStatus: String, Codable {
    case recording
    case completed
    case failed
    case transcribing
}
```

**Implementation Notes:**
- Generate session names: `YYYY-MM-DD-HH-MM-SessionName`
- Sanitize custom names (replace invalid filesystem characters)
- Store sessions in user-configurable base directory
- Use `FileManager` for directory and file operations
- Persist session metadata using `Codable` and JSON files

## Data Models

### Core Models

```swift
// Audio-related models
struct AudioDevice: Identifiable, Codable {
    let id: String
    let name: String
    let type: AudioDeviceType
    let isDefault: Bool
    let isAvailable: Bool
}

struct AudioFormat {
    let sampleRate: Int
    let bitsPerSample: Int
    let channels: Int
}

struct AudioData {
    let data: Data
    let format: AudioFormat
    let timestamp: Date
}

// Transcription models
struct TranscriptionResult {
    let text: String
    let isPartial: Bool
    let confidence: Double
    let startTime: TimeInterval?
    let endTime: TimeInterval?
    let speakerLabel: String?
    let detectedLanguage: String?
}

// Authentication models
struct AWSCredentials {
    let accessKeyId: String
    let secretAccessKey: String
    let sessionToken: String
    let expiration: Date
}

struct CognitoConfiguration: Codable {
    let userPoolId: String
    let appClientId: String
    let domain: String
    let iamRoleArn: String
    let region: String
    let redirectUri: String
}

// Configuration models
struct AppConfiguration: Codable {
    var cognito: CognitoConfiguration
    var s3: S3Configuration
    var transcription: TranscriptionConfiguration
    var storage: StorageConfiguration
}

struct S3Configuration: Codable {
    var bucketName: String
    var isEnabled: Bool
    var autoUploadAudio: Bool
    var autoBackupTranscriptions: Bool
    var keepLocalCopies: Bool
}

struct TranscriptionConfiguration: Codable {
    var defaultLanguageCode: String
    var enableAutomaticLanguageDetection: Bool
    var enableSpeakerDiarization: Bool
    var maxSpeakerLabels: Int
}

struct StorageConfiguration: Codable {
    var baseDirectory: URL
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

Now I need to perform prework analysis on the acceptance criteria before writing the correctness properties:



### Property Reflection

After analyzing all acceptance criteria, I've identified the following areas where properties can be consolidated:

**Redundancy Elimination:**
1. Device validation (1.3, 1.4) can be combined into a single property about device validation
2. Default device identification (1.5, 1.6) can be combined into a single property
3. Audio format properties (2.3, 2.4, 2.5) can be combined into a single comprehensive property
4. Session name sanitization (3.9, 7.3) are duplicate - use one property
5. UI status display properties (4.12, 5.13, 7.7) can be combined into a single property about UI state reflection
6. Configuration persistence properties (10.1-10.8, 10.11) can be combined into fewer comprehensive properties
7. S3 user prefix properties (5.2, 12.7) are duplicate - use one property
8. Token storage properties (6.4, 12.1) are duplicate - use one property

**Properties to Keep:**
- Audio format validation (combines 2.3, 2.4, 2.5)
- Device selection persistence (1.8)
- Session ID uniqueness (3.1)
- Session directory naming format (3.2, 7.1, 7.2)
- Session name sanitization (3.9/7.3 combined)
- Audio stream mixing (2.6)
- Transcription result handling (4.3, 4.4, 4.5)
- Stream reconnection (4.7, 4.10)
- Batch job configuration (5.4, 5.5, 5.6)
- JSON parsing (5.9)
- Token round-trip (6.4/12.1 combined)
- Credential exchange (6.3, 6.5)
- Service client updates (6.6)
- Session restoration (6.10)
- Session rename (7.5)
- Session filtering (7.9, 7.10)
- Configuration round-trip (10.1-10.12 combined)
- Configuration validation (10.9)
- Error logging (9.8)
- Error message formatting (9.9)
- S3 user prefix (5.2/12.7 combined)
- Credential expiration (12.6)

## Correctness Properties

### Property 1: Audio Format Validation
*For any* audio data captured by the system, the format SHALL be PCM 16-bit signed little-endian at 16kHz sample rate with 1 channel (mono).

**Validates: Requirements 2.3, 2.4, 2.5**

### Property 2: Device Selection Persistence
*For any* audio device selection (input or output), saving the selection and reloading it SHALL return the same device ID.

**Validates: Requirements 1.8**

### Property 3: Session ID Uniqueness
*For any* set of recording sessions created by the system, all session IDs SHALL be unique.

**Validates: Requirements 3.1**

### Property 4: Session Directory Naming Format
*For any* recording session with timestamp T and optional custom name N, the directory name SHALL match the format "YYYY-MM-DD-HH-MM" followed by "-N" if N is provided, where invalid filesystem characters in N are replaced with underscores.

**Validates: Requirements 3.2, 7.1, 7.2, 3.9, 7.3**

### Property 5: Audio Stream Mixing
*For any* two audio streams (input and output) with the same format, mixing them SHALL produce a single mono stream with the same sample rate and bit depth.

**Validates: Requirements 2.6**

### Property 6: Partial Transcription Display
*For any* partial transcription result received from AWS, the UI SHALL display it immediately without waiting for the final result.

**Validates: Requirements 4.3**

### Property 7: Final Transcription Replacement
*For any* final transcription result received from AWS, it SHALL replace the corresponding partial result in the UI based on matching timestamps.

**Validates: Requirements 4.4**

### Property 8: Speaker Label Display
*For any* transcription result when speaker diarization is enabled, the result SHALL include a speaker label if AWS provides one.

**Validates: Requirements 4.5**

### Property 9: Stream Reconnection Preservation
*For any* active streaming session that reconnects due to credential refresh, the timestamp offset SHALL be preserved such that new transcription timestamps continue from where the previous stream ended.

**Validates: Requirements 4.7, 4.10**

### Property 10: Batch Job Language Configuration
*For any* batch transcription job, if automatic language detection is enabled, the job configuration SHALL have `IdentifyLanguage` set to true; otherwise, it SHALL use the configured default language code.

**Validates: Requirements 5.4, 5.5**

### Property 11: Batch Job Speaker Diarization Configuration
*For any* batch transcription job, if speaker diarization is enabled, the job configuration SHALL have `ShowSpeakerLabels` set to true and `MaxSpeakerLabels` set to the configured value.

**Validates: Requirements 5.6**

### Property 12: Transcription JSON Parsing
*For any* valid AWS Transcribe batch result JSON, parsing SHALL successfully extract the transcription text and speaker-labeled segments without errors.

**Validates: Requirements 5.9**

### Property 13: Authentication Token Round-Trip
*For any* set of authentication tokens (ID, access, refresh), storing them in Keychain and retrieving them SHALL return the same token values.

**Validates: Requirements 6.4, 12.1**

### Property 14: Authorization Code Exchange
*For any* valid OAuth authorization code, exchanging it with Cognito SHALL return ID, access, and refresh tokens with non-empty values.

**Validates: Requirements 6.3**

### Property 15: Temporary Credential Acquisition
*For any* valid ID token, calling AWS STS AssumeRoleWithWebIdentity SHALL return temporary credentials with access key, secret key, session token, and expiration date.

**Validates: Requirements 6.5**

### Property 16: Service Client Credential Updates
*For any* credential update, all AWS service clients (Transcribe Streaming, Transcribe Batch, S3) SHALL be updated with the new credentials.

**Validates: Requirements 6.6**

### Property 17: Session Restoration
*For any* authenticated session with stored refresh token, restarting the application and restoring the session SHALL successfully refresh the tokens and restore AWS credentials.

**Validates: Requirements 6.10**

### Property 18: Session Rename File Updates
*For any* session rename operation, all files in the session directory SHALL be renamed to match the new session name while preserving file extensions.

**Validates: Requirements 7.5**

### Property 19: Session Date Range Filtering
*For any* date range filter [start, end], the filtered session list SHALL contain only sessions where createdAt is within the range.

**Validates: Requirements 7.9**

### Property 20: Session Name Search
*For any* search query Q, the filtered session list SHALL contain only sessions where the session name contains Q (case-insensitive).

**Validates: Requirements 7.10**

### Property 21: Configuration Round-Trip
*For any* application configuration object, saving it to storage and loading it back SHALL return an equivalent configuration with all values preserved.

**Validates: Requirements 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.8, 10.11, 10.12**

### Property 22: Configuration Validation
*For any* configuration value that violates constraints (e.g., empty bucket name, invalid region, negative max speakers), validation SHALL fail and return an error.

**Validates: Requirements 10.9**

### Property 23: Error Logging
*For any* error that occurs in the system, detailed error information SHALL be logged including error message, timestamp, and context.

**Validates: Requirements 9.8**

### Property 24: User-Friendly Error Messages
*For any* error displayed to the user, the message SHALL not contain AWS credentials, internal stack traces, or technical implementation details.

**Validates: Requirements 9.9**

### Property 25: S3 User-Specific Prefix
*For any* file uploaded to S3, the S3 key SHALL include the user-specific prefix "users/{username}/" where username is derived from the authenticated user.

**Validates: Requirements 5.2, 12.7**

### Property 26: Temporary Credential Expiration
*For any* temporary AWS credentials obtained from STS, the expiration time SHALL be 1 hour or less from the time of acquisition.

**Validates: Requirements 12.6**

### Property 27: Credential Redaction in Logs
*For any* log entry, AWS access keys, secret keys, and session tokens SHALL not appear in plain text.

**Validates: Requirements 12.2**

### Property 28: Device Validation
*For any* audio device selection, validation SHALL verify that the device ID exists in the current device list and the device is in an available state.

**Validates: Requirements 1.3, 1.4**

### Property 29: Default Device Identification
*For any* device enumeration result, at most one input device SHALL be marked as default, and at most one output device SHALL be marked as default.

**Validates: Requirements 1.5, 1.6**

### Property 30: UI State Reflection
*For any* system state change (connection status, job status, session status), the UI SHALL reflect the new state within one UI update cycle.

**Validates: Requirements 4.12, 5.13, 7.7, 11.8**

## Error Handling

### Error Categories

1. **Audio Capture Errors**
   - Device not available
   - Permission denied
   - Format conversion failure
   - Buffer overflow

2. **Network Errors**
   - Connection timeout
   - DNS resolution failure
   - SSL/TLS errors
   - AWS service unavailable

3. **Authentication Errors**
   - Invalid credentials
   - Expired tokens
   - OAuth callback failure
   - Keychain access denied

4. **File System Errors**
   - Disk full
   - Permission denied
   - File not found
   - Invalid path

5. **AWS Service Errors**
   - Transcription job failure
   - S3 upload/download failure
   - STS credential acquisition failure
   - Rate limiting

### Error Handling Strategy

**Retry Logic:**
- Network errors: Exponential backoff (1s, 2s, 4s) up to 3 attempts
- AWS service errors: Exponential backoff up to 3 attempts
- Authentication errors: No retry (prompt user to re-authenticate)
- File system errors: No retry (notify user immediately)

**Error Recovery:**
- Audio capture errors: Stop recording, notify user, release resources
- Network errors during streaming: Continue local recording, attempt reconnection
- Authentication errors: Clear invalid tokens, prompt re-authentication
- File system errors: Stop recording, notify user with specific error

**User Notification:**
- Critical errors: Alert dialog with error message and action buttons
- Non-critical errors: Status bar notification with dismiss option
- Background errors: Log only, no UI interruption

**Error Logging:**
- All errors logged to console with timestamp and context
- Sensitive information (credentials, tokens) redacted from logs
- Error logs stored in `~/Library/Logs/MeetingTranscriber/`

## Testing Strategy

### Unit Testing

**Framework:** XCTest (built-in Xcode testing framework)

**Coverage Areas:**
- Service layer logic (authentication, transcription, file management)
- Data model validation and transformation
- Configuration management
- Error handling and recovery
- Keychain operations (mocked)

**Example Unit Tests:**
- Test session name sanitization with various invalid characters
- Test audio format validation with different sample rates
- Test configuration validation with invalid values
- Test token storage and retrieval (mocked Keychain)
- Test S3 key generation with user prefix
- Test error message formatting (no credentials exposed)

### Property-Based Testing

**Framework:** SwiftCheck (Swift property-based testing library)

**Configuration:**
- Minimum 100 iterations per property test
- Each test tagged with feature name and property number
- Tag format: `Feature: macos-meeting-transcriber, Property {N}: {property_text}`

**Property Test Implementation:**
Each correctness property listed above SHALL be implemented as a property-based test that:
1. Generates random valid inputs
2. Executes the system behavior
3. Verifies the property holds for all generated inputs
4. Reports any counterexamples that violate the property

**Example Property Tests:**
- Property 3 (Session ID Uniqueness): Generate N sessions, verify all IDs are unique
- Property 4 (Session Directory Naming): Generate random timestamps and names, verify format
- Property 13 (Token Round-Trip): Generate random token strings, store and retrieve, verify equality
- Property 21 (Configuration Round-Trip): Generate random valid configurations, save and load, verify equality
- Property 25 (S3 User Prefix): Generate random usernames and file paths, verify prefix in S3 key

### Integration Testing

**Scope:**
- End-to-end audio capture and recording
- AWS service integration (with test credentials)
- OAuth authentication flow (with test Cognito pool)
- File system operations
- UI interactions

**Test Environment:**
- Separate AWS account for testing
- Test Cognito user pool with test users
- Test S3 bucket for file uploads
- Mock audio devices for automated testing

### Manual Testing

**Critical Paths:**
1. First-time setup and authentication
2. Audio device selection and recording
3. Real-time transcription with speaker diarization
4. Batch transcription submission and result retrieval
5. Session management and renaming
6. Offline recording and recovery
7. Credential refresh during active recording
8. Error scenarios (network loss, device disconnection, low disk space)

**Testing Checklist:**
- [ ] Audio capture from microphone and system audio
- [ ] Real-time transcription display with speaker labels
- [ ] Batch transcription with automatic language detection
- [ ] OAuth authentication and token refresh
- [ ] Session creation, renaming, and filtering
- [ ] Offline recording without AWS credentials
- [ ] Stream reconnection during credential refresh
- [ ] Error handling and user notifications
- [ ] Configuration persistence across restarts
- [ ] File organization and S3 uploads

### Performance Testing

**Metrics:**
- Audio capture latency: < 100ms
- Transcription display latency: < 500ms
- UI responsiveness: 60 FPS during recording
- Memory usage: < 200MB during active recording
- Disk I/O: Efficient buffered writes

**Load Testing:**
- Long recording sessions (> 2 hours)
- Multiple concurrent batch jobs
- Large audio files (> 1GB)
- Rapid device switching
- Frequent credential refreshes

## Implementation Notes

### Swift Concurrency

Use modern Swift concurrency features:
- `async/await` for asynchronous operations
- `Task` for structured concurrency
- `AsyncStream` for audio data streaming
- `@MainActor` for UI updates
- `actor` for thread-safe state management

### Combine Framework

Use Combine for reactive programming:
- Publishers for service events (transcription results, errors, state changes)
- Subscribers in ViewModels to update UI state
- Operators for data transformation and filtering
- `@Published` properties for observable state

### SwiftUI Best Practices

- Use `@StateObject` for ViewModel lifecycle management
- Use `@ObservedObject` for passed-in ViewModels
- Use `@State` for local view state
- Use `@Binding` for two-way data flow
- Implement `PreferenceKey` for child-to-parent communication
- Use `@Environment` for dependency injection

### Dependency Injection

Implement protocol-based dependency injection:
```swift
@main
struct MeetingTranscriberApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(appState.audioService)
                .environmentObject(appState.authService)
                .environmentObject(appState.transcriptionService)
        }
    }
}
```

### Error Handling Patterns

Use Swift's error handling:
```swift
enum AppError: LocalizedError {
    case audioDeviceNotAvailable(String)
    case authenticationFailed(String)
    case networkError(Error)
    case fileSystemError(Error)
    
    var errorDescription: String? {
        switch self {
        case .audioDeviceNotAvailable(let device):
            return "Audio device '\(device)' is not available"
        case .authenticationFailed(let reason):
            return "Authentication failed: \(reason)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .fileSystemError(let error):
            return "File system error: \(error.localizedDescription)"
        }
    }
}
```

### Logging

Use `os.log` for structured logging:
```swift
import os.log

extension Logger {
    static let audio = Logger(subsystem: "com.meetingtranscriber", category: "audio")
    static let auth = Logger(subsystem: "com.meetingtranscriber", category: "auth")
    static let transcription = Logger(subsystem: "com.meetingtranscriber", category: "transcription")
}

// Usage
Logger.audio.info("Starting audio capture from device: \(deviceName)")
Logger.auth.error("Authentication failed: \(error.localizedDescription)")
```

### Security Considerations

**Keychain Access:**
- Use `kSecAttrAccessibleAfterFirstUnlock` for token storage
- Set `kSecAttrSynchronizable` to `false` to prevent iCloud sync
- Use app bundle identifier as service name
- Implement proper error handling for keychain operations

**Network Security:**
- Use `URLSession` with default configuration (enforces HTTPS)
- Implement certificate pinning for AWS endpoints (optional)
- Validate SSL certificates
- Use secure random number generation for PKCE

**Data Privacy:**
- Request microphone permission with clear usage description
- Request screen recording permission for system audio
- Never log or display credentials in plain text
- Implement secure memory handling for sensitive data
- Clear sensitive data from memory after use

### macOS Entitlements

Required entitlements in `MeetingTranscriber.entitlements`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Audio input permission -->
    <key>com.apple.security.device.audio-input</key>
    <true/>
    
    <!-- Screen recording permission (for system audio capture) -->
    <key>com.apple.security.device.screen-recording</key>
    <true/>
    
    <!-- Network client (for AWS services) -->
    <key>com.apple.security.network.client</key>
    <true/>
    
    <!-- File access (for local storage) -->
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    
    <!-- Keychain access -->
    <key>keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.meetingtranscriber</string>
    </array>
</dict>
</plist>
```

### Info.plist Entries

Required privacy descriptions:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>Meeting Transcriber needs access to your microphone to record audio during meetings.</string>

<key>NSScreenCaptureUsageDescription</key>
<string>Meeting Transcriber needs screen recording permission to capture system audio from video conferencing applications.</string>
```

## Deployment Considerations

### Minimum macOS Version

- **Target:** macOS 15.0 (Sequoia) or later
- **Reason:** Modern ScreenCaptureKit APIs, latest Swift concurrency features, and SwiftUI improvements
- **No Fallback:** ScreenCaptureKit is the only supported method for system audio capture

### Distribution

- **Development:** Direct installation via Xcode
- **Beta:** TestFlight for macOS
- **Production:** Mac App Store or direct download with notarization

### Code Signing

- Developer ID Application certificate for direct distribution
- Mac App Store certificate for App Store distribution
- Notarization required for distribution outside App Store

### Updates

- Use Sparkle framework for automatic updates (direct distribution)
- App Store automatic updates (App Store distribution)
- Check for updates on app launch
- Download and install updates in background

## Future Enhancements

### Phase 2 Features

1. **Calendar Integration**
   - Integrate with macOS Calendar app (similar to Windows Outlook integration)
   - Auto-detect current meetings
   - Auto-populate session names from calendar events

2. **Advanced Audio Processing**
   - Noise reduction and echo cancellation
   - Audio level normalization
   - Multi-channel recording (separate tracks for input/output)

3. **Enhanced Transcription**
   - Custom vocabulary support
   - Real-time translation
   - Sentiment analysis
   - Action item extraction

4. **Collaboration Features**
   - Share transcriptions via iCloud
   - Collaborative editing of transcriptions
   - Export to various formats (PDF, DOCX, SRT)

5. **Analytics and Insights**
   - Speaking time analysis per participant
   - Keyword frequency analysis
   - Meeting summary generation
   - Trend analysis across multiple meetings

### Technical Debt

- Implement comprehensive error recovery for all edge cases
- Add telemetry and crash reporting
- Optimize memory usage for long recordings
- Implement audio compression for storage efficiency
- Add support for additional audio formats
- Implement background processing for batch jobs
- Add support for multiple AWS regions
- Implement caching for AWS service responses

## Conclusion

This design provides a comprehensive blueprint for implementing a macOS native Meeting Transcriber application that replicates the functionality of the Windows version while leveraging macOS-specific technologies and best practices. The architecture is modular, testable, and maintainable, with clear separation of concerns and well-defined interfaces.

The implementation will follow Apple's Human Interface Guidelines, use modern Swift patterns (async/await, Combine, SwiftUI), and prioritize security and user privacy. The testing strategy includes unit tests, property-based tests, integration tests, and manual testing to ensure correctness and reliability.

By following this design, the macOS application will provide a seamless user experience for recording and transcribing meetings with real-time and batch transcription capabilities, secure authentication, and robust error handling.
