# Zadanie 2 – GitHub Actions Pipeline

Repozytorium zawiera aplikację pogodową Flask z Zadania 1 oraz łańcuch GitHub Actions, który automatycznie buduje obraz wieloarchitekturowy, skanuje go pod kątem podatności CVE i przesyła do rejestru GHCR.

## Struktura plików

```
.
├── app.py
├── requirements.txt
├── Dockerfile
└── .github/
    └── workflows/
        └── build-push.yml
```

## Konfiguracja GitHub Actions

Plik workflow: [.github/workflows/build-push.yml](.github/workflows/build-push.yml)

### Sekrety wymagane w repozytorium GitHub

| Sekret | Opis |
|--------|------|
| `DOCKERHUB_USERNAME` | Nazwa użytkownika DockerHub (`mgodz`) |
| `DOCKERHUB_TOKEN` | Access Token DockerHub (Settings → Security → New Access Token) |

`GITHUB_TOKEN` jest dostarczany automatycznie przez GitHub Actions – nie wymaga konfiguracji.

### Etapy pipeline'u

1. **Checkout** – pobranie kodu źródłowego
2. **QEMU** – emulacja arm64 na hoście amd64 (`docker/setup-qemu-action`)
3. **Docker Buildx** – sterownik wieloplatformowy (`docker/setup-buildx-action`)
4. **Login do GHCR** – uwierzytelnienie przy `push` (nie przy PR)
5. **Login do DockerHub** – uwierzytelnienie do odczytu/zapisu cache
6. **Metadata** – generowanie tagów obrazu (`docker/metadata-action`)
7. **Build (amd64)** – budowanie obrazu lokalnie na potrzeby skanowania
8. **Trivy scan** – skan CVE; pipeline przerywa się przy CRITICAL lub HIGH
9. **Build & Push (multi-arch)** – budowanie i publikacja obrazu (tylko przy `push` do `main`)

---

## Tagowanie obrazów

Do generowania tagów użyto `docker/metadata-action@v5`. Każdy `push` do gałęzi `main` tworzy trzy tagi:

| Tag | Przykład | Cel |
|-----|---------|-----|
| `sha-<skrócony commit>` | `sha-a1b2c3d` | Precyzyjna identyfikacja wersji; tag jest niezmienny i umożliwia odtworzenie dokładnie tego samego obrazu |
| `<nazwa gałęzi>` | `main` | Ułatwia pobieranie najnowszego obrazu z danej gałęzi bez znania SHA |
| `latest` | `latest` | Konwencjonalny skrót do najnowszego stabilnego obrazu; generowany tylko dla gałęzi domyślnej |

**Uzasadnienie:** Strategia *immutable SHA tag + mutable branch/latest tag* jest rekomendowana przez [Docker documentation](https://docs.docker.com/build/ci/github-actions/manage-tags-labels/) oraz przez praktykę opisaną w [Semver tagging strategy](https://github.com/docker/metadata-action#tags-input). Tag SHA gwarantuje odtwarzalność (`reproducibility`) – można zawsze wskazać dokładnie ten obraz, który był używany w produkcji. Tagi `latest` i `main` służą wygodzie w CI/CD i lokalnym developmencie.

---

## Cache (DockerHub)

```
Rejestr cache: mgodz/weather-app-cache:buildcache
Tryb: mode=max
```

- **Eksporter i backend**: `type=registry` – dane cache są przechowywane jako manifest w publicznym repozytorium DockerHub `mgodz/weather-app-cache`.
- **Tryb `max`**: zapisuje cache dla wszystkich warstw pośrednich wszystkich etapów (`builder` + `runtime`), nie tylko warstw końcowego obrazu. Dzięki temu ponowne budowanie po małej zmianie kodu (`app.py`) pomija kosztowne `pip install` (etap `builder`), bo te warstwy są już w cache.
- Cache jest odczytywany (`cache-from`) w kroku skanowania oraz w kroku finalnego push, a zapisywany (`cache-to`) wyłącznie w kroku finalnego push – po pomyślnym przejściu skanu CVE.

---

## Skan CVE – Trivy

Do skanowania podatności wybrano **Trivy** (`aquasecurity/trivy-action@0.28.0`).

**Uzasadnienie wyboru Trivy zamiast Docker Scout:**

| Kryterium | Trivy | Docker Scout |
|-----------|-------|-------------|
| Licencja | Apache 2.0 (open source) | Wymaga subskrypcji Docker dla pełnego CI/CD |
| GitHub Action | `aquasecurity/trivy-action` – oficjalna, aktywnie rozwijana | `docker/scout-action` – wymaga logowania do Docker Hub z planem Pro |
| Bazy CVE | Wiele źródeł (NVD, GHSA, OS advisories) | Zależy od Docker Scout backend |
| Konfiguracja | Minimalna – `exit-code: '1'` zatrzymuje pipeline | Wymaga dodatkowej konfiguracji kont |

Trivy skanuje zarówno pakiety systemowe OS (`vuln-type: os`) jak i biblioteki aplikacji (`library`). Pipeline przerywa się z błędem (`exit-code: '1'`) gdy wykryte zostaną podatności o klasyfikacji `CRITICAL` lub `HIGH`, co uniemożliwia push obrazu do GHCR.

Skan jest wykonywany na obrazie `linux/amd64` zbudowanym lokalnie (opcja `load: true`) – Docker daemon nie obsługuje jednoczesnego ładowania obrazu wieloplatformowego do lokalnego engine.

---

## Wynik działania pipeline'u

Po poprawnym uruchomieniu workflow obraz jest dostępny pod adresami:

```
ghcr.io/neskepp/weather-app:latest
ghcr.io/neskepp/weather-app:main
ghcr.io/neskepp/weather-app:sha-<commit>
```

Cache przechowywany jest w:

```
mgodz/weather-app-cache:buildcache
```
