%{
/*Basado en el valor del case se tendra que determinar cual es la clase
Tablas necesarias:
    -Tabla Tokens: clase-valor
    -Palabras reservadas: valor-palabra
    -Operadores: valor-operador
    -Tabla de identicadores: posicion-nombre-tipo(-1) 
    -Tabla de cadenas: posicion-cadena
    -Tabla de valores: posicion-valor --int or float

Errores:
    -Continuar la lectura con el siguiente elemento
    -Guardar los errores

Archivos:
    -Tablas de simbolos, cadenas, valores y tokens
    -Errores    
*/
#include "listaIdentificadores.h"
#include "listaReservadas.h"
#include "listaTokens.h"
#include "listaValores.h"
#include <sys/stat.h>
#include <sys/types.h>

%}

dig [0-9]
let [a-zA-Z]
digSinCero [1-9]

%%

"alternative"|"big"|"evaluate"|"instead"|"large"|"loop"|"make"|"number"|"other"|"real"|"repeat"|"select"|"small"|"step"|"stop"|"symbol"|"throw" {return 1;}
\${let}+ 				{return 2;}
{dig}+ 					{return 3;}
(digSinCero{dig}*)|"0"  {return 3;}
(o|O)[0-7]+ 			{return 3;}
{dig}*\.{dig}+			{return 4;}
[\[\](){},:;]           {return 6;}
[+\-*/%\\\^]            {return 7;}
"<"|">"|"<="|">="|"=="|"!=" {return 8;}
"=" {return 9;}
(\"[^'"]+\")|(\'[^'"]\')|(""'"")|(\'\"\')		{return 5;}
("//"(.)*)|("/*"[^*/]*"*/") {return 11;}
[^ \n\t] {return 10;}

%%

//La funcion convierte de octal a decimal, para poder guardar el valor del entero
long int obtenerDecimal(char yytext[]){
    int i;
    char octal[strlen(yytext)-1];
    for(i=0;i<strlen(yytext);i++){
        octal[i]=yytext[i+1];
    }

    int octalDecimal=atoi(octal);
    
    long int decimal=0;
    int base=1;
    int temp=octalDecimal;
    while(temp){
        int lastdigit=temp%10;
        temp=temp/10;
        decimal+=lastdigit*base;
        base=base*8;
    }
    return decimal;
}


//Mediante la funcion se llenan las tablas de palabras reservadas y de operadores.
void llenadoTablas(ListaReservadas* listaPalabras, ListaReservadas* listaOperadores){
    addFinalListaR(listaPalabras,0,"alternative");
    addFinalListaR(listaPalabras,1,"big");
    addFinalListaR(listaPalabras,2,"evaluate");
    addFinalListaR(listaPalabras,3,"instead");
    addFinalListaR(listaPalabras,4,"large");
    addFinalListaR(listaPalabras,5,"loop");
    addFinalListaR(listaPalabras,6,"make");
    addFinalListaR(listaPalabras,7,"number");
    addFinalListaR(listaPalabras,8,"other");
    addFinalListaR(listaPalabras,9,"real");
    addFinalListaR(listaPalabras,10,"repeat");
    addFinalListaR(listaPalabras,11,"select");
    addFinalListaR(listaPalabras,12,"small");
    addFinalListaR(listaPalabras,13,"step");
    addFinalListaR(listaPalabras,14,"stop");
    addFinalListaR(listaPalabras,15,"symbol");
    addFinalListaR(listaPalabras,16,"throw");

    addFinalListaR(listaOperadores,0,"<");
    addFinalListaR(listaOperadores,1,">");
    addFinalListaR(listaOperadores,2,"<=");
    addFinalListaR(listaOperadores,3,">=");
    addFinalListaR(listaOperadores,4,"==");
    addFinalListaR(listaOperadores,5,"!=");
}

//Con la funcion yywrap se detiene la lectura del documento
int yywrap(void) {
	return 1;
}

/*
Se realizar la funcion main para poder realizar la lectura del documento y la creacion de cada una de las
listas, para crearlas se importarn los headers donde esta la implementacion para cada una de las tablas necesarias.
*/
int main(int argc, char *argv[]){
	yyin = fopen(argv[1], "r");
	int opcion;
    ListaReservadas listaPalabras=crearListaR();
    ListaReservadas listaCadenas=crearListaR();
    ListaReservadas listaOperadores=crearListaR();
    ListaReservadas listaErrores=crearListaR();
    ListaTokens listaTokens=crearListaT();
    ListaValores listaConstantes=crearListaV();
    ListaIdentificadores listaIdentificadores =crearListaI();

    llenadoTablas(&listaPalabras,&listaOperadores);

    /*
    La funcion obtiene el token que se analizo con las expresiones, y en base a la clase realizar las operaciones
    que corresponden, siendo la clase 0 la 1, la 1 la 2, y asi sucesivamente.
    */
    int posicion,posicionCadena=0,posicionValor=0,errores=0,posicionIdent=0;
    char *token;
    while((opcion=yylex())!=0){
        switch(opcion){
            //Palabras reservadas
            case 1:
                posicion=BuscarElementoR(listaPalabras,yytext);
                addFinalListaT(&listaTokens,0,posicion);
            break;

            //identicadores
            case 2:
                token=malloc(strlen(yytext)+1);
                strcpy(token,yytext);
                posicion=BuscarElementoI(listaIdentificadores,yytext);
                if(posicion==-1){
                    addFinalListaI(&listaIdentificadores,posicionIdent,token);
                    addFinalListaT(&listaTokens,1,posicionIdent);
                    posicionIdent++;
                }else{
                    addFinalListaT(&listaTokens,1,posicion);
                }
            break;

            //Constantes numericas enteras y octales
            case 3:
                if(yytext[0]=='O' || yytext[0]=='o'){
                    long int decimal=obtenerDecimal(yytext);
                    addFinalListaT(&listaTokens,2,decimal);
                }else{
                    addFinalListaT(&listaTokens,2,atoi(yytext));
                }
            break;

            //Constantes numericas reales
            case 4:
                addFinalListaV(&listaConstantes,posicionValor,atof(yytext));
                addFinalListaT(&listaTokens,3,posicionValor);
                posicionValor++;
            break;

            //Cadenas
            case 5:
                token=malloc(strlen(yytext)+1);
                strcpy(token,yytext);
                addFinalListaR(&listaCadenas,posicionCadena,token);
                addFinalListaT(&listaTokens,4,posicionCadena);
                posicionCadena++;
            break;

            //Simbolos especiales
            case 6:
                addFinalListaT(&listaTokens,5,(int)*yytext);
            break;

            //Operadores aritmeticos
            case 7:
                addFinalListaT(&listaTokens,6,(int)*yytext);
            break;

            //Operadores relacionales
            case 8:
                posicion=BuscarElementoR(listaOperadores,yytext);
                addFinalListaT(&listaTokens,7,posicion);
            break;

            //Operador asignacion
            case 9:
                addFinalListaT(&listaTokens,8,(int)*yytext);
            break;

            //Errores
            case 10:
                token=malloc(strlen(yytext)+1);
                printf("%s ",token);
                strcpy(token,yytext);
                addFinalListaR(&listaErrores,errores,token);
                errores++;
            break;

            //Comentarios
            default:
            break;
        }
    }
    //Se imprimen cada una de las tablas en su correspondiente archivo y se crea un directorio para poder
    //visualizar con mayor facilidad cada una
    int result = mkdir("Tablas", 0777);
    print_listT(listaTokens);
    print_listER(listaErrores);
    print_listR(listaCadenas);
    print_listV(listaConstantes);
    print_listI(listaIdentificadores);
	return 0;
}
