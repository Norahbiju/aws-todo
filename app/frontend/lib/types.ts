export interface Todo {
  id: number;
  title: string;
  description: string;
  completed: boolean;
  created_at: string;
}

export interface TodoCreate {
  title: string;
  description: string;
}

export interface TodoUpdate {
  title?: string;
  description?: string;
  completed?: boolean;
}

