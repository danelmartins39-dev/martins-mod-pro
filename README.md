# Sistema de Licenciamento de Software

Um sistema completo e profissional de licenciamento para aplicativos iOS, com API REST em Node.js, Bot do Telegram para administração e Dylib em Swift para integração no cliente.

## 📋 Características

- **API REST** em Node.js com Express
- **Banco de dados PostgreSQL** com schema seguro
- **Bot do Telegram** para geração e gerenciamento de chaves
- **Dylib em Swift** para iOS com validação segura
- **Verificações periódicas** a cada 6 horas
- **Armazenamento seguro** com hashes SHA-256
- **Vinculação de dispositivo** para evitar compartilhamento de chaves
- **Controle de expiração** pelo servidor (independente do relógio do dispositivo)

## 🏗️ Estrutura do Projeto

```
martins-mod-pro/
├── api/                    # API REST em Node.js
│   ├── src/
│   │   ├── index.ts       # Servidor principal
│   │   ├── config.ts      # Configurações
│   │   ├── database.ts    # Conexão com PostgreSQL
│   │   ├── crypto.ts      # Utilitários de criptografia
│   │   ├── types.ts       # Tipos TypeScript
│   │   ├── licenseService.ts  # Lógica de licenças
│   │   ├── routes.ts      # Rotas da API
│   │   └── migrate.ts     # Migrações do banco
│   ├── package.json
│   ├── tsconfig.json
│   └── .env.example
├── bot/                    # Bot do Telegram
│   ├── telegram-bot.ts    # Código do bot
│   ├── package.json
│   └── .env.example
├── dylib/                  # Dylib em Swift para iOS
│   ├── Sources/
│   │   ├── LicenseManager.swift
│   │   └── LicenseManagerExample.swift
│   ├── Tests/
│   ├── Package.swift
│   └── README.md
└── README.md
```

## 🚀 Instalação e Configuração

### 1. Preparar o VPS

```bash
# Conectar ao VPS
ssh root@187.127.45.32

# Atualizar sistema
apt update && apt upgrade -y

# Instalar Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs

# Instalar PostgreSQL
apt install -y postgresql postgresql-contrib

# Instalar Git
apt install -y git
```

### 2. Configurar PostgreSQL

```bash
# Iniciar PostgreSQL
systemctl start postgresql
systemctl enable postgresql

# Conectar ao PostgreSQL
sudo -u postgres psql

# Criar banco de dados e usuário
CREATE DATABASE licenses_db;
CREATE USER licenses_user WITH PASSWORD 'sua_senha_segura';
GRANT ALL PRIVILEGES ON DATABASE licenses_db TO licenses_user;
\q
```

### 3. Clonar e Configurar a API

```bash
# Clonar repositório
git clone https://github.com/danelmartins39-dev/martins-mod-pro.git
cd martins-mod-pro/api

# Instalar dependências
npm install

# Configurar variáveis de ambiente
cp .env.example .env
nano .env

# Preencher com:
# PORT=3000
# NODE_ENV=production
# DB_HOST=localhost
# DB_PORT=5432
# DB_USER=licenses_user
# DB_PASSWORD=sua_senha_segura
# DB_NAME=licenses_db
# TELEGRAM_BOT_TOKEN=seu_token_aqui

# Executar migrações
npm run migrate

# Compilar TypeScript
npm run build

# Iniciar API com PM2
npm install -g pm2
pm2 start dist/index.js --name "license-api"
pm2 startup
pm2 save
```

### 4. Configurar o Bot do Telegram

```bash
cd ../bot

# Instalar dependências
npm install

# Configurar variáveis de ambiente
cp .env.example .env
nano .env

# Preencher com:
# TELEGRAM_BOT_TOKEN=8735209273:AAHv82aDcbkE2LjKcVcmVFR1oqc_qqzB9aY
# API_URL=https://187.127.45.32:3000
# ADMIN_IDS=seu_id_telegram

# Compilar TypeScript
npm run build

# Iniciar bot com PM2
pm2 start dist/telegram-bot.js --name "license-bot"
pm2 save
```

### 5. Configurar SSL/HTTPS

```bash
# Instalar Certbot
apt install -y certbot python3-certbot-nginx

# Gerar certificado (usando IP ou domínio)
certbot certonly --standalone -d seu-dominio.com

# Ou usar auto-assinado para testes
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```

