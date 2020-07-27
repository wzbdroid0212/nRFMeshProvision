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

internal struct Features: OptionSet {
    let rawValue: UInt16
    
    static let relay    = Features(rawValue: 1 << 0)
    static let proxy    = Features(rawValue: 1 << 1)
    static let friend   = Features(rawValue: 1 << 2)
    static let lowPower = Features(rawValue: 1 << 3)
}

internal struct HearbeatMessage {
    let source: Address
    let destination: Address
    
    /// Message Op Code.
    let opCode: UInt8
    /// Initial TTL used when sending the message.
    let initTtl: UInt8
    /// Currently active features of the node.
    let features: Features
    
    init?(fromControlMessage message: ControlMessage) {
        opCode = message.opCode
        let data = message.upperTransportPdu
        guard opCode == 0x0A, data.count == 3 else {
            return nil
        }
        initTtl = data[0] & 0x7F
        features = Features(rawValue: UInt16(data[1] << 8) | UInt16(data[2]))
        
        source = message.source
        destination = message.destination
    }
    
    /// Creates a Heartbeat message.
    ///
    /// - parameter ttl:         Initial TTL used when sending the message.
    /// - parameter features:    Currently active features of the node.
    /// - parameter source:      The source address.
    /// - parameter destination: The destination address.
    init(withInitialTtl ttl: UInt8, andFeatures features: Features, from source: Address, targeting destination: Address) {
        self.opCode = 0x0A
        self.initTtl = ttl
        self.features = features
        self.source = source
        self.destination = destination
    }
}

extension HearbeatMessage: CustomDebugStringConvertible {
    
    var debugDescription: String {
        return "Heartbeat Message (initTTL: \(initTtl), features: 0x\(features.rawValue.hex))"
    }
    
}
