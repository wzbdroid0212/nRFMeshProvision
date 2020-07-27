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

public struct LightHSLSaturationStatus: GenericMessage, TransitionStatusMessage {
    public static var opCode: UInt32 = 0x8275
    
    public var parameters: Data? {
        let data = Data() + saturation
        if let targetSaturation = targetSaturation, let remainingTime = remainingTime {
            return data + targetSaturation + remainingTime.rawValue
        } else {
            return data
        }
    }
    
    /// The present value of the Light HSL Saturation state.
    public let saturation: UInt16
    /// The target value of the Light HSL Saturation state.
    public let targetSaturation: UInt16?
    
    public let remainingTime: TransitionTime?
    
    /// Creates the Light HSL Saturation Status message.
    ///
    /// The values for the Saturation state are defined in the following table:
    /// - 0x0000 - the lowest perceived saturation of a color light.
    /// - 0x0001 - 0xFFFE - the 16-bit value representing the saturation of a color light.
    /// - 0xFFFF - the highest perceived saturation of a light.
    ///
    /// - parameters:
    ///   - saturation: The present value of the Light HSL Saturation state.
    public init(saturation: UInt16) {
        self.saturation = saturation
        self.targetSaturation = nil
        self.remainingTime = nil
    }
    
    /// Creates the Light HSL Saturation Status message.
    ///
    /// The values for the Saturation state are defined in the following table:
    /// - 0x0000 - the lowest perceived saturation of a color light.
    /// - 0x0001 - 0xFFFE - the 16-bit value representing the saturation of a color light.
    /// - 0xFFFF - the highest perceived saturation of a light.
    ///
    /// - parameters:
    ///   - saturation: The present value of the Light HSL Saturation state.
    ///   - targetSaturation: The target value of the Light HSL Hue state.
    ///   - remainingTime: The time that an element will take to transition
    ///                    to the target state from the present state.
    public init(saturation: UInt16, targetSaturation: UInt16,
                remainingTime: TransitionTime) {
        self.saturation = saturation
        self.targetSaturation = targetSaturation
        self.remainingTime = remainingTime
    }
    
    public init?(parameters: Data) {
        guard parameters.count == 2 || parameters.count == 5 else { return nil }
        saturation = parameters.read()
        if parameters.count == 5 {
            targetSaturation = parameters.read(fromOffset: 2)
            remainingTime = TransitionTime(rawValue: parameters[4])
        } else {
            targetSaturation = nil
            remainingTime = nil
        }
    }
    
}
