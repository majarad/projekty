#define _GNU_SOURCE 
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h> // m.in. dla fork i exec
#include <string.h>
#include <sys/wait.h>
#include <sys/types.h>
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
#include <time.h>
#include <ctype.h>
#include <pwd.h>
#include <readline/readline.h>
#include <readline/history.h>

#define RESET     "\001\033[0m\002"
#define JASNY     "\001\033[1;38;5;225m\002"
#define CIEMNY    "\001\033[1;38;5;212m\002"
#define NIEB "\001\033[1;38;5;117m\002"
#define CZER  "\001\033[1;31m\002"
#define ZIEL   "\001\033[1;38;5;46m\002"

// Zmienne globalne potrzebne do 'cd -', obsługi Ctrl+C i obsługi podpowiadania
char ostatni_katalog[1024] = "";
volatile int przerwij = 0;
int w_readline = 0;
char *komendy[] = {
    "cd",
    "exit",
    "help",
    "mygrep",
    "myhexdump",
    "matrix",
    NULL // Koniec tablicy
};

// Funkcja obsługująca Ctrl+C
void obsluga_sigint(int znak) {
    (void)znak;
    przerwij = 1;
    
    if (w_readline) { // Tylko jeśli przerwaliśmy pisanie tekstu
        printf("\n");
        rl_on_new_line();
        rl_replace_line("", 0);
        rl_redisplay();
    } else {
        printf("\n");
    }
}

// Funkcja wołana przez readline w pętli
char *podpowiadanie_komend(const char *tekst, int stan) {
    static int indeks_listy; // Pamięta, gdzie skończyliśmy w tablicy
    int dlugosc;
    char *nazwa;

    // Jeśli stan == 0, to zaczynamy nowe szukanie
    if (stan == 0) {
        indeks_listy = 0;
    }

    dlugosc = strlen(tekst);

    while ((nazwa = komendy[indeks_listy]) != NULL) {
        indeks_listy++;
        // Sprawdzamy czy komenda zaczyna się od tego co wpisał użytkownik
        if (strncmp(nazwa, tekst, dlugosc) == 0) {
            return strdup(nazwa); // Zwracamy kopię nazwy dla readline
        }
    }
    return NULL; // Brak więcej pasujących komend
}

// Funkcja decydująca czy podpowiadać komendy (na początku linii) czy pliki (dalej) 
char **moje_podpowiadanie(const char *tekst, int start, int end) {
    (void)end;
    
    // Jeśli start == 0, to jesteśmy na początku linii (wpisujemy komendę)
    if (start == 0) {
        return rl_completion_matches(tekst, podpowiadanie_komend);
    }
    
    return NULL; // Standardowe podpowiadanie plików (to co robi readline domyślnie)
}

// Funkcja dzieląca linię na argumenty (obsługuje cudzysłowy)
int parsuj_linie(char *linia, char **args) {
    int i = 0;
    char *p = linia;
    int w_cudzyslowie = 0;
    
    while (*p) {
        // Pomijamy spacje/taby przed słowem
        while (*p == ' ' || *p == '\t') p++;
        if (*p == '\0') break;
        
        if (*p == '"') {
            w_cudzyslowie = 1;
            p++; 
        } else {
            w_cudzyslowie = 0;
        }
        
        args[i++] = p;
        if (i >= 99) break; 
        
        while (*p) {
            if (w_cudzyslowie) {
                if (*p == '"') {
                    *p = '\0';
                    p++;
                    w_cudzyslowie = 0;
                    break;
                }
            } else {
                if (*p == ' ' || *p == '\t') {
                    *p = '\0';
                    p++;
                    break;
                }
            }
            p++;
        }
    }
    args[i] = NULL; // Ostatni argument musi być NULL dla execvp
    return i;
}


