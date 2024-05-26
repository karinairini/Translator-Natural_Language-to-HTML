%{
	#include <stdio.h>
	#include <stdlib.h>
	int yylex();
	void yyerror(char *s);

	typedef struct structLine {
		int position;
		int length;
		int textType;
		int titleType;
		int style;
		int itemType;
    	int buttonStyle;
	} line;

	#define TAB_SIZE 30
	extern line lines[TAB_SIZE];

	#define TEXT_NORMAL 0
	#define TEXT_ITEM 1
	#define TEXT_TITLE 2
	#define EMPTY_LINE 3
	#define TEXT_BUTTON 4

	#define BUTTON_STYLE_NORMAL 0
	#define BUTTON_STYLE_PRIMARY 1
	#define BUTTON_STYLE_SECONDARY 2

	#define NONE_STYLE -1
	#define ITALIC_STYLE 0
	#define BOLD_STYLE 1
	#define BOLD_ITALIC_STYLE 2

	#define NONE_ITEM -1
	#define FIRST_ITEM 0
	#define NEW_ITEM 1
	#define LAST_ITEM 2
	#define NEW_AND_LAST_ITEM 3
	#define FIRST_AND_LAST_ITEM 4

	int lastIndexEndList=0;
%}

%token TEXT BEGINTITLE FINALIZETITLE BLANKLINE STARTLIST ITEMLIST FINALIZELIST ASTERISK BUTTON
%start file

%%

file: element | element file {};

element: TEXT | BLANKLINE | title | list | text_formatted | button {};

title: BEGINTITLE TEXT FINALIZETITLE {};

button: BUTTON {
    lines[$1].textType = TEXT_BUTTON;
}

list: STARTLIST list_texts next_lists {
    if ($1 == lastIndexEndList)
        lines[$1].itemType = FIRST_AND_LAST_ITEM;
    else
        lines[$1].itemType = FIRST_ITEM;
};

next_lists: ITEMLIST list_texts next_lists {
    if ($1 == lastIndexEndList)
        lines[$1].itemType = NEW_AND_LAST_ITEM;
    else
        lines[$1].itemType = NEW_ITEM;
}
| FINALIZELIST {
    lines[$1].itemType = LAST_ITEM;
    lastIndexEndList = $1;
};

text_formatted: italic | bold | bold_italic {};

italic: ASTERISK TEXT ASTERISK {
    lines[$2].style = ITALIC_STYLE;
};

bold: ASTERISK ASTERISK TEXT ASTERISK ASTERISK {
    lines[$3].style = BOLD_STYLE;
};

bold_italic: ASTERISK ASTERISK ASTERISK TEXT ASTERISK ASTERISK ASTERISK {
    lines[$4].style = BOLD_ITALIC_STYLE;
};

list_texts: TEXT | text_formatted | TEXT list_texts | text_formatted list_texts {};

%%

int main()
{
	yyparse();
	return 0;
}

void yyerror(char *error)
{
	fprintf(stderr,"error %s\n", error);
}
