%{
#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <string.h>
#include <math.h>
#include <float.h>
#include <ctype.h>
#include "y.tab.h"

#define NUMERO_INICIAL_TERCETO 10
#define SIN_MEMORIA 0
#define TODO_BIEN 1
#define COLA_VACIA 0
#define PILA_VACIA 0
#define TAM 35

extern int yylex(void);

FILE  *yyin, *tsout;

/*-- Estructura para la tabla de simbolos --*/
typedef struct {
	char nombre[30];
	char tipo[10];
	char valor[30];
	int longitud;
}t_ts;

t_ts tablaSimbolos[5000];

/*-- Estructura para tercetos --*/
typedef struct
	{
		char descripcion[TAM];
		char posicion_a[TAM];
		char posicion_b[TAM];
		char posicion_c[TAM];
	} info_cola_t;
	
typedef struct sNodoCola
	{
		info_cola_t info;
		struct sNodoCola *sig;
	} nodo_cola_t;

	typedef struct
	{
		nodo_cola_t *pri, *ult;
	} cola_t;

typedef struct
	{
		char descripcion[TAM];
		int numero_terceto;
	} info_pila_t;

	typedef struct sNodoPila
	{
		info_pila_t info;
		struct sNodoPila *sig;
	} nodo_pila_t;
	
	typedef nodo_pila_t *pila_t;
	
/*termina estructura tercetos*/	


/*variables tercetos*/
	char char_puntero_terceto[TAM];
	int numero_terceto = NUMERO_INICIAL_TERCETO;
	int cant_total_tercetos=0;//contador global
	cola_t cola_terceto;
	info_cola_t terceto_ent_sal;
	info_cola_t terceto_asignacion;
	info_cola_t terceto_expresion;
	info_cola_t terceto_termino;
	info_cola_t terceto_factor;
	info_cola_t terceto_if;
	info_cola_t terceto_cmp;
	info_cola_t terceto_operador_logico;
	info_cola_t terceto_while;
	
	info_cola_t terceto_ifunario;
	info_cola_t terceto_asignacion_especial;
	
	pila_t comparaciones,comparaciones_or;
	info_pila_t comparador,comparacion_or;
	
	pila_t saltos_incondicionales;
	info_pila_t salto_incondicional;
	pila_t ciclo_While;
	info_pila_t inicio_ciclo_While;
	
	int p_terceto_factor; 
	int p_terceto_termino;
	int p_terceto_expresion;
	int p_terceto_asig_especial;
	int p_terceto_if_then;
	int p_terceto_fin_then;
	int p_terceto_endif;
	int p_terceto_while_comienzo;
	int p_terceto_while_fin;
	char op_aux[2];
	int p_terceto_ifunario;
	
	
/*Finaliza variables tercetos*/

int posicionTabla=0;
int yystopparser=0;

extern char *yytext;

char tiposComparados[5000][10];
int cantComparaciones=0;

char tipoActual[10]={""};
char listaVariables[50][2]={""};
int contvariableActual=0;

/*funciones tercetos*/
	void crear_cola(cola_t *c);
	int poner_en_cola(cola_t *c, info_cola_t *d);
	int sacar_de_cola(cola_t *c, info_cola_t *d);
	void crear_pila(pila_t *p);
	int poner_en_pila(pila_t *p, info_pila_t *d);
	int sacar_de_pila(pila_t*p, info_pila_t *d);
	
	int crearTerceto(info_cola_t *info_terceto);
	void leerTerceto(int numero_terceto, info_cola_t *info_terceto_output);
	void modificarTerceto(int numero_terceto, info_cola_t *info_terceto_input);
	char *invertirOperadorLogico(char *operador_logico);
	
	char *normalizarPunteroTerceto(int terceto_puntero);// le agrega los corchetes al n?mero de terceto, osea entra 10 y sale [10]
	
	void clear_intermedia();
	void crear_intermedia(cola_t *cola_intermedia);
	void guardar_intermedia(cola_t *p, FILE *arch);

/*Finaliza funciones tercetos*/

int validarInt(int entero);
int validarString(char *str);
int validarFloat(float flotante);
int validarID(char *str);
int guardarEnTablaSimbolo(int num, char *yytext, char *valor);
void escribirTablaSimbolo(void);
int buscarEnTablaSimbolo(char *);
void existeEnTablaSimbolo(char *);
void guardarTipo();
int yyerror();

void validarTipos();

%}

%union {
  char *strVal;
}

%token PUNTOCOMA DOSPUNTOS COMA
%token P_A P_C
%token ENDIF END THEN INICIO_WHILE
%token OP_SUMA OP_RESTA OP_MUL OP_DIV
%token OP_ASIGNACION OP_ASIG_ESPECIAL OP_COMPARACION 
%token AND OR
%token NOT
%token DEFVAR ENDDEF
%token DISPLAY GET 
%token INT FLOAT STRING
%token IF ELSE
%token WHILE
%token <strVal>CONST_INT
%token <strVal>CONST_STRING
%token <strVal>CONST_FLOAT
%token <strVal>ID

%%
Inicio:
  {printf("\n\nINICIA COMPILACION\n\n");}  programa {printf("\n\nCOMPILACION EXITOSA!\n\n\n");
  
  } 
;

programa:  	   
	{printf("Bloque de declaraciones\n\n");}  bloque_Declaraciones 
	{printf("\n\nBloque de sentencias\n");}  bloque_Sentencias
;  

bloque_Declaraciones:
	DEFVAR declaraciones ENDDEF 					 {printf("Regla 3: Bloque_declaraciones es DEFVAR declaraciones ENDDEF\n\n");};


declaraciones:         	        	
	declaracion  								 {printf("Regla 4: declaraciones es declaracion\n");}
	|declaraciones declaracion						 {printf("Regla 5: declaraciones es declaraciones declaracion\n");}
