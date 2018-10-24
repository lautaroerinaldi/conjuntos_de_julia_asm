#include <mips/regdef.h>
#include <sys/syscall.h>

#define STDERR 2
#define ERROR -1
#define EXITO 0

// BUF_SZ debe tener un valor multiplo de 8 (distinto de CERO).
#ifndef BUF_SZ
#define BUF_SZ 8192
#endif

	.abicalls
	
	# variable global final_buffer
	.local	final_buffer
	.comm	final_buffer,4,4
	
	.text						# inicia segmento de codigo.
	
#-----------------------------------------------------------------------------------------------------
#-----------------------------------IMPLEMENTO FUNCION print_digits-----------------------------------
#-----------------------------------------------------------------------------------------------------

	.align	2					# alineacion de la siguiente linea de codigo a 2 ^ 2 bytes.
	.ent	print_digits		# punto de entrada a la funcion print_digits.
	
print_digits:
	.frame	$fp,40,ra

	# bloque para codigo PIC
	.set	noreorder	# apaga reordenameinto de instrucciones.
	.cpload	t9			# directiva usada para codigo PIC.
	.set	reorder		# activa el reordenamiento de instrucciones.
	
	# creo stack frame de 40 bytes.
	subu	sp,sp,40
	
	# directiva para codigo PIC
	.cprestore 24		# inserta aqui "sw gp, 24(sp)",
						# mas "lw gp, 24(sp)" luego de cada jal.
	
	# salvo registros en SRA. Esta funcion es NON-LEAF.
	sw	ra,32(sp)		# salvo ra.
	sw	$fp,28(sp)		# salvo fp.
	sw s0, 36(sp)		# salvo s0
	
	# de aqui al fin de la funcion uso $fp en lugar de sp.
	move	$fp,sp
	
	# salvo argumentos en ABA de la funcion llamadora (caller).
	sw	a0,40($fp)		# salvo argumento int fd
	sw	a1,44($fp)		# salvo argumento char * buffer
	sw	a2,48($fp)		# salvo argumento size_t n
	
	
	lw	v0,48($fp)		# v0 = n
	sltu	v0,v0,10	# si n < 10 ==> v0 = 1, sino v0 = 0.
	bne	v0,zero,_n_menor_que_10		# si v0 != 0, significa que n < 10, y debo saltar al else_del_if.
	lw	a0,48($fp)		# a0 = n
	remu v0, a0, 10		# v0 = n % 10
	sw	v0,16($fp)		# r = n % 10
	lw	v1,48($fp)		# v1 = n
	divu v0, v1, 10		# v0 = n / 10
	sw	v0,48($fp)		# n = n / 10
	
	# preparo argumentos para invocar a la funcion print_digits.
	lw	a0,40($fp)		# a0 = fd
	lw	a1,44($fp)		# a1 = buffer
	lw	a2,48($fp)		# a2 = n
	
	# llamado recursivo a print_digits(fd, buffer, n).
	la	t9,print_digits
	jal	ra,t9
	
	lbu	v0,16($fp)			# v0 = r
	addu	v0,v0,48		# v0 = r + '0' (codigo ASCII = 48)
	sb	v0,20($fp)			# c = r + '0'
	lb	v0,20($fp)			# v0 = c
	
	# preparo argumentos para invocar a la funcion buffer_write_char.
	lw	a0,40($fp)			# a0 = fd
	lw	a1,44($fp)			# a1 = buffer
	move	a2,v0			# a2 = v0 = c
	
	# invoco a la funcion buffer_write_char (fd, buffer, c).
	la	t9,buffer_write_char
	jal	ra,t9
	
	bgez	v0,_exito_print_digits					# Si v0 >= 0, no hubo error en la escritura. Salto a retornar exito.
	
	# Sino, hubo error de escritura:
	li	s0,ERROR									# Valor de retorno ERROR.
	b	_restauro_stack_y_finalizo_print_digits		# Salto incondicional.

	# else_del_if
