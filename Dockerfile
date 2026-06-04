FROM python:3.12-slim AS builder
WORKDIR /app
COPY requirements.txt .
RUN pip install --user --no-cache-dir -r requirements.txt

FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /root/.local /root/.local
COPY hello.py .
ENV PATH=/root/.local/bin:$PATH
EXPOSE 8080
CMD ["python", "hello.py"]
