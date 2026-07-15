"use client";

import { FormEvent, useCallback, useEffect, useState } from "react";

import { todoApi } from "@/lib/api";
import type { Todo } from "@/lib/types";

export default function Home() {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [loading, setLoading] = useState(true);
  const [busyId, setBusyId] = useState<number | "new" | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [title, setTitle] = useState("");
  const [description, setDescription] = useState("");
  const [editingId, setEditingId] = useState<number | null>(null);
  const [editTitle, setEditTitle] = useState("");
  const [editDescription, setEditDescription] = useState("");

  const loadTodos = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      setTodos(await todoApi.list());
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Could not load Todos");
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    let cancelled = false;
    todoApi
      .list()
      .then((items) => {
        if (!cancelled) setTodos(items);
      })
      .catch((requestError: unknown) => {
        if (!cancelled) {
          setError(requestError instanceof Error ? requestError.message : "Could not load Todos");
        }
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  async function createTodo(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!title.trim()) return;
    setBusyId("new");
    setError(null);
    try {
      const created = await todoApi.create({ title: title.trim(), description: description.trim() });
      setTodos((current) => [...current, created]);
      setTitle("");
      setDescription("");
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Could not create Todo");
    } finally {
      setBusyId(null);
    }
  }

  async function updateTodo(todo: Todo, changes: Partial<Todo>) {
    setBusyId(todo.id);
    setError(null);
    try {
      const updated = await todoApi.update(todo.id, changes);
      setTodos((current) => current.map((item) => (item.id === todo.id ? updated : item)));
      setEditingId(null);
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Could not update Todo");
    } finally {
      setBusyId(null);
    }
  }

  async function deleteTodo(todo: Todo) {
    setBusyId(todo.id);
    setError(null);
    try {
      await todoApi.delete(todo.id);
      setTodos((current) => current.filter((item) => item.id !== todo.id));
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : "Could not delete Todo");
    } finally {
      setBusyId(null);
    }
  }

  function beginEdit(todo: Todo) {
    setEditingId(todo.id);
    setEditTitle(todo.title);
    setEditDescription(todo.description);
  }

  const completed = todos.filter((todo) => todo.completed).length;

  return (
    <main>
      <section className="shell" aria-labelledby="page-title">
        <header className="hero">
          <div>
            <p className="eyebrow">YOUR DAY, CLEARLY</p>
            <h1 id="page-title">Focus List</h1>
            <p>Keep the next useful thing in sight.</p>
          </div>
          <div className="progress" aria-label={`${completed} of ${todos.length} completed`}>
            <strong>{completed}</strong><span> / {todos.length}</span>
            <small>complete</small>
          </div>
        </header>

        <form className="create" onSubmit={createTodo}>
          <label htmlFor="new-title">Add a task</label>
          <div className="form-grid">
            <input id="new-title" maxLength={120} value={title} onChange={(e) => setTitle(e.target.value)} placeholder="What needs doing?" disabled={busyId === "new"} />
            <input aria-label="Task description" maxLength={1000} value={description} onChange={(e) => setDescription(e.target.value)} placeholder="A little context (optional)" disabled={busyId === "new"} />
            <button type="submit" disabled={busyId === "new" || !title.trim()}>{busyId === "new" ? "Adding…" : "Add task"}</button>
          </div>
        </form>

        {error && <div className="error" role="alert"><span>{error}</span><button onClick={() => void loadTodos()}>Retry</button></div>}

        {loading ? (
          <div className="state" role="status">Loading your list…</div>
        ) : todos.length === 0 ? (
          <div className="state"><strong>Nothing on the list.</strong><span>Add one small thing above.</span></div>
        ) : (
          <ul className="todo-list">
            {todos.map((todo) => (
              <li key={todo.id} className={todo.completed ? "done" : ""}>
                {editingId === todo.id ? (
                  <form className="edit" onSubmit={(event) => { event.preventDefault(); void updateTodo(todo, { title: editTitle.trim(), description: editDescription.trim() }); }}>
                    <input aria-label="Edit task title" maxLength={120} value={editTitle} onChange={(e) => setEditTitle(e.target.value)} disabled={busyId === todo.id} />
                    <textarea aria-label="Edit task description" maxLength={1000} value={editDescription} onChange={(e) => setEditDescription(e.target.value)} disabled={busyId === todo.id} />
                    <div className="actions"><button type="submit" disabled={busyId === todo.id || !editTitle.trim()}>Save</button><button type="button" className="quiet" onClick={() => setEditingId(null)} disabled={busyId === todo.id}>Cancel</button></div>
                  </form>
                ) : (
                  <>
                    <button className="check" aria-label={`Mark ${todo.title} ${todo.completed ? "incomplete" : "complete"}`} onClick={() => void updateTodo(todo, { completed: !todo.completed })} disabled={busyId === todo.id}>{todo.completed ? "✓" : ""}</button>
                    <div className="content"><strong>{todo.title}</strong>{todo.description && <p>{todo.description}</p>}</div>
                    <div className="actions"><button className="quiet" onClick={() => beginEdit(todo)} disabled={busyId === todo.id}>Edit</button><button className="danger" onClick={() => void deleteTodo(todo)} disabled={busyId === todo.id}>Delete</button></div>
                  </>
                )}
              </li>
            ))}
          </ul>
        )}
      </section>
    </main>
  );
}