_n_menor_que_10:
	lbu	v0,48($fp)		# v0 = n
	addu	v0,v0,48	# v0 = n + '0' (codigo ASCII = 48)
	sb	v0,20($fp)		# c = n + '0'
	lb	v0,20($fp)		# v0 = c
	
	# preparo argumentos para invocar a la funcion buffer_write_char.
	lw	a0,40($fp)		# a0 = fd
	lw	a1,44($fp)		# a1 = buffer
	move	a2,v0		# a2 = v0 = c
	
	# invoco a la funcion buffer_write_char (fd, buffer, c).
	la	t9,buffer_write_char
	jal	ra,t9
	
	bgez	v0,_exito_print_digits					# Si v0 >= 0, no hubo error en la escritura. Salto a retornar exito.
	
	# Sino, hubo error de escritura:
	li	s0,ERROR									# Valor de retorno ERROR.
	b	_restauro_stack_y_finalizo_print_digits		# Salto incondicional.
	
_exito_print_digits:
	li	s0,EXITO									# Valor de retorno EXITO.

	
_restauro_stack_y_finalizo_print_digits:
	move	v0,s0				# Cargo el valor de retorno en v0.

	# empieza restauracion del stack.
	# recordar que el valor de retorno ya esta en v0.
	move	sp,$fp
	lw s0, 36(sp)		# restaura el valor original de s0.
	lw	ra,32(sp)			# restaura el valor original de ra.
	lw	$fp,28(sp)			# restaura el valor original de fp.
	addu	sp,sp,40		# achico el stack en 40 bytes.
	j	ra					# salto a la direccion de retorno.
	.end	print_digits	# indico que aca finaliza la funcion print_digits.
	.size	print_digits, .-print_digits
	
#-----------------------------------------------------------------------------------------------------
#-----------------------------------IMPLEMENTO FUNCION buffer_write_char------------------------------
#-----------------------------------------------------------------------------------------------------

	.align	2						# alineacion de la siguiente linea de codigo a 2 ^ 2 bytes.
	.ent	buffer_write_char		# punto de entrada a la funcion buffer_write_char.
	
buffer_write_char:
	.frame	$fp,40,ra
	
	# bloque para codigo PIC
	.set	noreorder	# apaga reordenameinto de instrucciones.
	.cpload	t9			# directiva usada para codigo PIC.
	.set	reorder		# activa el reordenamiento de instrucciones.
	
	# creo stack frame de 40 bytes.
	subu	sp,sp,40

	# directiva para codigo PIC.
	.cprestore 24		# inserta aqui "sw gp, 24(sp)",
						# mas "lw gp, 24(sp)" luego de cada jal.
	
	# salvo registros en SRA. Esta funcion es NON-LEAF.					
	sw	ra,32(sp)		# salvo ra.
	sw	$fp,28(sp)		# salvo fp.
	
	# de aqui al fin de la funcion uso $fp en lugar de sp.
	move	$fp,sp
	
	# salvo argumentos en ABA de la funcion llamadora (caller).
	sw	a0,40($fp)		# salvo argumento int fd
	sw	a1,44($fp)		# salvo argumento char * buffer
	move	v0,a2
	sb	v0,48($fp)		# salvo argumento char c
	
	# Aca inicia el codigo del cuerpo de la funcion:
	
	lw	v1,44($fp)			# v1 = fd
	lw	v0,final_buffer		# v0 = final_buffer
	addu	v1,v1,v0		# a v1 le asigno el indice de la proxima posicion para escribir en el buffer.
	lbu	v0,48($fp)			# v0 = c
	sb	v0,0(v1)			# guardo el caracter c al final de la cadena buffer.
	lw	v0,final_buffer		# v0 = final_buffer
	addu	v0,v0,1			# v0 = final_buffer + 1
	sw	v0,final_buffer		# final_buffer = final_buffer + 1
	lw	v1,final_buffer		# v1 = final_buffer
	li	v0,BUF_SZ			# v0 = BUF_SZ
	bne	v1,v0,_exito_buffer_write_char			# Si final_buffer != BUF_SZ ==> El caracter se escribio en el buffer y el buffer no esta lleno. Salto incondicional.
	
	# Sino, el buffer esta lleno y debo escribirlo.
	# preparo argumentos para invocar a la funcion buffer_flush.
	lw	a0,40($fp)			# a0 = fd
	lw	a1,44($fp)			# a1 = buffer
	
	# invoco a la funcion buffer_flush (fd, buffer).
	la	t9,buffer_flush
	jal	ra,t9
	
	bgez	v0,_exito_buffer_write_char		# Si v0 >= 0, no hubo error en la escritura. Salto a retornar exito.

	# Sino, hubo error en la escritura:
	li	v0,ERROR										# Valor de retorno ERROR.
	sw	v0,16($fp)										# Guardo el valor de retorno de la funcion en una variable temporal.
	b	_restauro_stack_y_finalizo_buffer_write_char	# Salto incondicional
	
