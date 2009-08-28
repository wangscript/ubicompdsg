#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <sys/stat.h>
#include <ftw.h>
#include <unistd.h>
#include <sys/types.h>



char task[9][100] = {"DragBoth","DragBack","DragHybrid","RotateFlip","RotateTorque","StrechBoth","StrechHybrid",
	"GrabBoth","GrabBack"};


void process(char* path){

	FILE* fp,*fp2;
	char buffer[1000];
	double comtime[2000];
	int extra[2000];
	double extramean, extrastd, extrasum , commean , comstd , comsum;
	double devicemean[3], devicesum[3] , devicestd[3];
	int count = 0;
	double onfront[100],onback[100],onboth[100];
	int i,j,k;
	char* pch;
	char temppath[100];


	fp2 = fopen("all.csv" , "a");

	if( (fp = fopen( path , "r")) == NULL)
		printf("fopen error\n");
#ifdef DEBUG
	printf("Start Read : %s\n", path);
#endif
	i = 0;
	j = -1;
	while( fgets( buffer,1000,fp ) != NULL ){

		pch = strstr( buffer , "csv");
		if( pch != NULL ){
#ifdef DEBUG			
			printf("Find csv !! \n");
#endif	
			j++;
		}else{

			sscanf(buffer,"%lf,%d,%lf,%lf,%lf\n",
					&comtime[i],&extra[i],&onfront[j],&onback[j],&onboth[j]);
#ifdef DEBUG
			printf("%lf,%d,%lf,%lf,%lf\n",comtime[i],extra[i],onfront[j],onback[j],onboth[j]);
#endif
			i++;
		}
	}

	extrasum = 0.0;
	comsum = 0.0;
	extrastd = 0.0;
	comstd = 0.0;

	for( k = 0; k < i ; k++){
		extrasum += extra[k];
		comsum += comtime[k];
		extrastd += extra[k] * extra[k];
		comstd += comtime[k] * comtime[k];
	}
	extramean = extrasum / k;
	commean = comsum / k;
	extrastd = sqrt(extrastd/k - extramean*extramean);
	comstd = sqrt(comstd/k - commean*commean);

	printf("Task: %s\n", path+6);
	printf("commean = %lf , comstd = %lf  , extramean = %lf , extrastd = %lf\n"
		,commean,comstd,extramean, extrastd);	



	for( i = 0 ; i < 3 ; i++)
		devicemean[i] = devicesum[i] = devicestd[i] = 0.0;

	for( k = 0; k <= j ; k++){
#ifdef DEBUG
		printf("onfront = %lf , onback = %lf , onboth = %lf\n",
					onfront[k], onback[k] , onboth[k]);
#endif
		devicesum[0] += onfront[k];
		devicesum[1] += onback[k];
		devicesum[2] += onboth[k];
		
		devicestd[0] += onfront[k]*onfront[k];
		devicestd[1] += onback[k]*onback[k];
		devicestd[2] += onboth[k]*onboth[k];
	}

	for( i = 0 ; i < 3 ; i++)
		devicemean[i] = devicesum[i]/k;
	
	for( i = 0 ; i < 3 ; i++)
		devicestd[i] = sqrt(devicestd[i]/k - devicemean[i]*devicemean[i]);

	printf("front  mean = %lf  front std = %lf\n", devicemean[0] , devicestd[0]);
	printf("back  mean = %lf  back std = %lf\n", devicemean[1] , devicestd[1]);
	printf("both  mean = %lf  both std = %lf\n", devicemean[2] , devicestd[2]);


	fprintf(fp2,"%s,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf,%lf\n",
		path+6,commean,comstd,extramean,extrastd,devicemean[0],devicestd[0],devicemean[1],devicestd[1],devicemean[2],devicestd[2]);
	
	
	fclose(fp);
	fclose(fp2);

}


int traverse(const char *fpath, const struct stat *sb, int tflag){

	if( tflag == FTW_F ){
#ifdef DEBUG
		printf("%s\n",fpath);
#endif	
		process( (char*)fpath );

	}

	return 0;
}



