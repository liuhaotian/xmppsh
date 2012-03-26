/* bot.c
** libstrophe XMPP client library -- basic usage example
**
** Copyright (C) 2005-2009 Collecta, Inc. 
**
**  This software is provided AS-IS with no warranty, either express
**  or implied.
**
**  This software is distributed under license and may not be copied,
**  modified or distributed except as expressly authorized under the
**  terms of the license contained in the file LICENSE.txt in this
**  distribution.
*/

/* simple bot example
**  
** This example was provided by Matthew Wild <mwild1@gmail.com>.
**
** This bot responds to basic messages and iq version requests.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <signal.h>


#include <strophe.h>
#include <src/common.h>

int RedirStatus = 0;
int pipeo2i[2];
int pipei2o[2];
int standardout;
int standardin;
char master[40];
pid_t pid;

#define BUFFSIZE 20480
#define DEBUGMOD 0


int version_handler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza, void * const userdata)
{
	xmpp_stanza_t *reply, *query, *name, *version, *text;
	char *ns;
	xmpp_ctx_t *ctx = (xmpp_ctx_t*)userdata;
	printf("Received version request from %s\n", xmpp_stanza_get_attribute(stanza, "from"));
	
	reply = xmpp_stanza_new(ctx);
	xmpp_stanza_set_name(reply, "iq");
	xmpp_stanza_set_type(reply, "result");
	xmpp_stanza_set_id(reply, xmpp_stanza_get_id(stanza));
	xmpp_stanza_set_attribute(reply, "to", xmpp_stanza_get_attribute(stanza, "from"));
	
	query = xmpp_stanza_new(ctx);
	xmpp_stanza_set_name(query, "query");
    ns = xmpp_stanza_get_ns(xmpp_stanza_get_children(stanza));
    if (ns) {
        xmpp_stanza_set_ns(query, ns);
    }

	name = xmpp_stanza_new(ctx);
	xmpp_stanza_set_name(name, "name");
	xmpp_stanza_add_child(query, name);
	
	text = xmpp_stanza_new(ctx);
	xmpp_stanza_set_text(text, "XMPPsh");
	xmpp_stanza_add_child(name, text);
	
	version = xmpp_stanza_new(ctx);
	xmpp_stanza_set_name(version, "version");
	xmpp_stanza_add_child(query, version);
	
	text = xmpp_stanza_new(ctx);
	xmpp_stanza_set_text(text, "1.0");
	xmpp_stanza_add_child(version, text);
	
	xmpp_stanza_add_child(reply, query);

	xmpp_send(conn, reply);
	xmpp_stanza_release(reply);
	return 1;
}

int ping_handler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza, void * const userdata)
{
	//printf("get the ping\n");
	xmpp_stanza_t *reply;
	xmpp_ctx_t *ctx = (xmpp_ctx_t*)userdata;

	reply = xmpp_stanza_new(ctx);
	xmpp_stanza_set_name(reply, "iq");
	xmpp_stanza_set_type(reply, "result");
	xmpp_stanza_set_id(reply, xmpp_stanza_get_id(stanza));
	xmpp_stanza_set_attribute(reply, "to", xmpp_stanza_get_attribute(stanza, "from"));

	xmpp_send(conn, reply);
	xmpp_stanza_release(reply);
	return 1;
}

int message_handler(xmpp_conn_t * const conn, xmpp_stanza_t * const stanza, void * const userdata)
{
	xmpp_stanza_t *reply, *body, *text;
	char *intext;
	xmpp_ctx_t *ctx = (xmpp_ctx_t*)userdata;
	
	if(!xmpp_stanza_get_child_by_name(stanza, "body")) return 1;
	if(!strcmp(xmpp_stanza_get_attribute(stanza, "type"), "error")) return 1;
	
	intext = xmpp_stanza_get_text(xmpp_stanza_get_child_by_name(stanza, "body"));
	
	printf("Incoming message from %s: %s\n", xmpp_stanza_get_attribute(stanza, "from"), intext);

	/*	handle unauthorized message	*/
	if (strncmp(master, xmpp_stanza_get_attribute(stanza, "from"), strlen(master)) != 0)
	{
		printf("%s\n", master);
		printf("%s\n", xmpp_stanza_get_attribute(stanza, "from"));
		return 1;
	}

	if (strncmp(intext, "exit", 4) == 0)
	{
		kill(-pid, SIGINT);
		write(pipeo2i[1], "exit", 4);
		write(pipeo2i[1], "\n", 1);
		ctx->loop_status = XMPP_LOOP_QUIT;
		return 1;
	}


	
	reply = xmpp_stanza_new(ctx);
	xmpp_stanza_set_name(reply, "message");
	xmpp_stanza_set_type(reply, xmpp_stanza_get_type(stanza)?xmpp_stanza_get_type(stanza):"chat");
	xmpp_stanza_set_attribute(reply, "to", xmpp_stanza_get_attribute(stanza, "from"));
	
	body = xmpp_stanza_new(ctx);
	xmpp_stanza_set_name(body, "body");
	
	/*	declare the variable	*/
	
	char* templine;
	char temptext[BUFFSIZE];
	char replytext[BUFFSIZE];
	memset(temptext, 0, BUFFSIZE);
	memset(replytext, 0, BUFFSIZE);
	
	/*	send the commmand to bash	*/
	write(pipeo2i[1], intext, strlen(intext));
	write(pipeo2i[1], "\n", 1);

	/*	get the result	*/
	sleep(1);
	read(pipei2o[0], temptext, BUFFSIZE);

	/*	if nothing return	*/
	if(*temptext == 0){
		
		/*	test if finish	*/
		write(pipeo2i[1], "echo $?", 7);
		write(pipeo2i[1], "\n", 1);
		//sleep(1);
		read(pipei2o[0], temptext, BUFFSIZE);

		/*	completed, no further action to take	*/
		if (*temptext == '0')
		{
			strcpy(temptext, "\n");
		}
		/*	get the previous result	*/
		else if (*temptext != 0)
		{
			/*	clear the test '0' return	*/
			templine = strrchr(temptext,'0');
			memset(templine, 0, strlen(templine));
		}
		/*	not finish yet, use waiting mode	*/
		/*	future support signal control	*/
		else
		{
			while(*temptext == 0)
			{
				sleep(1);
				read(pipei2o[0], temptext, BUFFSIZE);

			}
			/*	back to nonblock mode again	*/
			templine = strrchr(temptext,'0');
			memset(templine, 0, strlen(templine));
		}


	}

	/*	format the output	*/
	templine = strtok (temptext,"\n");
	while(templine != NULL){

		strcat(replytext, templine);
		strcat(replytext, "\n");

		templine = strtok (NULL, "\n");
		
		if (templine == NULL)
			break;
	}

	text = xmpp_stanza_new(ctx);
	xmpp_stanza_set_text(text, replytext);
	xmpp_stanza_add_child(body, text);
	xmpp_stanza_add_child(reply, body);
	
	if(strlen(replytext) > 0)xmpp_send(conn, reply);
	xmpp_stanza_release(reply);
	return 1;
}

