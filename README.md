# 🇵🇱: Portfolio Projektowe – Maja Radowska

Cześć! 👋 W tym repozytorium znajdziesz zbiór moich projektów programistycznych. Każdy z nich znajduje się w osobnym katalogu i demonstruje inne obszary moich umiejętności – od tworzenia aplikacji webowych z elementami sztucznej inteligencji, przez gry konsolowe, aż po programowanie systemowe.

Poniżej znajduje się krótki opis każdego z projektów.

---

### 1. Inteligentna Lista Zadań (Python + Prolog)
📂 **Katalog:** `ToDoList-prolog`

Aplikacja webowa typu "ToDo List", która wyróżnia się zastosowaniem logiki rozmytej. Dzięki połączeniu **Pythona (Flask)** z **Prologiem**, system potrafi analizować sens wprowadzanych zadań.

**Kluczowe funkcjonalności:**
* **Wykrywanie duplikatów:** Aplikacja ostrzega, jeśli spróbujesz dodać zadanie semantycznie podobne do istniejącego (np. "Kupić mleko" i "Kup mleko").
* **Analiza języka naturalnego:** Normalizacja tekstu, obsługa polskich znaków i usuwanie tzw. "stopwords" przy użyciu reguł w Prologu.
* **Interfejs:** Przejrzysty frontend oraz obsługa priorytetów zadań.

**Technologie:** Python, Flask, SWI-Prolog (biblioteka `pyswip`), HTML/CSS.

---

### 2. Bitwa Morska (Python CLI)
📂 **Katalog:** `statki-gra` 

Klasyczna gra w statki przeniesiona do terminala. Jest to projekt typu CLI (Command Line Interface), który kładzie nacisk na interaktywność i obsługę logiki gry turowej dla dwóch graczy.

**Kluczowe funkcjonalności:**
* **Sterowanie:** Możliwość poruszania się po planszy strzałkami i zatwierdzania wyborów klawiszem ENTER (biblioteka `keyboard`).
* **Oprawa wizualna:** Kolorowa grafika ASCII w terminalu (biblioteka `colorama`).
* **Mechanika:** Tryb "Hotseat" (zmiana graczy przy jednym komputerze) z ukrywaniem planszy między turami oraz walidacja rozstawiania statków (biblioteka `pandas`).

**Technologie:** Python, Pandas, Colorama, Keyboard.

---

### 3. Pogodynka (Bash & PowerShell)
📂 **Katalog:** `pogodynka-terminal`

Zestaw skryptów automatyzujących sprawdzanie pogody, napisanych w dwóch najpopularniejszych językach powłoki systemowej. Narzędzie automatycznie lokalizuje najbliższą stację pomiarową i pobiera z niej dane.

**Kluczowe funkcjonalności:**
* **Wieloplatformowość:** Dedykowane wersje dla Linuxa (`.sh`) i Windowsa (`.ps1`).
* **Praca z API:** Pobieranie danych z OpenStreetMap (geolokalizacja miasta) oraz IMGW (dane pogodowe).
* **Optymalizacja:** Obliczanie odległości metodą Haversine’a oraz cache'owanie współrzędnych stacji w celu przyspieszenia działania.

**Technologie:** Bash, PowerShell, JSON, cURL.

---

### 4. Microshell (C + Linux API)

📂 **Katalog:** `microshell`

Autorski interpreter poleceń napisany w języku C, demonstrujący niskopoziomowe mechanizmy działania systemów operacyjnych. Projekt skupia się na zarządzaniu procesami i pamięcią, a także zawiera własne implementacje narzędzi analitycznych przydatnych w cyberbezpieczeństwie.

**Kluczowe funkcjonalności:**
* **Narzędzia Forensics:** Własna implementacja `myhexdump` (podgląd binarny plików) oraz `mygrep` (wyszukiwanie wzorców), pomocne przy wstępnej analizie malware.
* **Zarządzanie Procesami:** Obsługa funkcji systemowych rodziny `fork` i `exec` do uruchamiania zewnętrznych programów.
* **Bezpieczeństwo i Stabilność:** Obsługa sygnałów (np. przechwytywanie `SIGINT`), historia poleceń (`readline`) oraz weryfikacja pod kątem wycieków pamięci (`Valgrind`).

**Technologie:** C, Linux API, Makefile, Valgrind.

---

### 📬 Kontakt
Jeśli masz pytania dotyczące kodu lub chciałbyś nawiązać współpracę, zapraszam do kontaktu!

# 🇬🇧: Project Portfolio – Maja Radowska

Hi! 👋 Welcome to my repository of programming projects. Each project is located in a separate directory and demonstrates different areas of my skills – from web applications with AI elements, through console games, to system automation.

Below is a brief description of each project.

---

### 1. Intelligent To-Do List (Python + Prolog)
📂 **Directory:** `ToDoList-prolog`

A hybrid "To-Do List" web application that stands out by using fuzzy logic. By combining **Python (Flask)** with **Prolog**, the system is capable of analyzing the meaning of the tasks entered.

**Key Features:**
* **Duplicate Detection:** The app warns you if you try to add a task that is semantically similar to an existing one (e.g., "Buy milk" vs. "Purchase milk").
* **Natural Language Processing:** Text normalization, handling Polish diacritics, and removing stopwords using Prolog rules.
* **Interface:** Clean frontend with task priority management (High/Medium/Low).

**Tech Stack:** Python, Flask, SWI-Prolog (`pyswip`), HTML/CSS.

---

### 2. Naval Battle (Python CLI)
📂 **Directory:** `statki-gra` 

The classic Battleship game ported to the terminal. This CLI (Command Line Interface) project emphasizes interactivity and turn-based game logic for two players.

**Key Features:**
* **Controls:** Navigate the board using arrow keys and confirm selections with ENTER (using the `keyboard` library).
* **Visuals:** Colorful ASCII graphics in the terminal (using the `colorama` library).
* **Mechanics:** "Hotseat" mode (switching players on one computer) with screen hiding between turns, and ship placement validation using `pandas`.

**Tech Stack:** Python, Pandas, Colorama, Keyboard.

---

### 3. Weather App (Bash & PowerShell)
📂 **Directory:** `pogodynka-terminal` 

A set of automation scripts for checking the weather, written in the two most popular shell languages. The tool automatically locates the nearest weather station and retrieves data from it.

**Key Features:**
* **Cross-Platform:** Dedicated versions for Linux (`.sh`) and Windows (`.ps1`).
* **API Integration:** Fetches data from OpenStreetMap (city geolocation) and IMGW (weather data).
* **Optimization:** Calculates distance using the Haversine formula and caches station coordinates to improve performance.

**Tech Stack:** Bash, PowerShell, JSON, cURL.

---

### 4. Microshell (C + Linux API)

📂 **Directory:** `microshell`

A custom command-line interpreter written in C, demonstrating low-level operating system mechanisms. The project focuses on process and memory management, featuring custom implementations of analysis tools useful in cybersecurity.

**Key Features:**
* **Forensics Tools:** Custom implementation of `myhexdump` (binary file analysis) and `mygrep` (pattern matching), useful for initial malware analysis.
* **Process Management:** Utilizing `fork` and `exec` family system calls to execute external programs.
* **Safety & Stability:** Signal handling (e.g., trapping `SIGINT`), command history (`readline`), and memory leak verification (`Valgrind`).

**Tech Stack:** C, Linux API, Makefile, Valgrind.

---

### 📬 Contact

If you have any questions about the code or would like to collaborate, feel free to reach out!