void help() {
    printf(CIEMNY "\n--- " JASNY "Mój Microshell" CIEMNY " ---\n" RESET);
    printf(CIEMNY "Autor: " JASNY "Maja Radowska <33\n" RESET);
    printf(CIEMNY "Wbudowane polecenia:\n" RESET);
    printf("  " JASNY "cd" NIEB " <katalog>" RESET "        - zmiana katalogu\n");
    printf("  " JASNY "exit" RESET "                - wyjście z programu\n");
    printf("  " JASNY "help" RESET "                - wyświetla tę pomoc\n");
    printf("  " JASNY "mygrep" NIEB " [opcje] <txt> <plik>" RESET " - szukanie tekstu\n");
    printf("        " CIEMNY "-i" RESET " ignoruj wielkość liter\n");
    printf("        " CIEMNY "-v" RESET " odwróć dopasowanie\n");
    printf("        " CIEMNY "-n" RESET " pokaż numery linii\n");
    printf("        " CIEMNY "-c" RESET " policz wystąpienia\n");
    printf("        " CIEMNY "-l" RESET " tylko nazwa pliku\n");
    printf("  " JASNY "myhexdump" NIEB " <plik>" RESET "    - podgląd binarny\n");
    printf("  " ZIEL "matrix" RESET "              - tryb haker (przerwij Ctrl+C)\n");
    printf("\n");
}

void cd(char **args) {
    char obecny[1024];
    if (getcwd(obecny, sizeof(obecny)) == NULL) {
        fprintf(stderr, "%s", CZER);
        perror("Błąd getcwd (ścieżka zbyt długa?)");
        fprintf(stderr, "%s", RESET);
        return;
    }
    char *cel = args[1];
    
    if (cel == NULL || strcmp(cel, "~") == 0) {
        cel = getenv("HOME");
    } else if (strcmp(cel, "-") == 0) {
        if (strlen(ostatni_katalog) == 0) {
            printf("%sBrak poprzedniego katalogu.%s\n", CZER, RESET);
            return;
        }
        cel = ostatni_katalog;
        printf("%s\n", cel);
    }
    
    if (chdir(cel) != 0) {
        fprintf(stderr, "%s", CZER);
        perror("Błąd cd");
        fprintf(stderr, "%s", RESET);
    } else {
        snprintf(ostatni_katalog, sizeof(ostatni_katalog), "%s", obecny); // Zapisz gdzie bylismy
    }
}

void mygrep(char **args) {
    int flag_i=0, flag_v=0, flag_n=0, flag_c=0, flag_l=0;
    char *szukane = NULL;
    char *plik = NULL;
    
    // Parsowanie flag w pętli
    for (int k=1; args[k] != NULL; k++) {
        if (args[k][0] == '-') {
            if (strchr(args[k], 'i')) flag_i = 1;
            if (strchr(args[k], 'v')) flag_v = 1;
            if (strchr(args[k], 'n')) flag_n = 1;
            if (strchr(args[k], 'c')) flag_c = 1;
            if (strchr(args[k], 'l')) flag_l = 1;
        } else {
            if (!szukane) szukane = args[k];
            else plik = args[k];
        }
    }
    
    if (!szukane || !plik) {
        printf("%sUżycie: mygrep [opcje] wzorzec plik%s\n", CZER, RESET);
        return;
    }
    
    FILE *f = fopen(plik, "r");
    if (!f) { 
        fprintf(stderr, "%s", CZER);
        perror("Błąd pliku"); 
        fprintf(stderr, "%s", RESET);
        return; 
    }
    
    char linia[2048];
    int nr = 0, licznik = 0;
    
    przerwij = 0;
    while (fgets(linia, sizeof(linia), f)) {
        if (przerwij) {
            printf("\n%sPrzerwano grep :(%s\n", CZER, RESET);
            break;
        }

        nr++;
        linia[strcspn(linia, "\n")] = 0; // Usunięcie entera na końcu
        
        int pasuje = 0;
        if (flag_i) {
            // Ignorowanie wielkości liter (rozszerzenie GNU)
            if (strcasestr(linia, szukane)) pasuje = 1;
        } else {
            if (strstr(linia, szukane)) pasuje = 1;
        }
        
        if (flag_v) pasuje = !pasuje; // Odwrócenie wyniku
        
        if (pasuje) {
            licznik++;
            if (flag_l) {
                printf("%s%s%s\n", NIEB, plik, RESET);
                break;
            }
            if (!flag_c) {
                if (flag_n) printf("%s%d:%s ", ZIEL, nr, RESET);
                else printf("Line: ");
                printf("%s\n", linia);
            }
        }
    }
    if (flag_c) printf("%d\n", licznik);
    fclose(f);
}

