FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy into backend/ subdirectory so `backend.xxx` imports resolve
COPY . ./backend/

ENV DATABASE_URL=""
ENV REDIS_URL=""
ENV OLLAMA_BASE_URL=""
ENV ANTHROPIC_API_KEY=""

EXPOSE 8000

CMD ["uvicorn", "backend.main:app", "--host", "0.0.0.0", "--port", "8000"]