;

declaracion:  
	tipo DOSPUNTOS lista_var 						 {printf("Regla 6: declaracion es tipo DOSPUNTOS lista_var\n");}
;

tipo:
	FLOAT {strcpy(tipoActual,"Float");}					{printf("Regla 7: tipo es FLOAT\n");}
	|INT {strcpy(tipoActual,"Int");}						{printf("Regla 8: tipo es INT\n");}
	|STRING {strcpy(tipoActual,"String");}					{printf("Regla 9: tipo es STRING\n");}
;

lista_var:  
	ID {printf("Variable: %s Tipo: %s \n",yylval.strVal,tipoActual); validarID(yylval.strVal); contvariableActual++; strcpy(listaVariables[contvariableActual],yylval.strVal); guardarTipo();}  {printf("Regla 10: lista_var es ID\n");}
	|lista_var PUNTOCOMA ID {printf("Variable: %s Tipo: %s \n",yylval.strVal,tipoActual); validarID(yylval.strVal); contvariableActual++; strcpy(listaVariables[contvariableActual],yylval.strVal); guardarTipo();} {printf("Regla 11: lista_var es lista_var PUNTOCOMA ID\n");}
;

bloque_Sentencias: 
	sentencia										{printf("Regla 12: bloque_sentencias es sentencia\n");}
	|bloque_Sentencias sentencia						{printf("Regla 13: bloque_sentencias es sentencia\n");}
;

sentencia:
	ciclo											{printf("Regla 14: sentencia es ciclo\n");}
	|si
	|asignacion								{printf("Regla 16: sentencia es asignacion \n");}
	|asignacionespecial								{printf("Regla 17: sentencia es asignacionespecial\n");}
	|salida										{printf("Regla 18: sentencia es salida\n");}
	|entrada										{printf("Regla 19: sentencia es entrada\n");}
;

ciclo: 
	WHILE //falta terminar while anidado 
	
	// apilar el inicio while para poder saltar a esta posici?n
			// cuando termina el bucle
			// se apila porque pueden haber while anidados
			{
			strcpy(terceto_while.posicion_a, yytext);
			strcpy(terceto_while.posicion_b, "_");
			strcpy(terceto_while.posicion_c, "_");
			inicio_ciclo_While.numero_terceto = crearTerceto(&terceto_while);
			poner_en_pila(&ciclo_While, &inicio_ciclo_While);
			}
	
	P_A decision P_C INICIO_WHILE
	 {
			// ac? salta si se cumple la primer condici?n de un OR
			info_cola_t terceto;

			// inicio del programa del IF
			strcpy(terceto_while.posicion_a, yytext);
			strcpy(terceto_while.posicion_b, "_");
			strcpy(terceto_while.posicion_c, "_");
			p_terceto_while_comienzo = crearTerceto(&terceto_while);
			// la primera condici?n de un OR, salta directo al THEN del IF, si es verdadera
			// leer terceto con el salto de la comparacion del OR
			if(sacar_de_pila(&comparaciones_or, &comparacion_or) != PILA_VACIA) {
				leerTerceto(comparacion_or.numero_terceto, &terceto);
				// asignar al operador l?gico el terceto al que debe saltar
				strcpy(terceto.posicion_b, normalizarPunteroTerceto(p_terceto_while_comienzo));
				modificarTerceto(comparacion_or.numero_terceto, &terceto);
			}
		}
	bloque_Sentencias END 
	{
			info_cola_t terceto;

			// el ciclo vuelve a chekear la condici?n siempre que termina el programa del REPEAT
			strcpy(terceto_while.posicion_a, "BRA");
			sacar_de_pila(&ciclo_While, &inicio_ciclo_While);
			strcpy(terceto_while.posicion_b, normalizarPunteroTerceto(inicio_ciclo_While.numero_terceto));
			strcpy(terceto_while.posicion_c, "_");
			crearTerceto(&terceto_while);

			// ac? salta si no se cumple cualquier condici?n de un AND
			// o si no se cumple la segunda condici?n de un OR
			// o si no se cumple una comparaci?n simple (con o sin NOT)
			strcpy(terceto_while.posicion_a, yytext);
			strcpy(terceto_while.posicion_b, "_");
			strcpy(terceto_while.posicion_c, "_");
			p_terceto_while_fin = crearTerceto(&terceto_while);

			// por cada comparaci?n que se haga en la condici?n
			int compraciones_condicion = 1;
			while(compraciones_condicion) {
				compraciones_condicion--;
				// desapilar y escribir la posici?n a la que se debe saltar 
				// si no se cumple la condici?n del if
				sacar_de_pila(&comparaciones, &comparador);
				leerTerceto(comparador.numero_terceto, &terceto);
				if (strcmp(terceto.posicion_b, "AND") == 0) {
					// si es una condici?n AND tiene m?s comparaciones para desapilar
					compraciones_condicion++;
				}
				// asignar al operador (por ejemplo un "BNE") el terceto al que debe saltar
				strcpy(terceto.posicion_b, normalizarPunteroTerceto(p_terceto_while_fin));
				modificarTerceto(comparador.numero_terceto, &terceto);				
			}
		}
																			{printf("Regla 20: sentencia es ciclo\n");}
;

asignacion: //falta terminar if unario 
	ID 			{strcpy(terceto_asignacion.posicion_b, $1);}
		{existeEnTablaSimbolo($1); strcpy(tiposComparados[cantComparaciones],tablaSimbolos[buscarEnTablaSimbolo($1)].tipo); cantComparaciones++;} 
	OP_ASIGNACION 	{strcpy(terceto_asignacion.posicion_a, yytext);}
	bifurque2 {validarTipos(); cantComparaciones=0;} 		  	