void myhexdump(char **args) {
    if (!args[1]) { printf("%sPodaj plik%s\n", CZER, RESET); return; }
    FILE *f = fopen(args[1], "rb");
    if (!f) { 
        fprintf(stderr, "%s", CZER);
        perror("Błąd"); 
        fprintf(stderr, "%s", RESET);
        return; 
    }
    
    unsigned char b[16];
    size_t n; 
    printf("%sHEX DUMP:%s\n", NIEB, RESET);
    
    przerwij = 0;
    // Czytanie po 16 bajtów
    while ((n = fread(b, 1, 16, f)) > 0) {
        if (przerwij) {
            printf("\n%sPrzerwano.%s\n", CZER, RESET);
            break;
        }

        // Wypisanie HEX
        for(size_t i=0; i<16; i++) {
            if (i<n) printf("%02x ", b[i]); else printf("   ");
        }
        printf("| ");
        // Wypisanie ASCII
        for(size_t i=0; i<n; i++) {
            if (isprint(b[i])) printf("%c", b[i]); else printf(".");
        }
        printf("\n");
    }
    fclose(f);
}

void matrix() {
    printf("%sMATRIX MODE ON\n", ZIEL);
    przerwij = 0;
    // Pętla nieskończona, przerywana przez Ctrl+C
    while (!przerwij) {
        for(int i=0; i<80; i++) {
            if (rand()%10 > 2) printf(" ");
            else printf("%d", rand()%2);
        }
        printf("\n");
        usleep(30000);
    }
    printf("%s", RESET);
    przerwij = 0;
}


int main() {
    signal(SIGINT, obsluga_sigint); // Rejestracja sygnału
    signal(SIGTSTP, SIG_IGN); // Ignorowanie Ctrl+Z w microshellu

    rl_attempted_completion_function = moje_podpowiadanie; // Podpięcie podpowiadania (TAB)

    srand(time(NULL));
    
    char *linia_input;
    char *args[100]; 
    char prompt[2048];
    
    while (1) {
        char path[1024];
        if (getcwd(path, sizeof(path)) == NULL) strcpy(path, "???");
        
        char *user = getenv("USER");
        if(!user) user="user";
        
        snprintf(prompt, sizeof(prompt), "%s%s@microshell<3%s[%s%s%s] $ %s", CIEMNY, user, NIEB, JASNY, path, NIEB, RESET);
                
        przerwij = 0;

        // Pobranie linii przez readline (obsługa historii i strzałek)
        w_readline = 1;
        linia_input = readline(prompt);
        w_readline = 0;
        
        // Ctrl+D kończy program
        if (!linia_input) { 
            printf(JASNY "\nDo widzenia" CIEMNY "! " NIEB "=^.^=\n\n" RESET);
            break;
        }

        // Jeśli użytkownik wcisnął Ctrl+C w trakcie wpisywania (readline zwróci pustą linię ale przerwij=1)
        if (przerwij) {
            free(linia_input);
            przerwij = 0;
            continue;
        }
        
        if (strlen(linia_input) > 0) {
            add_history(linia_input);
        }
        
        // Parsowanie (podział na słowa)
        parsuj_linie(linia_input, args);
        
        if (args[0] != NULL) {
            // Sprawdzanie komend wbudowanych
            if (strcmp(args[0], "exit") == 0) {
                printf(JASNY "\nDo widzenia" CIEMNY "! " NIEB "=^.^=\n\n" RESET);
                free(linia_input);
                break;
            }
            else if (strcmp(args[0], "cd") == 0) cd(args);
            else if (strcmp(args[0], "help") == 0) help();
            else if (strcmp(args[0], "mygrep") == 0) mygrep(args);
            else if (strcmp(args[0], "myhexdump") == 0) myhexdump(args);
            else if (strcmp(args[0], "matrix") == 0) matrix();
            else {
                // Uruchomienie zewnętrznego programu (fork + exec)
                pid_t pid = fork(); // Klonowanie procesu
                if (pid == 0) {
                    // Proces potomny (Dziecko)
                    signal(SIGINT, SIG_DFL); // Przywrócenie domyślnego Ctrl+C i Ctrl+Z dla programów zewnętrznych
                    signal(SIGTSTP, SIG_DFL);
                    execvp(args[0], args);
                    // Jeśli execvp wróci, to znaczy że błąd
                    printf("%sNieznane polecenie: %s%s\n", CZER, args[0], RESET);
                    exit(1);
                } else if (pid > 0) {
                    // Proces macierzysty (Rodzic) - czeka na dziecko
                    wait(NULL);
                } else {
                    fprintf(stderr, "%s", CZER);
                    perror("Błąd fork");
                    fprintf(stderr, "%s", RESET);
                }
            }
        }
        
        free(linia_input); // Readline alokuje pamięć
        przerwij = 0;
    }
    return 0;
}
