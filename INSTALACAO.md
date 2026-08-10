# Guia Completo de Instalação e Configuração

## 🖥️ Parte 1: Configurar o VPS (187.127.45.32)

### Passo 1: Conectar ao VPS

```bash
ssh root@187.127.45.32
# Senha: Julliana708
```

### Passo 2: Atualizar o Sistema

```bash
apt update && apt upgrade -y
apt install -y curl wget git build-essential
```

### Passo 3: Instalar Node.js 18+

```bash
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs npm
node --version  # Verificar instalação
```

### Passo 4: Instalar PostgreSQL

```bash
apt install -y postgresql postgresql-contrib
systemctl start postgresql
systemctl enable postgresql

# Verificar status
sudo -u postgres psql --version
```

### Passo 5: Criar Banco de Dados

```bash
sudo -u postgres psql

# Dentro do PostgreSQL, executar:
CREATE DATABASE licenses_db;
CREATE USER licenses_user WITH PASSWORD 'SenhaSegura123!@#';
GRANT ALL PRIVILEGES ON DATABASE licenses_db TO licenses_user;
ALTER DATABASE licenses_db OWNER TO licenses_user;
\q
```

### Passo 6: Instalar PM2 (Gerenciador de Processos)

```bash
npm install -g pm2
pm2 startup
pm2 save
```

### Passo 7: Instalar Nginx

```bash
apt install -y nginx
systemctl start nginx
systemctl enable nginx
```

### Passo 8: Instalar Certbot (SSL)

```bash
apt install -y certbot python3-certbot-nginx
```

---

## 🔧 Parte 2: Configurar a API

### Passo 1: Clonar o Repositório

```bash
cd /home
git clone https://github.com/danelmartins39-dev/martins-mod-pro.git
cd martins-mod-pro/api
```

### Passo 2: Instalar Dependências

```bash
npm install
```

### Passo 3: Configurar Variáveis de Ambiente

```bash
cp .env.example .env
nano .env
```

Preencher com:
```
PORT=3000
NODE_ENV=production

DB_HOST=localhost
DB_PORT=5432
DB_USER=licenses_user
DB_PASSWORD=SenhaSegura123!@#
DB_NAME=licenses_db

TELEGRAM_BOT_TOKEN=8735209273:AAHv82aDcbkE2LjKcVcmVFR1oqc_qqzB9aY

API_SECRET=sua_chave_secreta_aqui
LOG_LEVEL=info
```

### Passo 4: Executar Migrações do Banco

```bash
npm run migrate
```

### Passo 5: Compilar TypeScript

```bash
npm run build
```

### Passo 6: Iniciar a API com PM2

```bash
pm2 start dist/index.js --name "license-api"
pm2 save
pm2 logs license-api  # Ver logs
```

---

## 🤖 Parte 3: Configurar o Bot do Telegram

### Passo 1: Navegar para a Pasta do Bot

```bash
cd /home/martins-mod-pro/bot
```

### Passo 2: Instalar Dependências

```bash
npm install
```

### Passo 3: Configurar Variáveis de Ambiente

```bash
cp .env.example .env
nano .env
```

Preencher com:
```
TELEGRAM_BOT_TOKEN=8735209273:AAHv82aDcbkE2LjKcVcmVFR1oqc_qqzB9aY
API_URL=https://187.127.45.32:3000
ADMIN_IDS=seu_id_telegram_aqui
```

**Para obter seu ID do Telegram:**
1. Abra o Telegram
2. Envie uma mensagem para `@userinfobot`
3. Copie o ID que aparecer

### Passo 4: Compilar TypeScript

```bash
npm run build
```

### Passo 5: Iniciar o Bot com PM2

```bash
pm2 start dist/telegram-bot.js --name "license-bot"
pm2 save
pm2 logs license-bot  # Ver logs
```

---

## 🔒 Parte 4: Configurar SSL/HTTPS

### Opção A: Usar Domínio (Recomendado)

```bash
# Se você tiver um domínio, use:
certbot certonly --standalone -d seu-dominio.com

# Será criado em:
# /etc/letsencrypt/live/seu-dominio.com/fullchain.pem
# /etc/letsencrypt/live/seu-dominio.com/privkey.pem
```

