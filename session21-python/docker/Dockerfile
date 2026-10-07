# ---------- build/test stage ----------
FROM python:3.13-slim AS build
WORKDIR /app
COPY application/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY application/ .
RUN python -m unittest discover -s tests -v

# ---------- runtime stage ----------
FROM python:3.13-slim
WORKDIR /app
COPY --from=build /app/app ./app
EXPOSE 8000
USER nobody
CMD ["python", "app/main.py"]
