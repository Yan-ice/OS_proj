#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/spinlock.h"
#include "kernel/sleeplock.h"
#include "kernel/fs.h"
#include "kernel/file.h"
#include "user/user.h"
#include "kernel/fcntl.h"

int main(int argc, char **argv){
	fprintf(2, "tracing mem\n");
	char ch1[4096];
	char ch2[84];
	int last = 1;
	fprintf(2, "awa...");
	mmtrace(ch1);
	mmtrace(ch2);
	mmtrace(&last);
	exit(0);
	return 0;
}
