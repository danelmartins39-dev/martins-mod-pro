# LicenseManager - Dylib para iOS

Framework Swift para gerenciar licenças de aplicativos iOS com validação segura contra API remota.

## 📦 Características

- ✅ Validação de licenças contra API remota
- ✅ Armazenamento seguro no Keychain
- ✅ Verificações periódicas automáticas (a cada 6 horas)
- ✅ Vinculação de dispositivo via hash único
- ✅ Controle de expiração pelo servidor
- ✅ Crash automático se licença for inválida
- ✅ Suporte a iOS 14+

## 🚀 Instalação

### Via Swift Package Manager

1. No Xcode, vá para: **File → Add Packages**
2. Cole a URL do repositório
3. Selecione a versão e o target
4. Clique em "Add Package"

### Manual (Copiar Arquivos)

1. Copie a pasta `dylib/Sources/` para seu projeto
2. No Xcode, arraste os arquivos para o projeto
3. Marque "Copy items if needed"
4. Adicione ao seu target

## 💻 Uso Básico

### 1. Inicializar

```swift
import LicenseManager

let licenseManager = LicenseManager.shared
// ou
let licenseManager = LicenseManager(apiURL: "https://seu-dominio.com")
```

### 2. Ativar Licença

```swift
licenseManager.activateLicense("XXXX-XXXX-XXXX-XXXX") { success, error in
    if success {
        print("✅ Licença ativada!")
    } else {
        print("❌ Erro: \(error ?? "Desconhecido")")
        fatalError("Licença inválida")
    }
}
```

### 3. Verificar Licença

```swift
licenseManager.checkLicense { valid, error in
    if valid {
        print("✅ Licença válida!")
    } else {
        print("❌ Licença inválida: \(error ?? "Desconhecido")")
        fatalError("Acesso negado")
    }
}
```

### 4. Obter Informações

```swift
// Tempo restante
licenseManager.getRemainingSeconds { seconds, error in
    if let seconds = seconds {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        print("⏱️ \(hours)h \(minutes)m restantes")
    }
}

// Data de expiração
licenseManager.getExpirationDate { expirationDate, error in
    if let date = expirationDate {
        print("📅 Expira em: \(date)")
    }
}

// Verificar status
if licenseManager.isLicenseValid {
    print("✅ Acesso permitido")
} else {
    print("❌ Acesso negado")
}
```

## 🔧 Integração no AppDelegate

```swift
import UIKit
import LicenseManager

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Verificar licença na inicialização
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
```

## 🎨 Integração no SwiftUI

### Tela de Ativação

```swift
import SwiftUI
import LicenseManager

struct LicenseActivationView: View {
    @State private var licenseKey = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showSuccess = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("🔐 Ativar Licença")
                .font(.title2)
                .fontWeight(.bold)
            
            TextField("Cole sua chave de licença", text: $licenseKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.allCharacters)
                .disabled(isLoading)
            
            Button(action: activateLicense) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text("Ativar")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
            .disabled(isLoading || licenseKey.isEmpty)
            
            if let error = errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                    Text(error)
                }
                .foregroundColor(.red)
                .font(.caption)
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            if showSuccess {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Licença ativada com sucesso!")
                }
                .foregroundColor(.green)
                .font(.caption)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func activateLicense() {
        isLoading = true
        errorMessage = nil
        showSuccess = false
        
        LicenseManager.shared.activateLicense(licenseKey) { success, error in
            isLoading = false
            
            if success {
                showSuccess = true
                licenseKey = ""
                
                // Esconder mensagem de sucesso após 3 segundos
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    showSuccess = false
                }
            } else {
                errorMessage = error ?? "Erro desconhecido"
            }
        }
    }
}
```

### Tela de Status

```swift
struct LicenseStatusView: View {
    @State private var remainingTime: String = "Carregando..."
    @State private var expirationDate: String = "Carregando..."
    @State private var isValid = false
    
    var body: some View {
        VStack(spacing: 16) {
            Text("📊 Status da Licença")
                .font(.title2)
                .fontWeight(.bold)
            
            HStack {
                Text("Status:")
                Spacer()
                Text(isValid ? "✅ Ativo" : "❌ Inativo")
                    .foregroundColor(isValid ? .green : .red)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            HStack {
                Text("Tempo Restante:")
                Spacer()
                Text(remainingTime)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            HStack {
                Text("Expira em:")
                Spacer()
                Text(expirationDate)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding()
        .onAppear(perform: loadStatus)
    }
    
    private func loadStatus() {
        let manager = LicenseManager.shared
        
        manager.checkLicense { valid, _ in
            isValid = valid
        }
        
        manager.getRemainingSeconds { seconds, _ in
            if let seconds = seconds {
                let hours = seconds / 3600
                let minutes = (seconds % 3600) / 60
                remainingTime = "\(hours)h \(minutes)m"
            }
        }
        
        manager.getExpirationDate { date, _ in
            if let date = date {
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                expirationDate = formatter.string(from: date)
            }
        }
    }
}
```

## 🔐 Segurança

### Keychain
- Chaves são armazenadas de forma criptografada no Keychain
- Apenas o app pode acessar as chaves armazenadas
- Dados são protegidos pelo sistema de segurança do iOS

### Validação
- Todas as validações são feitas no servidor
- Dispositivos são identificados por hash único
- Comunicação via HTTPS apenas

### Crash Automático
- Se a licença for inválida, o app crasheia automaticamente
- Impossível contornar a validação

## 📋 Códigos de Erro

| Código | Significado |
|--------|-------------|
| `LICENSE_NOT_FOUND` | Chave não encontrada no servidor |
| `LICENSE_EXPIRED` | Licença expirou |
| `LICENSE_REVOKED` | Licença foi revogada pelo administrador |
| `DEVICE_MISMATCH` | Chave está vinculada a outro dispositivo |

## 🔄 Verificações Periódicas

O LicenseManager verifica automaticamente a validade da licença a cada **6 horas** enquanto o app está aberto.

Se a licença for inválida durante uma verificação, o app crasheia imediatamente.

Para desabilitar as verificações:
```swift
licenseManager.deactivateLicense()
```

## 📞 Suporte

Para dúvidas ou problemas, consulte o README.md principal do projeto.

## 📄 Licença

Propriedade privada. Todos os direitos reservados.
