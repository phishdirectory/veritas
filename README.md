# phishdirectory/auth
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

This service is deployed using [Kamal](https://kamal-deploy.org/). See the `.kamal` directory for configuration.

## Contributing

1. Fork the repo
2. Create a feature branch
3. Submit a pull request

Please follow our [Code of Conduct](./CODE_OF_CONDUCT.md).

## License

GPL-3.0 License. See [LICENSE](./LICENSE) for details.

---
