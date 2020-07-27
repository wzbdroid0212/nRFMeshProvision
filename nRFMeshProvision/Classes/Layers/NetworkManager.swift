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

internal class NetworkManager {
    let manager: MeshNetworkManager
    
    // MARK: - Layers
    
    var networkLayer        : NetworkLayer!
    var lowerTransportLayer : LowerTransportLayer!
    var upperTransportLayer : UpperTransportLayer!
    var accessLayer         : AccessLayer!
    
    // MARK: - Computed properties
    
    var transmitter: Transmitter? {
        return manager.transmitter
    }
    var meshNetwork: MeshNetwork? {
        return manager.meshNetwork
    }
    var defaultTtl: UInt8 {
        return max(min(manager.defaultTtl, 127), 2)
    }
    var incompleteMessageTimeout: TimeInterval {
        return max(manager.incompleteMessageTimeout, 10.0)
    }
    var acknowledgmentMessageTimeout: TimeInterval {
        return max(manager.acknowledgmentMessageTimeout, 30.0)
    }
    func acknowledgmentMessageInterval(_ ttl: UInt8, _ segmentCount: Int) -> TimeInterval {
        return max(manager.acknowledgmentMessageInterval, 2.0)
            + Double(ttl) * 0.050
            + Double(segmentCount) * 0.050
    }
    func acknowledgmentTimerInterval(_ ttl: UInt8) -> TimeInterval {
        return max(manager.acknowledgmentTimerInterval, 0.150) + Double(ttl) * 0.050
    }
    func transmissionTimerInteral(_ ttl: UInt8) -> TimeInterval {
        return max(manager.transmissionTimerInteral, 0.200) + Double(ttl) * 0.050
    }
    var retransmissionLimit: Int {
        return max(manager.retransmissionLimit, 2)
    }
    
    // MARK: - Implementation
    
    init(_ meshNetworkManager: MeshNetworkManager) {
        manager = meshNetworkManager
        
        networkLayer = NetworkLayer(self)
        lowerTransportLayer = LowerTransportLayer(self)
        upperTransportLayer = UpperTransportLayer(self)
        accessLayer = AccessLayer(self)
    }
    
    // MARK: - Receiving messages
    
    /// This method handles the received PDU of given type.
    ///
    /// - parameters:
    ///   - pdu:  The data received.
    ///   - type: The PDU type.
    func handle(incomingPdu pdu: Data, ofType type: PduType) {
        networkLayer.handle(incomingPdu: pdu, ofType: type)
    }
    
    // MARK: - Sending messages
    
    /// Encrypts the message with the Application Key and a Network Key
    /// bound to it, and sends to the given destination address.
    ///
    /// This method does not send nor return PDUs to be sent. Instead,
    /// for each created segment it calls transmitter's `send(:ofType)`,
    /// which should send the PDU over the air. This is in order to support
    /// retransmittion in case a packet was lost and needs to be sent again
    /// after block acknowlegment was received.
    ///
    /// - parameters:
    ///   - message:        The message to be sent.
    ///   - element:        The source Element.
    ///   - destination:    The destination address.
    ///   - initialTtl:     The initial TTL (Time To Live) value of the message.
    ///                     If `nil`, the default Node TTL will be used.
    ///   - applicationKey: The Application Key to sign the message.
    func send(_ message: MeshMessage,
              from element: Element, to destination: MeshAddress,
              withTtl initialTtl: UInt8?,
              using applicationKey: ApplicationKey) {
        accessLayer.send(message, from: element, to: destination,
                         withTtl: initialTtl, using: applicationKey)
    }
    
    /// Encrypts the message with the Device Key and the first Network Key
    /// known to the target device, and sends to the given destination address.
    ///
    /// The `ConfigNetKeyDelete` will be signed with a different Network Key
    /// that is being removed.
    ///
    /// This method does not send nor return PDUs to be sent. Instead,
    /// for each created segment it calls transmitter's `send(:ofType)`,
    /// which should send the PDU over the air. This is in order to support
    /// retransmittion in case a packet was lost and needs to be sent again
    /// after block acknowlegment was received.
    ///
    /// - parameters:
    ///   - configMessage: The message to be sent.
    ///   - destination:   The destination address.
    ///   - initialTtl:    The initial TTL (Time To Live) value of the message.
    ///                    If `nil`, the default Node TTL will be used.
    func send(_ configMessage: ConfigMessage, to destination: Address,
              withTtl initialTtl: UInt8?) {
        accessLayer.send(configMessage, to: destination, withTtl: initialTtl)
    }
    
