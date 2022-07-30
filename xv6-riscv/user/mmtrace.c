#include "kernel/types.h"
#include "kernel/stat.h"
#include "kernel/spinlock.h"
#include "kernel/sleeplock.h"
#include "kernel/fs.h"
#include "kernel/file.h"
#include "user/user.h"
#include "kernel/fcntl.h"

int main(int argc, char **argv){
	printf("single process test:\n");
	char *ch1 = (char*)malloc(4096);
	char *ch2 = (char*)malloc(4096);
	int *i1 = (int*)malloc(4096*4);
	mmtrace(ch1);
	mmtrace(ch2);
	mmtrace(i1);

	printf("\nimulti process test:\n");
	if(fork()==0){
		sleep(1);
		printf("proc0 - ");
		mmtrace(ch1);
	}else{
		wait(0);
		sleep(1);
		printf("proc1 - ");
		mmtrace(ch1);
	}
	exit(0);
	return 0;
}
