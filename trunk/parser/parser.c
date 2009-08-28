#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>


char task[9][100] = {"DragBoth","DragBack","DragHybrid","RotateFlip","RotateTorque","StrechBoth","StrechHybrid",
			"GrabBoth","GrabBack"};


void parse( char *filename , char* taskname , char* oldtaskname){

	FILE* fp,*fp2;
	char buffer[1000];
	int type[100],taskstate[100],extra[100];
	double comtime[100];
	int i = 0,j,k;
	char* pch;
	double extramean, extrastd, extrasum , commean , comstd , comsum;
	int count = 0;
	double onfront,onback,onboth;
	char temppath[100];
	

	fp = fopen(filename,"r");
	while( fgets( buffer,1000,fp ) != NULL){
		
		sscanf( buffer,"%s ,%d,%d,%lf,%d,%lf,%lf,%lf\n",
			taskname,&type[i],&taskstate[i],&comtime[i],&extra[i],&onfront,&onback,&onboth);
		
		/*printf("%s",buffer);
		printf("--%s,%d,%d,%lf,%d,%lf,%lf,%lf--\n",
			taskname,type[i],taskstate[i],comtime[i],extra[i],onfront,onback,onboth);
		*/
		if( i == 0)
			strcpy( oldtaskname , taskname );

		if( strcmp( taskname , oldtaskname) ){	
		
			count = i;
			i=0;
			
			for( k = 0 ; k < 9 ; k++){
				if( !strcmp(oldtaskname , task[k]) ){
					strcpy(temppath,"./ALL/");
					strcat(temppath,task[k]);
					printf("---%s\n",temppath);
					fp2 = fopen( temppath,"a");
						
					for( j = 0 ; j < count ; j++){
						fprintf(fp2,"%d,%lf,%lf,%lf,%lf\n",
							extra[j],comtime[j],onfront,onback,onboth);
						}
					}
				}

			printf("different Task\n");
		
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
		
			sscanf( buffer,"%s ,%d,%d,%lf,%d,%lf,%lf,%lf\n",
				taskname,&type[i],&taskstate[i],&comtime[i],&extra[i],&onfront,&onback,&onboth);
		
			printf("--%s,%d,%d,%lf,%d--\n",taskname,type[i],taskstate[i],comtime[i],extra[i]);
		}
		strcpy( oldtaskname , taskname);
		i++;
	}

	// remeber last time
		
			if( count == 0)
				count = i;
	

			for( k = 0 ; k < 9 ; k++){
				if( !strcmp(oldtaskname , task[k]) ){
					fp2 = fopen(task[k],"a");
						
					for( j = 0 ; j < count ; j++){
						fprintf(fp2,"%d,%lf,%lf,%lf,%lf\n",
							extra[j],comtime[j],onfront,onback,onboth);
						}
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

			printf("%lf , %lf  , %lf  , %lf\n",extramean, extrastd ,commean , comstd);	
		
	}



int main( int argc , char* argv[]){

	int i;
	char taskname[100],oldtaskname[100];

	mkdir("ALL","0777");

	for( i = 1 ; i < argc ; i++){	
		parse( argv[i] , taskname , oldtaskname);
		}
	return 0;	

	}
