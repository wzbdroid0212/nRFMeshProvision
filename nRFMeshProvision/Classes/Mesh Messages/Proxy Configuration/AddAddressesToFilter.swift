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

public struct AddAddressesToFilter: StaticAcknowledgedProxyConfigurationMessage {
    public static let opCode: UInt8 = 0x01
    public static let responseType: StaticProxyConfigurationMessage.Type = FilterStatus.self
    
    public var parameters: Data? {
        var data = Data()
        // Send addresses sorted. The primary Element will be added as a first one,
        // so if the Proxy Filter supports only one address, it will be that one.
        addresses.sorted().forEach { address in
            data += address.bigEndian
        }
        return data
    }
    
    /// Arrays of addresses to be added to the proxy filter.
    public let addresses: Set<Address>
    
    /// Creates the Add Addresses To Filter message.
    ///
    /// - parameter addresses: The array of addresses to be added
    ///                        to the current filter.
    public init(_ addresses: Set<Address>) {
        self.addresses = addresses
    }
    
    public init?(parameters: Data) {
        guard parameters.count % 2 == 0 else {
            return nil
        }
        var tmp: Set<Address> = []
        for i in stride(from: 0, to: parameters.count, by: 2) {
            let address: Address = parameters.readBigEndian(fromOffset: i)
            tmp.insert(address)
        }
        addresses = tmp
    }
}
