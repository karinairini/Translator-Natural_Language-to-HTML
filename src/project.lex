%{
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
// Fisier generat de Yacc, care contine definitii pentru parser.
#include "y.tab.h"

// Structura urmatoare stocheaza informatii despre fiecare linie de text.
typedef struct structLine {
	int position;    // Pozitia: Indicele de inceput al liniei in bufferul original de text.
	int length;      // Lungimea: Numarul de caractere din linie.
	int textType;    // Tipul textului: Indica tipul de text (normal, titlu, item de lista, linie goala).
	int titleType;   // Tipul titlului: Specifica nivelul titlului (h1, h2, h3), utilizat doar daca linia este un titlu.
	int style;       // Stilul: Specifica stilul textului (italic, bold, bold italic), utilizat doar pentru text normal.
	int itemType;    // Tipul itemului: Specifica tipul in cadrul unei liste (primul item, item nou, ultimul item), utilizat daca linia este un item de lista. 
    int buttonStyle; // Stilul: Specifica stilul butonului.
} line;

// Definitii pentru diferite tipuri de text.
#define TEXT_NORMAL 0
#define TEXT_ITEM 1
#define TEXT_TITLE 2
#define EMPTY_LINE 3
#define TEXT_BUTTON 4

// Definitii pentru diferite tipuri de butoane.
#define BUTTON_STYLE_NORMAL 0
#define BUTTON_STYLE_PRIMARY 1
#define BUTTON_STYLE_SECONDARY 2

// Definitii pentru diferite tipuri de stiluri.
#define NONE_STYLE -1
#define ITALIC_STYLE 0
#define BOLD_STYLE 1
#define BOLD_ITALIC_STYLE 2

// Definitii pentru diferite tipuri de itemuri.
#define NONE_ITEM -1
#define FIRST_ITEM 0
#define NEW_ITEM 1
#define LAST_ITEM 2
#define NEW_AND_LAST_ITEM 3
#define FIRST_AND_LAST_ITEM 4

#define TAB_SIZE 30

line lines[TAB_SIZE]; // Stocheaza informatii despre fiecare linie de text analizata.
char characters[500]; // Reprezinta bufferul unde este stocat textul original de intrare, pe masura ce este analizat si procesat.
char inputText[500];
int characterIndex = 0; // Un index care indica pozitia curenta in bufferul characters unde va fi inserat urmatorul text.
int lineIndex = 0; // Indica pozitia curenta in tabloul lines unde va fi inserata urmatoarea structura line.
int titleLevel = 0; // Setat pe baza numarului de caractere # din titlu (ex: ## ar seta titleLevel la 2).
bool isInParagraph = false; // Folosit pentru a determina daca un paragraf trebuie inchis (</p>) inainte de a incepe unul nou.

// Copiază o sectiune de text dintr-un buffer text intr-un alt buffer out dintre 2 pozitii.
void getTextBetweenFromAndTo(const char* text, const int from, const int to, char* out)
{
    for(int i = from, j = 0; i < to; i++, j++) {
        out[j] = text[i];
    }
}

void formatText(line currentLine, char* out) 
{
	// Adauga tagurile de deschidere corespunzatoare stilului specificat in structura line.
	if(currentLine.style == ITALIC_STYLE)
		strcat(out, "<i>");
	else if(currentLine.style == BOLD_STYLE)
		strcat(out, "<strong>");
	else if(currentLine.style == BOLD_ITALIC_STYLE)
		strcat(out, "<i><strong>");

	// Extrage textul dintre pozitiile l.position si l.position + l.length din bufferul characters si il adauga in out.
    char* aux = calloc(currentLine.length + 1, sizeof(char));

	getTextBetweenFromAndTo(characters, currentLine.position, currentLine.position + currentLine.length, aux);
	strcat(out, aux);

	// Adauga tagurile de inchidere corespunzatoare stilului specificat in structura line.
	if(currentLine.style == ITALIC_STYLE)
		strcat(out, "</i>");
	else if(currentLine.style == BOLD_STYLE)
		strcat(out, "</strong>");
	else if(currentLine.style == BOLD_ITALIC_STYLE)
		strcat(out, "</strong></i>");
	
	free(aux);
}

// Se ocupa de inchiderea unui paragraf HTML daca acesta este deschis.
void endParagraphIfOpen() 
{
	if(isInParagraph)
	{
		isInParagraph = false;
		printf("</p>\n");
	}
}

// Se ocupa de procesarea si afisarea textului formatat intr-un paragraf HTML.
void processText(line currentLine)
 {
	char* aux = calloc(1024, sizeof(char));

	formatText(currentLine, aux);

	// Daca nu suntem intr-un paragraf deschis, deschide un nou paragraf si afiseaza textul formatat.
	if(!isInParagraph) 
	{
		isInParagraph = true;
		printf("<p>%s", aux);
	} else 
	{
		printf("%s", aux);
	}

    free(aux);
}

// Se ocupa de procesarea si afisarea textului formatat intr-o lista HTML. 
void processList(line currentLine) 
{
	endParagraphIfOpen();

	char* aux = calloc(1024, sizeof(char));

	formatText(currentLine, aux);

	// Verifica tipul de element din lista si il afiseaza corespunzator.
    if(currentLine.itemType == FIRST_ITEM)
        printf("<ul>\n\t<li>%s", aux); // Deschide o noua lista si adauga primul element.
    else if(currentLine.itemType == NEW_ITEM)
        printf("</li>\n\t<li>%s", aux); // Incheie elementul anterior si adauga un nou element in lista.
    else if(currentLine.itemType == LAST_ITEM)
        printf("%s</li>\n</ul>\n", aux); // Incheie lista.
    else if(currentLine.itemType == NEW_AND_LAST_ITEM)
        printf("</li>\n\t<li>%s</li>\n</ul>\n", aux); // Incheie elementul anterior si lista.
    else
        printf("<ul>\n\t<li>%s</li>\n</ul>\n", aux); // Afiseaza un singur element intr-o lista separata

    free(aux);
}

// Se ocupa de procesarea si afisarea titlului formatat in HTML.
void processTitle(line currentLine) 
{
	endParagraphIfOpen();

    char* aux = calloc(1024, sizeof(char));

    getTextBetweenFromAndTo(characters, currentLine.position, currentLine.position + currentLine.length, aux);

	// Afiseaza titlul HTML formatat in functie de tipul de titlu specificat in currentLine.
    printf("<h%d>%s</h%d>\n", currentLine.titleType, aux, currentLine.titleType);
	
    free(aux);
}

// Se ocupa de procesarea si inchiderea unui paragraf HTML deschis in cazul aparitiei unei linii goale.
void processEmptyLine() 
{
	if(isInParagraph)
	{
		isInParagraph = false;
		printf("</p>\n");
	}
}

// Insereaza textul dat in bufferul de caractere si in structura de linii.
void insertText(char* text)
{
	// Concateneaza textul dat la sfarsitul bufferului de caractere existent.
	strcat(characters, text);
	strcat(inputText, text);
	strcat(inputText, " ");
	
	// Initializeaza o noua structura de linie cu informatii despre textul adaugat.
	line currentLine = {
		characterIndex, // Pozitia de inceput a textului in bufferul de caractere.
		strlen(text),   // Lungimea textului care este adaugat.
		TEXT_NORMAL,    // Tipul textului: textul nu este un titlu sau un element de lista.
		-1,             // Linia nu este un titlu.
		NONE_STYLE,     // Textul nu are un stil specificat.
		NONE_ITEM       // Textul nu este parte a unei liste.
	};

	lines[lineIndex++] = currentLine;

	characterIndex += strlen(text);
}

// Insereaza textul dat ca titlu in bufferul de caractere si in structura de linii.
void addTitle(char* title)
{
	strcat(characters, title);
	strcat(inputText, title);
	strcat(inputText, " ");

	// Initializeaza o noua structura de linie cu informatii despre titlul adaugat.
    line currentLine = {
        characterIndex, // Pozitia de inceput a titlului in bufferul de caractere.
        strlen(title),  // Lungimea textului titlului care este adaugat.
        TEXT_TITLE,     // Tipul textului: textul este un titlu.
        titleLevel,     // Nivelul titlului, precizat anterior in cod.
        NONE_STYLE,     // Textul nu are un stil specificat.
        NONE_ITEM       // Textul nu este parte a unei liste.
    };

	lines[lineIndex++] = currentLine;

	characterIndex += strlen(title);
}

// Insereaza textul dat ca element de lista in bufferul de caractere si in structura de linii.
void addItemToList(char* item)
{
	strcat(characters, item);
	strcat(inputText, item);
	strcat(inputText, " ");

	line currentLine = {characterIndex, strlen(item), TEXT_ITEM, -1, NONE_STYLE, NONE_ITEM};

	lines[lineIndex++] = currentLine;

	characterIndex += strlen(item);
}

// Insereaza o linie goala in structura de linii.
void addEmptyLine() 
{
	// A doua valoare este 1 deoarece lungimea unei linii goale este de 1 caracter (linia noua '\n').
	line currentLine = {characterIndex, 1, EMPTY_LINE, -1, NONE_ITEM, NONE_ITEM};

	lines[lineIndex++] = currentLine;
}

// Determina nivelul titlului dat pe baza numarului de caractere '#' din sirul de caractere.
int getTitleLevel(char* title)
{
	int nbOfHashtag = 0;
	for(int i = 0; i < strlen(title); i++)
		if(title[i] == '#')
			nbOfHashtag++;
	return nbOfHashtag;
}

void processButton(line currentLine) 
{
    endParagraphIfOpen();

    char* aux = calloc(1024, sizeof(char));
    formatText(currentLine, aux);

    // Afisam butonul in functie de stilul specificat
    switch (currentLine.buttonStyle) {
        case BUTTON_STYLE_PRIMARY:
            printf("<button class=\"btn btn-primary\">%s</button>\n", aux);
            break;
        case BUTTON_STYLE_SECONDARY:
            printf("<button class=\"btn btn-secondary\">%s</button>\n", aux);
            break;
        default:
            printf("<button>%s</button>\n", aux);
            break;
    }

    free(aux);
}

void addButton(char* button)
{
    strcat(characters, button);
    strcat(inputText, button);
    strcat(inputText, " ");

    line currentLine = {
        characterIndex,
        strlen(button),
        TEXT_BUTTON,
        -1,
        NONE_STYLE,
        NONE_ITEM
    };

    lines[lineIndex++] = currentLine;
    characterIndex += strlen(button);
}

// Curata sirul de caractere de caracterele speciale "\\" urmate de "*" si returneaza un nou sir curatat.
char* clean(char* text) 
{
    char* output;
	// Initializeaza un nou sir cu lungimea sirului de intrare plus un caracter pentru terminatorul '\0'.
    if(!(output = calloc(strlen(text) + 1, sizeof(char)))) 
	{
		// Afiseaza un mesaj de eroare in caz de esec la alocarea de memorie.
        fprintf(stderr, "%s\n", strerror(errno));
        exit(errno);
    }

    size_t in_iterator = 0;
    size_t out_iterator = 0;
    for(; in_iterator < strlen(text); in_iterator++) 
	{
		// Verifica daca caracterul curent este "\\" urmat de "*".
        if(in_iterator < strlen(text) - 1 && text[in_iterator] == '\\' && text[in_iterator + 1] == '*') 
		{
			// Adauga caracterul "*" in noul sir.
            output[out_iterator] = '*';
            in_iterator++;
        } else 
		{
			// Altfel, adauga caracterul curent in noul sir.
            output[out_iterator] = text[in_iterator];  
		}
        out_iterator++;
    }
    return output;
}

%}

