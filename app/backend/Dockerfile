FROM python:3.13.5-slim AS builder
WORKDIR /build
COPY pyproject.toml ./
COPY todo_api ./todo_api
RUN python -m pip install --no-cache-dir --upgrade pip build \
    && python -m build --wheel \
    && python -m pip wheel --no-cache-dir --wheel-dir /wheels dist/*.whl

FROM python:3.13.5-slim AS runtime
ARG SOURCE_URL="https://github.com/OWNER/REPOSITORY"
LABEL org.opencontainers.image.source=$SOURCE_URL
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1
RUN addgroup --system app && adduser --system --ingroup app --home /home/app app
COPY --from=builder /wheels /wheels
RUN python -m pip install --no-cache-dir /wheels/*.whl && rm -rf /wheels
WORKDIR /app
USER app
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/api/health', timeout=3)"
CMD ["uvicorn", "todo_api.main:app", "--host", "0.0.0.0", "--port", "8000", "--no-access-log"]