    /// Replies to the received message, which was sent with the given key set,
    /// with the given message. The message will be sent from the local
    /// Primary Element.
    ///
    /// - parameters:
    ///   - origin:      The destination address of the message that the reply is for.
    ///   - message:     The response message to be sent.
    ///   - destination: The destination address. This must be a Unicast Address.
    ///   - keySet:      The keySet that should be used to encrypt the message.
    func reply(toMessageSentTo origin: Address, with message: MeshMessage, to destination: Address, using keySet: KeySet) {
        guard let primaryElement = meshNetwork?.localProvisioner?.node?.elements.first else {
            return
        }
        accessLayer.reply(toMessageSentTo: origin, with: message,
                          from: primaryElement, to: destination, using: keySet)
    }
    
    /// Replies to the received message, which was sent with the given key set,
    /// with the given message.
    ///
    /// - parameters:
    ///   - origin:      The destination address of the message that the reply is for.
    ///   - message:     The response message to be sent.
    ///   - element:     The source Element.
    ///   - destination: The destination address. This must be a Unicast Address.
    ///   - keySet:      The keySet that should be used to encrypt the message.
    func reply(toMessageSentTo origin: Address, with message: MeshMessage,
               from element: Element, to destination: Address,
               using keySet: KeySet) {
        accessLayer.reply(toMessageSentTo: origin, with: message,
                          from: element, to: destination, using: keySet)
    }
    
    /// Sends the Proxy Configuration message to the connected Proxy Node.
    ///
    /// - parameter message: The message to be sent.
    func send(_ message: ProxyConfigurationMessage) {
        networkLayer.send(proxyConfigurationMessage: message)
    }
    
    /// Cancels sending the message with the given handler.
    ///
    /// - parameter handler: The message identifier.
    func cancel(_ handler: MessageHandle) {
        accessLayer.cancel(handler)
    }
    
    // MARK: - Callbacks
    
    /// Notifies the delegate about a new mesh message from the given source.
    ///
    /// - parameters:
    ///   - message: The mesh message that was received.
    ///   - source:  The source Unicast Address.
    ///   - destination: The destination address of the message received.
    func notifyAbout(newMessage message: MeshMessage, from source: Address, to destination: Address) {
        manager.delegateQueue.async {
            self.manager.delegate?.meshNetworkManager(self.manager, didReceiveMessage: message,
                                                      sentFrom: source, to: destination)
        }
    }
    
    /// Notifies the delegate about delivering the mesh message to the given
    /// destination address.
    ///
    /// - parameters:
    ///   - message:      The mesh message that was sent.
    ///   - localElement: The local element used to send the message.
    ///   - destination:  The destination address.
    func notifyAbout(deliveringMessage message: MeshMessage,
                     from localElement: Element, to destination: Address) {
        manager.delegateQueue.async {
            self.manager.delegate?.meshNetworkManager(self.manager, didSendMessage: message,
                                                      from: localElement, to: destination)
        }
    }
    
    /// Notifies the delegate about an error during sending the mesh message
    /// to the given destination address.
    ///
    /// - parameters:
    ///   - error:   The error that occurred.
    ///   - message: The mesh message that failed to be sent.
    ///   - localElement: The local element used to send the message.
    ///   - destination:  The destination address.
    func notifyAbout(_ error: Error, duringSendingMessage message: MeshMessage,
                     from localElement: Element, to destination: Address) {
        manager.delegateQueue.async {
            self.manager.delegate?.meshNetworkManager(self.manager, failedToSendMessage: message,
                                                      from: localElement, to: destination, error: error)
        }
    }
    
}
