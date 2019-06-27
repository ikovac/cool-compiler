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

%}

/*
	Na ovaj način smo definirali stanja koja uključujemo sa funkcijom BEGIN() koja dolazi sa flexom.
 */
%x COMMENT STRING ESCAPE
/*
 * Define names for regular expressions here.
 */

/*
 * U ovom dijelu regularnim izrazima dodjelimo nazive kako bi kod leksera bio pregledniji i jednostavniji
 */

DARROW          =>
ASSIGN		<-
LE		<=

INTEGERS	[0-9]+

TYPEID		[A-Z][A-Z|a-z|0-9|_]*
OBJECTID		[a-z][A-Z|a-z|0-9|_]*

newline		"\n"
whitespace		" "|"\f"|"\r"|"\t"|"\v"


/*
 * Popis specijalnih znakova sam pronašao na internetu.
 */
SINGLES_CHARACTERS		"+"|"-"|"*"|"/"|"<"|"="|"("|")"|"{"|"}"|";"|":"|"@"|"~"|"."|","

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */


/*
 * Sve Ključne riječi
 * ?i: označava da su navedeni izrazi case insensitive
 * Popis ključnih riječi našao sam u pdf-u cool_manual pod poglavljem 10.4 Keywords te su po tim redosljedu ključne riječi upisivane.
 * U cool_manual.pdf-u piše da TRUE I FALSE moraju započimati malim slovom, a da je ostatak case insensitive, stoga je za njih izraz: t(?i:rue).
 */
CLASS		(?i:class)
ELSE		(?i:else)
FALSE		f(?i:alse)
FI		(?i:fi)
IF		(?i:if)
IN		(?i:in)
INHERITS		(?i:inherits)
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


BEGIN_BLOCK_COMMENT		"(*"
END_BLOCK_COMMENT		"*)"
LINE_COMMENT		--(.)*

DBL_QUOTE		\"

