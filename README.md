<h1>Analizador Léxico</h1>
Este proyecto consiste en el desarrollo de un analizador léxico utilizando Flex/Lex, y lenguaje C, en el editor Visual Studio Code. Para crear el analizador, se utilizaron las siguientes estructuras y conceptos.

<h2>Conceptos utilizados</h2>
<ul>
    <li> Expresiones regulares, para identificar cada instrucción.
    <li> Listas de datos, para la tabla de tokens, cadenas, palabras reservadas, operadores, identificadores y valores.
    <li> Generación de archivos con el contenido de la tablas.
</ul>

El programa lee un archivo base, y por medio de Lex, se va identificando la instrucción, otorgando una posición dentro de la tabla que corresponda. 