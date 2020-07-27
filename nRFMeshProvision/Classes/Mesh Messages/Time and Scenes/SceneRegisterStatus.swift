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

public struct SceneRegisterStatus: GenericMessage, SceneStatusMessage {
    public static let opCode: UInt32 = 0x8245
    
    public var parameters: Data? {
        let data = Data([status.rawValue]) + currentScene
        return scenes.reduce(data) { (current, scene) -> Data in
            return current + scene
        }
    }
    
    public let status: SceneMessageStatus
    /// The number of the current scene.
    public let currentScene: Scene
    /// A list of scenes stored within an Element.
    public let scenes: [Scene]
    
    /// Creates the Scene Register Status message.
    ///
    /// - parameter currentScene: The number of the current scene.
    /// - parameter scenes: A list of scenes stored within an Element.
    public init(report currentScene: Scene, and scenes: [Scene]) {
        self.status = .success
        self.currentScene = currentScene
        self.scenes = scenes
    }
    
    /// Creates the Scene Register Status message.
    ///
    /// - parameters:
    ///   - status: Operation status.
    ///   - currentScene: The number of the current scene.
    ///   - scenes: A list of scenes stored within an Element.
    public init(_ status: SceneMessageStatus, for currentScene: Scene, and scenes: [Scene]) {
        self.status = status
        self.currentScene = currentScene
        self.scenes = scenes
    }
    
    public init?(parameters: Data) {
        guard parameters.count >= 3 && (parameters.count % 2) == 1 else {
            return nil
        }
        guard let status = SceneMessageStatus(rawValue: parameters[0]) else {
            return nil
        }
        self.status = status
        currentScene = parameters.read(fromOffset: 1)
        var array: [Scene] = []
        for offset in stride(from: 3, to: parameters.count, by: 2) {
            let scene: Scene = parameters.read(fromOffset: offset)
            array.append(scene)
        }
        scenes = array
    }
    
}
