//
//  LearningTrailsMessage.swift
//  
//  Copyright © 2020 Apple Inc. All rights reserved.
//

import Foundation
import UIKit
import PlaygroundSupport
import SPCCore

public struct LearningTrailsMessageOrigin: Codable, CustomStringConvertible {
    public var environment: Environment
    public var deviceName: String
    
    public static var current: LearningTrailsMessageOrigin {
        return LearningTrailsMessageOrigin(environment: Process.environment, deviceName: UIDevice.current.name)
    }
    
    public var description: String {
        return "(\(deviceName):\(environment == .live ? "LVP" : "UP"))"
    }
}

/// An enumeration of messages that can be sent between the User and Live View environments.
public enum LearningTrailsMessage: PlaygroundMessage {
    case refreshSteps(origin: LearningTrailsMessageOrigin)
    
    public enum MessageType: String, PlaygroundMessageType {
        case refreshSteps
    }
    
    public var messageType: MessageType {
        switch self {
        case .refreshSteps(origin:):
            return .refreshSteps
        }
    }
    
    public init?(messageType: MessageType, encodedPayload: Data?) {
        let decoder = JSONDecoder()
        
        switch messageType {
        case .refreshSteps:
            guard let payload = encodedPayload,
                let object = try? decoder.decode(LearningTrailsOriginPayload.self, from: payload) else { return nil }
            self = .refreshSteps(origin: object.origin)
        }
    }
    
    public func encodePayload() -> Data? {
        let encoder = JSONEncoder()
        
        switch self {
        case let .refreshSteps(origin: origin):
            let payload = LearningTrailsOriginPayload(origin: origin)
            return try! encoder.encode(payload)
        }
    }
}

public extension LearningTrailsMessage {
    
    func send(to destination: Environment = .live) {
        switch destination {
        case .live:
            guard let proxy = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy else { return }
            proxy.send(self.playgroundValue)
        case .user:
            guard let liveViewMessageHandler = PlaygroundPage.current.liveView as? PlaygroundLiveViewMessageHandler else { return }
            liveViewMessageHandler.send(self.playgroundValue)
        }
    }
}
