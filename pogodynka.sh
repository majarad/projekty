#!/bin/bash

export LANG=C.UTF-8

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;97m'
RESET='\033[0m'

# Funkcja do wyświetlania pomocy (treść help została napisana przy pomocy ChataGPT)
show_help()
{
    echo -e "${CYAN}------------------------------------------------------------"
    echo -e "      ${BLUE}Program do sprawdzania pogody na podstawie      "
    echo -e "         ${MAGENTA}najbliższej stacji meteorologicznej   "
    echo -e "${CYAN}------------------------------------------------------------"
    echo
    echo -e "${WHITE}Szukaj danych pogodowych dla miast w Polsce, korzystając"
    echo -e "z ${MAGENTA}najbliższej stacji meteorologicznej w pobliżu.${RESET}"
    echo
    echo -e "${BLUE}Użycie:"
    echo -e "  ./projekt.sh [opcje]"
    echo
    echo -e "${CYAN}Opcje:"
    echo -e "  ${GREEN}-h, --help            ${BLUE}Wyświetla tę pomoc${RESET}"
    echo -e "  ${GREEN}(brak opcji)          ${BLUE}Uruchamia interaktywny proces sprawdzania pogody${RESET}"
    echo
    echo -e "${WHITE}Opis:"
    echo -e "  Program pozwala na podanie nazwy miasta, oblicza odległość"
    echo -e "  do ${MAGENTA}najbliższej stacji meteorologicznej${RESET} i wyświetla dane"
    echo -e "  pogodowe takie jak ${CYAN}temperatura, wilgotność, ciśnienie"
    echo -e "  oraz prędkość i kierunek wiatru.${RESET}"
    echo
    echo -e "${WHITE}Zasady korzystania z programu:"
    echo -e "  - Program dba o ograniczenia czasowe podczas zapytań do"
    echo -e "    zewnętrznych serwisów, aby nie przekroczyć dozwolonych"
    echo -e "    limitów API."
    echo -e "  - ${MAGENTA}Odstęp między zapytaniami do API Nominatim${RESET} wynosi minimum"
    echo -e "    1 sekundę."
    echo
    echo -e "${GREEN}Twórca: Maja Radowska"
    echo -e "Wersja: 1.0"
    echo -e "Data: 2025-01-12${RESET}"
    echo -e "${CYAN}------------------------------------------------------------${RESET}"
}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

CACHE_DIR="$HOME/.cache/stations"
CACHE_FILE="$CACHE_DIR/stations_coordinates.txt"
URL="https://danepubliczne.imgw.pl/api/data/synop"
API_DELAY=1 # Odstęp między zapytaniami do API
LAST_API_CALL=0

mkdir -p "$CACHE_DIR"

if [[ ! -f "$CACHE_FILE" ]]; then
    echo -e "${GREEN}Pobieranie danych z $URL...${RESET}"
    echo
    DATA=$(curl -s "$URL")

    if [[ -z "$DATA" ]]; then
        echo -e "${RED}Nie udało się pobrać danych.${RESET}" 
        exit 1
    fi

    echo "$DATA" | jq -r '.[] | "\(.stacja)"' | while IFS= read -r city; do
        # Sprawdzanie opóźnienia między zapytaniami (pomoc ChataGPT)
        CURRENT_TIME=$(date +%s)
        TIME_DIFF=$((CURRENT_TIME - LAST_API_CALL))
        if ((TIME_DIFF < API_DELAY)); then
            sleep $((API_DELAY - TIME_DIFF))
        fi

        coords=$(curl -s "https://nominatim.openstreetmap.org/search?q=$(jq -sRr @uri <<< "$city")&format=json" | jq -r '.[0] | "\(.lat), \(.lon)" // "null, null"')
        echo -e "${MAGENTA}Zapisano dane dla:${RESET} $city, $coords"
        echo
        echo "$city, $coords" >> "$CACHE_FILE"
        LAST_API_CALL=$(date +%s) # Aktualizacja czasu ostatniego zapytania
    done
else
    DATA=$(curl -s "$URL")
fi

