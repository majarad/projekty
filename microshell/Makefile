CC = gcc
CFLAGS = -Wall -Wextra -pedantic
LIBS = -lreadline

all: microshell

microshell: microshell.c
	$(CC) $(CFLAGS) microshell.c -o microshell $(LIBS)

clean:
	rm -f microshell