_exito_buffer_write_char:
	li v0, EXITO			# Valor de retorno EXITO.
	sw	v0,16($fp)			# Guardo el valor de retorno de la funcion en una variable temporal.
	
_restauro_stack_y_finalizo_buffer_write_char:
	lw	v0,16($fp)			# Cargo el valor de retorno en v0.

	# empieza restauracion del stack.
	# recordar que el valor de retorno ya esta en v0.
	move	sp,$fp
	lw	ra,32(sp)					# restaura el valor original de ra.
	lw	$fp,28(sp)					# restaura el valor original de fp.
	addu	sp,sp,40				# achico el stack en 40 bytes.
	j	ra							# salto a la direccion de retorno.
	.end	buffer_write_char		# indico que aca finaliza la funcion buffer_write_char.
	.size	buffer_write_char, .-buffer_write_char
	
#-----------------------------------------------------------------------------------------------------
#-----------------------------------IMPLEMENTO FUNCION buffer_flush-----------------------------------
#-----------------------------------------------------------------------------------------------------

	.align	2				# alineacion de la siguiente linea de codigo a 2 ^ 2 bytes.
	.ent	buffer_flush	# punto de entrada a la funcion buffer_flush.
	
buffer_flush:
	.frame	$fp,32,ra
	
	# bloque para codigo PIC.
	.set	noreorder	# apaga reordenameinto de instrucciones.
	.cpload	t9			# directiva usada para codigo PIC.
	.set	reorder		# activa el reordenamiento de instrucciones.
	
	# creo stack frame de 32 bytes.
	subu	sp,sp,32

	# directiva para codigo PIC.
	.cprestore 16		# inserta aqui "sw gp, 16(sp)",
						# mas "lw gp, 16(sp)" luego de cada jal.
						
	# salvo registros en SRA. Esta funcion es NON-LEAF.	.
	sw	ra,24(sp)		# salvo ra.
	sw	$fp,20(sp)		# salvo fp.
	sw s0, 28(sp)	# salvo s0.
	
	# de aqui al fin de la funcion uso $fp en lugar de sp.
	move	$fp,sp

	# salvo argumentos en ABA de la funcion llamadora (caller).
	sw	a0,32($fp)		# salvo argumento int fd
	sw	a1,36($fp)		# salvo argumento char * buffer
	
	lw	v0,final_buffer				# v0 = final_buffer
	beq	v0,zero,_reiniciar_buffer	# si final_buffer == 0, el buffer está vacío y no hay nada que escribir. Puedo saltar al fin de la funcion.

	# Sino final_buffer > 0, es decir que hay datos que se pueden grabar:
	lw	a0,32($fp)			# a0 = fd
	lw	a1,36($fp)			# a1 = buffer
	lw	a2,final_buffer		# a2 = final_buffer
	
	# Escribo los datos que estan en el buffer invocando a un SYSCALL del sistema operativo.
	li	v0,SYS_write		# v0 = codigo de syscall encargada de realizar escrituras sobre archivos.
	syscall					# Se produce la escritura.
		
	bgez	v0,_reiniciar_buffer			# si v0 >= 0 ==> No hay error (res >=0) ==> Salgo de los ifs y salto a reiniciar_buffer.

	# Sino, hubo error en la escritura.
	li	s0,ERROR									# Valor de retorno ERROR.
	b	_restauro_stack_y_finalizo_buffer_flush		# Salto incondicional.
	
_reiniciar_buffer:
	sw	zero,final_buffer	# Como el buffer ya se escribio en el file descriptor, se debe empezar a escribir en el buffer desde el comienzo de nuevo (posicion 0).
	li s0, EXITO			# Valor de retorno EXITO.
	
_restauro_stack_y_finalizo_buffer_flush:
	move v0, s0				# Cargo el valor de retorno en v0.

	# empieza restauracion del stack.
	# recordar que el valor de retorno ya esta en v0.
	move	sp,$fp
	lw s0, 28(sp)			# restaura el valor original de s0.
	lw	ra,24(sp)				# restaura el valor original de ra.
	lw	$fp,20(sp)				# restaura el valor original de fp.
	addu	sp,sp,32			# achico el stack en 32 bytes.
	j	ra						# salto a la direccion de retorno.
	.end	buffer_flush		# indico que aca finaliza la funcion buffer_flush.
	.size	buffer_flush, .-buffer_flush
	
