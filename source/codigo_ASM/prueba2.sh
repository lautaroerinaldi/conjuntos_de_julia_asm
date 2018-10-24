set -x
# Casos de prueba de la sección 5.4 del enunciado del TP.
./tp1 -o uno.pgm

# Casos de prueba del apéndice A del enunciado del TP.
./tp1 -c 0.01+0i -r 1x1 -o -
./tp1 -c 10+0i -r 1x1 -o -
./tp1 -c 0+0i -r 0x1 -o -
./tp1 -o /tmp
./tp1 -c 1+3 -o -
./tp1 -c "" -o -
