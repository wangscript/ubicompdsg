#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>




int main(){
	
	FILE*fp;
	char buffer[1000];
	int type[100],taskstate[100],extra[100];
	double comtime[100];
	char taskname[100],oldtaskname[100];
	int i = 0,j;
	char* pch;
	float extramean, extrastd, extrasum , commean , comstd , comsum;
	int count;


	fp = fopen("1_CSV.csv","r");
	while( fgets( buffer,1000,fp ) != NULL){
		
		sscanf( buffer,"%s ,%d,%d,%lf,%d",taskname,&type[i],&taskstate[i],&comtime[i],&extra[i]);
		//printf("--%s,%d,%d,%lf,%d--\n",taskname,type[i],taskstate[i],comtime[i],extra[i]);
		
		if( i == 0)
			strcpy( oldtaskname , taskname);

		if( strcmp( taskname , oldtaskname) ){	
		
			printf("different Task\n");
			
			extrasum = 0.0;
			comsum = 0.0;
			extrastd = 0.0;
			comstd = 0.0;

			count = i;
			i=0;
			for( j = 0; j < count ; j++){
				extrasum += extra[j];
				comsum += comtime[j];
				extrastd += extra[j] * extra[j];
				comstd += comtime[j] * comtime[j];
			}
			extramean = extrasum / j;
			commean = comsum / j;
			extrastd = sqrt(extrastd/j - extramean*extramean);
			comstd = sqrt(comstd/j - commean*commean);

			printf("%lf , %lf  , %lf  , %lf\n",extramean, extrastd ,commean , comstd);	
			sscanf( buffer,"%s ,%d,%d,%lf,%d",taskname,&type[i],&taskstate[i],&comtime[i],&extra[i]);
			printf("--%s,%d,%d,%lf,%d--\n",taskname,type[i],taskstate[i],comtime[i],extra[i]);
		}
		strcpy( oldtaskname , taskname);
		i++;
	}

	// remeber last time
			extrasum = 0.0;
			comsum = 0.0;
			extrastd = 0.0;
			comstd = 0.0;

			for( j = 0; j < count ; j++){
				extrasum += extra[j];
				comsum += comtime[j];
				extrastd += extra[j] * extra[j];
				comstd += comtime[j] * comtime[j];
			}
			extramean = extrasum / j;
			commean = comsum / j;
			extrastd = sqrt(extrastd/j - extramean*extramean);
			comstd = sqrt(comstd/j - commean*commean);

			printf("%lf , %lf  , %lf  , %lf\n",extramean, extrastd ,commean , comstd);	
	
	return 0;	
	
	}
