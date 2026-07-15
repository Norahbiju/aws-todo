# Containers and local Compose

## Purpose and internal design

Containers make the CI artifact match the Fargate runtime. The frontend Dockerfile has dependency, build, and runtime stages. Only Next.js standalone output and static assets enter the non-root Alpine runtime. The backend builds a wheel, collects dependency wheels, and installs them into a non-root slim Python runtime without compilers.

Both images target `linux/amd64`, expose only their application port, use exec-form commands, and contain health checks. `.dockerignore` files exclude environments, caches, state, IDE files, tests from runtime contexts, and secrets. The OCI source label is supplied by CI so GHCR links packages back to the repository.

Compose starts the backend first, waits for health, then starts Next.js with `API_PROXY_TARGET=http://backend:8000`. Browser traffic remains same-origin on port 3000. Direct port 8000 exposure is only a local convenience.

## Image identity and security

CI publishes `ghcr.io/<owner>/<repository>-frontend:sha-<git-sha>` and the equivalent backend tag, captures registry digests, and deploys only `name@sha256:<64 hex>` references. Tags locate builds; digests identify exact content. The runtime users cannot write privileged host paths and no credential is baked into either image.

After first publication, make both GitHub packages public under package **Settings → Change visibility → Public**. A private GHCR package cannot be pulled anonymously. It would require a GitHub read token in AWS Secrets Manager and ECS repository credentials. Never commit a PAT or put it in task environment variables.

## Verification and common failures

Run `docker build app/frontend`, `docker build app/backend`, `docker compose config`, and `docker compose up --build`. Inspect health with `docker compose ps`. A missing `package-lock.json` breaks `npm ci`; missing standalone output breaks the frontend copy; a private package or failed NAT route causes ECS `CannotPullContainerError`. Confirm platform, package visibility, digest format, and task logs.

References: [Docker multi-stage builds](https://docs.docker.com/build/building/multi-stage/), [Compose](https://docs.docker.com/compose/), [Next.js deployment](https://nextjs.org/docs/app/getting-started/deploying), [GHCR](https://docs.github.com/packages/working-with-a-github-packages-registry/working-with-the-container-registry).

