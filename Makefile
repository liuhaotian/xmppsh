CC = gcc
RM = rm
CP = cp
CD = cd
MKDIR = mkdir
PWD =

IFLAGS =
LFLAGS =
CFLAGS =



LIBSTROPHE = libstrophe

#system flags
IFLAGS += -I/usr/local/include -I/usr/include
LFLAGS += -lssl -lxml2 -lresolv -lcrypto
CFLAGS += -O3

#strophe flags
IFLAGS += -I${LIBSTROPHE}/src -I${LIBSTROPHE}
LFLAGS +=
CFLAGS +=

#Mac flags
IFLAGS += -I/usr/include/libxml2
LFLAGS +=
CFLAGS += -DBIND_8_COMPAT -fno-stack-protector

#Linux flags
IFLAGS +=
LFLAGS +=
CFLAGS +=

#build flags
IFLAGS += -Ibuild/include -Ibuild/include/libxml2
LFLAGS += -Lbuild/lib
CFLAGS +=


SRCS = auth.c conn.c ctx.c event.c handler.c hash.c jid.c md5.c \
		parser_libxml2.c \
		sasl.c sha1.c snprintf.c sock.c stanza.c thread.c tls_openssl.c util.c
OBJS = ${SRCS:.c=.o}
PROJ = xmppsh bot active basic roster

all: ${PROJ}


obj: ${OBJS}

bot: ${OBJS}
	${CC} ${CFLAGS} ${IFLAGS} -o $@ ${LIBSTROPHE}/../examples/bot.c ${OBJS} ${LFLAGS}

active: ${OBJS}
	${CC} ${CFLAGS} ${IFLAGS} -o $@ ${LIBSTROPHE}/../examples/active.c ${OBJS} ${LFLAGS}

basic: ${OBJS}
	${CC} ${CFLAGS} ${IFLAGS} -o $@ ${LIBSTROPHE}/../examples/basic.c ${OBJS} ${LFLAGS}

roster: ${OBJS}
	${CC} ${CFLAGS} ${IFLAGS} -o $@ ${LIBSTROPHE}/../examples/roster.c ${OBJS} ${LFLAGS}

xmppsh: ${OBJS}
	${CC} ${CFLAGS} ${IFLAGS} -o $@ xmppsh.c ${OBJS} ${LFLAGS}















auth.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/auth.c

conn.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/conn.c

ctx.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/ctx.c

event.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/event.c

handler.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/handler.c

hash.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/hash.c

jid.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/jid.c

md5.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/md5.c

parser_expat.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/parser_expat.c

parser_libxml2.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/parser_libxml2.c

sasl.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/sasl.c

sha1.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/sha1.c

snprintf.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/snprintf.c

sock.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/sock.c

stanza.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/stanza.c

thread.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/thread.c

tls_dummy.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/tls_dummy.c

tls_openssl.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/tls_openssl.c

util.o:
	${CC} ${CFLAGS} ${IFLAGS} -c ${LIBSTROPHE}/src/util.c

clean:
	${RM} -f ${PROJ}

cleanall:
	${RM} -f ${OBJS} ${PROJ}

