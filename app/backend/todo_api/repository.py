import asyncio
from datetime import UTC, datetime

from .models import Todo, TodoCreate, TodoUpdate


class TodoNotFoundError(Exception):
    def __init__(self, todo_id: int) -> None:
        super().__init__(f"Todo {todo_id} was not found")
        self.todo_id = todo_id


class InMemoryTodoRepository:
    """Concurrency-safe process-local repository for demonstration use only."""

    def __init__(self) -> None:
        now = datetime.now(UTC)
        self._todos: dict[int, Todo] = {
            1: Todo(
                id=1,
                title="Review the architecture",
                description="Follow a request from the ALB to both containers.",
                completed=True,
                created_at=now,
            ),
            2: Todo(
                id=2,
                title="Publish immutable images",
                description="Build once, then promote digest-pinned images.",
                completed=False,
                created_at=now,
            ),
        }
        self._next_id = 3
        self._lock = asyncio.Lock()

    async def list(self) -> list[Todo]:
        async with self._lock:
            return list(sorted(self._todos.values(), key=lambda todo: todo.id))

    async def get(self, todo_id: int) -> Todo:
        async with self._lock:
            try:
                return self._todos[todo_id]
            except KeyError as error:
                raise TodoNotFoundError(todo_id) from error

    async def create(self, request: TodoCreate) -> Todo:
        async with self._lock:
            todo = Todo(
                id=self._next_id,
                title=request.title,
                description=request.description,
                completed=request.completed,
                created_at=datetime.now(UTC),
            )
            self._todos[todo.id] = todo
            self._next_id += 1
            return todo

    async def update(self, todo_id: int, request: TodoUpdate) -> Todo:
        async with self._lock:
            try:
                current = self._todos[todo_id]
            except KeyError as error:
                raise TodoNotFoundError(todo_id) from error
            updated = current.model_copy(update=request.model_dump(exclude_unset=True))
            self._todos[todo_id] = updated
            return updated

    async def delete(self, todo_id: int) -> None:
        async with self._lock:
            if self._todos.pop(todo_id, None) is None:
                raise TodoNotFoundError(todo_id)
