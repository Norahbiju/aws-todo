# Application

## What and why

The application demonstrates the cloud delivery path without hiding state management behind a database. Next.js provides an accessible responsive UI; FastAPI provides a typed REST service. Keeping them separate mirrors independently built production services while one ECS task keeps the example compact.

## How it works

`app/frontend/lib/api.ts` owns all HTTP calls and uses relative `/api/todos` URLs. `app/frontend/app/page.tsx` owns UI state, including loading, mutation, error, retry, empty, edit, and completion states. The ALB intercepts `/api/*`; during local development `API_PROXY_TARGET` enables the equivalent Next.js rewrite.

FastAPI request and response types live in `models.py`. `InMemoryTodoRepository` serialises shared mutations with `asyncio.Lock`, assigns IDs, and holds seeded records. Route functions remain thin. Middleware emits JSON logs and request IDs; exception handlers return safe messages rather than stack traces.

API contract:

| Method | Path | Result |
|---|---|---|
| GET | `/api/health` | unauthenticated health response |
| GET | `/api/todos` | ordered Todo list |
| GET | `/api/todos/{id}` | one Todo or 404 |
| POST | `/api/todos` | validated Todo and 201 |
| PATCH | `/api/todos/{id}` | partial update |
| DELETE | `/api/todos/{id}` | 204 or 404 |

Titles are trimmed, required, and limited to 120 characters; descriptions are limited to 1,000. Pydantic reports invalid input as a safe 422 response.

## Security, failures, and verification

Production is same-origin and does not enable CORS. Setting `LOCAL_FRONTEND_ORIGIN` enables one explicit local origin—never a wildcard with credentials. There is no authentication because the data is disposable demonstration data. Add identity and authorisation before storing real user information.

If UI requests return 404, verify the path begins `/api/`, the ALB listener rule has priority 100, and FastAPI uses the same prefix. Verify locally with `pytest`, `npm test`, `curl http://localhost:8000/api/health`, and browser accessibility tools.

The repository is process-local: restart resets it, multiple tasks do not share it, and target-group load balancing can expose inconsistent lists after scaling. “Repository” here means the storage abstraction; “request model” and “response model” mean Pydantic schemas.

References: [FastAPI](https://fastapi.tiangolo.com/), [Pydantic](https://docs.pydantic.dev/), [Next.js](https://nextjs.org/docs), [Testing Library](https://testing-library.com/docs/).