### 6. Configurar Nginx como Reverse Proxy

```bash
# Instalar Nginx
apt install -y nginx

# Criar configuração
nano /etc/nginx/sites-available/license-api

# Adicionar:
server {
    listen 443 ssl;
    server_name 187.127.45.32;

    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;

    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}

# Ativar configuração
ln -s /etc/nginx/sites-available/license-api /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

## 📱 Integração da Dylib no iOS

### 1. Adicionar ao Projeto Xcode

```bash
# Copiar a dylib para o projeto
cp -r dylib/ seu-projeto-ios/

# No Xcode:
# 1. File > Add Files to Project
# 2. Selecionar a pasta dylib/
# 3. Marcar "Copy items if needed"
# 4. Adicionar ao target
```

### 2. Usar no AppDelegate

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

### 3. Ativar Licença no App

```swift
import SwiftUI
import LicenseManager

struct ContentView: View {
    @State private var licenseKey = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            TextField("Insira a chave de licença", text: $licenseKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            Button("Ativar Licença") {
                activateLicense()
            }
            .disabled(isLoading)
            .padding()
        }
    }
    
    private func activateLicense() {
        isLoading = true
        
        LicenseManager.shared.activateLicense(licenseKey) { success, error in
            isLoading = false
            
            if success {
                print("✅ Licença ativada!")
            } else {
                print("❌ Erro: \(error ?? "Desconhecido")")
            }
        }
    }
}
```

## 🤖 Comandos do Bot do Telegram

### Gerar Chave
```
/gerar 1    # Gera chave com 1 dia
/gerar 3    # Gera chave com 3 dias
/gerar 7    # Gera chave com 7 dias
/gerar 15   # Gera chave com 15 dias
/gerar 30   # Gera chave com 30 dias
```

### Gerenciar Chaves
```
/info CHAVE         # Exibe informações da chave
/revogar CHAVE      # Revoga a chave
/reativar CHAVE     # Reativa a chave
/deletar CHAVE      # Deleta a chave
/listar             # Lista todas as chaves
/help               # Mostra ajuda
```

## 🔌 Endpoints da API

### POST /api/license/activate
Ativa uma licença vinculando ao dispositivo.

**Request:**
```json
{
  "key": "XXXX-XXXX-XXXX-XXXX",
  "deviceId": "hash-do-dispositivo",
  "appVersion": "1.0.0",
  "osVersion": "17.0"
}
```

**Response:**
```json
{
  "valid": true,
  "status": "ACTIVE",
  "expiresAt": "2024-08-17T10:30:00Z",
  "remainingSeconds": 604800
}
```

### POST /api/license/check
Verifica se uma licença é válida.

**Request:**
```json
{
  "key": "XXXX-XXXX-XXXX-XXXX",
  "deviceId": "hash-do-dispositivo"
}
```

**Response:**
```json
{
  "valid": true,
  "status": "ACTIVE",
  "expiresAt": "2024-08-17T10:30:00Z",
  "remainingSeconds": 604800
}
```

### POST /api/license/deactivate
Desativa uma licença.

**Request:**
```json
{
  "key": "XXXX-XXXX-XXXX-XXXX"
}
```

**Response:**
```json
{
  "success": true,
  "message": "License deactivated"
}
```

## 🔐 Códigos de Erro

- `LICENSE_NOT_FOUND` - Chave não encontrada
- `LICENSE_EXPIRED` - Chave expirou
- `LICENSE_REVOKED` - Chave foi revogada
- `DEVICE_MISMATCH` - Chave vinculada a outro dispositivo

## 📊 Monitoramento

### Ver logs da API
```bash
pm2 logs license-api
```

### Ver logs do Bot
```bash
pm2 logs license-bot
```

### Status dos serviços
```bash
pm2 status
```

## 🛡️ Segurança

- Todas as chaves são armazenadas como hash SHA-256
- Dispositivos são identificados por hash único
- Comunicação via HTTPS
- Token do Telegram armazenado apenas em variável de ambiente
- Verificações periódicas a cada 6 horas
- Expiração controlada exclusivamente pelo servidor

## 📝 Licença

Propriedade privada. Todos os direitos reservados.

## 👨‍💻 Suporte

Para dúvidas ou problemas, entre em contato através do Telegram.
