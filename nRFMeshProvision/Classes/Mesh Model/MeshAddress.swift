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

public struct MeshAddress {
    /// 16-bit address.
    public let address: Address
    /// Virtual label UUID.
    public let virtualLabel: UUID?
    
    public init?(hex: String) {
        if let address = Address(hex: hex) {
            self.init(address)
        } else if let virtualLabel = UUID(hex: hex) {
            self.init(virtualLabel)
        } else {
            return nil
        }
    }
    
    /// Creates a Mesh Address. For virtual addresses use
    /// `init(_ virtualAddress:UUID)` instead.
    ///
    /// This method will be used for Virtual Address
    /// if the Virtual Label is not known, that is in
    /// `ConfigModelPublicationStatus`.
    public init(_ address: Address) {
        self.address = address
        self.virtualLabel = nil
    }
    
    /// Creates a Mesh Address based on the virtual label.
    public init(_ virtualLabel: UUID) {
        self.virtualLabel = virtualLabel
        
        // Calculate the 16-bit virtual address based on the 128-bit label.
        let helper = OpenSSLHelper()
        let salt = helper.calculateSalt("vtad".data(using: .ascii)!)!
        let hash = helper.calculateCMAC(Data(hex: virtualLabel.hex), andKey: salt)!
        var address = UInt16(data: hash.dropFirst(14)).bigEndian
        address |= 0x8000
        address &= 0xBFFF
        self.address = address
    }
}

internal extension MeshAddress {
    
    var hex: String {
        if let virtualLabel = virtualLabel {
            return virtualLabel.hex
        }
        return address.hex
    }
    
}

extension MeshAddress: Equatable {
    
    public static func == (lhs: MeshAddress, rhs: MeshAddress) -> Bool {
        return lhs.address == rhs.address
    }
    
    public static func != (lhs: MeshAddress, rhs: MeshAddress) -> Bool {
        return lhs.address != rhs.address
    }
    
}

extension MeshAddress: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(address)
    }
    
}

extension MeshAddress: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        if let virtualLabel = virtualLabel {
            return virtualLabel.uuidString
        }
        return "0x\(address.hex)"
    }
    
}
