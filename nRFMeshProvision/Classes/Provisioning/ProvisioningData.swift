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

internal class ProvisioningData {
    private let helper = OpenSSLHelper()
    
    private(set) var networkKey: NetworkKey!
    private(set) var ivIndex: IvIndex!
    private(set) var unicastAddress: Address!
    
    private var privateKey: SecKey!
    private var publicKey: SecKey!
    private var sharedSecret: Data!
    private var authValue: Data!
    private var deviceConfirmation: Data!
    private var deviceRandom: Data!
    
    private(set) var deviceKey: Data!
    private(set) var provisionerRandom: Data!
    private(set) var provisionerPublicKey: Data!
    
    /// The Confirmation Inputs is built over the provisioning process.
    /// It is composed for: Provisioning Invite PDU, Provisioning Capabilities PDU,
    /// Provisioning Start PDU, Provisioner's Public Key and device's Public Key.
    private var confirmationInputs: Data = Data(capacity: 1 + 11 + 5 + 64 + 64)
    
    func prepare(for network: MeshNetwork, networkKey: NetworkKey, unicastAddress: Address) {
        self.networkKey     = networkKey
        self.ivIndex        = network.ivIndex
        self.unicastAddress = unicastAddress
    }
    
    func generateKeys(usingAlgorithm algorithm: Algorithm) throws {
        // Generate Private and Public Keys.
        let (sk, pk) = try generateKeyPair(using: algorithm)
        privateKey = sk
        publicKey  = pk
        try provisionerPublicKey = pk.toData()
        
        // Generate Provisioner Random.
        provisionerRandom = helper.generateRandom()
    }
    
}

internal extension ProvisioningData {
    
    /// This method adds the given PDU to the Provisioning Inputs.
    /// Provisioning Inputs are used for authenticating the Provisioner
    /// and the Unprovisioned Device.
    ///
    /// This method must be called (in order) for:
    /// * Provisioning Invite
    /// * Provisioning Capabilities
    /// * Provisioning Start
    /// * Provisioner Public Key
    /// * Device Public Key
    func accumulate(pdu: Data) {
        confirmationInputs += pdu
    }
    
    /// Call this method when the device Public Key has been
    /// obtained. This must be called after generating keys.
    ///
    /// - parameter key: The device Public Key.
    /// - throws: This method throws when generating ECDH Secure
    ///           Secret failed.
    func provisionerDidObtain(devicePublicKey key: Data) throws {
        guard let _ = privateKey else {
            throw ProvisioningError.invalidState
        }
        sharedSecret = try calculateSharedSecret(publicKey: key)
    }
    
    /// Call this method when the Auth Value has been obtained.
    func provisionerDidObtain(authValue data: Data) {
        authValue = data
    }
    
    /// Call this method when the device Provisioning Confirmation
    /// has been obtained.
    func provisionerDidObtain(deviceConfirmation data: Data) {
        deviceConfirmation = data
    }
    
    /// Call this method when the device Provisioning Random
    /// has been obtained.
    func provisionerDidObtain(deviceRandom data: Data) {
        deviceRandom = data
    }
    
    /// This method validates the received Provisioning Confirmation and
    /// matches it with one calculated locally based on the Provisioning
    /// Random received from the device and Auth Value.
    ///
    /// - throws: The method throws when the validation failed, or
    ///           it was called before all data were ready.
    func validateConfirmation() throws {
        guard let deviceRandom = deviceRandom, let authValue = authValue, let _ = sharedSecret else {
            throw ProvisioningError.invalidState
        }
        let confirmation = calculateConfirmation(random: deviceRandom, authValue: authValue)
        guard deviceConfirmation == confirmation else {
            throw ProvisioningError.confirmationFailed
        }
    }
    
    /// Returns the Provisioner Confirmation value. The Auth Value
    /// must be set prior to calling this method.
    var provisionerConfirmation: Data {
        return calculateConfirmation(random: provisionerRandom, authValue: authValue)
    }
    
    /// Returns the encrypted Provisioning Data together with MIC.
    /// Data will be encrypted using Session Key and Session Nonce.
    /// For that, all properties should be set when this method is called.
    /// Returned value is 25 + 8 bytes long, where the MIC is the last 8 bytes.
    var encryptedProvisioningDataWithMic: Data {
        let keys = calculateKeys()
        deviceKey = keys.deviceKey
        
        let flags = Flags(ivIndex: ivIndex, networkKey: networkKey)
        let data  = networkKey.key + networkKey.index.bigEndian + flags.rawValue + ivIndex.index.bigEndian + unicastAddress.bigEndian
        return helper.calculateCCM(data, withKey: keys.sessionKey, nonce: keys.sessionNonce, andMICSize: 8, withAdditionalData: nil)
    }
    
}

// MARK: - Helper methods

private extension ProvisioningData {
    
    /// Generates a pair of Private and Public Keys using P256 Elliptic Curve
    /// algorithm.
    ///
    /// - parameter algorithm: The algorithm for key pair generation.
    /// - returns: The Private and Public Key pair.
    /// - throws: This method throws an error if the key pair generation has failed
    ///           or the given algorithm is not supported.
    func generateKeyPair(using algorithm: Algorithm) throws -> (privateKey: SecKey, publicKey: SecKey) {
        guard case .fipsP256EllipticCurve = algorithm else {
            throw ProvisioningError.unsupportedAlgorithm
        }
        
        // Private key parameters.
        let privateKeyParams = [kSecAttrIsPermanent : false] as CFDictionary
        
        // Public key parameters.
        let publicKeyParams = [kSecAttrIsPermanent : false] as CFDictionary
        
        // Global parameters.
        let parameters = [kSecAttrKeyType : kSecAttrKeyTypeECSECPrimeRandom,
                          kSecAttrKeySizeInBits : 256,
                          kSecPublicKeyAttrs : publicKeyParams,
                          kSecPrivateKeyAttrs : privateKeyParams] as CFDictionary
        
        var publicKey, privateKey: SecKey?
        let status = SecKeyGeneratePair(parameters as CFDictionary, &publicKey, &privateKey)
        
        guard status == errSecSuccess else {
            throw ProvisioningError.keyGenerationFailed(status)
        }
        return (privateKey!, publicKey!)
    }
    
