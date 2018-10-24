set -x
# Casos de prueba espaciales (o puntos cardinales)
./tp1 -o centro.pgm
./tp1 -c 0+1i -o abajo.pgm
./tp1 -c 0-1i -o arriba.pgm
./tp1 -c 1+0i -o izquierda.pgm
./tp1 -c -1+0i -o derecha.pgm
./tp1 -c 1-1i -o arriba_izquierda.pgm
./tp1 -c -1-1i -o arriba_derecha.pgm
./tp1 -c -1+1i -o abajo_derecha.pgm
./tp1 -c 1+1i -o abajo_izquierda.pgm

# Casos de prueba extraidos de Wikipedia: https://en.wikipedia.org/wiki/Julia_set
./tp1 -C -0.4+0.6i -o wiki_02.pgm
./tp1 -C 0.285+0i -o wiki_03.pgm
./tp1 -C 0.285+0.01i -o wiki_04.pgm
./tp1 -C 0.45+0.1428i -o wiki_05.pgm
./tp1 -C -0.70176-0.3842i -o wiki_06.pgm
./tp1 -C -0.835-0.2321i -o wiki_07.pgm
./tp1 -C -0.8+0.156i -o wiki_08.pgm
./tp1 -C -0.7269+0.1889i -o wiki_09.pgm
