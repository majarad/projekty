from flask import Flask, request, render_template, jsonify
from pyswip import Prolog
import os

app = Flask(__name__)
prolog = Prolog()

# Wczytanie pliku z logiką Prolog
prolog.consult("logic.pl")

TASK_FILE = "tasks.txt"  # Plik tekstowy z zapisanymi zadaniami

# Wczytuje zadania z pliku, każdy w formacie "tekst|priorytet"
def read_tasks():
    try:
        with open(TASK_FILE, "r", encoding="cp1250") as f:
            tasks = []
            for line in f:
                line = line.strip()
                if "|" in line:
                    text, priority = line.split("|", 1)
                else:
                    text = line
                    priority = "niski"  # Domyślny priorytet
                tasks.append({"text": text, "priority": priority})
            return tasks
    except FileNotFoundError:
        return []  # Jeśli plik nie istnieje, zwróć pustą listę

# Zapisuje listę zadań do pliku
def write_tasks(tasks):
    with open(TASK_FILE, "w", encoding="cp1250") as f:
        for t in tasks:
            f.write(f"{t['text']}|{t['priority']}\n")

# Dodaje pojedyncze zadanie na końcu pliku
def add_task(text, priority):
    with open(TASK_FILE, "a", encoding="cp1250") as f:
        f.write(f"{text}|{priority}\n")

# Wywołuje predykat Prolog do sprawdzenia podobieństwa dwóch zdań (zadań)
def check_similarity_prolog(task1, task2):
    query = f"podobienstwo_zadan('{task1}', '{task2}', Wynik)"
    result = list(prolog.query(query, maxresult=1))
    if result:
        return float(result[0]["Wynik"])
    return 0.0

# Sprawdza, czy nowe zadanie jest podobne do któregoś istniejącego,
# zwraca true/false, komunikat i typ podobieństwa
def check_similarity(new_task, tasks):
    for t in tasks:
        sim = check_similarity_prolog(new_task, t['text'])
        if sim >= 0.90:
            return True, "Identyczne zadanie już istnieje! ⚠️", "identical"
        elif sim >= 0.60:
            return True, "Bardzo podobne zadanie istnieje! ⚠️ Czy na pewno chcesz je dodać? 🤔", "very_similar"
        elif sim >= 0.40:
            return True, "Podobne zadanie już istnieje! ⚠️ Czy na pewno chcesz je dodać? 🤔", "similar"
    return False, "", ""

# Sprawdza podobieństwo nowego zadania do już istniejących – używane przez JavaScript (AJAX)
@app.route("/check_task", methods=["POST"])
def check_task():
    data = request.get_json()
    new_task = data.get("task", "").strip()
    priority = data.get("priority", "średni").lower()

    tasks = read_tasks()
    exists, message, similarity_type = check_similarity(new_task, tasks)

    return jsonify({
        "exists": exists,
        "message": message,
        "type": similarity_type
    })

# Endpoint do potwierdzenia i dodania zadania po weryfikacji
@app.route("/confirm_add_task", methods=["POST"])
def confirm_add_task():
    data = request.get_json()
    new_task = data.get("task", "").strip()
    priority = data.get("priority", "średni").lower()

    add_task(new_task, priority)
    return jsonify({"status": "added"})

# Główna strona wyświetlająca listę zadań z sortowaniem po priorytecie
@app.route("/", methods=["GET", "POST"])
def index():
    tasks = read_tasks()
    message = ""

    # Sortowanie priorytetów: wysoki > średni > niski
    priority_order = {"wysoki": 0, "średni": 1, "niski": 2}
    tasks.sort(key=lambda x: priority_order.get(x["priority"], 3))

    return render_template("index.html", tasks=tasks, message=message)

# Endpoint do usuwania zadania (wywołanie AJAX)
@app.route("/delete_task", methods=["POST"])
def delete_task():
    data = request.get_json()
    task_to_delete = data.get("task", "")
    tasks = read_tasks()

    # Usuwa zadanie o podanym tekście
    tasks = [t for t in tasks if t["text"] != task_to_delete]
    write_tasks(tasks)
    return jsonify({"status": "ok"})

if __name__ == "__main__":
    app.run(debug=True)
