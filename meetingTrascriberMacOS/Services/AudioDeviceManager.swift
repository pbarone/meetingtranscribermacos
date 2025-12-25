//
//  AudioDeviceManager.swift
//  meetingTrascriberMacOS
//
//  Service for managing audio device enumeration and selection
//

import Foundation
import AVFoundation
import ScreenCaptureKit
import Combine
import os.log

/// Errors that can occur during audio device management
enum AudioDeviceError: LocalizedError {
    case enumerationFailed(String)
    case deviceNotFound(String)
    case permissionDenied(String)
    case screenCaptureNotAvailable
    
    var errorDescription: String? {
        switch self {
        case .enumerationFailed(let reason):
            return "Failed to enumerate audio devices: \(reason)"
        case .deviceNotFound(let deviceId):
            return "Audio device not found: \(deviceId)"
        case .permissionDenied(let reason):
            return "Permission denied: \(reason)"
        case .screenCaptureNotAvailable:
            return "ScreenCaptureKit is not available on this system"
        }
    }
}

/// Protocol for audio device management
protocol AudioDeviceManagerProtocol {
    func getInputDevices() async throws -> [AudioDevice]
    func getOutputDevices() async throws -> [AudioDevice]
}

/// Service for managing audio device enumeration
@MainActor
class AudioDeviceManager: AudioDeviceManagerProtocol, ObservableObject {
    private let logger = Logger(subsystem: "com.meetingtranscriber", category: "audio")
    
    @Published var inputDevices: [AudioDevice] = []
    @Published var outputDevices: [AudioDevice] = []
    
    private var deviceChangeObserver: NSObjectProtocol?
    
    init() {
        logger.info("AudioDeviceManager initialized")
        setupDeviceChangeNotifications()
    }
    
    deinit {
        if let observer = deviceChangeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    /// Set up notifications for device changes
    private func setupDeviceChangeNotifications() {
        // Subscribe to AVCaptureDevice notifications for input devices
        deviceChangeObserver = NotificationCenter.default.addObserver(
            forName: .AVCaptureDeviceWasConnected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            if let device = notification.object as? AVCaptureDevice,
               device.hasMediaType(.audio) {
                self.logger.info("Audio input device connected: \(device.localizedName)")
                
                // Refresh the device list
                Task {
                    do {
                        _ = try await self.getInputDevices()
                    } catch {
                        self.logger.error("Failed to refresh input devices: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Subscribe to device disconnection notifications
        NotificationCenter.default.addObserver(
            forName: .AVCaptureDeviceWasDisconnected,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            if let device = notification.object as? AVCaptureDevice,
               device.hasMediaType(.audio) {
                self.logger.info("Audio input device disconnected: \(device.localizedName)")
                
                // Refresh the device list
                Task {
                    do {
                        _ = try await self.getInputDevices()
                    } catch {
                        self.logger.error("Failed to refresh input devices: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        logger.info("Device change notifications configured")
    }
    
    /// Refresh all device lists
    func refreshDevices() async {
        logger.info("Refreshing all audio devices")
        
        do {
            async let inputs = getInputDevices()
            async let outputs = getOutputDevices()
            
            _ = try await (inputs, outputs)
            logger.info("Device refresh completed")
        } catch {
            logger.error("Failed to refresh devices: \(error.localizedDescription)")
        }
    }
    
    /// Get all available input devices using AVFoundation
    func getInputDevices() async throws -> [AudioDevice] {
        logger.info("Enumerating input devices")
        
        do {
            // Get the discovery session for audio devices
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInMicrophone, .externalUnknown],
                mediaType: .audio,
                position: .unspecified
            )
            
            let devices = discoverySession.devices
            logger.info("Found \(devices.count) input device(s)")
            
            // Get the default device
            let defaultDevice = AVCaptureDevice.default(for: .audio)
            let defaultDeviceId = defaultDevice?.uniqueID
            
            // Map AVCaptureDevice to AudioDevice
            let audioDevices = devices.map { device in
                AudioDevice(
                    id: device.uniqueID,
                    name: device.localizedName,
                    type: .input,
                    isDefault: device.uniqueID == defaultDeviceId,
                    isAvailable: !device.isSuspended
                )
            }
            
            // Update published property
            self.inputDevices = audioDevices
            
            return audioDevices
        } catch {
            logger.error("Failed to enumerate input devices: \(error.localizedDescription)")
            throw AudioDeviceError.enumerationFailed(error.localizedDescription)
        }
    }
    
    /// Get all available output devices using ScreenCaptureKit
    func getOutputDevices() async throws -> [AudioDevice] {
        logger.info("Enumerating output devices using ScreenCaptureKit")
        
        // Check if ScreenCaptureKit is available (macOS 13+)
        guard #available(macOS 13.0, *) else {
            logger.error("ScreenCaptureKit is not available on this macOS version")
            throw AudioDeviceError.screenCaptureNotAvailable
        }
        
        do {
            // Get shareable content which includes audio devices
            let content = try await SCShareableContent.current
            
            logger.info("Found \(content.applications.count) application(s) for audio capture")
            
            // For system audio capture, we'll enumerate running applications
            // that can provide audio output
            var audioDevices: [AudioDevice] = []
            
            // Add system audio as the primary output device
            let systemAudioDevice = AudioDevice(
                id: "system-audio",
                name: "System Audio",
                type: .output,
                isDefault: true,
                isAvailable: true
            )
            audioDevices.append(systemAudioDevice)
            
            // Add individual applications as potential audio sources
            for app in content.applications where app.applicationName != "" {
                let appDevice = AudioDevice(
                    id: "app-\(app.processID)",
                    name: app.applicationName,
                    type: .output,
                    isDefault: false,
                    isAvailable: true
                )
                audioDevices.append(appDevice)
            }
            
            logger.info("Enumerated \(audioDevices.count) output device(s)")
            
            // Update published property
            self.outputDevices = audioDevices
            
            return audioDevices
        } catch {
            logger.error("Failed to enumerate output devices: \(error.localizedDescription)")
            throw AudioDeviceError.enumerationFailed(error.localizedDescription)
        }
    }
}
