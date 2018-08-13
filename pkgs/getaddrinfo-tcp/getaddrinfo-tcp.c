#include <errno.h>
#include <error.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <netinet/in.h>
#include <sys/socket.h>

int main(int argc, char *argv[]) {

	struct addrinfo hints;
	int err;
	struct addrinfo *ai;
	struct addrinfo *runp;
	char buf[INET6_ADDRSTRLEN];

	if (argc != 2) {
		fprintf(stderr, "Usage:	%s <hostname>\n", argv[0]);
		return -1;
	}

	gethostbyname(argv[1]);

	memset(&hints, '\0', sizeof(hints));
	//hints.ai_family = AF_UNSPEC; // any address family (either IPv4 or IPv6, for example)
	//hints.ai_socktype = 0; // socket addresses of any type
	hints.ai_protocol = IPPROTO_TCP; // socket addresses with TCP protocol
	//hints.ai_protocol = 0; // socket addresses with any protocol
	//hints.ai_flags = AI_V4MAPPED | AI_ADDRCONFIG | AI_ALL;
	if ((err = getaddrinfo(argv[1], argc == 3 ? argv[2] : "", &hints, &ai)) != 0) {
		error(EXIT_FAILURE, 0, "getaddrinfo(%d): %s", err, gai_strerror(err));
	}

	for (runp = ai; runp != NULL; runp = runp->ai_next) {
		getnameinfo(runp->ai_addr, runp->ai_addrlen, buf, INET6_ADDRSTRLEN, NULL, 0, NI_NUMERICHOST);
		printf("family:%2d socktype:%2d protocol:%3d addr:%s(%d)\n", runp->ai_family, runp->ai_socktype, runp->ai_protocol, buf, runp->ai_addrlen);
	}

	freeaddrinfo(ai);
	return 0;
}
