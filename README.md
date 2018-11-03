# Dibujado de conjuntos de Julia y vecindades, con cómputo de fractales en ASM.

## Objetivo del trabajo

Se trata de implementar un programa que dibuje el conjunto de Julia y sus vecindades introducido, en el cual la lógica de cómputo del fractal deberá tener soporte nativo para MIPS32 sobre NetBSD/pmax.

## Motivación

El presente proyecto fue elaborado como trabajo práctico académico para la materia Organización de Computadoras de la Facultad de Ingeniería de la Universidad de Buenos Aires. El mismo, se desarrolló durante el segundo cuatrimestre del año 2016.

## Compilación:

Desde la consola de linux, una vez dentro de la carpeta **source** y una vez elegida una de las versiones, ejecutar las siguientes instrucciones:
**
```
make makefiles
make
```
**
### Observación:
Es importante destacar que el código que se encuentra dentro de la carpeta **codigo_ASM** solo funcionará si se compila y ejecuta sobre NetBSD corriendo sobre una arquitectura Mips32.
Una buena forma de emular dicha arquitectura, es utilizando GXemul.

## Autor
   - Lautaro Ezequiel Rinaldi.
