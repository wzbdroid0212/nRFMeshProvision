/*
* Copyright (c) 2019, Nordic Semiconductor
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification,
* are permitted provided that the following conditions are met:
*
* 1. Redistributions of source code must retain the above copyright notice, this
*    list of conditions and the following disclaimer.
*
* 2. Redistributions in binary form must reproduce the above copyright notice, this
*    list of conditions and the following disclaimer in the documentation and/or
*    other materials provided with the distribution.
*
* 3. Neither the name of the copyright holder nor the names of its contributors may
*    be used to endorse or promote products derived from this software without
*    specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
* ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
* WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
* IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
* INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
* NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
* WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
* ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
* POSSIBILITY OF SUCH DAMAGE.
*/

import Foundation

/// The state of a feature.
public enum NodeFeaturesState: UInt8, Codable {
    case notEnabled   = 0
    case enabled      = 1
    case notSupported = 2
}

/// The features object represents the functionality of a mesh node
/// that is determined by the set features that the node supports.
public class NodeFeatures: Codable {
    /// The state of Relay feature. `nil` if unknown.
    public internal(set) var relay: NodeFeaturesState?
    /// The state of Proxy feature. `nil` if unknown.
    public internal(set) var proxy: NodeFeaturesState?
    /// The state of Friend feature. `nil` if unknown.
    public internal(set) var friend: NodeFeaturesState?
    /// The state of Low Power feature. `nil` if unknown.
    public internal(set) var lowPower: NodeFeaturesState?
    
    internal var rawValue: UInt16 {
        var bitField: UInt16 = 0
        if relay    == nil || relay!    == .notSupported {} else { bitField |= 0x01 }
        if proxy    == nil || proxy!    == .notSupported {} else { bitField |= 0x02 }
        if friend   == nil || friend!   == .notSupported {} else { bitField |= 0x04 }
        if lowPower == nil || lowPower! == .notSupported {} else { bitField |= 0x08 }
        return bitField
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: CodingKey {
        case relay
        case proxy
        case friend
        case lowPower
    }
    
    internal init(relay: NodeFeaturesState?,
                  proxy: NodeFeaturesState?,
                  friend: NodeFeaturesState?,
                  lowPower: NodeFeaturesState?) {
        self.relay    = relay
        self.proxy    = proxy
        self.friend   = friend
        self.lowPower = lowPower
    }
    
    internal init() {
        self.relay    = nil
        self.proxy    = nil
        self.friend   = nil
        self.lowPower = nil
    }
    
    internal init(rawValue: UInt16) {
        self.relay    = rawValue & 0x01 == 0 ? .notSupported : .notEnabled
        self.proxy    = rawValue & 0x02 == 0 ? .notSupported : .notEnabled
        self.friend   = rawValue & 0x04 == 0 ? .notSupported : .notEnabled
        self.lowPower = rawValue & 0x08 == 0 ? .notSupported : .notEnabled
    }
}

extension NodeFeaturesState: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .notEnabled:   return "Not enabled"
        case .enabled:      return "Enabled"
        case .notSupported: return "Not supported"
        }
    }
    
}

extension NodeFeatures: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        return """
        Relay Feature:     \(relay?.debugDescription ?? "Unknown")
        Proxy Feature:     \(proxy?.debugDescription ?? "Unknown")
        Friend Feature:    \(friend?.debugDescription ?? "Unknown")
        Low Power Feature: \(lowPower?.debugDescription ?? "Unknown")
        """
    }
    
}