void parse( char *filename , char* taskname , char* oldtaskname){

	FILE* fp,*fp2,*fp3;
	char buffer[1000];
	int type[100],taskstate[100],extra[100];
	double comtime[100];
	int i = 0,j,k;
	char* pch;
	double extramean, extrastd, extrasum , commean , comstd , comsum;
	int count = 0;
	double onfront,onback,onboth;
	double oldonfront,oldonback,oldonboth;
	char temppath[100];




	fp = fopen(filename,"r");
	strcpy(temppath,"_");
	strcat(temppath,filename);
	fp3 = fopen( temppath , "w");
	while( fgets( buffer,1000,fp ) != NULL){

		sscanf( buffer,"%s ,%d,%d,%lf,%d,%lf,%lf,%lf\n",
				taskname,&type[i],&taskstate[i],&comtime[i],&extra[i],&onfront,&onback,&onboth);

#ifdef DEBUG
		printf("%s",buffer);
		  printf("--%s,%d,%d,%lf,%d,%lf,%lf,%lf--\n",
		  taskname,type[i],taskstate[i],comtime[i],extra[i],onfront,onback,onboth);
#endif
		if( i == 0)
			strcpy( oldtaskname , taskname );

		if( strcmp( taskname , oldtaskname) ){	

			count = i;
			i=0;

			for( k = 0 ; k < 9 ; k++){
				if( !strcmp(oldtaskname , task[k]) ){
					strcpy(temppath,"./ALL/");
					strcat(temppath,task[k]);
					fp2 = fopen( temppath,"a");
#ifdef DEBUG	
					printf("Will creat file : %s\n",temppath);
#endif
					fprintf(fp2,"##%s##\n", filename);
					
					for( j = 0 ; j < count ; j++){
						fprintf(fp2,"%lf,%d,%lf,%lf,%lf\n",
								comtime[j],extra[j],oldonfront,oldonback,oldonboth);
#ifdef DEBUG
						   printf("%lf,%d,%lf,%lf,%lf\n",
		                                              comtime[j],extra[j],oldonfront,oldonback,oldonboth);
	
						
#endif
					      }

					fclose(fp2);
				}
			}

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

			printf("For %s %s\n",filename,oldtaskname);
			printf("%lf , %lf  , %lf  , %lf\n",commean, comstd ,extramean , extrastd);	

			fprintf(fp3,"%s,%lf,%lf,%lf,%lf,%lf,%lf,%lf\n"
				,oldtaskname,commean,comstd,extramean,extrastd,oldonfront,oldonback,oldonboth);

			sscanf( buffer,"%s ,%d,%d,%lf,%d,%lf,%lf,%lf\n",
					taskname,&type[i],&taskstate[i],&comtime[i],&extra[i],&onfront,&onback,&onboth);
			//printf("--%s,%d,%d,%lf,%d--\n",taskname,type[i],taskstate[i],comtime[i],extra[i]);
		}
		strcpy( oldtaskname , taskname);
		oldonfront = onfront;
		oldonback = onback;
		oldonboth = onboth;
		i++;
	}

	// remeber last time

	count = i;

	for( k = 0 ; k < 9 ; k++){
		if( !strcmp(oldtaskname , task[k]) ){
			strcpy(temppath,"./ALL/");
			strcat(temppath,task[k]);
			fp2 = fopen( temppath,"a");

			//printf("Will creat file : %s\n",temppath);

			fprintf(fp2,"##%s##\n", filename);

			for( j = 0 ; j < count ; j++){
				fprintf(fp2,"%lf,%d,%lf,%lf,%lf\n",
						comtime[j],extra[j],onfront,onback,onboth);
			}
		}
	}


	fclose(fp2);

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

	printf("For %s %s\n",filename,taskname);
	printf("%lf , %lf  , %lf  , %lf\n",commean, comstd ,extramean , extrastd);	
			fprintf(fp3,"%s,%lf,%lf,%lf,%lf,%lf,%lf,%lf\n"
				,taskname,commean,comstd,extramean,extrastd,oldonfront,oldonback,oldonboth);
	fclose(fp);
	fclose(fp3);

}



int main( int argc , char* argv[]){

	int i;
	char taskname[100],oldtaskname[100];

	mkdir("ALL",S_IRWXU);

	for( i = 1 ; i < argc ; i++){	
		parse( argv[i] , taskname , oldtaskname);
	}

	ftw( "./ALL" , &traverse , 1);

	return 0;	

}
