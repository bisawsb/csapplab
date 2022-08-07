/***************************************************************************
 *            load_kernel_fib.c
 *
 *  2018/11/15 13:56:46 星期四
 *  Copyright  2018  XuDongLai
 *  <XuDongLai0923@163.com>
 ****************************************************************************/
/*
 * load_kernel_fib.c
 *
 * Copyright (C) 2018 - XuDongLai
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */
#include "l3router.h"

#define PATH4 "/proc/net/route"

extern struct fib_info fi;
extern int poll;


void show_kernel_fib4(void)
{
	int i = 0;
	printf("%-127s\n", "Iface\tDestination\tGateway\tFlags\tRefCnt\tUse\tMetric\tMask\t\tMTU\tWindow\tIRTT\tPort");
	if(fi.use_flag)
	{
		for(;i<FAST_ROUTE_FIB_CNT + 1;i++)
		{
			if(fi.f4[i].portidx > -1)
			{
				if(fi.f4[i].dest == 0)
					printf("%s\t%08X\t%08X\t%04X\t%d\t%u\t%d\t%08X\t%d\t%u\t%u\t%d<--default GW\n",
					       fi.f4[i].if_name,fi.f4[i].dest,fi.f4[i].gw,fi.f4[i].flags,fi.f4[i].refcnt,fi.f4[i].use,
					       fi.f4[i].metric,fi.f4[i].mask,fi.f4[i].mtu,fi.f4[i].window,fi.f4[i].irtt,fi.f4[i].portidx);	
				else
					printf("%s\t%08X\t%08X\t%04X\t%d\t%u\t%d\t%08X\t%d\t%u\t%u\t%d\n",
					       fi.f4[i].if_name,fi.f4[i].dest,fi.f4[i].gw,fi.f4[i].flags,fi.f4[i].refcnt,fi.f4[i].use,
					       fi.f4[i].metric,fi.f4[i].mask,fi.f4[i].mtu,fi.f4[i].window,fi.f4[i].irtt,fi.f4[i].portidx);	
			}
		}
	}
	else
	{
		for(;i<FAST_ROUTE_FIB_CNT + 1;i++)
		{
			if(fi.f4[i].portidx > -1)
			{
				if(fi.f4_bak[i].dest == 0)
					printf("%s\t%08X\t%08X\t%04X\t%d\t%u\t%d\t%08X\t%d\t%u\t%u\t%d<--default GW\n",
					       fi.f4_bak[i].if_name,fi.f4_bak[i].dest,fi.f4_bak[i].gw,fi.f4_bak[i].flags,fi.f4_bak[i].refcnt,fi.f4_bak[i].use,
					       fi.f4_bak[i].metric,fi.f4_bak[i].mask,fi.f4_bak[i].mtu,fi.f4_bak[i].window,fi.f4_bak[i].irtt,fi.f4_bak[i].portidx);	
				else
					printf("%s\t%08X\t%08X\t%04X\t%d\t%u\t%d\t%08X\t%d\t%u\t%u\t%d\n",
					       fi.f4_bak[i].if_name,fi.f4_bak[i].dest,fi.f4_bak[i].gw,fi.f4_bak[i].flags,fi.f4_bak[i].refcnt,fi.f4_bak[i].use,
					       fi.f4_bak[i].metric,fi.f4_bak[i].mask,fi.f4_bak[i].mtu,fi.f4_bak[i].window,fi.f4_bak[i].irtt,fi.f4_bak[i].portidx);		
			}
		}
	}
			
}

void load_kernel_fib4(struct fib4 fib[])
{
	FILE *fp = NULL;
	char buf[256] = {0};
	u32 dest = 0;
	int i = 0;


	for(;i<FAST_ROUTE_FIB_CNT + 1;i++)
	{
		fib[i].portidx = -1;/*标记未使用*/	
	}
	i = 0;
	
	fp = fopen (PATH4, "r"); 
	if (NULL == fp) 
	{ 
		perror ("can't open file!\n");
		exit (0); 
	} 	
	if(!feof (fp))fgets (buf, BUFSIZ, fp);/*跳过标题行*/
	while (!feof (fp))
	{ 
		fgets (buf, BUFSIZ, fp);
		sscanf(buf,"%s\t%X\t%X\t%X\t%d\t%u\t%d\t%X\t%d\t%u\t%u",
		       fib[i].if_name,&fib[i].dest,&fib[i].gw,&fib[i].flags,&fib[i].refcnt,
		       &fib[i].use,&fib[i].metric,&fib[i].mask,&fib[i].mtu,&fib[i].window,&fib[i].irtt);		
		
		if(!strncmp(fib[i].if_name,"obx",3))
		{
			if(fib[i].dest == 0)/*说明读到了默认网关，保存在FIB表的最后一条，i的计数不加，重新获取新的表项*/
			{
				memcpy(&fib[FAST_ROUTE_FIB_CNT],&fib[i],sizeof(struct fib4));
				fib[FAST_ROUTE_FIB_CNT].portidx = (int)(fib[i].if_name[3] - 48);
				continue;
			}
			else
			{
				fib[i].portidx = (int)(fib[i].if_name[3] - 48);/*取端口号名称尾字符，做为物理端口号信息*/
				i++;
			}
		}	
		else
		{
			memset(&fib[i],0x00,sizeof(struct fib4));/*不属于FAST接口的数据不要，可能是最后一条，导致数据不对，故要清零*/
			fib[i].portidx = -1;/*将其使用端口置为无效*/
		}
	} 
	fclose (fp); 
}

void *update_fib4_thread(void *argv)
{
	int i = 0;
	while(poll)
	{
		sleep(10);
		if(fi.use_flag)
		{
			load_kernel_fib4(fi.f4_bak);
		}
		else
		{
			load_kernel_fib4(fi.f4);
		}
		
		if(0==memcmp(fi.f4_bak,fi.f4,sizeof(struct fib4)*(FAST_ROUTE_FIB_CNT+1)))/*非0为不相等*/
		{
			printf("FIB4 fresh...\n");			
		}
		else
		{
			printf("FIB4 update...\n");
			fi.use_flag = !fi.use_flag;
		}
	}
}

void start_update_fib4_thread(void)
{
	pthread_t tid;
	int *idx = malloc(sizeof(int *));	
	
	if(pthread_create(&tid, NULL, update_fib4_thread, (void *)idx))
	{
		printf("Create update_fib4_thread error!\n");		
	}
	else
	{
		printf("Create update_fib4_thread OK!\n");			
	}	
}


void load_kernel_fib_info(void)
{	
	fi.f4 = (struct fib4 *)malloc(sizeof(struct fib4)*(FAST_ROUTE_FIB_CNT+1));
	fi.f4_bak = (struct fib4 *)malloc(sizeof(struct fib4)*(FAST_ROUTE_FIB_CNT+1));
	memset(fi.f4,0,sizeof(struct fib4)*(FAST_ROUTE_FIB_CNT+1));
	memset(fi.f4_bak,0,sizeof(struct fib4)*(FAST_ROUTE_FIB_CNT+1));
	load_kernel_fib4(fi.f4);		
	fi.use_flag = 1;
	show_kernel_fib4();	
	start_update_fib4_thread();
}

void get_out_gw(int *outport,u32 *gw,int tlbidx)
{
	//TODO User add code
}


int fib_lookup(u32 dst)
{
	int i = 0;
	//TODO User add code
	return FAST_ROUTE_FIB_CNT;/*返回默认网关位置*/
}
