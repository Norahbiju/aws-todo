import pytest
from fastapi.testclient import TestClient

from todo_api.main import create_app
from todo_api.repository import InMemoryTodoRepository


@pytest.fixture
def client() -> TestClient:
    with TestClient(create_app(InMemoryTodoRepository()), raise_server_exceptions=False) as client:
        yield client

