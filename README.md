<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue.svg?style=for-the-badge" alt="Version">
  <img src="https://img.shields.io/badge/bash-4.0+-green.svg?style=for-the-badge&logo=gnu-bash&logoColor=white" alt="Bash">
  <img src="https://img.shields.io/badge/docker-required-2496ED.svg?style=for-the-badge&logo=docker&logoColor=white" alt="Docker">
  <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg?style=for-the-badge" alt="License">
</p>

<h1 align="center">🚀 Deploy CLI</h1>

<p align="center">
  <strong>Professional Docker Deployment Automation Tool</strong>
</p>

<p align="center">
  A unified, configurable CLI tool for deploying Docker-based microservices with automated pre-flight checks, multi-environment support, rollback capability, and CI/CD integration.
</p>

<p align="center">
  <a href="#-features">Features</a> •
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-configuration">Configuration</a> •
  <a href="#-usage">Usage</a> •
  <a href="#-cicd-integration">CI/CD</a>
</p>

---

## ✨ Features

| Feature | Description |
|:--------|:------------|
| 🎯 **Unified CLI** | Single `./deploy.sh` command for all deployment operations |
| 📦 **Multi-Service** | Deploy one, multiple, or all services at once |
| � **Configurable** | Define your own project name, services, and servers |
| �🔍 **Pre-flight Checks** | Validates Docker, SSH, Git before any deployment |
| 👀 **Dry-Run Mode** | Preview changes without executing anything |
| ⏪ **Rollback** | Instantly revert to the previous deployed version |
| 🌍 **Multi-Environment** | Support for staging, production, or custom environments |
| 🏥 **Health Checks** | HTTP and TCP verification after deployment |
| 🎨 **Beautiful Output** | Colored terminal UI with status icons |

---

## � Quick Start

### 1. Clone & Enter

```bash
git clone https://github.com/arramandhanu/deploy-cli.git
cd deploy-cli
```

### 2. Configure Your Project

```bash
# Copy the template
cp config/services.env.template config/services.env

# Edit with your project details
nano config/services.env
```

**Key settings to configure:**

```bash
# Your project name (shown in CLI)
PROJECT_NAME="My Project"

# Your deployment server
REMOTE_HOST="your-server-ip"
REMOTE_USER="deploy"
REMOTE_COMPOSE_DIR="/opt/myproject/compose"
SSH_KEY="${HOME}/.ssh/id_rsa"

# Your services (comma-separated)
SERVICES="frontend,backend,api"

# Service configuration (for each service)
FRONTEND_IMAGE="yourname/myproject-frontend"
FRONTEND_SERVICE_NAME="frontend"
FRONTEND_DIRECTORY="../frontend"
# ... more settings per service
```

### 3. Configure Credentials

```bash
# Copy and fill in DockerHub credentials
cp .env.template .env
nano .env
```

```bash
DOCKERHUB_USERNAME=your_username
DOCKERHUB_PASSWORD=your_access_token
```

### 4. Make Executable & Test

```bash
chmod +x deploy.sh
./deploy.sh --help
./deploy.sh --list
./deploy.sh frontend --dry-run
```

### 5. Deploy!

```bash
./deploy.sh frontend
```

---

## 📖 Usage

### Basic Commands

```bash
# Show help with your configured services
./deploy.sh --help

# List all available services
./deploy.sh --list

# Deploy a single service
./deploy.sh frontend

# Deploy multiple services
./deploy.sh frontend backend api

# Deploy all configured services
./deploy.sh --all
```

### Deployment Options

```bash
# Preview what would happen (no changes made)
./deploy.sh frontend --dry-run

# Deploy to staging environment
./deploy.sh frontend --env staging

# Deploy with a custom tag
./deploy.sh frontend --tag v1.2.3

# Skip confirmation prompts
./deploy.sh frontend --yes

# Rollback to previous version
./deploy.sh frontend --rollback
```

### Build Options

```bash
# Build and push only, don't deploy
./deploy.sh frontend --build-only

# Deploy existing image (skip build)
./deploy.sh frontend --deploy-only --tag abc1234
```

---

## ⚙️ Configuration

### Project Structure

```
deploy-cli/
├── deploy.sh                    # Main CLI script
├── lib/                         # Library modules
│   ├── colors.sh               # Terminal colors & logging
│   ├── utils.sh                # Utility functions
│   ├── checks.sh               # Pre-flight validations
│   ├── docker.sh               # Docker operations
│   └── ssh.sh                  # SSH deployment logic
├── config/
│   ├── services.env            # Your project config (git-ignored)
│   └── services.env.template   # Configuration template
├── .env                         # Credentials (git-ignored)
├── .env.template                # Credentials template
├── .github/workflows/deploy.yml # GitHub Actions
├── .gitlab-ci.yml               # GitLab CI/CD
└── bitbucket-pipelines.yml      # Bitbucket Pipelines
```