#-----------------------------------------------------------------------------------------------------
#-----------------------------------IMPLEMENTO FUNCION mips32_plot------------------------------------
#-----------------------------------------------------------------------------------------------------

#define GP_POS BUF_SZ + 72
#define FP_POS BUF_SZ + 76
#define RA_POS BUF_SZ + 80
#define S0_POS BUF_SZ + 84
#define PARMS_POS BUF_SZ + 88
#define STACK_SIZE BUF_SZ + 88


	.rdata			# Segmento de datos de solo lectura.
	
	.align	2		# alineacion de la siguiente linea de datos a 2 ^ 2 bytes.
_error_1:
	.ascii	"io error.\n\000"
	
	.align	2		# alineacion de la siguiente linea de datos a 2 ^ 2 bytes.
_error_2:
	.ascii	"i/o error.\n\000"
	
	.align	2		# alineacion de la siguiente linea de datos a 2 ^ 2 bytes.
_error_3:
	.ascii	"cannot flush output file.\n\000"
	
	.align	2		# alineacion de la siguiente linea de datos a 2 ^ 2 bytes.
_valor_4:
	.word	1082130432		# Valor numerico 4.0f
	
	
	.text					# inicia segmento de codigo.
	
	.align	2				# alineacion de la siguiente linea de codigo a 2 ^ 2 bytes.
	.globl	mips32_plot		# declara que la etiqueta mips32_plot es GLOBAL y puede ser usada desde otros archivos.
	.ent	mips32_plot		# punto de entrada a la funcion mips32_plot.
	
