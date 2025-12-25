//
//  AudioDevice.swift
//  meetingTrascriberMacOS
//
//  Audio device model for representing input and output audio devices
//

import Foundation

/// Represents an audio device type
enum AudioDeviceType: String, Codable {
    case input
    case output
}

/// Represents an audio device on the system
struct AudioDevice: Identifiable, Codable {
    let id: String
    let name: String
    let type: AudioDeviceType
    let isDefault: Bool
    let isAvailable: Bool
    
    init(id: String, name: String, type: AudioDeviceType, isDefault: Bool = false, isAvailable: Bool = true) {
        self.id = id
        self.name = name
        self.type = type
        self.isDefault = isDefault
        self.isAvailable = isAvailable
    }
}

// MARK: - Equatable
extension AudioDevice: Equatable {
    static func == (lhs: AudioDevice, rhs: AudioDevice) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Hashable
extension AudioDevice: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
