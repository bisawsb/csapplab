#include <stdio.h>
#include <syscall.h>

int result=0;
//result 3628800
int cal_n(int i)
{
	if(i==1)
		return i;
	else
		return i*cal_n(i-1);
}

int main()  
{
	result=cal_n(10);

	// output
	sys_write_int(result);
	sys_write_chr('\n');
	
	return 0;
}  