mips32_plot:
	.frame	$fp,STACK_SIZE,ra
	
	# bloque para codigo PIC.
	.set	noreorder	# apaga reordenameinto de instrucciones.
	.cpload	t9			# directiva usada para codigo PIC.
	.set	reorder		# activa el reordenamiento de instrucciones.
	
	# creo stack frame de STACK_SIZE bytes.
	subu	sp,sp,STACK_SIZE
	
	# directiva para codigo PIC.
	.cprestore GP_POS		# inserta aqui "sw gp, GP_POS(sp)",
						# mas "lw gp, GP_POS(sp)" luego de cada jal.
	
	# salvo registros en SRA. Esta funcion es NON-LEAF.
	sw	ra,RA_POS(sp)		# salvo ra
	sw	$fp,FP_POS(sp)	# salvo fp
	sw	gp,GP_POS(sp)		# salvo gp
	sw s0, S0_POS(sp)		# salvo s0
	
	# de aqui al fin de la funcion uso $fp en lugar de sp
	move	$fp,sp
	
	# salvo argumentos en ABA de la funcion llamadora (caller).
	sw	a0,PARMS_POS($fp)		# salvo argumento param_t * parms

	# Aca inicia el cuerpo de la funcion:
	
	lw	v0,PARMS_POS($fp)	# v0 = parms
	l.s	$f0,24(v0)		# $f0 = cp_re
	s.s	$f0,60($fp)		# cpr = cp_re
	lw	v0,PARMS_POS($fp)	# v0 = parms
	l.s	$f0,28(v0)		# $f0 = cp_im
	s.s	$f0,64($fp)		# cpi = cp_im
	lw	v0,PARMS_POS($fp)	# v0 = parms
	addu	v1,$fp,72	# v1 = buffer
	
	# preparo argumentos para invocar a la funcion buffer_write_char
	lw	a0,44(v0)			# a0 = fd
	move	a1,v1			# a1 = buffer
	li	a2,80				# a2 = 'P'
	
	# invoco a la funcion buffer_write_char (fd, buffer, 'P')
	la	t9,buffer_write_char
	jal	ra,t9
	
	sw	v0,16($fp)			# res = valor de retorno de la funcion buffer_write_char.
	lw	v0,PARMS_POS($fp)		# v0 = parms
	addu	v1,$fp,72		# v1 = buffer
	
	# preparo argumentos para invocar a la funcion buffer_write_char
	lw	 a0,44(v0)			# a0 = fd
	move a1,v1				# a1 = buffer
	li 	 a2,50				# a2 = '2'
	
	# invoco a la funcion buffer_write_char (fd, buffer, '2')
	la	t9,buffer_write_char
	jal	ra,t9
	
	sw	v0,16($fp)			# res = valor de retorno de la funcion buffer_write_char.
	lw	v0,PARMS_POS($fp)		# v0 = parms
	addu	v1,$fp,72		# v1 = buffer
	
	# preparo argumentos para invocar a la funcion buffer_write_char.
	lw	a0,44(v0)			# a0 = fd
	move	a1,v1			# a1 = buffer
	li	a2,10				# a2 = '\n'
	
	# invoco a la funcion buffer_write_char (fd, buffer, '\n')
	la	t9,buffer_write_char
	jal	ra,t9
	
	sw	v0,16($fp)			# res = valor de retorno de la funcion buffer_write_char.
	lw	v0,PARMS_POS($fp)		# v0 = parms
	addu	v1,$fp,72		# v1 = buffer
	lw	a2,PARMS_POS($fp)		# a2 = parms
	
	# preparo argumentos para invocar a la funcion print_digits.
	lw	a0,44(v0)			# a0 = fd
	move	a1,v1			# a1 = buffer
	lw	a2,32(a2)			# a2 = x_res
	
	# invoco a la funcion print_digits(fd, buffer, x_res).
	la	t9,print_digits
	jal	ra,t9
	
	lw	v0,PARMS_POS($fp)		# v0 = parms
	addu	v1,$fp,72		# v1 = buffer
	
	# preparo argumentos para invocar a la funcion buffer_write_char.
	lw	a0,44(v0)			# a0 = fd
	move	a1,v1			# a1 = buffer
	li	a2,10				# a2 = '\n'
	
	# invoco a la funcion buffer_write_char (fd, buffer, '\n').
	la	t9,buffer_write_char
	jal	ra,t9
	
	sw	v0,16($fp)			# res = valor de retorno de la funcion buffer_write_char.
	lw	v0,PARMS_POS($fp)		# v0 = parms
	addu	v1,$fp,72		# v1 = buffer
	lw	a2,PARMS_POS($fp)		# a2 = parms
	
	# preparo argumentos para invocar a la funcion print_digits.
	lw	a0,44(v0)			# a0 = fd
	move	a1,v1			# a1 = buffer
	lw	a2,36(a2)			# a2 = y_res
	
	# invoco a la funcion print_digits(fd, buffer, y_res).
	la	t9,print_digits
	jal	ra,t9
	
	lw	v0,PARMS_POS($fp)		# v0 = parms
	addu	v1,$fp,72		# v1 = buffer
	
	# preparo argumentos para invocar a la funcion buffer_write_char.
	lw	a0,44(v0)			# a0 = fd
	move	a1,v1			# a1 = buffer
	li	a2,10				# a2 = '\n'
	
	# invoco a la funcion buffer_write_char (fd, buffer, '\n').
	la	t9,buffer_write_char
	jal	ra,t9
	
	sw	v0,16($fp)			# res = valor de retorno de la funcion buffer_write_char.
	lw	v0,PARMS_POS($fp)		# v0 = parms
	addu	v1,$fp,72		# v1 = buffer
	lw	a2,PARMS_POS($fp)		# a2 = parms
	
	# preparo argumentos para invocar a la funcion print_digits.
	lw	a0,44(v0)			# a0 = fd
	move	a1,v1			# a1 = buffer
	lw	a2,40(a2)			# a2 = shades
	
	# invoco a la funcion print_digits(fd, buffer, shades).
	la	t9,print_digits
	jal	ra,t9
	
	lw	v0,PARMS_POS($fp)		# v0 = parms
	addu	v1,$fp,72		# v1 = buffer
	
	# preparo argumentos para invocar a la funcion buffer_write_char.
	lw	a0,44(v0)			# a0 = fd
	move	a1,v1			# a1 = buffer
	li	a2,10				# a2 = '\n'
	
	# invoco a la funcion buffer_write_char (fd, buffer, '\n').
	la	t9,buffer_write_char
	jal	ra,t9
	
	sw	v0,16($fp)				# res = valor de retorno de la funcion buffer_write_char.
	lw	v0,16($fp)				# v0 = res
	bgez	v0,_bucle_for_y		# si v0 >= 0 ==> No hay error (res >=0) ==> Voy al bucle de y.

	# Sino hubo error, res <= 0. Muestro mensaje de error:
	li	a0,STDERR				# a0 = STDERR
	la	a1,_error_1				# a1 tiene un mensaje de error.
	li	a2,10					# a2 tiene la cantidad de caracteres del mensaje de error (10).

	li	v0,SYS_write			# v0 = codigo de syscall encargada de realizar escrituras sobre archivos.			
	syscall						# Se produce la escritura.
	# Aca no importa el codigo de retorno del SYSCALL, ya que es una escritura en STDERR. De todas formas se debe abortar el programa por un error anterior.
	
	sw	v0,16($fp)				# res = valor de retorno de la funcion buffer_write_char.
	li	s0,ERROR					# Valor de retorno ERROR.
	b	_restauro_stack_y_finalizo_mips32_plot		# Salto incondicional.

