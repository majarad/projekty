import os
import platform
import time
import pandas as pd  
import keyboard   
from colorama import init, Fore   

# Colorama dla Windowsa
init(autoreset = True)

def erasing():
    if platform.system() == "Windows":
        os.system("cls")
    else:
        os.system("clear")

# Funkcja do tworzenia pustej planszy
def create_board():
    columns = [chr(i) for i in range(ord("A"), ord("J") + 1)]
    index = [str(i) for i in range(0, 10)]
    return pd.DataFrame(" ", index = index, columns = columns)
          
# Funkcja do tworzenia rameczki i printowania planszy
def print_board(board, cursor_x = None, cursor_y = None):
    rows = board.reset_index().values.tolist()
    header = [" "] + board.columns.tolist()

    green_X = Fore.LIGHTGREEN_EX + "X" + Fore.RESET

    horizontal_line = "+" + "+".join(["---"] * len(header)) + "+"
    print(horizontal_line)
    print("| " + " | ".join(header) + " |")
    print(horizontal_line)
    for y, row in enumerate(rows):
        row_str = "|"
        for x, cell in enumerate(row):
            if cursor_x != None and cursor_y != None and x == cursor_x + 1 and y == cursor_y:
                row_str += f" {green_X} "
            else:
                row_str += f" {cell} "
            row_str += "|"
        print(row_str)
        print(horizontal_line)

def get_ship_color(ship_size):
    colors = {
        4: Fore.BLUE,
        3: Fore.CYAN,
        2: Fore.LIGHTMAGENTA_EX,
        1: Fore.LIGHTGREEN_EX
    }
    return colors.get(ship_size, Fore.WHITE)

def ships_placement(board, player_number, player):
    erasing()

    ships = [4, 3, 3, 2, 2, 1, 1, 1]
    for ship_size in ships:
        cursor_x, cursor_y = 0, 0
        ship_color = get_ship_color(ship_size)

        selecting = True
        while selecting:
            erasing()
            color = Fore.CYAN if player_number == 1 else Fore.LIGHTMAGENTA_EX
            print(color + f"DOWÓDCA {player}" + Fore.RESET)
            print(f"\nRozmieść statek o rozmiarze " + Fore.LIGHTGREEN_EX + f"{ship_size}" + Fore.RESET + " pól!")
            print("\nWybierz strzałkami współrzędną, na której ma rozpocząć się jego pozycja i zatwierdź ją przyciskiem " + Fore.RED + "ENTER" + Fore.RESET + ".\n")
            print_board(board, cursor_x, cursor_y)

            if keyboard.is_pressed("up") and cursor_y > 0:
                cursor_y -= 1
            elif keyboard.is_pressed("down") and cursor_y < 9:
                cursor_y += 1
            elif keyboard.is_pressed("left") and cursor_x > 0:
                cursor_x -= 1
            elif keyboard.is_pressed("right") and cursor_x < 9:
                cursor_x += 1
            elif keyboard.is_pressed("enter"):
                if place_ship(board, ship_size, cursor_x, cursor_y, ship_color):
                    selecting = False
                else:
                    print("\nZrób to lepiej! To jest wojna żołnierzu - tu nie ma czasu na błędy!\n" + Fore.RED + "\nStatki nie mogą nachodzić na siebie, stykać się bokami, ani rogami." + Fore.RESET)
                    time.sleep(2)
            time.sleep(0.1)