### Service Configuration

For each service, define these variables in `config/services.env`:

| Variable | Required | Description |
|:---------|:--------:|:------------|
| `{SERVICE}_IMAGE` | ✅ | Docker image name (e.g., `user/myapp`) |
| `{SERVICE}_SERVICE_NAME` | ✅ | Service name in docker-compose |
| `{SERVICE}_CONTAINER_NAME` | ❌ | Container name for logs |
| `{SERVICE}_DIRECTORY` | ✅ | Path to Dockerfile |
| `{SERVICE}_BUILD_ARGS` | ❌ | Comma-separated build args |
| `{SERVICE}_ENV_FILE` | ❌ | .env file for build args |
| `{SERVICE}_HEALTH_TYPE` | ❌ | `http` or `tcp` |
| `{SERVICE}_HEALTH_PORT` | ❌ | Port for health check |
| `{SERVICE}_HEALTH_PATH` | ❌ | HTTP endpoint (if type=http) |

**Example:**

```bash
FRONTEND_IMAGE="myuser/myapp-frontend"
FRONTEND_SERVICE_NAME="frontend"
FRONTEND_CONTAINER_NAME="myapp-frontend"
FRONTEND_DIRECTORY="../frontend"
FRONTEND_BUILD_ARGS="NEXT_PUBLIC_API_URL,NODE_ENV"
FRONTEND_HEALTH_TYPE="http"
FRONTEND_HEALTH_PORT="3000"
FRONTEND_HEALTH_PATH="/api/health"
```

---

## 🔒 Pre-flight Checks

Before each deployment, the tool automatically validates:

| Check | Status |
|:------|:------:|
| Docker daemon running | ✅ Required |
| DockerHub authentication | ✅ Required |
| SSH key exists | ✅ Required |
| SSH connection works | ✅ Required |
| Dockerfile exists | ✅ Required |
| Remote compose file exists | ✅ Required |
| Git working directory clean | ⚠️ Warning |
| Remote disk space | ⚠️ Warning |

Skip checks with `--skip-checks` (not recommended for production).

---

## 🔄 CI/CD Integration

### GitHub Actions

Pre-configured workflow at `.github/workflows/deploy.yml`:

- Manual dispatch with service selection
- Automatic deployment on push to main
- Environment-aware deployments

**Required Secrets:**
- `DOCKERHUB_USERNAME`
- `DOCKERHUB_PASSWORD`
- `SSH_PRIVATE_KEY`
- `REMOTE_HOST`
- `REMOTE_USER`

### GitLab CI

Configuration at `.gitlab-ci.yml` with per-service deployment jobs.

### Bitbucket Pipelines

Configuration at `bitbucket-pipelines.yml` with custom pipeline triggers.

---

## 🛟 Troubleshooting

<details>
<summary><strong>SSH connection failed</strong></summary>

1. Verify SSH key path in config
2. Check key permissions: `chmod 600 ~/.ssh/your_key`
3. Test manually: `ssh -i ~/.ssh/your_key user@host`
</details>

<details>
<summary><strong>Docker login failed</strong></summary>

1. Verify credentials in `.env`
2. Use Docker Hub access token (recommended)
3. Generate at: https://hub.docker.com/settings/security
</details>

<details>
<summary><strong>Service not found</strong></summary>

1. Check `SERVICES` list in `config/services.env`
2. Ensure service name matches exactly (case-sensitive)
3. Run `./deploy.sh --list` to see available services
</details>

---

## 🤝 Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) before submitting a Pull Request.

### Quick Overview

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit with convention: `git commit -m "feat: add amazing feature"`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

We use **Conventional Commits** - see [CONTRIBUTING.md](CONTRIBUTING.md) for details.

---

## 📄 License

MIT License - Free for personal and commercial use.

See [LICENSE](LICENSE) for details.

---

<p align="center">
  <sub>Built with ❤️ by <a href="https://github.com/arramandhanu">Arya Ramandhanu</a></sub>
</p>
<p align="center">
  <a href="https://linkedin.com/in/arya-ramandhanu">LinkedIn</a> •
  <a href="https://github.com/arramandhanu">GitHub</a>
</p>
