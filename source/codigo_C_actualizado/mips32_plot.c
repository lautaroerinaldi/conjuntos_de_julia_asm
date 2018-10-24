#include <debug.h>
#include <stdio.h>
#include <defs.h>
#include <param.h>
#include <unistd.h>

#define STDERR 2
#define ERROR -1
#define EXITO 0

// BUF_SZ debe tener un valor multiplo de 8 (distinto de CERO).
#ifndef BUF_SZ
#define BUF_SZ 8192
#endif

// final_buffer indica el ultimo dato valido del buffer
static unsigned long int final_buffer = 0;

/**
* Declaraciones de funciones anticipadas
**/
int buffer_write_char(int fd, char * buffer, char c);

int buffer_flush(int fd, char * buffer);

/**
* Escribe en un buffer el numero entero pasado por parametro, 
* digito a digito (en forma de chars).
**/
int print_digits(int fd, char * buffer, size_t n) {
	// n := numero
	// r := resto
	// c := caracter
	size_t r;
	char c;

	if (n >= 10) {
		r = n % 10;
		n = n / 10;
		print_digits(fd, buffer, n);
		c = r + '0';
		if (buffer_write_char(fd, buffer, c) < 0)
			return ERROR;
	} else {
		c = n + '0';
		if (buffer_write_char(fd, buffer, c) < 0)
			return ERROR;
	}
	return EXITO;
}

/**
* Escribe en el buffer el caracter pasado por parámetro.
* Si el buffer se llena, invoca a buffer_flush que escribe todo el
* contenido del buffer en el fd pasado por parametro.
* Retorna EXITO si no hubo inconvenientos, y ERROR si no pudo escribir
* el buffer en el fd pasado.
**/
int buffer_write_char(int fd, char * buffer, char c) {
	buffer[final_buffer] = c;
	final_buffer += 1;
	if (final_buffer == BUF_SZ)
		if (buffer_flush(fd, buffer) < 0)
			return ERROR;

	return EXITO;
}

/**
* Vuelca la informacion escrita en el buffer en el archivo
* que se corresponde con el file_descriptor pasado por
* parametro. El archivo debe estar previamente abierto.
* Si se pudo escribir sin problemas, setea final_buffer en 0
* (es decir, el ultimo dato valido del buffer) y retorna EXITO.
* En caso de falla, retorna ERROR.
**/
int buffer_flush(int fd, char * buffer) {
	if (final_buffer > 0)
		if (write(fd, buffer, final_buffer) < 0)
			return ERROR;

	final_buffer = 0;
	return EXITO;
}

/**
* Genera el conjunto de Julia y lo escribe en una archivo.
**/
int mips32_plot(param_t *parms) {
	int res;
	float cr, ci;
	float zr, zi;
	float sr, si;
	float absz;
	int x, y;
	int c;

	float cpr = parms->cp_re;
	float cpi = parms->cp_im;

	char buffer[BUF_SZ];

	/* Header PGM. */

	res = buffer_write_char(parms->fd, buffer, 'P');
	res = buffer_write_char(parms->fd, buffer, '2');
	res = buffer_write_char(parms->fd, buffer, '\n');
	print_digits(parms->fd, buffer, (unsigned) parms->x_res);

	res = buffer_write_char(parms->fd, buffer, '\n');
	print_digits(parms->fd, buffer, (unsigned) parms->y_res);

	res = buffer_write_char(parms->fd, buffer, '\n');
	print_digits(parms->fd, buffer, (unsigned) parms->shades);

	res = buffer_write_char(parms->fd, buffer, '\n');

	if (res < 0) {
		res = write(STDERR, "io error.\n", 10);
		return ERROR;
	}

	/* 
	 * Barremos la regi�n rectangular del plano complejo comprendida 
	 * entre (parms->UL_re, parms->UL_im) y (parms->LR_re, parms->LR_im).
	 * El par�metro de iteraci�n es el punto (cr, ci).
	 */

	for (y = 0, ci = parms->UL_im; y < parms->y_res; ++y, ci -= parms->d_im) {
		for (x = 0, cr = parms->UL_re; x < parms->x_res;
				++x, cr += parms->d_re) {
			zr = cr;
			zi = ci;

			/*
			 * Determinamos el nivel de brillo asociado al punto
			 * (cr, ci), usando la f�rmula compleja recurrente 
			 * f = f^2 + c.
			 */

			for (c = 0; c < parms->shades; ++c) {
				if ((absz = zr * zr + zi * zi) > 4.0f)
					break;
				sr = zr * zr - zi * zi + cpr;
				si = 2 * zr * zi + cpi;
				zr = sr;
				zi = si;
			}

			if (print_digits(parms->fd, buffer, (int) c) < 0) {
				res = write(STDERR, "i/o error.\n", 11);
				return ERROR;
			} else {
				res = buffer_write_char(parms->fd, buffer, '\n');
				if (res < 0)
					return ERROR;
			}
		}
	}

	/* Flushea (escribe en el archivo) toda la informacion valida que quedo en el buffer antes de salir. */
	if (buffer_flush(parms->fd, buffer) < 0) {
		res = write(STDERR, "cannot flush output file.\n", 26);
		return ERROR;
	}
	
	// La siguiente linea esta para evitar el Warning del Compilador
	// Es por si falla escribir en STDERR
	if (res < 0)
		return ERROR;

	return EXITO;
}