def place_ship(board, size, cursor_x, cursor_y, ship_color):
    direction = None
    if size > 1:
        print("\nWbierz kierunek statku - wciśnij odpowiednią strzałkę: w górę, w dół, w lewo lub w prawo.")
        while direction not in ["up", "down", "left", "right"]:
            if keyboard.is_pressed("up"):
                direction = "up"
            elif keyboard.is_pressed("down"):
                direction = "down"
            elif keyboard.is_pressed("left"):
                direction = "left"
            elif keyboard.is_pressed("right"):
                direction = "right"
            time.sleep(0.1)
    else:
        direction = "1"
    time.sleep(0.1)

    coordinates = []
    for i in range(size):
        if direction == "up" and cursor_y - i >= 0:
            coordinates.append((cursor_y - i, cursor_x))
        elif direction == "down" and cursor_y + i < 10:
            coordinates.append((cursor_y + i, cursor_x))
        elif direction == "left" and cursor_x - i >= 0:
            coordinates.append((cursor_y, cursor_x - i))
        elif direction == "right" and cursor_x + i < 10:
            coordinates.append((cursor_y, cursor_x + i))
        elif direction == "1":
            coordinates.append((cursor_y, cursor_x))
        else:
            return False
    
    for y, x in coordinates:
        if board.at[str(y), chr(ord("A") + x)] != " ":
            return False
        
        for dy in [-1, 0, 1]:
            for dx in [-1, 0, 1]:
                if 0 <= y + dy < 10 and 0 <= x + dx < 10:
                    if board.at[str(y + dy), chr(ord("A") + x + dx)] != " ":
                        return False
                    
    for y, x in coordinates:
        board.at[str(y), chr(ord("A") + x)] = ship_color + "X" + Fore.RESET
    
    return True

def print_radar(radar, cursor_x = None, cursor_y = None):
    rows = radar.reset_index().values.tolist()
    header = [" "] + radar.columns.tolist()

    crosshair = Fore.RED + "+" + Fore.RESET

    horizontal_line = "+" + "+".join(["---"] * len(header)) + "+"
    print(horizontal_line)
    print("| " + " | ".join(header) + " |")
    print(horizontal_line)
    for y, row in enumerate(rows):
        row_str = "|"
        for x, cell in enumerate(row):
            if cursor_x != None and cursor_y != None and x == cursor_x + 1 and y == cursor_y:
                row_str += f" {crosshair} "
            else:
                row_str += f" {cell} "
            row_str += "|"
        print(row_str)
        print(horizontal_line)

def player_shoot(radar, board_enemy, board_player, player_number, player):
    cursor_x, cursor_y = 0, 0
    
    shooting = True
    while shooting:
        erasing()
        color = Fore.CYAN if player_number == 1 else Fore.LIGHTMAGENTA_EX
        print(color + f"DOWÓDCA {player}" + Fore.RESET)
        print("\nWybierz współrzędne, w które Twoja flota ma wymierzyć!\n")
        print(Fore.LIGHTGREEN_EX + "RADAR:" + Fore.RESET)
        print_radar(radar, cursor_x, cursor_y)
        
        if keyboard.is_pressed("up") and cursor_y > 0:
            cursor_y -= 1
            time.sleep(0.1)
        elif keyboard.is_pressed("down") and cursor_y < 9:
            cursor_y += 1
            time.sleep(0.1)
        elif keyboard.is_pressed("left") and cursor_x > 0:
            cursor_x -= 1
            time.sleep(0.1)
        elif keyboard.is_pressed("right") and cursor_x < 9:
            cursor_x += 1
            time.sleep(0.1)
        elif keyboard.is_pressed("enter"):
            cell = radar.at[str(cursor_y), chr(ord("A") + cursor_x)]
            if cell == " ":
                if "X" in board_enemy.at[str(cursor_y), chr(ord("A") + cursor_x)]:
                    radar.at[str(cursor_y), chr(ord("A") + cursor_x)] = Fore.LIGHTGREEN_EX + "O" + Fore.RESET
                    board_enemy.at[str(cursor_y), chr(ord("A") + cursor_x)] = Fore.RED + "O" + Fore.RESET
                    print(Fore.LIGHTGREEN_EX + "TRAFIONY!")
                else:
                    radar.at[str(cursor_y), chr(ord("A") + cursor_x)] = Fore.LIGHTBLUE_EX + "~" + Fore.RESET
                    board_enemy.at[str(cursor_y), chr(ord("A") + cursor_x)] = Fore.LIGHTBLUE_EX + "~" + Fore.RESET
                    print(Fore.RED + "Pudło... :(" + Fore.RESET)
                shooting = False
            else: 
                print("To pole było już ostrzelane. Wybierz inne!")
                time.sleep(1)
            time.sleep(1)
    erasing()
    print("Tak wyglądają " + color + "Twoje" + Fore.RESET + " floty:\n")
    print_board(board_player)
    time.sleep(4)

