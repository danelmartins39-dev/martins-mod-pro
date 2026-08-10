import Foundation
import Security

/**
 LicenseManager - Gerenciador de Licenças para iOS
 Responsável por validar, armazenar e verificar licenças de forma segura
 */
public class LicenseManager {
    static let shared = LicenseManager()
    
    private let keychainService = "com.martinsmod.license"
    private let keychainAccount = "license_key"
    private let apiBaseURL: String
    private var verificationTimer: Timer?
    private let verificationInterval: TimeInterval = 6 * 60 * 60 // 6 horas
    
    public var isLicenseValid: Bool {
        guard let key = retrieveKeyFromKeychain() else { return false }
        return validateLicenseLocally(key)
    }
    
    public init(apiURL: String = "https://187.127.45.32:3000") {
        self.apiBaseURL = apiURL
        setupVerificationTimer()
    }
    
    // MARK: - Public Methods
    
    /**
     Ativa uma licença no dispositivo
     */
    public func activateLicense(_ key: String, completion: @escaping (Bool, String?) -> Void) {
        guard isValidKeyFormat(key) else {
            completion(false, "Formato de chave inválido")
            return
        }
        
        let deviceId = getDeviceIdentifier()
        let appVersion = getAppVersion()
        let osVersion = UIDevice.current.systemVersion
        
        let requestBody: [String: Any] = [
            "key": key,
            "deviceId": deviceId,
            "appVersion": appVersion,
            "osVersion": osVersion
        ]
        
        makeAPIRequest(
            endpoint: "/api/license/activate",
            method: "POST",
            body: requestBody
        ) { [weak self] response, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(false, error)
                return
            }
            
            guard let response = response as? [String: Any],
                  let valid = response["valid"] as? Bool else {
                completion(false, "Resposta inválida da API")
                return
            }
            
            if valid {
                // Armazena a chave no Keychain
                self.storeKeyInKeychain(key)
                completion(true, nil)
            } else {
                let errorCode = response["error"] as? String ?? "Erro desconhecido"
                completion(false, errorCode)
            }
        }
    }
    
    /**
     Verifica se a licença é válida
     */
    public func checkLicense(completion: @escaping (Bool, String?) -> Void) {
        guard let key = retrieveKeyFromKeychain() else {
            completion(false, "LICENSE_NOT_FOUND")
            return
        }
        
        let deviceId = getDeviceIdentifier()
        
        let requestBody: [String: Any] = [
            "key": key,
            "deviceId": deviceId
        ]
        
        makeAPIRequest(
            endpoint: "/api/license/check",
            method: "POST",
            body: requestBody
        ) { response, error in
            if let error = error {
                completion(false, error)
                return
            }
            
            guard let response = response as? [String: Any],
                  let valid = response["valid"] as? Bool else {
                completion(false, "Resposta inválida da API")
                return
            }
            
            if valid {
                completion(true, nil)
            } else {
                let errorCode = response["error"] as? String ?? "Erro desconhecido"
                completion(false, errorCode)
            }
        }
    }
    
    /**
     Obtém o tempo restante da licença em segundos
     */
    public func getRemainingSeconds(completion: @escaping (Int?, String?) -> Void) {
        guard let key = retrieveKeyFromKeychain() else {
            completion(nil, "LICENSE_NOT_FOUND")
            return
        }
        
        let deviceId = getDeviceIdentifier()
        
        let requestBody: [String: Any] = [
            "key": key,
            "deviceId": deviceId
        ]
        
        makeAPIRequest(
            endpoint: "/api/license/check",
            method: "POST",
            body: requestBody
        ) { response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let response = response as? [String: Any],
                  let remainingSeconds = response["remainingSeconds"] as? Int else {
                completion(nil, "Erro ao obter tempo restante")
                return
            }
            
            completion(remainingSeconds, nil)
        }
    }
    
    /**
     Obtém a data de expiração da licença
     */
    public func getExpirationDate(completion: @escaping (Date?, String?) -> Void) {
        guard let key = retrieveKeyFromKeychain() else {
            completion(nil, "LICENSE_NOT_FOUND")
            return
        }
        
        let deviceId = getDeviceIdentifier()
        
        let requestBody: [String: Any] = [
            "key": key,
            "deviceId": deviceId
        ]
        
        makeAPIRequest(
            endpoint: "/api/license/check",
            method: "POST",
            body: requestBody
        ) { response, error in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let response = response as? [String: Any],
                  let expiresAtString = response["expiresAt"] as? String else {
                completion(nil, "Erro ao obter data de expiração")
                return
            }
            
            let formatter = ISO8601DateFormatter()
            if let expiresAt = formatter.date(from: expiresAtString) {
                completion(expiresAt, nil)
            } else {
                completion(nil, "Formato de data inválido")
            }
        }
    }
    
    /**
     Desativa a licença (remove do Keychain)
     */
    public func deactivateLicense() {
        removeKeyFromKeychain()
        stopVerificationTimer()
    }
    
    // MARK: - Private Methods
    
    private func setupVerificationTimer() {
        verificationTimer = Timer.scheduledTimer(withTimeInterval: verificationInterval, repeats: true) { [weak self] _ in
            self?.verifyLicensePeriodically()
        }
    }
    
    private func stopVerificationTimer() {
        verificationTimer?.invalidate()
        verificationTimer = nil
    }
    
    private func verifyLicensePeriodically() {
        checkLicense { [weak self] valid, error in
            if !valid {
                // Licença inválida, crashea o app
                self?.crashApp(reason: error ?? "Licença inválida")
            }
        }
    }
    
    private func validateLicenseLocally(_ key: String) -> Bool {
        return isValidKeyFormat(key)
    }
    
    private func isValidKeyFormat(_ key: String) -> Bool {
        let keyRegex = "^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", keyRegex)
        return predicate.evaluate(with: key)
    }
    
    private func getDeviceIdentifier() -> String {
        // Gera um hash do identificador único do dispositivo
        var systemInfo = utsname()
        uname(&systemInfo)
        
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        // Combina com UUID do dispositivo
        let uuid = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        let combined = "\(identifier)-\(uuid)"
        
        return hashSHA256(combined)
    }
    
    private func getAppVersion() -> String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        return version
    }
    
    private func hashSHA256(_ input: String) -> String {
        let data = input.data(using: .utf8) ?? Data()
        var digest = [UInt8](repeating: 0, count: Int(32))
        
        #if os(iOS)
        import CommonCrypto
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &digest)
        }
        #else
        // Fallback para simulador
        digest = Array(data.prefix(32))
        #endif
        
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Keychain Methods
    
    private func storeKeyInKeychain(_ key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecValueData as String: key.data(using: .utf8) ?? Data()
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func retrieveKeyFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return key
    }
    
    private func removeKeyFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - API Methods
    
    private func makeAPIRequest(
        endpoint: String,
        method: String = "GET",
        body: [String: Any]? = nil,
        completion: @escaping ([String: Any]?, String?) -> Void
    ) {
        guard let url = URL(string: apiBaseURL + endpoint) else {
            completion(nil, "URL inválida")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let body = body {
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
            } catch {
                completion(nil, "Erro ao serializar JSON")
                return
            }
        }
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil, error.localizedDescription)
                return
            }
            
            guard let data = data else {
                completion(nil, "Sem dados na resposta")
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    completion(json, nil)
                } else {
                    completion(nil, "Resposta não é um JSON válido")
                }
            } catch {
                completion(nil, "Erro ao decodificar JSON")
            }
        }
        
        task.resume()
    }
    
    // MARK: - Crash Methods
    
    private func crashApp(reason: String) {
        print("🚨 LICENÇA INVÁLIDA: \(reason)")
        
        // Força o crash do app
        let exception = NSException(name: NSExceptionName("LicenseInvalidException"), reason: reason, userInfo: nil)
        exception.raise()
    }
}

// MARK: - UIDevice Extension

extension UIDevice {
    var identifierForVendor: UUID? {
        return UIDevice.current.identifierForVendor
    }
}