### Opção B: Certificado Auto-Assinado (Testes)

```bash
openssl req -x509 -newkey rsa:4096 \
  -keyout /etc/ssl/private/key.pem \
  -out /etc/ssl/certs/cert.pem \
  -days 365 -nodes \
  -subj "/CN=187.127.45.32"
```

---

## 🌐 Parte 5: Configurar Nginx

### Passo 1: Criar Configuração

```bash
nano /etc/nginx/sites-available/license-api
```

### Passo 2: Adicionar Configuração

```nginx
server {
    listen 80;
    server_name 187.127.45.32;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name 187.127.45.32;

    # SSL (ajustar caminhos conforme necessário)
    ssl_certificate /etc/ssl/certs/cert.pem;
    ssl_certificate_key /etc/ssl/private/key.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Proxy para a API
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
}
```

### Passo 3: Ativar Configuração

```bash
ln -s /etc/nginx/sites-available/license-api /etc/nginx/sites-enabled/
nginx -t  # Testar configuração
systemctl restart nginx
```

---

## 📱 Parte 6: Integrar Dylib no iOS

### Passo 1: Adicionar ao Projeto Xcode

1. Abra seu projeto no Xcode
2. File → Add Files to Project
3. Selecione a pasta `dylib/` do repositório
4. Marque "Copy items if needed"
5. Adicione ao seu target

### Passo 2: Importar no AppDelegate

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

### Passo 3: Criar Interface para Ativar Licença

```swift
import SwiftUI
import LicenseManager

struct LicenseActivationView: View {
    @State private var licenseKey = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Ativar Licença")
                .font(.title)
                .fontWeight(.bold)
            
            TextField("Cole sua chave de licença", text: $licenseKey)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .autocapitalization(.allCharacters)
            
            Button(action: activateLicense) {
                if isLoading {
                    ProgressView()
                } else {
                    Text("Ativar")
                }
            }
            .disabled(isLoading || licenseKey.isEmpty)
            
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }
    
    private func activateLicense() {
        isLoading = true
        
        LicenseManager.shared.activateLicense(licenseKey) { success, error in
            isLoading = false
            
            if success {
                errorMessage = nil
                print("✅ Licença ativada!")
            } else {
                errorMessage = error ?? "Erro desconhecido"
            }
        }
    }
}
```

---

## ✅ Verificação Final

### Testar a API

```bash
# Health check
curl -k https://187.127.45.32/health

# Deve retornar:
# {"status":"ok","timestamp":"..."}
```

### Testar o Bot do Telegram

1. Abra o Telegram
2. Procure pelo seu bot
3. Digite `/help`
4. Teste `/gerar 7` para gerar uma chave com 7 dias

### Ver Status dos Serviços

```bash
pm2 status
pm2 logs license-api
pm2 logs license-bot
```

---

## 🚨 Troubleshooting

### API não conecta ao banco

```bash
# Verificar conexão PostgreSQL
psql -h localhost -U licenses_user -d licenses_db

# Se não conectar, verificar:
sudo systemctl status postgresql
sudo -u postgres psql
```

### Bot não responde

```bash
# Verificar logs
pm2 logs license-bot

# Reiniciar bot
pm2 restart license-bot

# Verificar se a API está rodando
pm2 logs license-api
```

### Erro de SSL

```bash
# Verificar certificado
openssl x509 -in /etc/ssl/certs/cert.pem -text -noout

# Renovar certificado (Let's Encrypt)
certbot renew --dry-run
```

---

## 📊 Monitorar Serviços

```bash
# Ver todos os processos
pm2 status

# Ver logs em tempo real
pm2 logs

# Ver apenas a API
pm2 logs license-api --lines 100

# Reiniciar um serviço
pm2 restart license-api

# Parar um serviço
pm2 stop license-api

# Iniciar um serviço
pm2 start license-api
```

---

## 🎉 Pronto!

Seu sistema de licenciamento está funcionando! 

**Próximos passos:**
1. Gere uma chave usando o bot: `/gerar 7`
2. Integre a Dylib no seu app iOS
3. Teste a ativação da licença
4. Configure verificações periódicas

**Suporte:** Para dúvidas, consulte o README.md principal.