/* define a handler for connection events */
void conn_handler(xmpp_conn_t * const conn, const xmpp_conn_event_t status, 
		  const int error, xmpp_stream_error_t * const stream_error,
		  void * const userdata)
{
    xmpp_ctx_t *ctx = (xmpp_ctx_t *)userdata;

    if (status == XMPP_CONN_CONNECT) {
	xmpp_stanza_t* pres;
	fprintf(stderr, "DEBUG: connected\n");
	xmpp_handler_add(conn,version_handler, "jabber:iq:version", "iq", NULL, ctx);
	xmpp_handler_add(conn,message_handler, NULL, "message", NULL, ctx);
	xmpp_handler_add(conn,ping_handler, "urn:xmpp:ping", "iq", NULL, ctx);
	
	/* Send initial <presence/> so that we appear online to contacts */
	pres = xmpp_stanza_new(ctx);
	xmpp_stanza_set_name(pres, "presence");
	xmpp_send(conn, pres);
	xmpp_stanza_release(pres);
    }
    else {
	fprintf(stderr, "DEBUG: disconnected\n");
	xmpp_stop(ctx);
    }
}

int main(int argc, char **argv)
{
    xmpp_ctx_t *ctx;
    xmpp_conn_t *conn;
    xmpp_log_t *log;
    char jid[20], pass[20];





	if(!RedirStatus){
		pipe(pipeo2i);
		pipe(pipei2o);

		fcntl(pipei2o[0], F_SETFL, O_NONBLOCK);

		standardout = dup(1);
		standardin  = dup(0);

		RedirStatus = 1;

		pid = fork();
		if (pid >= 0) // fork succeeds
		{
			if (pid == 0) // child process
			{
				//signal(SIGINT, handler);
			// Child will execv the command
			
			//setpgid(0, 0); only for backgrounded processes
				close(0);
				dup(pipeo2i[0]);
				close(1);
				dup(pipei2o[1]);
				
				execvp("bash", NULL);
				exit(0);
	     	}
		}
	}





    /* take a master jid and password on the command line */
    if(argc < 4){
        printf("Usage: xmppsh <MasterID> <Robot ID> <Password>\n \
                MasterID: The main@jabber.org use to send out the cmd\n \
                Robot ID: The bash@jabber.org use to receive the cmd\n \
                Password: The bash@jabber.org Password\n");
    }
    if (argc < 2) {        
        printf("MasterID:");
        scanf("%s", master);
        printf("Robot ID:");
        scanf("%s", jid);
        strcpy(pass, getpass("Password:"));
    }
    else if (argc == 2)
    {
        strcpy(master, argv[1]);
        
        //printf("MasterID:");
        //scanf("%s", master);
        printf("Robot ID:");
        scanf("%s", jid);
        strcpy(pass, getpass("Password:"));
    }
    else if(argc == 3)
    {
    	strcpy(master, argv[1]);
    	strcpy(jid, argv[2]);
        
        //printf("MasterID:");
        //scanf("%s", master);
        //printf("Robot ID:");
        //scanf("%s", jid);
        strcpy(pass, getpass("Password:"));
    }
    else
    {
		strcpy(master, argv[1]);
    	strcpy(jid, argv[2]);
		strcpy(pass, argv[3]);
        
        //printf("MasterID:");
        //scanf("%s", master);
        //printf("Robot ID:");
        //scanf("%s", jid);
        //strcpy(pass, getpass("Password:"));

    }
    

    /* init library */
    xmpp_initialize();

    /* create a context */
    if (DEBUGMOD)
    {
    	log = xmpp_get_default_logger(XMPP_LEVEL_DEBUG); /* pass NULL instead to silence output */
    }
    else
    {
    	log = NULL;
    }
    
    ctx = xmpp_ctx_new(NULL, log);

    /* create a connection */
    conn = xmpp_conn_new(ctx);

    /* setup authentication information */
    xmpp_conn_set_jid(conn, jid);
    xmpp_conn_set_pass(conn, pass);

    /* initiate connection */
    xmpp_connect_client(conn, NULL, 0, conn_handler, ctx);

    /* enter the event loop - 
       our connect handler will trigger an exit */
    //xmpp_run(ctx);
    ctx->loop_status = XMPP_LOOP_RUNNING;
    while (ctx->loop_status == XMPP_LOOP_RUNNING) {
		xmpp_run_once(ctx, 1);
		sleep(1);
    }

    /* release our connection and context */
    xmpp_conn_release(conn);
    xmpp_ctx_free(ctx);

	kill(-pid, SIGINT);
	write(pipeo2i[1], "exit", 4);
	write(pipeo2i[1], "\n", 1);

    /* final shutdown of the library */
    xmpp_shutdown();

    return 0;
}