;
	bifurque2: expresion  
				{
				strcpy(terceto_asignacion.posicion_c, normalizarPunteroTerceto(p_terceto_expresion));
				// crea un terceto con la forma (":=", ID, [10])
				// donde [10] es un ejemplo de p_terceto_expresion
				crearTerceto(&terceto_asignacion);
				}								
												{printf("Regla 21: asignacion es ID OP_ASIGNACION expresion\n");};
	bifurque2: ifUnario;

	ifUnario: 
	IF P_A decision COMA expresion {
				strcpy(terceto_asignacion.posicion_c, normalizarPunteroTerceto(p_terceto_expresion));
				crearTerceto(&terceto_asignacion);
				strcpy(terceto_if.posicion_a, "BRA");
				strcpy(terceto_if.posicion_b, "_");
				strcpy(terceto_if.posicion_c, "_");
				salto_incondicional.numero_terceto = crearTerceto(&terceto_if);
				poner_en_pila(&saltos_incondicionales, &salto_incondicional);//[18]
				//Etiqueta del ELSE para el Assembler
				strcpy(terceto_if.posicion_a, "INICIO_ELSE_UNARIA");
				strcpy(terceto_if.posicion_b, "_");
				strcpy(terceto_if.posicion_c, "_");
				crearTerceto(&terceto_if);
				////
				info_cola_t info_terceto_aux;
				if(sacar_de_pila(&comparaciones, &comparador) != PILA_VACIA){//aca tenemos el 13
					leerTerceto(comparador.numero_terceto, &info_terceto_aux);
					
					// asignar al operador (por ejemplo un "BNE") el terceto al que debe saltar
					strcpy(info_terceto_aux.posicion_b, normalizarPunteroTerceto(salto_incondicional.numero_terceto+1));
					modificarTerceto(comparador.numero_terceto, &info_terceto_aux);
				}	
				}
 COMA expresion {
	 			strcpy(terceto_asignacion.posicion_c, normalizarPunteroTerceto(p_terceto_expresion));
				int p_terceto_aux=crearTerceto(&terceto_asignacion);//22
				 info_cola_t info_terceto_aux;
				if(sacar_de_pila(&saltos_incondicionales, &salto_incondicional) != PILA_VACIA){//aca tenemos el 13
					leerTerceto(salto_incondicional.numero_terceto, &info_terceto_aux);
					
					// asignar al operador (por ejemplo un "BNE") el terceto al que debe saltar
					strcpy(info_terceto_aux.posicion_b, normalizarPunteroTerceto(p_terceto_aux+1));
					modificarTerceto(salto_incondicional.numero_terceto, &info_terceto_aux);
				}	
				}P_C{
				
				strcpy(terceto_if.posicion_a, "FIN_UNARIA");
				strcpy(terceto_if.posicion_b, "_");
				strcpy(terceto_if.posicion_c, "_");
				crearTerceto(&terceto_if);
				};

asignacionespecial: 
	ID {
		existeEnTablaSimbolo($1);	
		strcpy(tiposComparados[0],tablaSimbolos[buscarEnTablaSimbolo($1)].tipo); 
		strcpy(terceto_expresion.posicion_b, $1);
 	}OP_ASIG_ESPECIAL {
	 					strcpy(op_aux, yytext);
 	}ID {
		existeEnTablaSimbolo($1); 
		strcpy(tiposComparados[1],tablaSimbolos[buscarEnTablaSimbolo($1)].tipo); 
		validarTipos(); 
		cantComparaciones=0;
		strcpy(terceto_expresion.posicion_c, yytext);
		if (strcmp("+=",op_aux)==0)
			strcpy(terceto_expresion.posicion_a, "+");
		if (strcmp("-=",op_aux)==0)
			strcpy(terceto_expresion.posicion_a, "-");	
		if (strcmp("*=",op_aux)==0)
			strcpy(terceto_expresion.posicion_a, "*");
		if (strcmp("/=",op_aux)==0)
			strcpy(terceto_expresion.posicion_a, "/");
		p_terceto_expresion=crearTerceto(&terceto_expresion);
		strcpy(terceto_asignacion.posicion_b, terceto_expresion.posicion_b);
		strcpy(terceto_asignacion.posicion_c, normalizarPunteroTerceto(p_terceto_expresion));
		strcpy(terceto_asignacion.posicion_a,":=");
		crearTerceto(&terceto_asignacion);
	};

si: 
	IF 
	P_A decision P_C THEN 
		{
			info_cola_t terceto;

			// inicio del programa del IF
			strcpy(terceto_if.posicion_a, "THEN");
			strcpy(terceto_if.posicion_b, "_");
			strcpy(terceto_if.posicion_c, "_");
			p_terceto_if_then = crearTerceto(&terceto_if);
			// la primera condición de un OR, salta directo al THEN del IF, si es verdadera
			// leer terceto con el salto de la comparacion del OR
			if(sacar_de_pila(&comparaciones_or, &comparacion_or) != PILA_VACIA) {
				leerTerceto(comparacion_or.numero_terceto, &terceto);
				// asignar al operador lógico el terceto al que debe saltar
				strcpy(terceto.posicion_b, normalizarPunteroTerceto(p_terceto_if_then));
				modificarTerceto(comparacion_or.numero_terceto, &terceto);
			}
		}
	bloque_Sentencias  bifurque {printf("Regla 24: if es IF P_A decision P_C L_A bloque_Sentencias L_C\n");}	 		
	;
