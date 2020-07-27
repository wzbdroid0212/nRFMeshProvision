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

public protocol GenericMessage: StaticMeshMessage {
    // No additional fields.
}

public protocol AcknowledgedGenericMessage: GenericMessage, StaticAcknowledgedMeshMessage {
    // No additional fields.
}

public extension Array where Element == GenericMessage.Type {
    
    /// A helper method that can create a map of message types required
    /// by the `ModelDelegate` from a list of `GenericMessage`s.
    ///
    /// - returns: A map of message types.
    func toMap() -> [UInt32 : MeshMessage.Type] {
        return (self as [StaticMeshMessage.Type]).toMap()
    }
    
}

// MARK: - GenericMessageStatus

public enum GenericMessageStatus: UInt8 {
    case success           = 0x00
    case cannotSetRangeMin = 0x01
    case cannotSetRangeMax = 0x02
}

public protocol GenericStatusMessage: GenericMessage, StatusMessage {
    /// Operation status.
    var status: GenericMessageStatus { get }
}

public extension GenericStatusMessage {
    
    var isSuccess: Bool {
        return status == .success
    }
    
    var message: String {
        return "\(status)"
    }
    
}

extension GenericMessageStatus: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .success:
            return "Success"
        case .cannotSetRangeMin:
            return "Cannot Set Range Min"
        case .cannotSetRangeMax:
            return "Cannot Set Range Max"
        }
    }
    
}

// MARK: - SceneMessageStatus

public enum SceneMessageStatus: UInt8 {
    case success           = 0x00
    case sceneRegisterFull = 0x01
    case sceneNotFound     = 0x02
}

public protocol SceneStatusMessage: GenericMessage, StatusMessage {
    /// Operation status.
    var status: SceneMessageStatus { get }
}

public extension SceneStatusMessage {
    
    var isSuccess: Bool {
        return status == .success
    }
    
    var message: String {
        return "\(status)"
    }
    
}

extension SceneMessageStatus: CustomDebugStringConvertible {
    
    public var debugDescription: String {
        switch self {
        case .success:
            return "Success"
        case .sceneRegisterFull:
            return "Scene Register Full"
        case .sceneNotFound:
            return "Scene Not Found"
        }
    }
    
}