%%
	 /*
	  * Nested comments
	  * Svi komentari obrađeni su u sekciji ispod
	  * Funkcija BEGIN je gotova funkcija u FLEX-u koja nam omogućava uključivanje pojedinog stanja
	  * Npr ako uključimo stanje BEGIN(test), onda možemo uz uvjet da smo u stanju <test> izvršavati određene radnje tj. "jesti" znakove sa ulaza
	  * greške "Unmatched" i "EOF in comment" sam vratio na osnovu upustava u prezentaciji jip_sem_04_cool_lexer.pdf
	  * Stanje INITIAL je osnovno stanje, koje je aktivno kada nismo u nikojem drugom stanju.
  	  */
{END_BLOCK_COMMENT} {
		cool_yylval.error_msg = "Unmatched *)";
		return (ERROR);	
}
{BEGIN_BLOCK_COMMENT} { 
		commentLvl++;
		BEGIN(COMMENT); 
}
<COMMENT><<EOF>> {
	BEGIN(INITIAL);
	if(commentLvl>0) {
		cool_yylval.error_msg = "EOF in comment";
		commentLvl=0;
		return (ERROR);
	}
}
<COMMENT>{BEGIN_BLOCK_COMMENT} { 
	commentLvl++;
}
<COMMENT>\n	{
	curr_lineno++;
}
<COMMENT>.	{ }
<COMMENT>{END_BLOCK_COMMENT} { 
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
{LINE_COMMENT} 		{ }


	/*
	* Keywords are case-insensitive except for the values true and false,
    * which must begin with a lower-case letter.
	* Obrada svih ključnih riječi
	*/
{CLASS} { return (CLASS); }
{ELSE} { return (ELSE); }
{FI} { return (FI); }
{IF} { return (IF); }
{IN} { return (IN); }
{INHERITS} { return (INHERITS); }
{ISVOID} { return (ISVOID); }
{LET} { return (LET); }
{LOOP} { return (LOOP); }
{POOL} { return (POOL); }
{THEN} { return (THEN); }
{WHILE} { return (WHILE); }
{CASE} { return (CASE); }
{ESAC} { return (ESAC); }
{OF} { return (OF); }
{NEW} { return (NEW); }
{NOT} { return (NOT); }
{TRUE} { 
	cool_yylval.boolean = true;
	return (BOOL_CONST);
}
{FALSE} {
	cool_yylval.boolean = false;
	return (BOOL_CONST);
}
 /*
  *  The multiple-character operators.
  */
{DARROW} { return (DARROW); }
{ASSIGN} { return (ASSIGN); }
{LE} { return (LE); }


{INTEGERS} {
	cool_yylval.symbol = inttable.add_string(yytext);
	return (INT_CONST);
}		
{TYPEID} {
	cool_yylval.symbol = idtable.add_string(yytext);
	return (TYPEID);
}
{OBJECTID} {
	cool_yylval.symbol = idtable.add_string(yytext);
	return (OBJECTID);
}

	/*
	 * Tokeni za simbole koji imaju samo jedan znak su ASCII vrijednost samog znaka.
	 */
{SINGLES_CHARACTERS} { return (yytext[0]); }

	/*
	 * Za sve nevažeće znakove vratimo error i u error_msg stavimo nevažeći znak.
	 */


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *  U sekciji ispod slijedi obrada stringova
  *  Greške vraćam na osnovu uputa u prezentaciji jip_sem_04_cool_lexer.pdf.
  */


	/*
	 * Sa znakom double quote string ako nije u stanju STRING započinje,
	 * Ako se već nalazimo u stanju STRING tada završava.
	 * Nakon što smo zatvorili string, treba provjeriti je li duži od dozvoljene vrijednosti
	 * koja je definirana sa konstantom MAX_STR_CONST
	 * Ukoliko je duži vraćamo error sa porukom String constant too long
	 * Ukoliko je sve ispravno vraćamo STR_CONT token sa vrijednošću tog stringa koja se spremi u cool_yylval.symbol
	 */
{DBL_QUOTE} { 
			
	BEGIN(STRING);
	string_buf_ptr = string_buf;
}
<STRING><<EOF>> {
	BEGIN(INITIAL);
	cool_yylval.error_msg = "EOF in string";
	return (ERROR);
}
<STRING>\0 {
	*string_buf = '\0';
	cool_yylval.error_msg = "String contains null character";
	BEGIN(ESCAPE);
	return (ERROR);
}
<STRING>{newline} {
	*string_buf = '\0';
	BEGIN(INITIAL);
	cool_yylval.error_msg = "Unterminated string constant";
	return (ERROR);
}

<STRING>{DBL_QUOTE} {
	if(string_buf_ptr - string_buf > MAX_STR_CONST-1){
		BEGIN(ESCAPE);
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

<STRING>\\n { *string_buf_ptr++ = '\n'; }
<STRING>\\t { *string_buf_ptr++ = '\t'; }
<STRING>\\b { *string_buf_ptr++ = '\b'; }
<STRING>\\f { *string_buf_ptr++ = '\f'; }
<STRING>\\[^\0]	{ *string_buf_ptr++ = yytext[1]; }

/*
 * Čitamo znakove stringa i stavljamo ih u buffer.
 */
<STRING>. { *string_buf_ptr++ = *yytext; }

{newline} { curr_lineno++; }
{whitespace} 

<ESCAPE>[\n|"]		BEGIN(INITIAL);
<ESCAPE>[^\n|"]


/*
 * Ukoliko ništa od prethodnih pravila nije tokeniziralo ulazni string znači da su na ulazu nedopušteni ili neispravno napisani znakovi.
 * U tom slučaju vraćamo error sa tekstom neispravnih/nedopuštenih ulaznih znakova.
 */ 

. 		{
	cool_yylval.error_msg = yytext;
	return (ERROR);		
}
%%