bifurque: ENDIF {
			info_cola_t terceto;

			strcpy(terceto_if.posicion_a, yytext);
			strcpy(terceto_if.posicion_b, "_");
			strcpy(terceto_if.posicion_c, "_");
			p_terceto_fin_then = crearTerceto(&terceto_if);
			// por cada comparación que se haga en la condición
			int compraciones_condicion = 1;
			while(compraciones_condicion) {
				compraciones_condicion--;
				// desapilar y escribir la posición a la que se debe saltar 
				// si no se cumple la condición del if
				if(sacar_de_pila(&comparaciones, &comparador) != PILA_VACIA) {
					leerTerceto(comparador.numero_terceto, &terceto);
					if (strcmp(terceto.posicion_b, "AND") == 0) {
						// si es una condición AND tiene más comparaciones para desapilar
						compraciones_condicion++;
					}
					// asignar al operador (por ejemplo un "BNE") el terceto al que debe saltar
					strcpy(terceto.posicion_b, normalizarPunteroTerceto(p_terceto_fin_then));
					modificarTerceto(comparador.numero_terceto, &terceto);
				}				
			}
		}
	;
bifurque: ELSE{
				info_cola_t terceto;

				// al finalizar el "THEN" se salta incondicionalmente al ENDIF
				strcpy(terceto_if.posicion_a, "BRA");
				strcpy(terceto_if.posicion_b, "_");
				strcpy(terceto_if.posicion_c, "_");
				salto_incondicional.numero_terceto = crearTerceto(&terceto_if);
				poner_en_pila(&saltos_incondicionales, &salto_incondicional);

				// agregar terceto con el "ELSE"
				strcpy(terceto_if.posicion_a, yytext);
				strcpy(terceto_if.posicion_b, "_");
				strcpy(terceto_if.posicion_c, "_");
				p_terceto_if_then = crearTerceto(&terceto_if);

				char aux[5];
				itoa(p_terceto_if_then, aux, 10);
				strcat(terceto_if.posicion_a, aux);

				// por cada comparaci?n que se haga en la condici?n
				int compraciones_condicion = 1;
				while(compraciones_condicion) {
					compraciones_condicion--;
					// desapilar y escribir la posici?n a la que se debe saltar 
					// si no se cumple la condici?n del if
					sacar_de_pila(&comparaciones, &comparador);
					leerTerceto(comparador.numero_terceto, &terceto);
					if (strcmp(terceto.posicion_b, "AND") == 0) {
						// si es una condici?n AND tiene m?s comparaciones para desapilar
						compraciones_condicion++;
					}
					// asignar al operador (por ejemplo un "BNE") el terceto al que debe saltar
					strcpy(terceto.posicion_b, normalizarPunteroTerceto(p_terceto_if_then));
					modificarTerceto(comparador.numero_terceto, &terceto);				
				}
			}

bloque_Sentencias ENDIF 
			{
				info_cola_t terceto;

				strcpy(terceto_if.posicion_a, yytext);
				strcpy(terceto_if.posicion_b, "_");
				strcpy(terceto_if.posicion_c, "_");
				p_terceto_endif = crearTerceto(&terceto_if);

				sacar_de_pila(&saltos_incondicionales, &salto_incondicional);
				leerTerceto(salto_incondicional.numero_terceto, &terceto);
				strcpy(terceto.posicion_b, normalizarPunteroTerceto(p_terceto_endif));//lo pone en []
				modificarTerceto(salto_incondicional.numero_terceto, &terceto);
			}
																		{printf("Regla 25: if es IF P_A decision P_C L_A bloque_Sentencias L_C ELSE L_A bloque_Sentencias L_C	\n");}
;



decision:
	condicion	{	
				// crear terceto con el "FCOMP"			
				crearTerceto(&terceto_cmp); //crea el 12
				// crear terceto del operador de la comparaci?n. BLE, BGT. El 13
				strcpy(terceto_operador_logico.posicion_b, "_"); 
				strcpy(terceto_operador_logico.posicion_c, "_");
				// apilamos la posici?n del operador, para luego escribir a donde debe saltar el terceto por false
				comparador.numero_terceto = crearTerceto(&terceto_operador_logico);
				poner_en_pila(&comparaciones, &comparador);					   				
				printf("Regla 27: decision es condicion \n");
			}
	|condicion
			{ 
				crearTerceto(&terceto_cmp);// crear terceto con el "CMP"
				// crear terceto del operador de la comparaci?n
				strcpy(terceto_operador_logico.posicion_b, "_"); 
				strcpy(terceto_operador_logico.posicion_c, "_");
				// apilamos la posici?n del operador, para luego escribir a donde debe saltar por false
				comparador.numero_terceto = crearTerceto(&terceto_operador_logico);
				poner_en_pila(&comparaciones, &comparador);
			}
	AND condicion	
			{	// crear terceto con el "CMP"
				crearTerceto(&terceto_cmp);
				// crear terceto del operador de la comparaci?n
				// si es un AND lo indicamos para saber que la condici?n tiene doble comparaci?n
				strcpy(terceto_operador_logico.posicion_b, "AND"); 
				strcpy(terceto_operador_logico.posicion_c, "_");
				// apilamos la posici?n del operador, para luego escribir a donde debe saltar por false
				comparador.numero_terceto = crearTerceto(&terceto_operador_logico);
				poner_en_pila(&comparaciones, &comparador);
			}			
																			{printf("Regla 28: decision es condicion AND condicion \n");}
	|condicion
			{
				crearTerceto(&terceto_cmp);// crear terceto con el "CMP"
				// crear terceto del operador de la comparaci?n
				// como es un OR debemos invertir el operador ya que por true, va directo al "THEN" del "IF"
				// sin evaluar la segunda condici?n
				strcpy(terceto_operador_logico.posicion_a, invertirOperadorLogico(terceto_operador_logico.posicion_a));
				strcpy(terceto_operador_logico.posicion_b, "_"); 
				strcpy(terceto_operador_logico.posicion_c, "_");
				// apilamos la posici?n del operador, para luego escribir a donde debe saltar por false
				comparacion_or.numero_terceto = crearTerceto(&terceto_operador_logico);
				poner_en_pila(&comparaciones_or, &comparacion_or);
			}
	OR condicion																	
			{	// crear terceto con el "CMP"
				crearTerceto(&terceto_cmp);
				// crear terceto del operador de la comparaci?n
				strcpy(terceto_operador_logico.posicion_b, "_"); 
				strcpy(terceto_operador_logico.posicion_c, "_");
				// apilamos la posici?n del operador, para luego escribir a donde debe saltar por false
				comparador.numero_terceto = crearTerceto(&terceto_operador_logico);
				poner_en_pila(&comparaciones, &comparador);}
				{printf("Regla 29: decision es condicion OR condicion \n");}
	|NOT condicion		
			{	// es igual que la comparaci?n sin el NOT
				// pero llamando a "invertirOperadorLogico"
				// crear terceto con el "CMP"			
				crearTerceto(&terceto_cmp);
				// crear terceto del operador de la comparaci?n
				strcpy(terceto_operador_logico.posicion_a, invertirOperadorLogico(terceto_operador_logico.posicion_a));
				strcpy(terceto_operador_logico.posicion_b, "_"); 
				strcpy(terceto_operador_logico.posicion_c, "_");
				// apilamos la posici?n del operador, para luego escribir a donde debe saltar el terceto por false
				comparador.numero_terceto = crearTerceto(&terceto_operador_logico);
				poner_en_pila(&comparaciones, &comparador);}
				{printf("Regla 30: decision es NOT condicion \n");}
