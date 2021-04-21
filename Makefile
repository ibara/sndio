# sndio Makefile

LIB =	libsndio-d.a
OBJS =	deimos/sndio.o

PROG =		sndio-example
EXAMPLE =	example.o

DFLAGS =	-O2 -pipe -frelease -finline

all: ${OBJS}
	${AR} cru ${LIB} ${OBJS}
	ranlib ${LIB}

test: ${EXAMPLE}
	${DC} ${LDFLAGS} -o ${PROG} ${EXAMPLE} -L . -lsndio-d -lsndio

clean:
	rm -f ${LIB} ${OBJS} ${PROG} ${EXAMPLE}