_bucle_for_y:
	sw	zero,52($fp)		# y = 0
	lw	v0,PARMS_POS($fp)		# v0 = parms
	l.s	$f0,4(v0)			# $f0 = UL_im
	s.s	$f0,24($fp)			# ci = UL_IM

_evaluar_condicion_for_y:
	lw	v0,PARMS_POS($fp)		# v0 = parms
	lw	v1,52($fp)			# v1 = y
	lw	v0,36(v0)			# v0 = y_res
	sltu	v0,v1,v0					# Si y < y_res ==> v0 = 1, sino v0 = 0.
	bne	v0,zero,_bucle_for_x			# Si v0 != 0 (es decir, y < y_res) cumple la condicion y voy al bucle_for_x.
	b	_flushear_datos_pendientes		# Sino salgo del for_y y voy a flushar los datos que quedaron en el buffer.

_bucle_for_x:
	sw	zero,48($fp)		# x = 0
	lw	v0,PARMS_POS($fp)		# v0 = parms
	l.s	$f0,0(v0)			# $f0 = UL_re
	s.s	$f0,20($fp)			# cr = UL_re

_evaluar_condicion_for_x:
	lw	v0,PARMS_POS($fp)		# v0 = parms
	lw	v1,48($fp)			# v1 = x
	lw	v0,32(v0)			# v0 = x_res
	sltu	v0,v1,v0				# Si x < x_res ==> v0 = 1, sino v0 = 0.
	bne	v0,zero,_ingreso_for_x		# Si v0 != 0 (es decir, x < x_res) cumple la condicion y voy al cuerpo del bucle_for_x.
	b	_incremento_for_y			# Sino salgo del for_x y vuelvo a incrementar la condicion del for_y.
	
_ingreso_for_x:
	l.s	$f0,20($fp)			# $f0 = cr
	s.s	$f0,28($fp)			# zr = cr
	l.s	$f0,24($fp)			# zr = cr
	s.s	$f0,32($fp)			# zi = ci

	# preparo variable de iteracion del bucle for_c
	sw	zero,56($fp)		# c = 0
	
_bucle_for_c:
	lw	v0,PARMS_POS($fp)		# v0 = parms
	lw	v1,56($fp)			# v1 = c
	lw	v0,40(v0)			# v0 = shades
	sltu	v0,v1,v0							# Si c < shades ==> v0 = 1, sino v0 = 0.
	bne	v0,zero,_calculo_de_nuevos_zr_y_zi		# Si v0 != 0 (es decir, c < shades) cumple la condicion y voy al cuerpo del bucle_for_c.
	b	_escribir_caracter						# Sino salgo del for_c porque ya tengo el valor deseado que debo escribir en el buffer y salto incondicional.
	