;

condicion:
	expresion { strcpy(terceto_cmp.posicion_b, normalizarPunteroTerceto(p_terceto_expresion));}
	
	OP_COMPARACION { 
				 if (strcmp(yytext,"==")==0){strcpy(terceto_operador_logico.posicion_a, "BNE");}
				 if (strcmp(yytext,"<")==0){strcpy(terceto_operador_logico.posicion_a, "BGE");}
				 if (strcmp(yytext,"<=")==0){strcpy(terceto_operador_logico.posicion_a, "BGT");}
				 if (strcmp(yytext,">")==0){strcpy(terceto_operador_logico.posicion_a, "BLE");}
				 if (strcmp(yytext,">=")==0){strcpy(terceto_operador_logico.posicion_a, "BLT");}
				 if (strcmp(yytext,"!=")==0){strcpy(terceto_operador_logico.posicion_a, "BEQ");}
				 strcpy(terceto_cmp.posicion_a, "FCOMP");
				}
	expresion	{strcpy(terceto_cmp.posicion_c, normalizarPunteroTerceto(p_terceto_expresion));
				// terceto del "CMP"
				}	
																			{printf("Regla 31: condicion es expresion OP_COMPARACION expresion \n");}
;

expresion:
	termino	{p_terceto_expresion = p_terceto_termino;}									{printf("Regla 32:expresion es termino\n");}
	
	|expresion 
	OP_SUMA 	{strcpy(terceto_expresion.posicion_a, yytext);}
	termino 	
	{strcpy(terceto_expresion.posicion_b, normalizarPunteroTerceto(p_terceto_expresion));
	strcpy(terceto_expresion.posicion_c, normalizarPunteroTerceto(p_terceto_termino));
	p_terceto_expresion = crearTerceto(&terceto_expresion);}					
																			{printf("Regla 33:expresion es expresion OP_SUMA termino\n");}
	
	|expresion {strcpy(terceto_expresion.posicion_b, normalizarPunteroTerceto(p_terceto_expresion));}
	OP_RESTA 	{strcpy(terceto_expresion.posicion_a, yytext);}
	termino 	{strcpy(terceto_expresion.posicion_c, normalizarPunteroTerceto(p_terceto_termino));
			p_terceto_expresion = crearTerceto(&terceto_expresion);}												
																			{printf("Regla 34:expresion es expresion OP_RESTA termino\n");}
;

termino: 
	factor 	{ p_terceto_termino = p_terceto_factor;}									{printf("Regla 35:termino es factor\n");}
	
	|termino 	{ strcpy(terceto_termino.posicion_b, normalizarPunteroTerceto(p_terceto_termino));}
	OP_MUL   	{ strcpy(terceto_termino.posicion_a, yytext);}
	factor 	{ strcpy(terceto_termino.posicion_c, normalizarPunteroTerceto(p_terceto_factor));
			  p_terceto_termino = crearTerceto(&terceto_termino); }						
	
																			{printf("Regla 36:termino es termino OP_MUL factor\n");}
	//aca se valida que una division no tenga denominador = 0????
	|termino { strcpy(terceto_termino.posicion_b, normalizarPunteroTerceto(p_terceto_termino));}
	
	OP_DIV   { strcpy(terceto_termino.posicion_a, yytext);}
	
	factor 	{ strcpy(terceto_termino.posicion_c, normalizarPunteroTerceto(p_terceto_factor));
			  p_terceto_termino = crearTerceto(&terceto_termino); }						
																			{printf("Regla 37:termino es termino OP_DIV factor\n");}

;

