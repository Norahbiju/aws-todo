import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { beforeEach, describe, expect, it, vi } from "vitest";

import Home from "./page";

const seeded = [{ id: 1, title: "Test the UI", description: "", completed: false, created_at: "2026-01-01T00:00:00Z" }];

describe("Home", () => {
  beforeEach(() => vi.restoreAllMocks());

  it("loads and completes a Todo", async () => {
    const fetchMock = vi.spyOn(globalThis, "fetch")
      .mockResolvedValueOnce(new Response(JSON.stringify(seeded), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ ...seeded[0], completed: true }), { status: 200 }));
    render(<Home />);
    expect(await screen.findByText("Test the UI")).toBeInTheDocument();
    await userEvent.click(screen.getByLabelText("Mark Test the UI complete"));
    await waitFor(() => expect(screen.getByLabelText("Mark Test the UI incomplete")).toBeInTheDocument());
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it("creates a Todo", async () => {
    vi.spyOn(globalThis, "fetch")
      .mockResolvedValueOnce(new Response(JSON.stringify([]), { status: 200 }))
      .mockResolvedValueOnce(new Response(JSON.stringify({ ...seeded[0], title: "A new task" }), { status: 201 }));
    render(<Home />);
    await screen.findByText("Nothing on the list.");
    await userEvent.type(screen.getByLabelText("Add a task"), "A new task");
    await userEvent.click(screen.getByRole("button", { name: "Add task" }));
    expect(await screen.findByText("A new task")).toBeInTheDocument();
  });

  it("shows an error with retry", async () => {
    vi.spyOn(globalThis, "fetch").mockRejectedValueOnce(new Error("Network unavailable"));
    render(<Home />);
    expect(await screen.findByRole("alert")).toHaveTextContent("Network unavailable");
    expect(screen.getByRole("button", { name: "Retry" })).toBeEnabled();
  });
});

