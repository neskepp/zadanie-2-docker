## Zadanie 3

Należy podać polecenia niezbędne do:

- a. zbudowania opracowanego obrazu kontenera,
- b. uruchomienia kontenera na podstawie zbudowanego obrazu,
- c. sposobu uzyskania informacji z logów, które wygenerowała opracowana aplikacja podczas uruchamiania kontenera,
- d. sprawdzenia, ile warstw posiada zbudowany obraz oraz jaki jest rozmiar obrazu.

---

## a. Budowanie obrazu

```bash
docker build -t weather-app .
```

## b. Uruchomienie kontenera

```bash
docker run -d -p 8080:8080 --name weather weather-app
```

## c. Logi aplikacji

```bash
docker logs weather
```

## d. Warstwy i rozmiar obrazu

```bash
docker images weather-app
```

```bash
docker inspect weather-app --format='{{len .RootFS.Layers}} layers'
```

---

## Uruchomienie krok po kroku

### 1. Zbuduj obraz

```bash
docker build -t weather-app .
```

### 2. Uruchom kontener

```bash
docker run -d -p 8080:8080 --name weather weather-app
```

### 3. Sprawdź czy kontener działa

```bash
docker ps
```

### 4. Wyślij przykładowe zapytanie

Dostępne miasta: `Krakow`, `Gdansk`, `Lublin`.

```bash
curl "http://localhost:8080/weather?city=Krakow"
```

Przykładowa odpowiedź:

```json
{
  "city": "Krakow",
  "temperature_c": 18.5,
  "precipitation_mm": 0.0
}
```

### 5. Sprawdź logi

```bash
docker logs weather
```
