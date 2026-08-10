# Compilação da Dylib LicenseManager

## 🖥️ Opção 1: Compilar no GitHub Actions (Recomendado - Sem Mac)

### Passo 1: Fazer Push para o GitHub

```bash
git add -A
git commit -m "build: Atualizar dylib"
git push origin main
```

### Passo 2: Aguardar Compilação

1. Vá para: https://github.com/danelmartins39-dev/martins-mod-pro/actions
2. Procure pelo workflow "Build LicenseManager Dylib"
3. Aguarde a compilação terminar (geralmente 5-10 minutos)

### Passo 3: Baixar a Dylib

1. Clique no workflow que compilou
2. Procure por "Artifacts" na parte inferior
3. Baixe "LicenseManager-Dylib"
4. Extraia o arquivo .zip
5. A dylib estará em: `LicenseManager.dylib`

---

## 🍎 Opção 2: Compilar Localmente no Mac

### Pré-requisitos

```bash
# Instalar Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar ldid
brew install ldid

# Instalar Theos
export THEOS=~/theos
git clone --recursive https://github.com/theos/theos.git $THEOS

# Baixar SDKs
cd $THEOS
curl -L https://github.com/theos/sdks/archive/master.zip -o sdks.zip
unzip -q sdks.zip
mv sdks-master/* sdks/
rm -rf sdks-master sdks.zip
```

### Compilar

```bash
# Ir para a pasta da dylib
cd dylib

# Compilar
export THEOS=~/theos
make FINALPACKAGE=1

# A dylib estará em:
# .theos/obj/LicenseManager.dylib
```

### Ou usar o script

```bash
cd dylib
./build.sh
```

---

## 📦 Estrutura da Dylib Compilada

Após a compilação, você terá:

```
LicenseManager.dylib
├── arm64 (iPhone 6s+, iPad 5+)
└── arm64e (iPhone XS+, iPad Pro 2nd gen+)
```

---

## 🔧 Integração no Xcode

### Passo 1: Adicionar ao Projeto

1. Abra seu projeto no Xcode
2. Vá para: **Build Phases → Link Binary With Libraries**
3. Clique em **+**
4. Clique em **Add Other...**
5. Selecione o arquivo `LicenseManager.dylib`

### Passo 2: Configurar Paths

1. Vá para: **Build Settings**
2. Procure por: **Runpath Search Paths**
3. Adicione: `@executable_path/Frameworks`

### Passo 3: Usar no Código

```swift
import LicenseManager

let licenseManager = LicenseManager.shared
licenseManager.checkLicense { valid, error in
    if !valid {
        fatalError("Licença inválida")
    }
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
# Verificar SDKs instalados
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

---

## 📊 Verificar Compilação

```bash
# Verificar arquitetura da dylib
file .theos/obj/LicenseManager.dylib

# Deve retornar algo como:
# Mach-O universal binary with 2 architectures: [arm64:Mach-O 64-bit dynamically linked shared library arm64] [arm64e:Mach-O 64-bit dynamically linked shared library arm64e]
```

---

## 🚀 Próximas Etapas

1. ✅ Compilar a dylib
2. ✅ Adicionar ao projeto Xcode
3. ✅ Importar no AppDelegate
4. ✅ Testar no simulador ou dispositivo real

---

## 📞 Suporte

Para dúvidas sobre compilação, consulte:
- [Documentação do Theos](https://theos.dev)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