factor: //en la regla P_A expresion P_C resuelve mal la operacion aritmetica.
	ID {existeEnTablaSimbolo($1); strcpy(tiposComparados[cantComparaciones],tablaSimbolos[buscarEnTablaSimbolo($1)].tipo); cantComparaciones++;} 	{printf("Regla 38:factor es ID\n");}
		{	
			strcpy(terceto_factor.posicion_a, yytext);
			strcpy(terceto_factor.posicion_b, "_");
			strcpy(terceto_factor.posicion_c, "_");
			p_terceto_factor = crearTerceto(&terceto_factor);
		}
	| CONST_STRING {validarString(yylval.strVal); strcpy(tiposComparados[cantComparaciones], "String"); cantComparaciones++;}				{printf("Regla 39:factor es CONST_STRING\n");}
		{
			strcpy(terceto_factor.posicion_a, yytext);
			strcpy(terceto_factor.posicion_b, "_");
			strcpy(terceto_factor.posicion_c, "_");
			p_terceto_factor = crearTerceto(&terceto_factor);
		}
	| CONST_INT    {validarInt(atoi(yylval.strVal)); strcpy(tiposComparados[cantComparaciones], "Int"); cantComparaciones++;}		{printf("Regla 40:factor es CONST_INT\n");}
		{	
			strcpy(terceto_factor.posicion_a, yytext);
			strcpy(terceto_factor.posicion_b, "_");
			strcpy(terceto_factor.posicion_c, "_");
			p_terceto_factor = crearTerceto(&terceto_factor);
		}
	| CONST_FLOAT  {validarFloat(atof(yylval.strVal)); strcpy(tiposComparados[cantComparaciones], "Float"); cantComparaciones++;} 			{printf("Regla 41:factor es CONST_FLOAT\n");}
		{	
			strcpy(terceto_factor.posicion_a, yytext);
			strcpy(terceto_factor.posicion_b, "_");
			strcpy(terceto_factor.posicion_c, "_");
			p_terceto_factor = crearTerceto(&terceto_factor);
		}
	| P_A expresion P_C 		{printf("Regla 42:factor es P_A expresion P_C\n");}
		{
			p_terceto_factor = p_terceto_expresion;
		}
;


salida:
	DISPLAY CONST_STRING {validarString(yylval.strVal);}
	{printf("Regla 43:salida es DISPLAY CONST_STRING\n");}
	
	{
			strcpy(terceto_ent_sal.posicion_a, "DISPLAY");
			strcpy(terceto_ent_sal.posicion_b, yytext);
			strcpy(terceto_ent_sal.posicion_c, "_");
			crearTerceto(&terceto_ent_sal);
	}//
	|DISPLAY ID {existeEnTablaSimbolo($2);}				{printf("Regla 44:salida es DISPLAY ID\n");}
	{	
			strcpy(terceto_ent_sal.posicion_a, "DISPLAY");
			strcpy(terceto_ent_sal.posicion_b, yytext);
			strcpy(terceto_ent_sal.posicion_c, "_");
			crearTerceto(&terceto_ent_sal);
	}
;

entrada:
	GET ID {existeEnTablaSimbolo($2);}					{printf("Regla 45:entrada es GET ID\n");}
		{
			strcpy(terceto_ent_sal.posicion_a, "GET");
			strcpy(terceto_ent_sal.posicion_b, yytext);
			strcpy(terceto_ent_sal.posicion_c, "_");
			crearTerceto(&terceto_ent_sal);
		}
;

%%
int main(int argc,char *argv[]) //falta terminar  
{
	#ifdef YYDEBUG
        yydebug = 1;
    #endif
	if((yyin = fopen(argv[1], "rt")) == NULL){
		fprintf(stderr, "\nNo se puede abrir el archivo: %s\n", argv[1]);
		return 1;
  	}
  	else{
		clear_intermedia();
		crear_cola(&cola_terceto);
			crear_pila(&comparaciones);
			crear_pila(&comparaciones_or);
			crear_pila(&saltos_incondicionales);
			crear_pila(&ciclo_While);
		if( (tsout = fopen("ts.txt", "wt")) == NULL){
			fprintf(stderr,"\nERROR: No se puede abrir o crear el archivo: %s\n", "ts.txt");
			fclose(yyin);
			return 1;
		}

		fprintf(tsout, "NOMBRE                        |   TIPO    |                VALOR                | L |\n");
		fprintf(tsout, "-------------------------------------------------------------------------------------\n");

		yyparse();

		escribirTablaSimbolo();
		crear_intermedia(&cola_terceto);
	}

	fclose(yyin);
	fclose(tsout);
	return 0;
}

int yyerror(void)
{
  fflush(stdout);
  printf("Error de sintaxis\n\n");
  fclose(yyin);
  fclose(tsout);
  system ("Pause");
  exit (1);
}

//Funcion para validar ID 
int validarID(char *str){
	if(contvariableActual>=50){
		printf("\nNo puede declarar mas de 50 variables\n", str);
		yyerror();
	}
	
	int largo=strlen(str);
	if(largo > 20){
		printf("\nERROR: ID \"%s\" demasiado largo (<20)\n", str);
		yyerror();
	}
	
	// Compruebo que ID no exista ya en la tabla de simbolos
	if(buscarEnTablaSimbolo(str) != -1){
		printf("\nERROR: ID \"%s\" duplicado\n", str);
		yyerror();
	}
	guardarEnTablaSimbolo(1, str, str);
	return 1;
}

//Funcion para validar el rango de enteros 
int validarInt(int entero){
	char var[32];
	if(entero < 0 || entero >= 32767){
		printf("\nERROR: Entero fuera de rango (-32768; 32767)\n");
		yyerror();
	}

	sprintf(var, "%d",entero);

	if(buscarEnTablaSimbolo(var) == -1) {
		guardarEnTablaSimbolo(2, var, "");
	}

	return 1;
}


//Funcion para validar string 
int validarString(char *str){
	int a=0,i;
	char *aux = str;
  int largo = strlen(aux);
  char cadenaPura[30];

	if(largo > 30){
		printf("\nERROR: Cadena demasiado larga (<30)\n");
		yyerror();
	}
	
	for(i=1; i<largo-1;i++){
    cadenaPura[a]=str[i];
    a++;
  }

	cadenaPura[a--]='\0'; 

  if(buscarEnTablaSimbolo(cadenaPura) == -1) guardarEnTablaSimbolo(3, cadenaPura, "");

	return 1;
}


