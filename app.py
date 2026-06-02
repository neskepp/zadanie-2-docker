from flask import Flask, jsonify, request
import requests, logging, datetime, sys

app = Flask(__name__)
PORT = 8080

# predefiniowana lista miast z koordynatami geograficznymi
CITIES = {
    "Krakow": (50.0647, 19.9450),
    "Gdansk": (54.3520, 18.6466),
    "Lublin": (51.2465, 22.5683),
}

@app.route("/weather")
def weather():
    # pobierz nazwe miasta z query stringa
    city = request.args.get("city", "")
    if city not in CITIES:
        return jsonify({"error": f"Dostepne miasta: {list(CITIES)}"}), 400
    lat, lon = CITIES[city]
    # zapytanie do open meteo api - brak klucza api wymagany
    r = requests.get("https://api.open-meteo.com/v1/forecast", params={
        "latitude": lat, "longitude": lon,
        "current": "temperature_2m,precipitation",
    }, timeout=10).json()
    cur = r["current"]
    # zwroc temperature i opady dla wybranego miasta
    return jsonify({"city": city, "temperature_c": cur["temperature_2m"], "precipitation_mm": cur["precipitation"]})

if __name__ == "__main__":
    logging.basicConfig(stream=sys.stdout, level=logging.INFO, format="%(asctime)s %(message)s")
    # log startowy z data autorem i portem
    logging.info(f"Start: {datetime.datetime.now().isoformat()} | Autor: Mieszko Godzisz | Port: {PORT}")
    app.run(host="0.0.0.0", port=PORT)
