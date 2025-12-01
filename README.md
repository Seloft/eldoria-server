# 🏰 Eldoria

<div align="center">

**Uma plataforma completa para gerenciamento de servidores Minecraft com mods, interface web moderna e sistema de backup automatizado.**

[![Minecraft](https://img.shields.io/badge/Minecraft-1.21.1-green.svg)](https://minecraft.net/)
[![Fabric](https://img.shields.io/badge/Fabric-0.18.0-orange.svg)](https://fabricmc.net/)
[![Docker](https://img.shields.io/badge/Docker-Compose-blue.svg)](https://www.docker.com/)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.115+-009688.svg)](https://fastapi.tiangolo.com/)
[![React](https://img.shields.io/badge/React-19-61DAFB.svg)](https://react.dev/)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.9-3178C6.svg)](https://www.typescriptlang.org/)

</div>

---

## 📖 Sobre o Projeto

O **Eldoria** é uma solução completa e moderna para hospedar e gerenciar servidores Minecraft com suporte a mods. O projeto oferece uma interface web intuitiva para gerenciamento de mods, controle do servidor e monitoramento em tempo real, tudo empacotado em containers Docker para fácil implantação.

### ✨ Características Principais

- 🎮 **Servidor Minecraft Fabric** - Servidor otimizado com Fabric Loader
- 🔧 **Gerenciamento de Mods** - Instale, remova e gerencie mods facilmente
- 🔍 **Integração Modrinth** - Busque e baixe mods diretamente do Modrinth com resolução automática de dependências
- 💻 **Interface Web Moderna** - Frontend React com Material-UI
- 📡 **Controle RCON** - Envie comandos para o servidor via interface web
- 📊 **Logs em Tempo Real** - Acompanhe os logs do servidor via WebSocket
- 💾 **Backup Automático** - Sistema de backup configurável do mundo
- 🐳 **Docker Compose** - Implantação simplificada com containers

---

## 🏗️ Arquitetura

O projeto é dividido em 4 módulos principais:

```
eldoria/
├── eldoria-server/      # 🎮 Servidor Minecraft + Docker Compose
├── eldoria-backend/     # ⚙️ API FastAPI (Python)
├── eldoria-frontend/    # 🖥️ Interface Web (React + TypeScript)
└── eldoria-backup/      # 💾 Sistema de Backup (Python)
```

### 📦 Componentes

| Componente | Descrição | Tecnologias |
|------------|-----------|-------------|
| **eldoria-server** | Servidor Minecraft Fabric containerizado e orquestração | Docker, Java 21, Fabric |
| **eldoria-backend** | API REST para gerenciamento do servidor | Python, FastAPI, Docker SDK |
| **eldoria-frontend** | Interface web para administração | React 19, TypeScript, Vite, MUI |
| **eldoria-backup** | Sistema automatizado de backups | Python, RCON |

---

## 🖥️ Interface Web

A interface web oferece as seguintes funcionalidades:

| Página | Funcionalidade |
|--------|----------------|
| **Mods** | Pesquise e instale mods do Modrinth |
| **Mod Details** | Visualize detalhes, versões e dependências de mods |
| **Server** | Controle o servidor (iniciar, parar, reiniciar) |
| **Terminal** | Execute comandos RCON e visualize logs em tempo real |

---

## 🚀 Início Rápido

### Pré-requisitos

- **Docker Desktop** 20.10+ com Docker Compose v2
- **Git** para clonar os repositórios
- **4GB+ RAM** disponível para o servidor

### Instalação

1. **Clone o repositório principal**
```bash
git clone https://github.com/Seloft/eldoria-server.git
cd eldoria-server
```

2. **Execute o script de setup**

**Linux/Mac:**
```bash
chmod +x scripts/setup.sh
./scripts/setup.sh
```

**Windows (PowerShell):**
```powershell
.\scripts\setup.ps1
```

O script irá:
- Clonar todos os repositórios necessários
- Configurar as variáveis de ambiente
- Preparar a estrutura de diretórios

3. **Configure as variáveis de ambiente**

Copie o arquivo `.env.example` para `.env` e ajuste:

```env
# Minecraft
MC_VERSION=1.21.1
FABRIC_LOADER_VERSION=0.18.0
MEMORY=-Xmx4G -Xms2G

# RCON
MINECRAFT_RCON_PASSWORD=sua_senha_segura

# Modrinth API (opcional)
MODRINTH_AUTHORIZATION=seu_token_modrinth

# Backend
ALLOWED_ORIGINS=http://localhost,http://localhost:80

# Backup
BACKUP_INTERVAL=3600
KEEP_BACKUPS=10

# Timezone
TZ=America/Sao_Paulo
```

4. **Inicie os serviços**
```bash
docker compose -f minecraft-server.yaml up -d --build
```

5. **Acesse a interface**

Abra o navegador em: **http://localhost**

---

## 🐳 Serviços Docker

| Serviço | Porta | Descrição |
|---------|-------|-----------|
| `minecraft` | 25565 | Servidor Minecraft |
| `minecraft-frontend` | 80, 443 | Interface Web (Nginx) |
| `minecraft-backend` | 8000 (interno) | API REST |
| `minecraft-backup` | - | Sistema de Backup |

### Comandos Úteis

```bash
# Ver status dos containers
docker compose -f minecraft-server.yaml ps

# Ver logs do servidor Minecraft
docker compose -f minecraft-server.yaml logs -f minecraft

# Parar todos os serviços
docker compose -f minecraft-server.yaml down

# Reconstruir e reiniciar
docker compose -f minecraft-server.yaml up -d --build

# Executar comando RCON
docker exec minecraft-server rcon-cli -p <password> "<comando>"
```

---

## 📁 Volumes Docker

| Volume | Descrição |
|--------|-----------|
| `minecraft-world` | Dados do mundo do servidor |
| `minecraft-mods` | Mods instalados |
| `minecraft-config` | Configurações do servidor |
| `minecraft-logs` | Logs do servidor |
| `minecraft-backups` | Backups do mundo |
| `backend-config` | Configurações do backend |

---

## 🔧 API Endpoints

O backend expõe os seguintes endpoints principais:

| Endpoint | Método | Descrição |
|----------|--------|-----------|
| `/health` | GET | Health check |
| `/modrinth/*` | GET | Busca de mods no Modrinth |
| `/mods/*` | GET/POST/DELETE | Gerenciamento de mods instalados |
| `/server/*` | GET/POST | Controle do servidor |
| `/files/*` | GET | Acesso a arquivos e logs |

---

## 🎮 Configuração do Servidor

O servidor vem pré-configurado com:

- **Gamemode:** Survival
- **Dificuldade:** Normal
- **PvP:** Habilitado
- **Max Players:** 20
- **View Distance:** 10 chunks
- **RCON:** Habilitado (porta 25575)

Edite o arquivo `server.properties` para personalizar.

---

## 💾 Sistema de Backup

O sistema de backup automatizado:

- Executa backups em intervalos configuráveis
- Pausa o salvamento do mundo durante o backup
- Compacta em `.tar.gz`
- Mantém rotação de backups antigos
- Notifica jogadores via chat do servidor

---

## 🛠️ Desenvolvimento

### Backend (eldoria-backend)
```bash
cd eldoria-backend
python -m venv venv
source venv/bin/activate  # ou venv\Scripts\activate no Windows
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### Frontend (eldoria-frontend)
```bash
cd eldoria-frontend
npm install
npm run dev
```

---

## 📚 Tecnologias Utilizadas

### Backend
- Python 3.10+
- FastAPI
- Docker SDK for Python
- MCRcon
- WebSockets

### Frontend
- React 19
- TypeScript 5.9
- Vite 7
- Material-UI (MUI)
- React Router
- Axios

### Infraestrutura
- Docker & Docker Compose
- Nginx
- Eclipse Temurin (Java 21)
- Fabric Loader

---

## 🤝 Contribuindo

Contribuições são bem-vindas! Por favor, abra uma issue primeiro para discutir as mudanças que você gostaria de fazer.

1. Fork o repositório
2. Crie sua branch de feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

---

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

---

## 👥 Autores

- **Seloft** - [GitHub](https://github.com/Seloft)

---

<div align="center">

**Feito com ❤️ para a comunidade Minecraft**

</div>
