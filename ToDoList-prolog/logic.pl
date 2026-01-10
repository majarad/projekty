% ----------------------------------
% logic.pl
% ----------------------------------

:- module(logika, [
    normalizuj_slowo/2,
    usun_akcenty/2,
    podziel_na_slowa/2,
    usun_stopwords/2,
    podobne_slowo/2,
    podobienstwo_zadan/3
]).

:- encoding(utf8).
:- use_module(library(isub)).    % biblioteka do podobieństwa tekstowego


% ----------------------------------
% Stopwords do usunięcia (wszystkie znormalizowane)
% ----------------------------------

stopword(na).
stopword(sie).
stopword(do).
stopword(w).
stopword(i).
stopword(z).
stopword(a).
stopword(ze).
stopword(ale).
stopword(bo).
stopword(ktory).
stopword(ktore).
stopword(ktorzy).
stopword(ktorych).
stopword(ktoremu).
stopword(ktorym).
stopword(ktorej).
stopword(ktorymi).


% ----------------------------------
% Usuwanie stopwords z listy słów
% ----------------------------------

usun_stopwords([], []).
usun_stopwords([W|Ws], Res) :-
    ( stopword(W) -> usun_stopwords(Ws, Res)
    ; Res = [W|R], usun_stopwords(Ws, R)
    ).

% ----------------------------------
% Normalizacja pojedynczego słowa
% ----------------------------------

normalizuj_slowo(Atom, Wynik) :-
    downcase_atom(Atom, Male),
    usun_akcenty(Male, BezAkcentu),
    atom_chars(BezAkcentu, Znaki),
    maplist(zamien_znak, Znaki, BezpieczneZnaki),
    atom_chars(AtomBezpieczny, BezpieczneZnaki),
    normalize_space(atom(Wynik), AtomBezpieczny).

zamien_znak(Znak, ' ') :- \+ char_type(Znak, alnum), !.
zamien_znak(Znak, Znak).


% ----------------------------------
% Usuwanie diakrytyków (dla małych liter)
% ----------------------------------

usun_akcenty(Atom, Wynik) :-
    atom_chars(Atom, Znaki),
    maplist(bez_akcentu, Znaki, ZnakiBez),
    atom_chars(Wynik, ZnakiBez).

bez_akcentu(Znak, P) :- ( diakrytyk(Znak, X) -> P = X ; P = Znak ).

:- discontiguous logika:diakrytyk/2.

diakrytyk('ą','a').
diakrytyk('ć','c').
diakrytyk('ę','e').
diakrytyk('ł','l').
diakrytyk('ń','n').
diakrytyk('ó','o').
diakrytyk('ś','s').
diakrytyk('ź','z').
diakrytyk('ż','z').


% ----------------------------------
% Dzielenie zdania na liste słów (atomów)
% ----------------------------------

podziel_na_slowa(Tekst, Slowa) :-
    split_string(Tekst, " ", " ", List),            % dzieli po spacji, usuwa puste ciągi
    exclude(=(""), List, CzyscLista),
    maplist(atom_string, Slowa, CzyscLista).        % zamienia stringi na atomy


% ----------------------------------
% Porównywanie 2 słów z dopuszczeniem literówek
% ----------------------------------

podobne_slowo(S1, S2) :-
    normalizuj_slowo(S1, N1), normalizuj_slowo(S2, N2),
    ( N1 == N2 -> !
    ; atom_chars(N1, L1), atom_chars(N2, L2),
      length(L1, Dlugosc), length(L2, Dlugosc), Dlugosc =< 3,
      policz_roznice(L1, L2, R), R =< 1 -> !
    ; isub(N1, N2, Wynik, [normalize(true), zero_to_one(true)]), Wynik >= 0.7
    ).


% ----------------------------------
% Helper - zwraca liczbę pozycji, w których znaki się różnią
% ----------------------------------

policz_roznice([], [], 0).
policz_roznice([X|Xs], [Y|Ys], Liczba) :-
    policz_roznice(Xs, Ys, L1),
    ( X == Y -> Liczba = L1 ; Liczba is L1 + 1 ).


% ----------------------------------
% Porównywanie list słów jako zbiorów (bez powtórzeń)
% ----------------------------------

unikalne([], Ak, Ak).
unikalne([W|Ws], Ak, U) :-
    ( podobne_w_liscie(W, Ak) -> unikalne(Ws, Ak, U)        % jeśli podobne słowo już jest – pomiń
    ; unikalne(Ws, [W|Ak], U)                               % inaczej dodaj do accumulatora
    ).

% Sprawdza, czy słowo podobne jest do któregoś ze słów na liście
podobne_w_liscie(W, [H|_]) :- podobne_slowo(W, H), !.
podobne_w_liscie(W, [_|T]) :- podobne_w_liscie(W, T).

unikalne_slowa(L, U) :- unikalne(L, [], R), reverse(R, U).


% ----------------------------------
% Zliczanie wspólnych słów podobnych między dwoma listami
% ----------------------------------

policz_wspolne(L1, L2, Wspolne, Suma) :-
    unikalne_slowa(L1, U1), unikalne_slowa(L2, U2),
    licz_wspolne(U1, U2, Wspolne),
    length(U1, D1), length(U2, D2), Suma is D1 + D2 - Wspolne.

% Liczy ile słów z L1 występuje w L2 (ze względu na podobieństwo)
licz_wspolne([], _, 0).
licz_wspolne([W|Ws], L, Liczba) :-
    ( znajdz_i_usun(W, L, Reszta) -> licz_wspolne(Ws, Reszta, L1), Liczba is L1 + 1
    ; licz_wspolne(Ws, L, Liczba)
    ).

znajdz_i_usun(W, [H|T], T) :- podobne_slowo(W, H), !.
znajdz_i_usun(W, [H|T], [H|R]) :- znajdz_i_usun(W, T, R).


% ----------------------------------
% Obliczanie podobieństwa zdań
% ----------------------------------

podobienstwo_zadan(T1, T2, Wynik) :-
    podziel_na_slowa(T1, Surowe1), 
    maplist(normalizuj_slowo, Surowe1, Norm1), 
    usun_stopwords(Norm1, W1),
    
    podziel_na_slowa(T2, Surowe2), 
    maplist(normalizuj_slowo, Surowe2, Norm2), 
    usun_stopwords(Norm2, W2),
    
    policz_wspolne(W1, W2, Wsp, Suma),
    ( Suma > 0 -> Wynik is Wsp / Suma ; Wynik = 1.0 ).