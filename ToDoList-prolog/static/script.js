document.addEventListener("DOMContentLoaded", () => {
  // Pobieranie elementów z HTML-a
  const taskList = document.getElementById("task-list");
  const form = document.getElementById("task-form");
  const confirmationBox = document.getElementById("confirmation-box");
  const confirmationMessage = document.getElementById("confirmation-message");
  const confirmYes = document.getElementById("confirm-yes");
  const confirmNo = document.getElementById("confirm-no");

  let tempTask = "";
  let tempPriority = "";

  // Usuwanie z localStorage zadań, które już nie istnieją na liście
  Object.keys(localStorage).forEach(key => {
    if (key.startsWith("task-")) {
      const taskText = key.slice(5);
      const taskExists = Array.from(taskList.querySelectorAll(".task-text"))
        .some(span => span.textContent === taskText);
      if (!taskExists) {
        localStorage.removeItem(key);
      }
    }
  });

  // Odtwarzanie zaznaczeń checkboxów z localStorage (po odświeżeniu strony)
  taskList.querySelectorAll(".task-checkbox").forEach(cb => {
    const taskText = cb.closest("label").querySelector(".task-text").textContent;
    const checked = localStorage.getItem("task-" + taskText);
    if (checked === "true") {
      cb.checked = true;
      cb.closest("label").querySelector(".task-text").classList.add("checked");
    }
  });

  // Zapisanie zaznaczenia checkboxa do localStorage
  taskList.addEventListener("change", e => {
    if (e.target.classList.contains("task-checkbox")) {
      const label = e.target.closest("label");
      const span = label.querySelector(".task-text");
      const taskText = span.textContent;
      if (e.target.checked) {
        span.classList.add("checked");
        localStorage.setItem("task-" + taskText, "true");
      } else {
        span.classList.remove("checked");
        localStorage.setItem("task-" + taskText, "false");
      }
    }
  });

  // Obsługa kliknięcia przycisku „Usuń”
  taskList.addEventListener("click", e => {
    if (e.target.classList.contains("delete-btn")) {
      const li = e.target.closest("li");
      const taskText = li.querySelector(".task-text").textContent;

      // Wysyłanie żądania do serwera, by usunąć zadanie
      fetch("/delete_task", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ task: taskText })
      })
      .then(response => {
        if (response.ok) {
          localStorage.removeItem("task-" + taskText);  // Usunięcie z localStorage
          li.remove();  // Usunięcie z listy na stronie
        } else {
          alert("Błąd usuwania zadania");
        }
      })
      .catch(() => alert("Błąd sieci"));
    }
  });

  // Obsługa dodawania nowego zadania
  form.addEventListener("submit", (e) => {
    e.preventDefault(); // Zatrzymanie domyślnego wysłania formularza

    const taskInput = form.querySelector('input[name="task"]');
    const priorityInput = form.querySelector('select[name="priority"]');
    const task = taskInput.value.trim();
    const priority = priorityInput.value;

    if (!task) return; // Nie dodawaj pustego zadania

    // Sprawdzenie, czy zadanie już istnieje (porównanie podobieństwa)
    fetch("/check_task", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ task, priority })
    })
    .then(res => res.json())
    .then(data => {
      if (data.exists) {
        // Zawsze pokazujemy komunikat:
        confirmationMessage.textContent = data.message;
        confirmationMessage.style.display = "block";

        // Usuwamy poprzednie klasy kolorów i dodajemy nową:
        confirmationMessage.classList.remove("similar-red", "similar-yellow", "similar-green");
        if (data.type === "identical") {
          confirmationMessage.classList.add("similar-red");
        } else if (data.type === "very_similar") {
          confirmationMessage.classList.add("similar-yellow");
        } else if (data.type === "similar") {
          confirmationMessage.classList.add("similar-green");
        }

        // Pokaż lub ukryj przyciski:
        if (data.type === "very_similar" || data.type === "similar") {
          confirmationBox.style.display = "block";
          confirmYes.style.display = "inline-block";
          confirmNo.style.display = "inline-block";
        } else {
          // dla identical – wyświetl tylko komunikat, ukryj przyciski
          confirmationBox.style.display = "block";
          confirmYes.style.display = "none";
          confirmNo.style.display = "none";
        }

        // Zapisz tymczasowo dane zadania, jeśli użytkownik potwierdzi
        tempTask = task;
        tempPriority = priority;
      } else {
        // Jeśli nie ma podobnego zadania, dodaj od razu
        confirmAndAdd(task, priority);
      }
    });
  });

  // Użytkownik potwierdził dodanie podobnego zadania
  confirmYes.addEventListener("click", () => {
    confirmAndAdd(tempTask, tempPriority);
    confirmationBox.style.display = "none";
    tempTask = "";
  });

  // Użytkownik anulował dodanie podobnego zadania
  confirmNo.addEventListener("click", () => {
    confirmationBox.style.display = "none";
    tempTask = "";
  });

  // Funkcja dodająca zadanie do pliku po potwierdzeniu
  function confirmAndAdd(task, priority) {
    fetch("/confirm_add_task", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ task, priority })
    })
    .then(() => location.reload()); // Odświeżenie strony po dodaniu
  }
});