_calculo_de_nuevos_zr_y_zi:

	# calculo de absz
	l.s	$f2,28($fp)			# $f2 = zr
	l.s	$f0,28($fp)			# $f0 = zr
	mul.s	$f4,$f2,$f0			# f4 = zr * zr
	l.s	$f2,32($fp)			# $f2 = zi
	l.s	$f0,32($fp)			# $f0 = zi
	mul.s	$f0,$f2,$f0			# $f0 = zi * zi
	add.s	$f0,$f4,$f0		# $f0 = zr * zr + zi * zi
	mov.s	$f2,$f0					# $f2 = zr * zr + zi * zi
	s.s	$f2,44($fp)				# absz = zr * zr + zi * zi
	
	# comparacion de absz dentro del _if
	l.s	$f0,_valor_4				# $f0 = 4.0f
	c.lt.s	$f0,$f2					# ¿$f0 < $f2? equivale a preguntar ¿4.0f < absz?
	bc1t	_escribir_caracter		# Si 4.0f < absz, interrumpo el for_c y voy a escribir el dato en el buffer
	
	# calculo sr
	l.s	$f2,28($fp)			# $f2 = zr
	l.s	$f0,28($fp)			# $f0 = zr
	mul.s	$f4,$f2,$f0		# f4 = zr * zr
	l.s	$f2,32($fp)			# $f2 = zi
	l.s	$f0,32($fp)			# $f2 = zi
	mul.s	$f0,$f2,$f0		# $f0 = zi * zi
	sub.s	$f2,$f4,$f0		# $f2 = zr * zr - zi * zi
	l.s	$f0,60($fp)			# $f0 = cpr
	add.s	$f0,$f2,$f0		# $f0 = zr * zr - zi * zi + cpr
	s.s	$f0,36($fp)			# sr = zr * zr - zi * zi + cpr
	
	# calculo si
	l.s	$f0,28($fp)			# $f0 = zr
	add.s	$f2,$f0,$f0		# $f2 = zr + zr = 2 * zr
	l.s	$f0,32($fp)			# $f0 = zi
	mul.s	$f2,$f2,$f0		# $f2 = 2 * zr * zi
	l.s	$f0,64($fp)			# $f0 = cpi
	add.s	$f0,$f2,$f0		# $f0 = 2 * zr * zi + cpi
	s.s	$f0,40($fp)			# si = 2 * zr * zi + cpi
	
	# Asignaciones zr = sr y zi = si
	l.s	$f0,36($fp)			# $f0 = sr
	s.s	$f0,28($fp)			# zr = sr
	l.s	$f0,40($fp)			# $f0 = si
	s.s	$f0,32($fp)			# zi = si
	
	# incremento c del bucle
	lw	v0,56($fp)			# v0 = c
	addu	v0,v0,1			# v0 = c + 1
	sw	v0,56($fp)			# c = v0 = c + 1
	b	_bucle_for_c		# Loop al bucle for_c. Salto incondicional.
	
_escribir_caracter:
	lw	v0,PARMS_POS($fp)		# v0 = parms
	addu	v1,$fp,72		# v1 = buffer
	
	# preparo argumentos para invocar a la funcion print_digits.
	lw	a0,44(v0)			# a0 = fd
	move	a1,v1			# a1 = buffer
	lw	a2,56($fp)			# a2 = c
	
	# invoco a la funcion print_digits(fd, buffer, c)
	la	t9,print_digits
	jal	ra,t9
	
	bgez	v0,_caracter_escrito_ok			# si v0 >= 0 ==> La funcion no retorno error ==> Voy a escribir '\n' en buffer (entro al_else porque el caracter se escribio correctamente)

	# Sino, hubo error en la escritura del caracter:
	li	a0,STDERR			# a0 = STDERR
	la	a1,_error_2			# a1 tiene un mensaje de error.
	li	a2,11				# a2 tiene la cantidad de caracteres del mensaje de error (11).
	
	li	v0,SYS_write								# v0 = codigo de syscall encargada de realizar escrituras sobre archivos .				
	syscall											# Se produce la escritura.
	# Aca no importa el codigo de retorno del SYSCALL, ya que es una escritura en STDERR. De todas formas se debe abortar el programa por un error anterior.
	
	sw	v0,16($fp)			# res = valor de retorno de la funcion print_digits.
	li	s0,ERROR					# Valor de retorno ERROR.
	b	_restauro_stack_y_finalizo_mips32_plot		# Salto incondicional.
	
_caracter_escrito_ok:
	lw	v0,PARMS_POS($fp)		# v0 = parms
	addu	v1,$fp,72		# v1 = buffer
	
	# preparo argumentos para invocar a la funcion buffer_write_char.
	lw	a0,44(v0)			# a0 = fd
	move	a1,v1			# a1 = buffer
	li	a2,10				# a2 = '\n'
	
	# invoco a la funcion buffer_write_char (fd, buffer, '\n')
	la	t9,buffer_write_char
	jal	ra,t9
	
	sw	v0,16($fp)					# res = valor de retorno de la funcion buffer_write_char.
	lw	v0,16($fp)					# v0 = res.
	bgez	v0,_incremento_for_x	# si v0 >= 0 ==> La funcion no retorno error ==> Voy a incrementar la variable de iteracion x.
	
	# Sino hubo error y muestro mensaje:
	li	s0,ERROR					# Valor de retorno ERROR.
	b	_restauro_stack_y_finalizo_mips32_plot	# Salto incondicional.

	# Estoy en el incremento del for x (++x) y tambien la variable cr (cr += parms->d_re).
