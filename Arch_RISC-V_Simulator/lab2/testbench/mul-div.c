#include<stdio.h>
#include <syscall.h>

int result[10]={1,2,3,4,5,2,4,6,8,10};

//result:5 10 15 20 25 1 2 3 4 5

int main()
{
	int i=0;
	for(i=0;i<5;i++)
		result[i]=result[i]*5;
	for(i=5;i<10;i++)
		result[i]=result[i]/2;

	// output
	for (int i = 0; i < 10; i++)
	{
		sys_write_int(result[i]);
		sys_write_chr(' ');
	}
	sys_write_chr('\n');
	
	return 0;
}
