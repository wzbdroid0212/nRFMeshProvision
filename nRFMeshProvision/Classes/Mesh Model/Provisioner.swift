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

public class Provisioner: Codable {
    internal weak var meshNetwork: MeshNetwork?
    
    /// 128-bit Device UUID.
    internal let provisionerUuid: MeshUUID
    /// Random 128-bit UUID allows differentiation among multiple mesh networks.
    public var uuid: UUID {
        return provisionerUuid.uuid
    }
    /// UTF-8 string, which should be a human readable name of the Provisioner.
    public var provisionerName: String {
        didSet {
            if let network = meshNetwork, let node = network.node(for: self) {
                node.name = provisionerName
            }
        }
    }
    /// An array of unicast range objects.
    public internal(set) var allocatedUnicastRange: [AddressRange]
    /// An array of group range objects.
    public internal(set) var allocatedGroupRange:   [AddressRange]
    /// An array of scene range objects.
    public internal(set) var allocatedSceneRange:   [SceneRange]
    
    public init(name: String,
                uuid: UUID,
                allocatedUnicastRange: [AddressRange],
                allocatedGroupRange:   [AddressRange],
                allocatedSceneRange:   [SceneRange]) {
        self.provisionerName = name
        self.provisionerUuid = MeshUUID(uuid)
        self.allocatedUnicastRange = allocatedUnicastRange.merged()
        self.allocatedGroupRange   = allocatedGroupRange.merged()
        self.allocatedSceneRange   = allocatedSceneRange.merged()
    }
    
    public convenience init(name: String,
                            allocatedUnicastRange: [AddressRange],
                            allocatedGroupRange:   [AddressRange],
                            allocatedSceneRange:   [SceneRange]) {
        self.init(name: name,
                  uuid: UUID(),
                  allocatedUnicastRange: allocatedUnicastRange,
                  allocatedGroupRange:   allocatedGroupRange,
                  allocatedSceneRange:   allocatedSceneRange
        )
    }
    
    public convenience init(name: String) {
        self.init(name: name,
                  uuid: UUID(),
                  allocatedUnicastRange: [AddressRange.allUnicastAddresses],
                  allocatedGroupRange:   [AddressRange.allGroupAddresses],
                  allocatedSceneRange:   [SceneRange.allScenes]
        )
    }
    
    // MARK: - Codable
    
    private enum CodingKeys: String, CodingKey {
        case provisionerUuid = "UUID"
        case provisionerName
        case allocatedUnicastRange
        case allocatedGroupRange
        case allocatedSceneRange
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        provisionerName = try container.decode(String.self, forKey: .provisionerName)
        provisionerUuid = try container.decode(MeshUUID.self, forKey: .provisionerUuid)
        allocatedUnicastRange = try container.decode([AddressRange].self, forKey: .allocatedUnicastRange).merged()
        allocatedGroupRange = try container.decode([AddressRange].self, forKey: .allocatedGroupRange).merged()
        allocatedSceneRange = try container.decode([SceneRange].self, forKey: .allocatedSceneRange).merged()
    }
}

// MARK: - Operators

extension Provisioner: Equatable {
    
    public static func == (lhs: Provisioner, rhs: Provisioner) -> Bool {
        return lhs.uuid == rhs.uuid
    }
    
    public static func != (lhs: Provisioner, rhs: Provisioner) -> Bool {
        return lhs.uuid != rhs.uuid
    }
    
}
