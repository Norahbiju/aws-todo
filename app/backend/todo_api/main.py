import logging
import os
import time
import uuid
from collections.abc import Awaitable, Callable

from fastapi import FastAPI, Request, Response, status
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from .logging_config import configure_logging
from .models import ErrorResponse, HealthResponse, Todo, TodoCreate, TodoUpdate
from .repository import InMemoryTodoRepository, TodoNotFoundError

configure_logging()
logger = logging.getLogger("todo_api")


def create_app(repository: InMemoryTodoRepository | None = None) -> FastAPI:
    app = FastAPI(title="Todo API", version="1.0.0", docs_url="/api/docs")
    app.state.repository = repository or InMemoryTodoRepository()

    local_origin = os.getenv("LOCAL_FRONTEND_ORIGIN")
    if local_origin:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=[local_origin],
            allow_credentials=False,
            allow_methods=["GET", "POST", "PATCH", "DELETE"],
            allow_headers=["Content-Type"],
        )

    @app.middleware("http")
    async def request_logging(
        request: Request, call_next: Callable[[Request], Awaitable[Response]]
    ) -> Response:
        request_id = request.headers.get("x-request-id", str(uuid.uuid4()))
        started = time.perf_counter()
        response = await call_next(request)
        response.headers["x-request-id"] = request_id
        logger.info(
            "request_complete method=%s path=%s status=%s duration_ms=%.2f",
            request.method,
            request.url.path,
            response.status_code,
            (time.perf_counter() - started) * 1000,
            extra={"request_id": request_id},
        )
        return response

    @app.exception_handler(TodoNotFoundError)
    async def todo_not_found(_: Request, error: TodoNotFoundError) -> JSONResponse:
        return JSONResponse(status_code=404, content={"detail": str(error)})

    @app.exception_handler(RequestValidationError)
    async def validation_failed(_: Request, error: RequestValidationError) -> JSONResponse:
        logger.info("request_validation_failed errors=%s", error.errors())
        return JSONResponse(status_code=422, content={"detail": "Request validation failed"})

    @app.exception_handler(Exception)
    async def unexpected_error(_: Request, error: Exception) -> JSONResponse:
        logger.exception("unhandled_error", exc_info=error)
        return JSONResponse(status_code=500, content={"detail": "Internal server error"})

    @app.get("/api/health", response_model=HealthResponse, tags=["health"])
    async def health() -> HealthResponse:
        return HealthResponse(status="ok")

    @app.get("/api/todos", response_model=list[Todo], tags=["todos"])
    async def list_todos(request: Request) -> list[Todo]:
        return await request.app.state.repository.list()

    @app.get(
        "/api/todos/{todo_id}",
        response_model=Todo,
        responses={404: {"model": ErrorResponse}},
        tags=["todos"],
    )
    async def get_todo(todo_id: int, request: Request) -> Todo:
        return await request.app.state.repository.get(todo_id)

    @app.post(
        "/api/todos",
        response_model=Todo,
        status_code=status.HTTP_201_CREATED,
        tags=["todos"],
    )
    async def create_todo(todo: TodoCreate, request: Request) -> Todo:
        return await request.app.state.repository.create(todo)

    @app.patch(
        "/api/todos/{todo_id}",
        response_model=Todo,
        responses={404: {"model": ErrorResponse}},
        tags=["todos"],
    )
    async def update_todo(todo_id: int, todo: TodoUpdate, request: Request) -> Todo:
        return await request.app.state.repository.update(todo_id, todo)

    @app.delete(
        "/api/todos/{todo_id}",
        status_code=status.HTTP_204_NO_CONTENT,
        tags=["todos"],
    )
    async def delete_todo(todo_id: int, request: Request) -> Response:
        await request.app.state.repository.delete(todo_id)
        return Response(status_code=status.HTTP_204_NO_CONTENT)

    return app


app = create_app()
