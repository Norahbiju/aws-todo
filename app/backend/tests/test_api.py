from fastapi.testclient import TestClient


def test_health(client: TestClient) -> None:
    response = client.get("/api/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_list_seeded_todos(client: TestClient) -> None:
    response = client.get("/api/todos")
    assert response.status_code == 200
    assert len(response.json()) == 2


def test_create_and_get_todo(client: TestClient) -> None:
    created = client.post("/api/todos", json={"title": "Ship it", "description": "Carefully"})
    assert created.status_code == 201
    todo_id = created.json()["id"]
    assert client.get(f"/api/todos/{todo_id}").json()["title"] == "Ship it"


def test_update_and_complete_todo(client: TestClient) -> None:
    response = client.patch(
        "/api/todos/2", json={"title": "Publish images safely", "completed": True}
    )
    assert response.status_code == 200
    assert response.json()["title"] == "Publish images safely"
    assert response.json()["completed"] is True


def test_delete_todo(client: TestClient) -> None:
    assert client.delete("/api/todos/1").status_code == 204
    assert client.get("/api/todos/1").status_code == 404


def test_validation_rejects_blank_and_long_titles(client: TestClient) -> None:
    assert client.post("/api/todos", json={"title": "   "}).status_code == 422
    assert client.post("/api/todos", json={"title": "x" * 121}).status_code == 422


def test_missing_todo_responses(client: TestClient) -> None:
    assert client.get("/api/todos/999").status_code == 404
    assert client.patch("/api/todos/999", json={"completed": True}).status_code == 404
    assert client.delete("/api/todos/999").status_code == 404

