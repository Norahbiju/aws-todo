# ECS Fargate Todo application

This repository is a complete learning-oriented example of a Next.js frontend and FastAPI backend deployed as two containers in one private Amazon ECS Fargate task. An internet-facing ALB sends ordinary paths to Next.js and `/api/*` to FastAPI. Terraform defines the AWS resources once; Terragrunt supplies isolated dev, staging, and production account inputs. GitHub Actions is the only authorised infrastructure mutation path.

## Repository map

```text
app/
  frontend/                 Next.js, TypeScript, tests, Dockerfile
  backend/                  FastAPI, pytest, Ruff, Dockerfile
infra/
  modules/ecs-todo/         single reusable Terraform module
  live/{dev,staging,prod}/  account-specific Terragrunt inputs
.github/workflows/          image and exact-plan infrastructure pipelines
docs/                       architecture, setup, security, and operations guides
compose.yaml                local two-service environment
```

## Local development

Prerequisites are Node.js 22, npm, Python 3.13, and optionally Docker Desktop.

Without Docker, start the backend:

```bash
cd app/backend
python -m venv .venv
source .venv/bin/activate       # Windows PowerShell: .venv\Scripts\Activate.ps1
python -m pip install -e '.[dev]'
uvicorn todo_api.main:app --reload --host 127.0.0.1 --port 8000
```

Then start the frontend in another terminal. `API_PROXY_TARGET` makes Next.js proxy local `/api/*` calls; the production ALB performs that routing instead.

```bash
cd app/frontend
cp .env.example .env.local      # Windows PowerShell: Copy-Item .env.example .env.local
npm ci
npm run dev
```

Open <http://localhost:3000>. For Docker-based development, run `docker compose up --build`. The frontend is on port 3000 and the API is also inspectable directly on port 8000.

## Safe local validation

```bash
cd app/frontend && npm ci && npm run lint && npm test && npm run build
cd app/backend && python -m pip install -e '.[dev]' && ruff check . && ruff format --check . && pytest
docker compose config
terraform fmt -check -recursive infra
terraform -chdir=infra/modules/ecs-todo init -backend=false
terraform -chdir=infra/modules/ecs-todo validate
```

Local `apply` and `destroy` are prohibited by this project's operating model. Use the protected GitHub Actions workflow described in [the setup guide](docs/setup-guide.md).

## Important demonstration limitation

Todos live only in the FastAPI process. They reset whenever a task restarts and are not shared across tasks. Autoscaling can therefore show different lists on different requests. A production design needs DynamoDB, Aurora, RDS, or another external state service.

## Documentation

Start with [architecture](docs/architecture.md), [setup](docs/setup-guide.md), [GitHub Actions](docs/github-actions.md), [security](docs/security.md), and [operations](docs/operations.md). The remaining documents explain each subsystem and its failure modes.

## Cost and security warnings

Each account creates two NAT gateways by default, an ALB, a Fargate service, logs, metrics, and alarms. Three accounts multiply the baseline cost; see [cost considerations](docs/cost-considerations.md). ECS tasks have no public IP and accept application traffic only from the ALB security group. GHCR packages must be public; never put a GitHub PAT in repository files, Terraform inputs, or task environment variables.