check_weather()
{
    echo -e "${CYAN}Podaj nazwę miasta: ${RESET}"
    read -e userCity
    userCity=$(echo "$userCity" | iconv -f utf-8 -t ascii//TRANSLIT) # Usunięcie znaków specjalnych

    # Sprawdzenie opóźnienia przed zapytaniem
    CURRENT_TIME=$(date +%s)
    TIME_DIFF=$((CURRENT_TIME - LAST_API_CALL))
    if ((TIME_DIFF < API_DELAY)); then
        sleep $((API_DELAY - TIME_DIFF))
    fi

    user_coords=$(curl -s "https://nominatim.openstreetmap.org/search?q=$(jq -sRr @uri <<< "$userCity")&format=json" | jq -r '.[0] | "\(.lat), \(.lon)" // "null, null"')
    LAST_API_CALL=$(date +%s)

    if [[ "$user_coords" == "null, null" ]]; then
        echo -e "${RED}Nie znaleziono miasta:${RESET} $userCity"
        return
    fi

    CURRENT_LAT=$(echo "$user_coords" | cut -d, -f1 | xargs)
    CURRENT_LON=$(echo "$user_coords" | cut -d, -f2 | xargs)

    haversine()
    {
        awk -v lat1="$1" -v lon1="$2" -v lat2="$3" -v lon2="$4" '
        BEGIN {
            pi = 3.141592653589793;
            r = 6371;  # Promień Ziemi w km

            lat1 = lat1 * pi / 180;
            lon1 = lon1 * pi / 180;
            lat2 = lat2 * pi / 180;
            lon2 = lon2 * pi / 180;

            dlat = lat2 - lat1;
            dlon = lon2 - lon1;

            a = sin(dlat / 2) ^ 2 + cos(lat1) * cos(lat2) * sin(dlon / 2) ^ 2;
            c = 2 * atan2(sqrt(a), sqrt(1 - a));

            print r * c;
        }'
    }

    closest_distance=99999999
    closest_station=""

    while IFS=, read -r name lat lon; do
        distance=$(haversine "$CURRENT_LAT" "$CURRENT_LON" "$lat" "$lon")
        if (( $(echo "$distance < $closest_distance" | bc -l) )); then
            closest_distance=$distance
            closest_station=$name
        fi
    done < "$CACHE_FILE"

    # Wyświetlanie danych pogodowych
    weather_data=$(echo "$DATA" | jq -r --arg station "$closest_station" '.[] | select(.stacja == $station)')
    if [[ -z "$weather_data" ]]; then
        echo -e "${RED}Nie udało się pobrać danych pogodowych dla stacji:${RESET} $closest_station"
        return
    fi

    station_id=$(echo "$weather_data" | jq -r '.id_stacji')
    measurement_date=$(echo "$weather_data" | jq -r '.data_pomiaru')
    measurement_hour=$(echo "$weather_data" | jq -r '.godzina_pomiaru')

    echo
    echo -e "${MAGENTA}${closest_station} [${station_id}] / ${measurement_date} ${measurement_hour}:00${RESET}"
    echo
    typing_effect_green "Temperatura:         $(echo "$weather_data" | jq -r '.temperatura') °C" 0.1
    typing_effect_green "Prędkość wiatru:     $(echo "$weather_data" | jq -r '.predkosc_wiatru') m/s" 0.1
    typing_effect_green "Kierunek wiatru:     $(echo "$weather_data" | jq -r '.kierunek_wiatru') °" 0.1
    typing_effect_green "Wilgotność wzgl.:    $(echo "$weather_data" | jq -r '.wilgotnosc_wzgledna') %" 0.1
    typing_effect_green "Suma opadu:          $(echo "$weather_data" | jq -r '.suma_opadu') mm" 0.1
    typing_effect_green "Ciśnienie:           $(echo "$weather_data" | jq -r '.cisnienie') hPa" 0.1
}

# Bajery wyświetlania - pomoc ChataGPT
typing_effect_magenta() 
{
    local text="$1"
    local delay="${2:-0.1}"
    
    # Pętla przez każdy znak tekstu
    for ((i = 0; i < ${#text}; i++)); do
        echo -e -n "${MAGENTA}${text:$i:1}${RESET}"
        sleep $delay
    done
    echo
}

typing_effect_green() 
{
    local text="$1"
    local delay="${2:-0.1}"
    
    for ((i = 0; i < ${#text}; i++)); do
        echo -e -n "${GREEN}${text:$i:1}${RESET}"
        sleep $delay
    done
    echo
}

# Główna pętla
while true; do
    check_weather
    echo
    echo -e "Czy chcesz sprawdzić inne miasto? Jeśli tak, kliknij ${GREEN}'t'${RESET}, a jeśli nie, to ${RED}dowolny klawisz${RESET}: "
    echo
    read -e choice
    echo
    if [[ "$choice" != "t" ]]; then
		clear
        # Zakończenie z efektem „typing”
        typing_effect_magenta "Dziękujemy za skorzystanie z programu! Do zobaczenia!"
        
        # Prosty efekt animacji
        clear
        typing_effect_magenta "Zamykam program za 3 sekundy..." 0.1
        sleep 1
        clear
        typing_effect_magenta "Zamykam program za 2 sekundy..." 0.1
        sleep 1
        clear
        typing_effect_magenta "Zamykam program za 1 sekundę..." 0.1
        sleep 1
        clear
        echo -e "${RED}Program zakończony!${RESET}"
        break
    fi
done