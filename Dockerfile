# ---- etap 1 builder ----
# instalujemy zaleznosci w osobnym etapie zeby nie trafily do obrazu finalnego
FROM python:3.12-slim AS builder

WORKDIR /install

# kopiujemy tylko requirements.txt zeby cache nie byl uniewazniony przy kazdej zmianie kodu
COPY requirements.txt .

# instalujemy paczki do izolowanego katalogu
RUN pip install --no-cache-dir --target=/install/pkgs -r requirements.txt


# ---- etap 2 runtime ----
# czysty obraz slim bez pip i setuptools
FROM python:3.12-slim

# metadane oci
LABEL org.opencontainers.image.authors="Mieszko Godzisz" \
      org.opencontainers.image.title="weather-app" \
      org.opencontainers.image.description="Aplikacja pogodowa Open Meteo"

WORKDIR /app

# kopiujemy paczki z etapu builder
COPY --from=builder /install/pkgs /app/pkgs

# kod aplikacji kopiujemy na koncu bo zmienia sie najczesciej
COPY app.py .

# pythonpath wskazuje na katalog z paczkami
ENV PYTHONPATH=/app/pkgs \
    PYTHONUNBUFFERED=1

EXPOSE 8080

# healthcheck sprawdza co 30s czy aplikacja odpowiada
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c \
        "import urllib.request; urllib.request.urlopen('http://localhost:8080/weather?city=Krakow', timeout=4)"

CMD ["python", "app.py"]
