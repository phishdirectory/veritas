# veritas (phishdirectory/auth)

**Central authentication microservice for all phish.directory services**<br>
<sub>Maintainer: <a href="mailto:jasper.mayone@phish.directory">@jaspermayone</a></sub>

```
┌───────────────────┐      ┌────────────────────┐
│                   │      │                    │
│ Central Auth      │◄────►│  Service A         │
│ (auth.p.d)        │      │  (api.p.d)         │
│                   │      │                    │
└─────────┬─────────┘      └────────────────────┘
          │                           ▲
          │                           │
          ▼                           │
┌───────────────────┐      ┌────────────────────┐
│                   │      │                    │
│ User Database     │      │  Service B         │
│                   │      │  (dashboard.p.d)   │
│                   │      │                    │
└───────────────────┘      └────────────────────┘
```

---

![CodeRabbit Pull Request Reviews](https://img.shields.io/coderabbit/prs/github/phishdirectory/auth?utm_source=oss&utm_medium=github&utm_campaign=phishdirectory%2Fauth&labelColor=171717&color=FF570A&link=https%3A%2F%2Fcoderabbit.ai&label=CodeRabbit+Reviews)

## Overview

This service handles user authentication across the phish.directory platform. It provides secure login, token management, and session handling for all connected applications.

## Features

- Centralized authentication for all services
- Token-based session management
- Built with security best practices
- Containerized with Docker
- Ready for deployment with Kamal

## Tech Stack

- **Ruby on Rails** – Web framework
- **PostgreSQL** – Database
- **Redis** – Session and cache store
- **Docker** – Containerization
- **Kamal** – Deployment orchestration

## Getting Started

### Prerequisites

- Docker
- Docker Compose
- Ruby 3.2+
- Node.js 18+
- PostgreSQL 14+

### Setup

```bash
git clone https://github.com/phishdirectory/auth.git
cd auth
cp .env.example .env
docker-compose up --build
```

Visit `http://localhost:3000` to confirm the service is running.

## Development

To run the app locally without Docker:

```bash
bundle install
yarn install
rails db:setup
rails server
```

## Deployment

We don't quite have this figured out yet :)

## Contributing

1. Fork the repo
2. Create a feature branch
3. Submit a pull request

Please follow our [Code of Conduct](./CODE_OF_CONDUCT.md).

## License

GPL-3.0 License. See [LICENSE](./LICENSE) for details.

---
