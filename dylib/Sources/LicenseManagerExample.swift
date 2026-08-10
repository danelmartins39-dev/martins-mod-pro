import Foundation

/**
 Exemplo de uso do LicenseManager em um aplicativo iOS
 */

// MARK: - Inicialização

// Inicializar o gerenciador de licenças
let licenseManager = LicenseManager(apiURL: "https://187.127.45.32:3000")

// MARK: - Ativar Licença

func activateLicenseExample() {
    let licenseKey = "XXXX-XXXX-XXXX-XXXX" // Chave fornecida pelo usuário
    
    licenseManager.activateLicense(licenseKey) { success, error in
        if success {
            print("✅ Licença ativada com sucesso!")
        } else {
            print("❌ Erro ao ativar licença: \(error ?? "Desconhecido")")
            // Crashea o app se a licença for inválida
            fatalError("Licença inválida: \(error ?? "Desconhecido")")
        }
    }
}

// MARK: - Verificar Licença

func checkLicenseExample() {
    licenseManager.checkLicense { valid, error in
        if valid {
            print("✅ Licença válida!")
        } else {
            print("❌ Licença inválida: \(error ?? "Desconhecido")")
            // Crashea o app se a licença for inválida
            fatalError("Licença inválida: \(error ?? "Desconhecido")")
        }
    }
}

// MARK: - Obter Tempo Restante

func getRemainingTimeExample() {
    licenseManager.getRemainingSeconds { seconds, error in
        if let seconds = seconds {
            let hours = seconds / 3600
            let minutes = (seconds % 3600) / 60
            print("⏱️ Tempo restante: \(hours)h \(minutes)m")
        } else {
            print("❌ Erro ao obter tempo restante: \(error ?? "Desconhecido")")
        }
    }
}

// MARK: - Obter Data de Expiração

func getExpirationDateExample() {
    licenseManager.getExpirationDate { expirationDate, error in
        if let expirationDate = expirationDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            print("📅 Data de expiração: \(formatter.string(from: expirationDate))")
        } else {
            print("❌ Erro ao obter data de expiração: \(error ?? "Desconhecido")")
        }
    }
}

// MARK: - Verificar Status

func checkStatusExample() {
    if licenseManager.isLicenseValid {
        print("✅ Licença válida - Acesso permitido")
    } else {
        print("❌ Licença inválida - Acesso negado")
        fatalError("Acesso negado - Licença inválida")
    }
}

// MARK: - Desativar Licença

func deactivateLicenseExample() {
    licenseManager.deactivateLicense()
    print("🔓 Licença desativada")
}

// MARK: - Integração no AppDelegate

/*
 Adicione isto no seu AppDelegate.swift:

 import UIKit
 import LicenseManager

 @main
 class AppDelegate: UIResponder, UIApplicationDelegate {
     func application(
         _ application: UIApplication,
         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
         // Verifica a licença na inicialização
         let licenseManager = LicenseManager.shared
         
         licenseManager.checkLicense { valid, error in
             if !valid {
                 print("❌ Licença inválida: \(error ?? "Desconhecido")")
                 fatalError("Acesso negado - Licença inválida")
             }
         }
         
         return true
     }
 }
 */
