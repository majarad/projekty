[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$CACHE_DIR = "$HOME\.cache\stations"
$CACHE_FILE = "$CACHE_DIR\stations_coordinates.txt"

if (-not (Test-Path -Path $CACHE_DIR)) 
{
    New-Item -Path $CACHE_DIR -ItemType Directory
}

if (Test-Path -Path $CACHE_FILE) 
{

} 
else 
{
    Write-Host "Pobieranie danych z https://danepubliczne.imgw.pl/api/data/synop..." -ForegroundColor Green
    Write-Host ""
    try {
        $URL = "https://danepubliczne.imgw.pl/api/data/synop"
        $response = Invoke-RestMethod -Uri $URL -Method Get
        
        foreach ($station in $response) {
            $city = $station.stacja
            
            $API = "https://nominatim.openstreetmap.org/search?q=$city&format=json&addressdetails=1&limit=1"
            $nominatimResponse = Invoke-RestMethod -Uri $API -Method Get
            
            if ($nominatimResponse.Count -gt 0) 
            {
                $lat = $nominatimResponse[0].lat
                $lon = $nominatimResponse[0].lon
                $coords = "$city, $lat, $lon"
                
                # Zapisz do pliku
                $coords | Out-File -FilePath $CACHE_FILE -Append -Encoding UTF8
                Write-Host "Zapisano dane dla: $city, $lat, $lon" -ForegroundColor Magenta
                Write-Host ""
            } 
            else 
            {
                Write-Host "Nie znaleziono wspolrzednych dla miasta: $city" -ForegroundColor Red
                Write-Host ""
            }
            # Ograniczenie częstotliwości zapytań do Nominatim 
            Start-Sleep -Seconds 1
        }
    } 
    catch 
    {
        Write-Host "Wystapil blad podczas pobierania danych z API." -ForegroundColor Red
    }
}

function Haversine 
{
    param (
        [Parameter(Mandatory=$true)]
        [float]$lat1,

        [Parameter(Mandatory=$true)]
        [float]$lon1,

        [Parameter(Mandatory=$true)]
        [float]$lat2,

        [Parameter(Mandatory=$true)]
        [float]$lon2
    )

    $R = 6371

    $lat1 = [math]::PI * $lat1 / 180
    $lon1 = [math]::PI * $lon1 / 180
    $lat2 = [math]::PI * $lat2 / 180
    $lon2 = [math]::PI * $lon2 / 180

    $dlat = $lat2 - $lat1
    $dlon = $lon2 - $lon1

    $a = [math]::Sin($dlat / 2) * [math]::Sin($dlat / 2) + [math]::Cos($lat1) * [math]::Cos($lat2) * [math]::Sin($dlon / 2) * [math]::Sin($dlon / 2)
    $c = 2 * [math]::Atan2([math]::Sqrt($a), [math]::Sqrt(1 - $a))

    $distance = $R * $c
    return $distance
}

# Bajery wyświetlania - pomoc ChataGPT
function TypingEffectGreen 
{
    param (
        [string]$Text,
        [double]$Delay = 0.2 
    )

    $green = [ConsoleColor]::Green
    $defaultColor = [Console]::ForegroundColor
    [Console]::ForegroundColor = $green

    foreach ($char in $Text.ToCharArray()) 
    {
        Write-Host -NoNewline $char
        Start-Sleep -Seconds $Delay
    }

    [Console]::ForegroundColor = $defaultColor
    Write-Host
}

Write-Host "Podaj nazwe miasta:" -ForegroundColor Cyan
$userCity = Read-Host 
Write-Host ""

$userCityUrl = "https://nominatim.openstreetmap.org/search?q=$userCity&format=json&addressdetails=1&limit=1"
$userCityResponse = Invoke-RestMethod -Uri $userCityUrl -Method Get

if ($userCityResponse.Count -gt 0) 
{
    $userLat = $userCityResponse[0].lat
    $userLon = $userCityResponse[0].lon

    $closestDistance = 99999999
    $closestStation = ""

    $stations = Get-Content -Path $CACHE_FILE

    foreach ($station in $stations) 
    {
        $parts = $station -split ","
        $name = $parts[0].Trim()
        $lat = [double]$parts[1].Trim()
        $lon = [double]$parts[2].Trim()

        $distance = Haversine -lat1 $userLat -lon1 $userLon -lat2 $lat -lon2 $lon

        # Jeśli stacja jest bliżej, zaktualizuj wynik
        if ($distance -lt $closestDistance) 
        {
            $closestDistance = $distance
            $closestStation = $name
        }
    }

    $weatherUrl = "https://danepubliczne.imgw.pl/api/data/synop/$closestStation"
    $weatherResponse = Invoke-RestMethod -Uri $weatherUrl -Method Get

    if ($weatherResponse) 
    {
        $temperatura = $weatherResponse[0].temperatura
        $predkosc_wiatru = $weatherResponse[0].predkosc_wiatru
        $kierunek_wiatru = $weatherResponse[0].kierunek_wiatru
        $wilgotnosc_wzgledna = $weatherResponse[0].wilgotnosc_wzgledna
        $suma_opadu = $weatherResponse[0].suma_opadu
        $cisnienie = $weatherResponse[0].cisnienie
        $data_pomiaru = $weatherResponse[0].data_pomiaru
        $godzina_pomiaru = $weatherResponse.godzina_pomiaru
        $godzina = "{0:D2}:00" -f [int]$godzina # Pomoc ChatuGPT w sformatowaniu godziny

        TypingEffectGreen "$closestStation / $data_pomiaru $godzina" -Delay 0.5
        Write-Host ""
        TypingEffectGreen "Temperatura:            $temperatura °C" -Delay 0.5
        TypingEffectGreen "Predkosc wiatru:        $predkosc_wiatru m/s" -Delay 0.5
        TypingEffectGreen "Kierunek wiatru:        $kierunek_wiatru °" -Delay 0.5
        TypingEffectGreen "Wilgotnosc wzgled.:     $wilgotnosc_wzgledna %" -Delay 0.5
        TypingEffectGreen "Suma opadu:             $suma_opadu mm" -Delay 0.5
        TypingEffectGreen "Cisnienie:              $cisnienie hPa" -Delay 0.5
        Write-Host ""
    } 
    else 
    {
        Write-Host "Brak danych pogodowych dla najblizszej stacji." -ForegroundColor Red
    }

} 
else 
{
    Write-Host "Nie znaleziono wspolrzednych dla Twojego miasta: $userCity" -ForegroundColor Red
}
Pause