//Funcion para validar float 
int validarFloat(float nro){
	char var[32];
	double limiteMin=pow(-1.17549,-38);
	double limiteMax=pow(3.40282,38);
	if(nro < limiteMin || nro > limiteMax){
		printf("\nERROR: Float fuera de rango (-1.17549e-38; 3.40282e38) \n");
		yyerror();
	}

	sprintf(var, "%.2f",nro);

	if(buscarEnTablaSimbolo(var) == -1) guardarEnTablaSimbolo(4, var,"");

	return 1;
}

//Validar que los tipos de datos sean compatibles
void validarTipos(){
	int flgOK=1;
	int flgNumerico=0;
	int x;
	printf("\nComparacion\n");
	for(x=0;x<cantComparaciones;x++){
		printf("TIPO: %s\n",tiposComparados[x]);

		if(x==0){
			if(strcmpi(tiposComparados[x],"String")!=0)
				flgNumerico=1;
		}
		else{
			if((flgNumerico == 0 && (strcmpi(tiposComparados[x],"Int")==0 || strcmpi(tiposComparados[x],"Float")==0)) || (flgNumerico == 1 && strcmpi(tiposComparados[x],"String")==0)){
				//Si (no es numerico pero me vienen enteros o float) ó (si es numerico y me viene un string) = ERROR
				flgOK=0;
				break;
			}
		}
	}

	if(flgOK==1){
		printf("Comparacion OK\n");
	}
	else{
		printf("\nERROR: Tipos de dato incompatibles\n");
		yyerror();
	}
}

/* -- FUNCIONES TABLA DE SIMBOLOS -- */

//Funcion para guardar en la Tabla de Simbolos
int guardarEnTablaSimbolo(int num, char *str, char *valor ) {
	switch(num){
		case 1:  // ID
				strcpy(tablaSimbolos[posicionTabla].nombre,str);
				posicionTabla++;
				break;
				
		case 2: // INT
				strcpy(tablaSimbolos[posicionTabla].nombre,str);
				strcpy(tablaSimbolos[posicionTabla].valor,str);
				strcpy(tablaSimbolos[posicionTabla].tipo,"CteInt");
				posicionTabla++;
				break;
				
		case 3: // STRING
				strcpy(tablaSimbolos[posicionTabla].nombre,str);
				strcpy(tablaSimbolos[posicionTabla].valor,str);
				tablaSimbolos[posicionTabla].longitud=strlen(str);
				strcpy(tablaSimbolos[posicionTabla].tipo,"CteStr");
				posicionTabla++;
				break;
				
		case 4: // FLOAT
				strcpy(tablaSimbolos[posicionTabla].nombre,str);
				strcpy(tablaSimbolos[posicionTabla].valor,str);
				strcpy(tablaSimbolos[posicionTabla].tipo,"CteFloat");
				posicionTabla++;
				break;
		
		default:
				break;
	}
}

//Funcion para actualizar el tipo de una variable en la tabla de simbolos
void guardarTipo(){
    int pos=buscarEnTablaSimbolo(listaVariables[contvariableActual]);
    if(pos!=-1) strcpy(tablaSimbolos[pos].tipo,tipoActual); 
}

//Funcion para buscar la posicion de un simbolo en la tabla de simbolos
int buscarEnTablaSimbolo(char *id){
	int i;
	for(i=0; i<5000; i++){
		if(strcmpi(id,tablaSimbolos[i].nombre)==0)
			return i;
	}
	return -1;
}

//Funcion para comprobar que un simbolo existe en la tabla de simbolos
void existeEnTablaSimbolo(char *id){
	if(buscarEnTablaSimbolo(id)==-1){
		printf("\nERROR: ID \"%s\" no declarado\n", id);
		yyerror();
	}
}

//Funcion para crear la ts de simbolos en un archivo, en base a la Tabla declarada 
void escribirTablaSimbolo(){
	int i;
	for(i=0; i<posicionTabla; i++){
		if( strcmpi(tablaSimbolos[i].tipo,"") != 0 && 
			strcmpi(tablaSimbolos[i].tipo,"Cte") != 0 &&
			strcmpi(tablaSimbolos[i].tipo,"CteFloat") !=0 &&
			strcmpi(tablaSimbolos[i].tipo,"CteInt") != 0 && 
			strcmpi(tablaSimbolos[i].tipo,"CteStr")!= 0 ){  
			//si es ID
			fprintf(tsout, "%-30s|  %-7s  |                  -               	| - |\n", tablaSimbolos[i].nombre, tablaSimbolos[i].tipo);
		}else{ //Si es cte
			if(tablaSimbolos[i].longitud>0){
				fprintf(tsout, "_%-29s|           |              %-16s	|%03d|\n", tablaSimbolos[i].nombre, tablaSimbolos[i].valor, tablaSimbolos[i].longitud);
			}else{
				fprintf(tsout, "_%-29s|           |              %-16s	| - |\n", tablaSimbolos[i].nombre, tablaSimbolos[i].valor);
			}
		}
	}
}


/*desarrollo funciones tercetos*/
void crear_cola(cola_t *c) {
	c->pri=NULL;
	c->ult=NULL;
}

int poner_en_cola(cola_t *c, info_cola_t *d) {
	nodo_cola_t *nue=(nodo_cola_t*)malloc(sizeof(nodo_cola_t));

	if(nue==NULL)
		return SIN_MEMORIA;

	nue->info=*d;
	nue->sig=NULL;
	if(c->ult==NULL)
		c->pri=nue;
	else
		c->ult->sig=nue;

	c->ult=nue;

	return TODO_BIEN;
}

