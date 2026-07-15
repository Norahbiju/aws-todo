from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator


class TodoBase(BaseModel):
    title: str = Field(min_length=1, max_length=120)
    description: str = Field(default="", max_length=1000)

    @field_validator("title")
    @classmethod
    def title_must_not_be_blank(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("title must not be blank")
        return value


class TodoCreate(TodoBase):
    completed: bool = False


class TodoUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=120)
    description: str | None = Field(default=None, max_length=1000)
    completed: bool | None = None

    @field_validator("title")
    @classmethod
    def title_must_not_be_blank(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        if not value:
            raise ValueError("title must not be blank")
        return value


class Todo(TodoBase):
    model_config = ConfigDict(frozen=True)

    id: int
    completed: bool
    created_at: datetime


class HealthResponse(BaseModel):
    status: str


class ErrorResponse(BaseModel):
    detail: str

