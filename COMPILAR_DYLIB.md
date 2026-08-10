# 🔨 Como Compilar a Dylib LicenseManager

Você não tem Mac? Sem problema! Vou te dar as instruções para compilar no Mac de alguém ou em um serviço na nuvem.

---

## 🍎 Opção 1: Compilar em um Mac Local (Recomendado)

### Pré-requisitos

1. **Mac com macOS 12+**
2. **Xcode instalado** (ou pelo menos Command Line Tools)
3. **Homebrew instalado**

### Passo 1: Instalar Ferramentas Necessárias

```bash
# Instalar ldid (para assinar a dylib)
brew install ldid

# Instalar Theos (framework para compilar tweaks/dylibs iOS)
export THEOS=~/theos
git clone --recursive https://github.com/theos/theos.git $THEOS

# Baixar SDKs do iOS
cd $THEOS
curl -L https://github.com/theos/sdks/archive/master.zip -o sdks.zip
unzip -q sdks.zip
mv sdks-master/* sdks/
rm -rf sdks-master sdks.zip

# Adicionar ao .bashrc ou .zshrc
echo 'export THEOS=~/theos' >> ~/.zshrc
source ~/.zshrc
```

### Passo 2: Clonar o Repositório

```bash
git clone https://github.com/danelmartins39-dev/martins-mod-pro.git
cd martins-mod-pro/dylib
```

### Passo 3: Compilar a Dylib

```bash
# Definir Theos
export THEOS=~/theos

# Compilar
make FINALPACKAGE=1

# Ou usar o script
./build.sh
```

### Passo 4: Encontrar a Dylib Compilada

```bash
# A dylib estará em:
ls -lah .theos/obj/LicenseManager.dylib

# Ou em:
ls -lah ../build/LicenseManager.dylib
```

---

## ☁️ Opção 2: Compilar em um Serviço na Nuvem

### Usando MacStadium ou Similar

1. Alugar um Mac na nuvem (MacStadium, MacInCloud, etc)
2. Seguir os passos acima
3. Baixar a dylib compilada

---

## 🤖 Opção 3: Usar GitHub Actions (Automático)

Você pode configurar o GitHub Actions para compilar automaticamente:

1. **Vá para:** https://github.com/danelmartins39-dev/martins-mod-pro/settings/actions
2. **Clique em:** "Allow all actions and reusable workflows"
3. **Crie um arquivo:** `.github/workflows/build-dylib.yml`
4. **Cole o conteúdo abaixo:**

```yaml
name: Build LicenseManager Dylib

on:
  push:
    branches: [ main ]
    paths:
      - 'dylib/**'
  workflow_dispatch:

jobs:
  build:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Theos
      run: |
        brew install ldid
        export THEOS=~/theos
        git clone --recursive https://github.com/theos/theos.git $THEOS
        
        curl -L https://github.com/theos/sdks/archive/master.zip -o sdks.zip
        unzip -q sdks.zip
        mv sdks-master/* $THEOS/sdks/
        rm -rf sdks-master sdks.zip
    
    - name: Build LicenseManager Dylib
      run: |
        export THEOS=~/theos
        cd dylib
        make FINALPACKAGE=1
    
    - name: Upload Artifact
      uses: actions/upload-artifact@v4
      with:
        name: LicenseManager-Dylib
        path: dylib/.theos/obj/LicenseManager.dylib
```

5. **Faça um push:**
```bash
git add .github/workflows/build-dylib.yml
git commit -m "ci: Adicionar workflow para compilar dylib"
git push origin main
```

6. **Aguarde a compilação:**
   - Vá para: https://github.com/danelmartins39-dev/martins-mod-pro/actions
   - Procure pelo workflow "Build LicenseManager Dylib"
   - Baixe o artifact "LicenseManager-Dylib"

---

## 📦 Estrutura da Dylib Compilada

Após compilar, você terá:

```
LicenseManager.dylib
├── arm64 (iPhone 6s+, iPad 5+)
└── arm64e (iPhone XS+, iPad Pro 2nd gen+)
```

---

## 🔧 Verificar a Compilação

```bash
# Ver informações da dylib
file LicenseManager.dylib

# Deve retornar algo como:
# LicenseManager.dylib: Mach-O universal binary with 2 architectures: [arm64:Mach-O 64-bit dynamically linked shared library arm64] [arm64e:Mach-O 64-bit dynamically linked shared library arm64e]

# Ver símbolos
nm LicenseManager.dylib | grep LicenseManager
```

---

## 🚀 Integrar no Xcode

### Passo 1: Adicionar ao Projeto

1. Abra seu projeto no Xcode
2. **Build Phases → Link Binary With Libraries**
3. Clique em **+**
4. Clique em **Add Other...**
5. Selecione `LicenseManager.dylib`

### Passo 2: Configurar Header Search Paths

1. **Build Settings**
2. Procure por: **Header Search Paths**
3. Adicione o caminho para a pasta `dylib/Sources/`

### Passo 3: Usar no Código

```objective-c
#import "LicenseManager.h"

// No AppDelegate.m
- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    LicenseManager *licenseManager = [LicenseManager sharedManager];
    [licenseManager checkLicenseWithCompletion:^(BOOL valid, NSString *error) {
        if (!valid) {
            NSLog(@"❌ Licença inválida: %@", error);
            // Crashear o app
            @throw [NSException exceptionWithName:@"LicenseInvalidException"
                                           reason:error
                                         userInfo:nil];
        }
    }];
    
    return YES;
}
```

---

## 🐛 Troubleshooting

### Erro: "THEOS not defined"

```bash
export THEOS=~/theos
make FINALPACKAGE=1
```

### Erro: "SDK not found"

```bash
# Verificar SDKs
ls $THEOS/sdks/

# Se vazio, baixar novamente
cd $THEOS
curl -L https://github.com/theos/sdks/archive/master.zip -o sdks.zip
unzip -q sdks.zip
mv sdks-master/* sdks/
```

### Erro: "ldid not found"

```bash
brew install ldid
```

### Erro: "make: *** No targets specified"

```bash
# Verificar se está na pasta certa
pwd  # Deve ser: /caminho/para/martins-mod-pro/dylib

# Verificar se Makefile existe
ls -la Makefile
```

---

## 📞 Suporte

Se tiver problemas:

1. Verifique se Theos está instalado corretamente
2. Verifique se os SDKs estão em `$THEOS/sdks/`
3. Consulte: https://theos.dev/docs/

---

## ✅ Checklist Final

- [ ] Theos instalado
- [ ] SDKs baixados
- [ ] Repositório clonado
- [ ] Dylib compilada
- [ ] Dylib verificada com `file`
- [ ] Dylib adicionada ao Xcode
- [ ] Header search paths configurados
- [ ] Código integrado no AppDelegate
- [ ] App testado

---

## 🎉 Pronto!

Sua dylib está compilada e pronta para usar! 🚀