# Sprawdzanie wygranej
def check(board_enemy):
    for row in board_enemy.values:
        for cell in row:
            if "X" in cell:
                return False
    return True

def game():
    board1 = create_board()
    radar1 = create_board()
    board2 = create_board()
    radar2 = create_board()

    print("Witajcie dowódcy. Dziś na wodach rozstrzygnie się starcie, które raz na zawsze rozstrzygnie tą wieloletnią wojnę.")
    print(Fore.CYAN + "\nDowódco 1" + Fore.RESET + ", podaj swój pseudonim!")
    d1 = input()
    print(Fore.CYAN + f"\nDowódca {d1}" + Fore.RESET + " melduje gotowość do walki.")
    print(Fore.LIGHTMAGENTA_EX + "\nDowódco 2" + Fore.RESET + ", podaj swój pseudonim!")
    d2 = input()
    print(Fore.LIGHTMAGENTA_EX + f"\nDowódca {d2}" + Fore.RESET + " melduje gotowość do walki.")
    time.sleep(2)
    erasing()

    print(Fore.CYAN + f"Dowódco {d1}" + Fore.RESET + ", Twoja flota oczekuje Twoje na rozkazy.")
    print(Fore.LIGHTMAGENTA_EX + f"\nDowódca {d2}" + Fore.RESET + " proszony jest o " + Fore.RED + "usunięcie się" + Fore.RESET + " z pola widzenia monitora.\n")
    time.sleep(2.5)
    erasing()
    
    print(Fore.CYAN + f"DOWÓDCO {d1}" + Fore.RESET + ", ZA " + Fore.RED + "5 SEKUND" + Fore.RESET + " ROZPOCZNIESZ GRĘ!")
    time.sleep(2)
    erasing()
    print(Fore.CYAN + f"DOWÓDCO {d1}" + Fore.RESET + ", ZA " + Fore.BLUE + "4 SEKUNDY" + Fore.RESET + " ROZPOCZNIESZ GRĘ!")
    time.sleep(1)
    erasing()
    print(Fore.CYAN + f"DOWÓDCO {d1}" + Fore.RESET + ", ZA " + Fore.CYAN + "3 SEKUNDY" + Fore.RESET + " ROZPOCZNIESZ GRĘ!")
    time.sleep(1)
    erasing()
    print(Fore.CYAN + f"DOWÓDCO {d1}" + Fore.RESET + ", ZA " + Fore.LIGHTMAGENTA_EX + "2 SEKUDNY" + Fore.RESET + " ROZPOCZNIESZ GRĘ!")
    time.sleep(1)
    erasing()
    print(Fore.CYAN + f"DOWÓDCO {d1}" + Fore.RESET + ", ZA " + Fore.LIGHTGREEN_EX + "1 SEKUNDĘ" + Fore.RESET + " ROZPOCZNIESZ GRĘ!")
    time.sleep(1)
    erasing()
    print(Fore.RED + "START!!!!" + Fore.RESET)
    time.sleep(1)
    erasing()

    ships_placement(board1, 1, d1)
    time.sleep(1.5)
    erasing()

    print("Czas na " + Fore.LIGHTMAGENTA_EX + f"Dowódcę {d2}" + Fore.RESET + Fore.CYAN + f"\n\nDowódco {d1}" + Fore.RESET + ", teraz Twoja kolej – proszę " + Fore.RED + "usunąć się" + Fore.RESET + " z pola widzenia monitora.\n")
    time.sleep(2.5)
    erasing()

    print(Fore.LIGHTMAGENTA_EX + f"DOWÓDCO {d2}" + Fore.RESET + ", ZA " + Fore.RED + "5 SEKUND" + Fore.RESET + " ROZPOCZNIESZ GRĘ!")
    time.sleep(2)
    erasing()
    print(Fore.LIGHTMAGENTA_EX + f"DOWÓDCO {d2}" + Fore.RESET + ", ZA " + Fore.BLUE + "4 SEKUNDY" + Fore.RESET + " ROZPOCZNIESZ GRĘ!")
    time.sleep(1)
    erasing()
    print(Fore.LIGHTMAGENTA_EX + f"DOWÓDCO {d2}" + Fore.RESET + ", ZA " + Fore.CYAN + "3 SEKUNDY" + Fore.RESET + " ROZPOCZNIESZ GRĘ!")
    time.sleep(1)
    erasing()
    print(Fore.LIGHTMAGENTA_EX + f"DOWÓDCO {d2}" + Fore.RESET + ", ZA " + Fore.LIGHTMAGENTA_EX + "2 SEKUDNY" + Fore.RESET + " ROZPOCZNIESZ GRĘ!")
    time.sleep(1)
    erasing()
    print(Fore.LIGHTMAGENTA_EX + f"DOWÓDCO {d2}" + Fore.RESET + ", ZA " + Fore.LIGHTGREEN_EX + "1 SEKUNDĘ" + Fore.RESET + " ROZPOCZNIESZ GRĘ!")
    time.sleep(1)
    erasing()
    print(Fore.RED + "START!!!!" + Fore.RESET)
    time.sleep(1)
    erasing()

    ships_placement(board2, 2, d2)
    time.sleep(1.5)
    erasing()

    while True:
        erasing()
        print(Fore.CYAN + f"DOWÓDCO {d1}" + Fore.RESET + ", ZA " + Fore.RED + "3 SEKUNDY" + Fore.RESET + " BĘDZIE TWÓJ RUCH!")
        time.sleep(2)
        erasing()
        print(Fore.CYAN + f"DOWÓDCO {d1}" + Fore.RESET + ", ZA " + Fore.LIGHTGREEN_EX + "2 SEKUNDY" + Fore.RESET + " BĘDZIE TWÓJ RUCH!")
        time.sleep(1)
        erasing()
        print(Fore.CYAN + f"DOWÓDCO {d1}" + Fore.RESET + ", ZA " + Fore.YELLOW + "1 SEKUNDĘ" + Fore.RESET + " BĘDZIE TWÓJ RUCH!")
        time.sleep(1)
        erasing()
        print(Fore.RED + "DO DZIEŁA!!!!" + Fore.RESET)
        time.sleep(1)
        erasing()
        player_shoot(radar1, board2, board1, 1, d1)
        if check(board2):
            erasing()
            print(Fore.CYAN + f"DOWÓDCO {d1}" + Fore.RESET + ", ZWYCIĘŻYŁEŚ!!!!!!!!")
            time.sleep(4)
            return

        erasing()
        print(Fore.LIGHTMAGENTA_EX + f"DOWÓDCO {d2}" + Fore.RESET + ", ZA " + Fore.RED + "3 SEKUNDY" + Fore.RESET + " BĘDZIE TWÓJ RUCH!")
        time.sleep(2)
        erasing()
        print(Fore.LIGHTMAGENTA_EX + f"DOWÓDCO {d2}" + Fore.RESET + ", ZA " + Fore.LIGHTGREEN_EX + "2 SEKUNDY" + Fore.RESET + " BĘDZIE TWÓJ RUCH!")
        time.sleep(1)
        erasing()
        print(Fore.LIGHTMAGENTA_EX + f"DOWÓDCO {d2}" + Fore.RESET + ", ZA " + Fore.YELLOW + "1 SEKUNDĘ" + Fore.RESET + " BĘDZIE TWÓJ RUCH!")
        time.sleep(1)
        erasing()
        print(Fore.RED + "DO DZIEŁA!!!!" + Fore.RESET)
        time.sleep(1)
        erasing()
        player_shoot(radar2, board1, board2, 2, d2)
        if check(board1):
            erasing()
            print(Fore.LIGHTMAGENTA_EX + f"DOWÓDCO {d2}" + Fore.RESET + ", ZWYCIĘŻYŁEŚ!!!!!!!!")
            time.sleep(4)
            return

if __name__ == "__main__":
    game()