_incremento_for_x:
	lw	v0,48($fp)			# v0 = x
	addu	v0,v0,1			# v0 = x + 1
	sw	v0,48($fp)			# x = x + 1
	lw	v0,PARMS_POS($fp)		# v0 = parms
	l.s	$f2,20($fp)			# $f2 = cr
	l.s	$f0,16(v0)			# $f0 = d_re
	add.s	$f0,$f2,$f0		# $f0 = cr + d_re
	s.s	$f0,20($fp)			# cr = cr + d_re
	b	_evaluar_condicion_for_x	# Vuelvo a evaluar la condicion del for x.

	# Incremento de la variable y del for (++y) y decremento la variable ci (ci -= parms->d_im).
_incremento_for_y:
	lw	v0,52($fp)			# v0 = y
	addu	v0,v0,1			# v0 = y + 1
	sw	v0,52($fp)			# y = y + 1
	lw	v0,PARMS_POS($fp)		# v0 = parms
	l.s	$f2,24($fp)			# $f2 = ci
	l.s	$f0,20(v0)			# $f0 = d_im
	sub.s	$f0,$f2,$f0		# $f0 = ci - d_im
	s.s	$f0,24($fp)			# ci = ci - d_im
	b	_evaluar_condicion_for_y	# Vuelvo a evaluar la condicion del for y.
	
_flushear_datos_pendientes:
	lw	v0,PARMS_POS($fp)		# v0 = parms
	addu	v1,$fp,72		# v1 = buffer
	
	# preparo argumentos para invocar a la funcion buffer_flush.
	lw	a0,44(v0)			# a0 = fd
	move	a1,v1			# a1 = buffer
	
	# invoco a la funcion buffer_flush.
	la	t9,buffer_flush
	jal	ra,t9
	
	bgez	v0,_verifico_escritura_en_stderr_sin_error		# si v0 >= 0 ==> No hay error ==> Voy a verificar escritura en stderr

	# Sino, hubo error, muestro mensaje de error:
	li	a0,STDERR			# a0 = STDERR
	la	a1,_error_3			# a1 tiene un mensaje de error.
	li	a2,26				# a2 tiene la cantidad de caracteres del mensaje de error (26).
	
	li	v0,SYS_write								# v0 = codigo de syscall encargada de realizar escrituras sobre archivos.			
	syscall											# Se produce la escritura.
	# Aca no importa el codigo de retorno del SYSCALL, ya que es una escritura en STDERR. De todas formas se debe abortar el programa por un error anterior.
	
	sw	v0,16($fp)			# res = valor de retorno de la funcion buffer_flush.
	li	s0,ERROR					# Valor de retorno ERROR.
	b	_restauro_stack_y_finalizo_mips32_plot		# Salto incondicional.
	
_verifico_escritura_en_stderr_sin_error:
	lw	v0,16($fp)					# v0 = res
	bgez	v0,_exito_mips32_plot	# si v0 >= 0 ==> No hay error ==> Voy a retornar y finalizar la función.
	
	# Sino, hubo error en la escritura en STDERR:
	li	s0,ERROR					# Valor de retorno ERROR.
	b	_restauro_stack_y_finalizo_mips32_plot		# Salto incondicional.
	
_exito_mips32_plot:
	li s0, EXITO				# Valor de retorno EXITO.
	
_restauro_stack_y_finalizo_mips32_plot:
	# Cargo el valor de retorno de la funcion en v0.
	move v0, s0

	# empieza restauracion del stack.
	# recordar que el valor de retorno ya esta en v0.
	move	sp,$fp
	lw s0, S0_POS(sp)				# restaura el valor original de s0.
	lw	ra,RA_POS(sp)					# restaura el valor original de ra.
	lw	$fp,FP_POS(sp)				# restaura el valor original de fp.
	
	addu	sp,sp,STACK_SIZE		# achico el stack en STACK_SIZE bytes.
	j	ra							# salto a la direccion de retorno.
	
	.end	mips32_plot				# indico que aca finaliza la funcion mips32_plot.	
	.size	mips32_plot, .-mips32_plot
