/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;
int commentLvl = 0;

extern YYSTYPE cool_yylval;


/*
 *  Add Your own definitions here
 */
int checkStringLength() {
	int lenght = string_buf_ptr - string_buf;
	if(lenght >= MAX_STR_CONST)
		return 0;
	else
		return 1;
}
%}
%x COMMENT
%x STRING
%x RESET
/*
 * Define names for regular expressions here.
 */

/*
 * U ovom dijelu regularnim izrazima dodjelimo nazive kako bi kod leksera bio pregledniji i jednostavniji
 */

DARROW          =>
ASSIGN		<-
LE		<=

INT		[0-9]+
TYPE		[A-Z][A-Z|a-z|0-9|_]*
OBJECT		[a-z][A-Z|a-z|0-9|_]*

NEWLINE		"\n"
WHITESPACE	" "|"\f"|"\r"|"\t"|"\v"

SPECIAL		"+"|"-"|"*"|"/"|"~"|"<"|"="|"("|")"|"{"|"}"|"."|","|":"|";"|"@"
INVALID		"!"|"#"|"$"|"%"|"^"|"&"|"_"|">"|"?"|"`"|"["|"]"|"\\"|"|"

/*
 * Sve Ključne riječi
 * ?i: označava da su navedeni izrazi case insensitive
 * Popis ključnih riječi našao sam u pdf-u cool_manual pod poglavljem 10.4 Keywords
 * U cool_manual.pdf-u piše da TRUE I FALSE moraju započimati malim slovom, a da je ostatak case insensitive, stoga je za njih izraz: t(?i:rue).
 * /
CLASS		(?i:class)
ELSE		(?i:else)
FI		(?i:fi)
IF		(?i:if)
IN		(?i:in)
INHERITS	(?i:inherits)
ISVOID		(?i:isvoid)
LET		(?i:let)
LOOP		(?i:loop)
POOL		(?i:pool)
THEN		(?i:then)
WHILE		(?i:while)
CASE		(?i:case)
ESAC		(?i:esac)
NEW		(?i:new)
OF		(?i:of)
NOT		(?i:not)
TRUE		t(?i:rue)
FALSE		f(?i:alse)


BEGIN_COMMENT 	"(*"
END_COMMENT 	"*)"
DASH_COMMENT	--(.)*

STR		\"
NO_MATCH	.

%%
	 /*
	  * Svi komentari obrađeni su u sekciji ispod
	  * Funkcija BEGIN je gotova funkcija u FLEX-u koja nam omogućava uključivanje pojedinog stanja
	  * Npr ako uključimo stanje BEGIN(test), onda možemo uz uvjet da smo u stanju <test> izvršavati određene radnje tj. "jesti" znakove sa ulaza
	  * greške "Unmatched" i "EOF in comment" sam vratio na osnovu upustava u prezentaciji jip_sem_04_cool_lexer.pdf
	  * Stanje INITIAL je osnovno stanje, koje je aktivno kada nismo u nikojem drugom stanju.
  	  */
{END_COMMENT}		{
				cool_yylval.error_msg = "Unmatched *)";
				return (ERROR);	
			}
{BEGIN_COMMENT}		{ 
				commentLvl++;
				BEGIN(COMMENT); 
			}
<COMMENT><<EOF>>	{
				BEGIN(INITIAL);
				if(commentLvl>0) {
					cool_yylval.error_msg = "EOF in comment";
					commentLvl=0;
					return (ERROR);
				}
			}
<COMMENT>{BEGIN_COMMENT} { commentLvl++; }
<COMMENT>\n		{ curr_lineno++; }
<COMMENT>.		{ }
<COMMENT>{END_COMMENT}	{ 
				commentLvl--;
				if(commentLvl == 0) {
					BEGIN(INITIAL);
				}
				else if(commentLvl<0){
					cool_yylval.error_msg = "Unmatched *)";
					commentLvl=0;
					BEGIN(INITIAL);
					return (ERROR);
				}
			}
{DASH_COMMENT} 		{ }


	/*
	* Obrada svih ključnih riječi
	*/
{CLASS} 		{ return (CLASS); }
{ELSE} 			{ return (ELSE); }
{FI}			{ return (FI); }
{IF}			{ return (IF); }
{IN}			{ return (IN); }
{INHERITS}		{ return (INHERITS); }
{ISVOID}		{ return (ISVOID); }
{LET}			{ return (LET); }
{LOOP}			{ return (LOOP); }
{POOL}			{ return (POOL); }
{THEN}			{ return (THEN); }
{WHILE}			{ return (WHILE); }
{CASE}			{ return (CASE); }
{ESAC}			{ return (ESAC); }
{OF}			{ return (OF); }
{NEW}			{ return (NEW); }
{NOT}			{ return (NOT); }
{TRUE} 			{ 
			 	cool_yylval.boolean = true;
			 	return (BOOL_CONST);
			}
{FALSE}			{
				cool_yylval.boolean = false;
				return (BOOL_CONST);
			}
{NEWLINE}		{ curr_lineno++; }
{WHITESPACE} 
 /*
  *  The multiple-character operators.
  */
{INT} 			{
				cool_yylval.symbol = inttable.add_string(yytext);
				return (INT_CONST);
			}		
{TYPE}			{
				cool_yylval.symbol = idtable.add_string(yytext);
				return (TYPEID);
			}
{OBJECT} 		{
				cool_yylval.symbol = idtable.add_string(yytext);
				return (OBJECTID);
			}
{SPECIAL} 		{ return (yytext[0]); }
{INVALID}		{ 
				cool_yylval.error_msg = yytext;
				return (ERROR);
			}
{DARROW} 		{ return (DARROW); }
{ASSIGN} 		{ return (ASSIGN); }
{LE}			{ return (LE); }


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *  U sekciji ispod slijedi obrada stringova
  *  Greške vraćam na osnovu uputa u prezentaciji jip_sem_04_cool_lexer.pdf.
  */
{STR}			{ 
			
				BEGIN(STRING);
				string_buf_ptr = string_buf;
			}
<STRING><<EOF>>		{
				BEGIN(INITIAL);
				cool_yylval.error_msg = "EOF in string";
				return (ERROR);
			}

<STRING>{STR}		{
				if(!checkStringLength()){
						BEGIN(INITIAL);
						*string_buf_ptr = '\0';
						cool_yylval.error_msg = "String constant too long";
						return (ERROR);
					}
				else {
					BEGIN(INITIAL);
					*string_buf_ptr = '\0';
					cool_yylval.symbol = stringtable.add_string(string_buf);			
					return (STR_CONST);
				}
			}
<STRING>\0		{
				*string_buf = '\0';
				BEGIN(RESET);
				cool_yylval.error_msg = "String contains null character";
				return (ERROR);
			}
<STRING>{NEWLINE}	{
				*string_buf = '\0';
				BEGIN(INITIAL);
				cool_yylval.error_msg = "Unterminated string constant";
				return (ERROR);
			}
<STRING>\\n  		{ *string_buf_ptr++ = '\n'; }
<STRING>\\t 		{ *string_buf_ptr++ = '\t'; }
<STRING>\\b  		{ *string_buf_ptr++ = '\b'; }
<STRING>\\f  		{ *string_buf_ptr++ = '\f'; }
<STRING>\\[^\0\r]	{ *string_buf_ptr++ = yytext[1]; }
<STRING>.		{ *string_buf_ptr++ = *yytext; }

<RESET>[\n"]		{ BEGIN(INITIAL); }
<RESET>[^\n"]		{ }
{NO_MATCH}		{
				cool_yylval.error_msg = yytext;
				return (ERROR);		
			}
%%
