import type { Todo, TodoCreate, TodoUpdate } from "./types";

const API_BASE = process.env.NEXT_PUBLIC_API_BASE_URL ?? "";

export class ApiError extends Error {
  constructor(message: string, readonly status: number) {
    super(message);
    this.name = "ApiError";
  }
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${API_BASE}${path}`, {
    ...init,
    headers: { "Content-Type": "application/json", ...init?.headers },
  });
  if (!response.ok) {
    let message = `Request failed (${response.status})`;
    try {
      const body = (await response.json()) as { detail?: string };
      message = body.detail ?? message;
    } catch {
      // Preserve the status-based message for non-JSON responses.
    }
    throw new ApiError(message, response.status);
  }
  return response.status === 204 ? (undefined as T) : ((await response.json()) as T);
}

export const todoApi = {
  list: () => request<Todo[]>("/api/todos"),
  create: (todo: TodoCreate) =>
    request<Todo>("/api/todos", { method: "POST", body: JSON.stringify(todo) }),
  update: (id: number, todo: TodoUpdate) =>
    request<Todo>(`/api/todos/${id}`, { method: "PATCH", body: JSON.stringify(todo) }),
  delete: (id: number) => request<void>(`/api/todos/${id}`, { method: "DELETE" }),
};

