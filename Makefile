CC = gcc
RM = rm
CP = cp
CD = cd
MKDIR = mkdir
PWD =



LIBSTROPHE = libstrophe/src
IFLAGS = -I${LIBSTROPHE}/.. -I/usr/local/include -I/usr/include
CFLAGS = -lssl -lxml2 -lresolv -Ilibstrophe

SRCS = auth.c conn.c ctx.c event.c handler.c hash.c jid.c md5.c \
		parser_libxml2.c \
		sasl.c sha1.c snprintf.c sock.c stanza.c thread.c tls_openssl.c util.c
OBJS = ${SRCS:.c=.o}
PROJ = xmppsh bot active basic roster

all: ${PROJ}


obj: ${OBJS}

bot: ${OBJS}
	${CC} ${CFLAGS} -o $@ ${LIBSTROPHE}/../examples/bot.c ${OBJS}

active: ${OBJS}
	${CC} ${CFLAGS} -o $@ ${LIBSTROPHE}/../examples/active.c ${OBJS}

basic: ${OBJS}
	${CC} ${CFLAGS} -o $@ ${LIBSTROPHE}/../examples/basic.c ${OBJS}

roster: ${OBJS}
	${CC} ${CFLAGS} -o $@ ${LIBSTROPHE}/../examples/roster.c ${OBJS}

xmppsh: ${OBJS}
	${CC} ${CFLAGS} -o $@ xmppsh.c ${OBJS}















auth.o:
	${CC} -c ${LIBSTROPHE}/auth.c ${IFLAGS}

conn.o:
	${CC} -c ${LIBSTROPHE}/conn.c ${IFLAGS}

ctx.o:
	${CC} -c ${LIBSTROPHE}/ctx.c ${IFLAGS}

event.o:
	${CC} -c ${LIBSTROPHE}/event.c ${IFLAGS}

handler.o:
	${CC} -c ${LIBSTROPHE}/handler.c ${IFLAGS}

hash.o:
	${CC} -c ${LIBSTROPHE}/hash.c ${IFLAGS}

jid.o:
	${CC} -c ${LIBSTROPHE}/jid.c ${IFLAGS}

md5.o:
	${CC} -c ${LIBSTROPHE}/md5.c ${IFLAGS}

parser_expat.o:
	${CC} -c ${LIBSTROPHE}/parser_expat.c ${IFLAGS}

parser_libxml2.o:
	${CC} -c ${LIBSTROPHE}/parser_libxml2.c ${IFLAGS} -I/usr/include/libxml2

sasl.o:
	${CC} -c ${LIBSTROPHE}/sasl.c ${IFLAGS}

sha1.o:
	${CC} -c ${LIBSTROPHE}/sha1.c ${IFLAGS}

snprintf.o:
	${CC} -c ${LIBSTROPHE}/snprintf.c ${IFLAGS}

sock.o:
	${CC} -c ${LIBSTROPHE}/sock.c -DBIND_8_COMPAT

stanza.o:
	${CC} -c ${LIBSTROPHE}/stanza.c ${IFLAGS}

thread.o:
	${CC} -c ${LIBSTROPHE}/thread.c ${IFLAGS}

tls_dummy.o:
	${CC} -c ${LIBSTROPHE}/tls_dummy.c ${IFLAGS}

tls_openssl.o:
	${CC} -c ${LIBSTROPHE}/tls_openssl.c ${IFLAGS}

util.o:
	${CC} -c ${LIBSTROPHE}/util.c ${IFLAGS}

clean:
	${RM} -f ${PROJ}

cleanall:
	${RM} -f ${OBJS} ${PROJ}