%start TITLE
%start ITEM

STRING ([^#*_\n]|"\\*")+
ENDLINE (\n|\r\n)

%%

(" "|\t)+	{}

<INITIAL>"button primary "+{STRING}    {
    printf("Primary Button: %s\n", yytext + 14);
    yylval = lineIndex;
    addButton(yytext + 14);
    lines[lineIndex - 1].textType = TEXT_BUTTON;
    lines[lineIndex - 1].buttonStyle = BUTTON_STYLE_PRIMARY;
    return BUTTON;
}

<INITIAL>"button secondary "+{STRING}    {
    printf("Secondary Button: %s\n", yytext + 16);
    yylval = lineIndex;
    addButton(yytext + 16);
    lines[lineIndex - 1].textType = TEXT_BUTTON;
    lines[lineIndex - 1].buttonStyle = BUTTON_STYLE_SECONDARY;
    return BUTTON;
}

<INITIAL>"button "+{STRING}    {
    printf("Button: %s\n", yytext + 7);
    yylval = lineIndex;
    addButton(yytext + 7);
    lines[lineIndex - 1].textType = TEXT_BUTTON;
    lines[lineIndex - 1].buttonStyle = BUTTON_STYLE_NORMAL;
    return BUTTON;
}


<INITIAL>{STRING}	{
	printf("Piece of text : %s\n", clean(yytext));
	yylval = lineIndex;
	insertText(clean(yytext));
	return TEXT;
}

<TITLE>{STRING}	{
	printf("Piece of text : %s\n", yytext);
	yylval = lineIndex;
	addTitle(yytext);
	return TEXT;
}

<ITEM>{STRING}	{
	printf("Piece of text : %s\n", yytext);
	yylval = lineIndex;
	addItemToList(yytext);
	return TEXT;
}

<INITIAL>^" "{0,3}"#"{1,6}" "+	{
	printf("Title tag\n");
	BEGIN TITLE;
	titleLevel = getTitleLevel(yytext);
	return BEGINTITLE;
}

<TITLE>{ENDLINE}(" "*{ENDLINE})+|\n	{
	printf("End of title\n");
	BEGIN INITIAL;
	return FINALIZETITLE;
}

<INITIAL>{ENDLINE}(" "*{ENDLINE})+	{
	printf("Blank line\n");
	addEmptyLine();
	return BLANKLINE;
}

<INITIAL>^"*"" "+	{
	printf("Start of list\n");
	BEGIN ITEM;
	yylval = lineIndex;
	return STARTLIST;
}

<ITEM>^"*"" "+	{
	printf("List item\n");
	yylval = lineIndex;
	return ITEMLIST;
}

<ITEM>{ENDLINE}(" "*{ENDLINE})+	{
	printf("End the list\n");
	BEGIN INITIAL;
	yylval = lineIndex - 1;
	return FINALIZELIST;
}

"*" {
	printf("Asterisk\n");
	return ASTERISK;
}

. {
	printf("Lexical error : Character %s not allowed\n", yytext);
}

%%

int yywrap()
{
	
	printf("Input text :\n %s\n\n", inputText);

    printf("<!DOCTYPE html>\n");
    printf("<html>\n");
    printf("<head>\n");
    printf("\t <title>Title html</title>\n");
    printf("\t <meta charset=\"utf-8\"/>\n");
    printf("</head>\n");
    printf("<body>\n");

     for(int i = 0; i < TAB_SIZE; i++) {
        if(lines[i].length != 0) {
            switch(lines[i].textType) {
				case TEXT_BUTTON:
					processButton(lines[i]);
					break;
                case TEXT_NORMAL:
                    processText(lines[i]);
                    break;
                case TEXT_ITEM:
                    processList(lines[i]);
                    break;
                case EMPTY_LINE:
                    processEmptyLine();
                    break;
				default:
                    processTitle(lines[i]);
                    break;
			}
		}
	 }
	endParagraphIfOpen();

    printf("</body>\n");
    printf("</html>");

	return 1;
}