    /// Calculates the Shared Secret based on the given Public Key
    /// and the local Private Key.
    ///
    /// - parameter publicKey: The device's Public Key as bytes.
    /// - returns: The ECDH Shared Secret.
    func calculateSharedSecret(publicKey: Data) throws -> Data {
        // First byte has to be 0x04 to indicate uncompressed representation.
        var devicePublicKeyData = Data([0x04])
        devicePublicKeyData.append(contentsOf: publicKey)
        
        let pubKeyParameters = [kSecAttrKeyType : kSecAttrKeyTypeECSECPrimeRandom,
                                kSecAttrKeyClass: kSecAttrKeyClassPublic] as CFDictionary
        
        var error: Unmanaged<CFError>?
        let devicePublicKey = SecKeyCreateWithData(devicePublicKeyData as CFData,
                                                   pubKeyParameters, &error)
        guard error == nil else {
            throw error!.takeRetainedValue()
        }
        
        let exchangeResultParams = [SecKeyKeyExchangeParameter.requestedSize: 32] as CFDictionary
        
        let ssk = SecKeyCopyKeyExchangeResult(privateKey,
                                              SecKeyAlgorithm.ecdhKeyExchangeStandard,
                                              devicePublicKey!, exchangeResultParams, &error)
        guard error == nil else {
            throw error!.takeRetainedValue()
        }
        
        return ssk! as Data
    }
    
    /// This method calculates the Provisioning Confirmation based on the
    /// Confirmation Inputs, 16-byte Random and 16-byte AuthValue.
    ///
    /// - parameter random:    An array of 16 random bytes.
    /// - parameter authValue: The Auth Value calculated based on the Authentication Method.
    /// - returns: The Provisioning Confirmation value.
    func calculateConfirmation(random: Data, authValue: Data) -> Data {
        // Calculate the Confirmation Salt = s1(confirmationInputs).
        let confirmationSalt = helper.calculateSalt(confirmationInputs)!
        
        // Calculate the Confirmation Key = k1(ECDH Secret, confirmationSalt, 'prck')
        let confirmationKey  = helper.calculateK1(withN: sharedSecret!,
                                                  salt: confirmationSalt,
                                                  andP: "prck".data(using: .ascii)!)!
        
        // Calculate the Confirmation Provisioner using CMAC(random + authValue)
        let confirmationData = random + authValue
        return helper.calculateCMAC(confirmationData, andKey: confirmationKey)!
    }
    
    /// This method calculates the Session Key, Session Nonce and the Device Key based
    /// on the Confirmation Inputs, 16-byte Provisioner Random and 16-byte device Random.
    ///
    /// - returns: The Session Key, Session Nonce and the Device Key.
    func calculateKeys() -> (sessionKey: Data, sessionNonce: Data, deviceKey: Data) {
        // Calculate the Confirmation Salt = s1(confirmationInputs).
        let confirmationSalt = helper.calculateSalt(confirmationInputs)!
        
        // Calculate the Provisioning Salt = s1(confirmationSalt + provisionerRandom + deviceRandom)
        let provisioningSalt = helper.calculateSalt(confirmationSalt + provisionerRandom! + deviceRandom!)!
        
        // The Session Key is derived as k1(ECDH Shared Secret, provisioningSalt, "prsk")
        let sessionKey = helper.calculateK1(withN: sharedSecret!,
                                            salt: provisioningSalt,
                                            andP: "prsk".data(using: .ascii)!)!
        
        // The Session Nonce is derived as k1(ECDH Shared Secret, provisioningSalt, "prsn")
        // Only 13 least significant bits of the calculated value are used.
        let sessionNonce = helper.calculateK1(withN: sharedSecret!,
                                              salt: provisioningSalt,
                                              andP: "prsn".data(using: .ascii)!)!.dropFirst(3)
        
        // The Device Key is derived as k1(ECDH Shared Secret, provisioningSalt, "prdk")
        let deviceKey = helper.calculateK1(withN: sharedSecret!,
                                           salt: provisioningSalt,
                                           andP: "prdk".data(using: .ascii)!)!
        return (sessionKey: sessionKey, sessionNonce: sessionNonce, deviceKey: deviceKey)
    }
    
}

private struct Flags: OptionSet {
    let rawValue: UInt8
    
    static let keyRefreshFinalizing = Flags(rawValue: 1 << 0)
    static let ivUpdateActive       = Flags(rawValue: 1 << 1)
    
    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    init(ivIndex: IvIndex, networkKey: NetworkKey) {
        var value: UInt8 = 0
        if case .finalizing = networkKey.phase {
            value |= 1 << 0
        }
        if ivIndex.updateActive {
            value |= 1 << 1
        }
        self.rawValue = value
    }
}

private extension SecKey {
    
    /// Returns the Public Key as Data from the SecKey. The SecKey must contain the
    /// valid public key.
    func toData() throws -> Data {
        var error: Unmanaged<CFError>?
        guard let representation = SecKeyCopyExternalRepresentation(self, &error) else {
            throw error!.takeRetainedValue()
        }
        let data = representation as Data
        // First is 0x04 to indicate uncompressed representation.
        return data.dropFirst()
    }
    
}