int sacar_de_cola(cola_t *c, info_cola_t *d) {
	nodo_cola_t *aux;

	if(c->pri==NULL)
		return COLA_VACIA;

	aux=c->pri;
	*d=aux->info;
	c->pri=aux->sig;
	free(aux);

	if(c->pri==NULL)
		c->ult=NULL;

	return TODO_BIEN;
}


void crear_pila(pila_t *p) {
	*p=NULL;
}

int poner_en_pila(pila_t *p, info_pila_t *d) {
	nodo_pila_t *nue=(nodo_pila_t*)malloc(sizeof(nodo_pila_t));

	if(nue==NULL)
		return SIN_MEMORIA;

	nue->info=*d;
	nue->sig=*p;
	*p=nue;

	return TODO_BIEN;
}


int sacar_de_pila(pila_t *p, info_pila_t *d) {
	nodo_pila_t *aux;

	if(*p==NULL)
		return PILA_VACIA;

	aux=*p;
	*d=aux->info;
	*p=aux->sig;
	free(aux);

	return TODO_BIEN;
}

int crearTerceto(info_cola_t *info_terceto) {
	poner_en_cola(&cola_terceto, info_terceto);
	return numero_terceto++;
}

void leerTerceto(int numero_terceto, info_cola_t *info_terceto_output) {
	int index = NUMERO_INICIAL_TERCETO;
	cola_t aux;
	info_cola_t info_aux;
	
	crear_cola(&aux);
	while(sacar_de_cola(&cola_terceto, &info_aux) != COLA_VACIA) {
		poner_en_cola(&aux, &info_aux);
		if(index == numero_terceto) {
			// encontramos el terceto buscado
			strcpy(info_terceto_output->posicion_a, info_aux.posicion_a);
			strcpy(info_terceto_output->posicion_b, info_aux.posicion_b);
			strcpy(info_terceto_output->posicion_c, info_aux.posicion_c);
		}
		index++;
	}
	while(sacar_de_cola(&aux, &info_aux) != COLA_VACIA) {
		poner_en_cola(&cola_terceto, &info_aux);
	}
}

void modificarTerceto(int numero_terceto, info_cola_t *info_terceto_input) {
	int index = NUMERO_INICIAL_TERCETO;
	cola_t aux;
	info_cola_t info_aux;
	
	crear_cola(&aux);
	while(sacar_de_cola(&cola_terceto, &info_aux) != COLA_VACIA) {
		if(index == numero_terceto) {
			poner_en_cola(&aux, info_terceto_input);
		} else {
			poner_en_cola(&aux, &info_aux);
		}
		index++;
	}
	while(sacar_de_cola(&aux, &info_aux) != COLA_VACIA) {
		poner_en_cola(&cola_terceto, &info_aux);
	}
}

char *normalizarPunteroTerceto(int terceto_puntero) {
	char_puntero_terceto[0] = '\0';
	sprintf(char_puntero_terceto, "[%d]", terceto_puntero);
	return char_puntero_terceto;
}

// limpiar una intermedia de una ejecuci?n anterior
void clear_intermedia() {
	FILE *arch=fopen("intermedia.txt","w");
	fclose(arch);
}

void crear_intermedia(cola_t *cola_intermedia) {
	
	FILE *arch=fopen("intermedia.txt","w");
	printf("\n");
	printf("creando intermedia...\n");
	guardar_intermedia(cola_intermedia, arch);
	fclose(arch);
	printf("intermedia creada\n");
}

void guardar_intermedia(cola_t *p, FILE *arch) {
	int numero = NUMERO_INICIAL_TERCETO;
	info_cola_t info_terceto;
	while(sacar_de_cola(&cola_terceto, &info_terceto) != COLA_VACIA) {
		
		if(strcmp(info_terceto.posicion_a, "THEN") == 0 || strcmp(info_terceto.posicion_a, "ELSE") == 0 ||
		 strcmp(info_terceto.posicion_a, "ENDIF") == 0 || strcmp(info_terceto.posicion_a, "REPEAT") == 0 ||
		  strcmp(info_terceto.posicion_a, "ENDREPEAT") == 0 || strcmp(info_terceto.posicion_a, "LISTA") == 0 ||
		   strcmp(info_terceto.posicion_a, "ENDINLIST") == 0 || strcmp(info_terceto.posicion_a, "ENDFILTER") == 0
		   || strcmp(info_terceto.posicion_a, "COMPARACION") == 0 || strcmp(info_terceto.posicion_a, "RETURN_TRUE") == 0) {

			printf("[%d](%s_%d,%s,%s)\n", numero,info_terceto.posicion_a, numero, info_terceto.posicion_b ,info_terceto.posicion_c);
			fprintf(arch,"[%d](%s_%d,%s,%s)\n", numero, info_terceto.posicion_a, numero, info_terceto.posicion_b ,info_terceto.posicion_c);
			numero++;
		}
		else {
			printf("[%d](%s,%s,%s)\n", numero,info_terceto.posicion_a ,info_terceto.posicion_b ,info_terceto.posicion_c);
			fprintf(arch,"[%d](%s,%s,%s)\n", numero++, info_terceto.posicion_a ,info_terceto.posicion_b ,info_terceto.posicion_c);
		}
	}
	cant_total_tercetos=numero;
}

char *invertirOperadorLogico(char *operador_logico) {
	if(strcmp(operador_logico, "BLT") == 0)  {
		return "BGE";
	}
	if(strcmp(operador_logico, "BLE") == 0)  {
		return "BGT";
	}
	if(strcmp(operador_logico, "BGT") == 0)  {
		return "BLE";
	}
	if(strcmp(operador_logico, "BGE") == 0)  {
		return "BLT";
	}
	if(strcmp(operador_logico, "BNE") == 0)  {
		return "BEQ";
	}
	if(strcmp(operador_logico, "BEQ") == 0)  {
		return "BNE";
	}
}

/*finaliza desarrollo funciones tercetos*/

