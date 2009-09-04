#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <sys/stat.h>
#include <ftw.h>
#include <unistd.h>
#include <sys/types.h>
#define TASKNUM 13

char task[TASKNUM][100] = {"DragBoth","DragBack","DragHybrid","DragFront",
			"RotateFlip","RotateTorque",
			"StretchBoth","StretchHybrid","StretchBack","StretchFront",
			"GrabBoth","GrabBack","GrabFront"};


void process(char* path){

	FILE* fp,*fp2,*fp3,*fp4,*fp5;
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

	//ADD TYPE
	double typeextramean, typeextrastd, typeextrasum , typecommean , typecomstd , typecomsum;
	int typecount,typeflag,numoftype;
	char garbage[100];
	int ii,jj,kk;
	int tasknum;
	int index, numofdata;


	fp5 = fopen("all_type.csv","a");
	fp3 = fopen("all.txt","a");
	fp4 = fopen("all_type.txt","a");

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
			sscanf(buffer,"%s %d %d\n",garbage,&typecount,&numoftype);

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


	tasknum = numoftype*typecount;


	fprintf(fp4,"Task: %s\n", path+6);
	for(ii = 0 ; ii < numoftype ; ii++){

			typeextrasum = 0.0;
			typecomsum = 0.0;
			typeextrastd = 0.0;
			typecomstd = 0.0;

		for( jj = 0 ; jj <= j ; jj++){

			for( kk = 0 ; kk < typecount ; kk++){
			
				index = tasknum*jj + ii*typecount + kk;
				
				//printf(" index = %d\n",index);
				typeextrasum += extra[ index];
				typecomsum += comtime[ index ];
				typeextrastd += extra[index] * extra[index];
				typecomstd += comtime[index] * comtime[index];
							
			}

		}

		numofdata = (j+1)*typecount;

			typeextramean = typeextrasum / numofdata;
			typecommean = typecomsum / numofdata;
			typeextrastd = sqrt(typeextrastd/numofdata - typeextramean*typeextramean);
			typecomstd = sqrt(typecomstd/numofdata - typecommean*typecommean);

			fprintf(fp5,"%s,%d,%lf,%lf,%lf,%lf\n",path+6,ii+1,typecommean,typecomstd,typeextramean, typeextrastd);


			fprintf(fp4,"#For type : %d\n", ii+1);	
			fprintf(fp4,"Total Completion Time : %lf  Average Completion Time : %lf   Completion time STD: %lf\n",typecomsum, typecommean, typecomstd);

			fprintf(fp4,"Total Extra Movement : %lf   Average Extra Movement : %lf    Extra Movement STD: %lf\n\n\n", typeextrasum, typeextramean, typeextrastd);
			

		}


	extrasum = -1.0;
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

	fprintf(fp3,"Task: %s\n", path+6);

			fprintf(fp3,"Total Completion Time : %lf  Average Completion Time : %lf   Completion time STD: %lf\n",comsum,commean,comstd);

			fprintf(fp3,"Total Extra Movement : %lf   Average Extra Movement : %lf    Extra Movement STD: %lf\n",extrasum,extramean,extrastd);
			




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

	fprintf(fp3,"Front Sum = %lf  Front  Mean = %lf  Front Std = %lf\n",devicesum[0] ,devicemean[0] , devicestd[0]);
	fprintf(fp3,"Back Sum = %lf   Back  Mean = %lf  Back Std = %lf\n", devicesum[1] ,devicemean[1] , devicestd[1]);
	fprintf(fp3,"Both Sum = %lf   Both  Mean = %lf  Both Std = %lf\n",devicesum[2] , devicemean[2] , devicestd[2]);

	fprintf(fp3,"Efficency : %.2lf %%\n\n\n", (devicesum[2]/comsum)*100 );

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

	FILE* fp,*fp2,*fp3,*fp4,*fp5,*fp6;
	char buffer[1000];
	int type[100],taskstate[100],extra[100];
	double comtime[100];
	int i = 0,j,k;
	char* pch;
	double extramean, extrastd, extrasum , commean , comstd , comsum;
	int count = 0;
	double onfront,onback,onboth;
	double oldonfront,oldonback,oldonboth;
	char temppath[100],garbage[100];
	int idnum;

	double typeextramean, typeextrastd, typeextrasum , typecommean , typecomstd , typecomsum;
	int typecount,typeflag,numoftype=0;


	sscanf(filename,"%d%s",&idnum,garbage);

	fp = fopen(filename,"r");
	
	sprintf(temppath,"_%d.csv",idnum);
	fp3 = fopen( temppath , "w");

	sprintf(temppath,"_%d_type.txt",idnum);
	fp4 = fopen( temppath , "w");

	sprintf(temppath,"_%d_type.csv",idnum);
	fp6 = fopen( temppath , "w");
	
	sprintf(temppath,"_%d.txt",idnum);
	fp5 = fopen( temppath ,"w");

	while( fgets( buffer,1000,fp ) != NULL){

		sscanf( buffer,"%s ,%d,%d,%lf,%d,%lf,%lf,%lf\n",
				taskname,&type[i],&taskstate[i],&comtime[i],&extra[i],&onfront,&onback,&onboth);

#ifdef DEBUG
		printf("%s",buffer);
		  printf("%s,%d,%d,%lf,%d,%lf,%lf,%lf\n",
		  taskname,type[i],taskstate[i],comtime[i],extra[i],onfront,onback,onboth);
#endif
		if( i == 0)
			strcpy( oldtaskname , taskname );

		if( strcmp( taskname , oldtaskname) ){

			count = i;

			fprintf(fp5,"#For %s %s\n",filename,oldtaskname);
			fprintf(fp4,"#For %s %s\n",filename,oldtaskname);
//For TYPE
			typeextrasum = 0.0;
			typecomsum = 0.0;
			typeextrastd = 0.0;
			typecomstd = 0.0;
			numoftype = 0;

			for( j = 0; j < count ; j++){

				if( j == 0)
					typeflag = 0;

				if( (j!=0 && type[j] != type[j-1]) || j == count-1){	
		
					numoftype++;

					if( j == count - 1){
					
						typeextrasum += extra[j];
						typecomsum += comtime[j];
						typeextrastd += extra[j] * extra[j];
						typecomstd += comtime[j] * comtime[j];
			
					}

					if(typeflag == 0){
						typecount = j;
						typeflag = 1;
					}


					//printf("  j = %d, typecount = %d \n", j,typecount );

					typeextramean = typeextrasum / typecount;
					typecommean = typecomsum / typecount;
					typeextrastd = sqrt(typeextrastd/typecount - typeextramean*typeextramean);
					typecomstd = sqrt(typecomstd/typecount - typecommean*typecommean);

			fprintf(fp6,"%s,%d,%lf,%lf,%lf,%lf\n",oldtaskname,type[j-1],typecommean, typecomstd,typeextramean, typeextrastd);

			fprintf(fp4,"#For type : %d\n",type[j-1]);	
			fprintf(fp4,"Total Completion Time : %lf  Average Completion Time : %lf   Completion time STD: %lf\n",typecomsum, typecommean, typecomstd);

			fprintf(fp4,"Total Extra Movement : %lf   Average Extra Movement : %lf    Extra Movement STD: %lf\n\n\n", typeextrasum, typeextramean, typeextrastd);
			

					typeextrasum = 0.0;
					typecomsum = 0.0;
					typeextrastd = 0.0;
					typecomstd = 0.0;
				}

			
				typeextrasum += extra[j];
				typecomsum += comtime[j];
				typeextrastd += extra[j] * extra[j];
				typecomstd += comtime[j] * comtime[j];
			
			}


			i=0;

			for( k = 0 ; k < TASKNUM ; k++){

				if( !strcmp(oldtaskname , task[k]) ){
					strcpy(temppath,"./ALL/");
					strcat(temppath,task[k]);
					fp2 = fopen( temppath,"a");
#ifdef DEBUG	
					printf("Will creat file : %s\n",temppath);
#endif
			
					fprintf(fp2,"##%s %d %d\n", filename,typecount,numoftype);
					
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

			fprintf(fp5,"Total Completion Time : %lf  Average Completion Time : %lf   Completion time STD: %lf\n",comsum,commean,comstd);

			fprintf(fp5,"Total Extra Movement : %lf   Average Extra Movement : %lf    Extra Movement STD: %lf\n",extrasum,extramean,extrastd);
			
			fprintf(fp5,"Front: %lf , Back:%lf , Both:%lf\n",
					oldonfront,oldonback,oldonboth);

			fprintf(fp5,"Efficency : %.2lf %%\n\n\n", (oldonboth/comsum)*100 );

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

//For TYPE
			typeextrasum = 0.0;
			typecomsum = 0.0;
			typeextrastd = 0.0;
			typecomstd = 0.0;
			numoftype = 0;

	fprintf(fp5,"#For %s %s\n",filename,taskname);
	//printf("count = %d\n",count);	
			for( j = 0; j < count ; j++){

				if( j == 0)
					typeflag = 0;

				if( (j!=0 && type[j] != type[j-1]) || j == count-1){	
		
					numoftype++;

					if( j == count - 1){
					
						typeextrasum += extra[j];
						typecomsum += comtime[j];
						typeextrastd += extra[j] * extra[j];
						typecomstd += comtime[j] * comtime[j];
			
					}

					if(typeflag == 0){
						typecount = j;
						typeflag = 1;
					}

					//printf("  j = %d, typecount = %d \n", j,typecount );

					typeextramean = typeextrasum / typecount;
					typecommean = typecomsum / typecount;
					typeextrastd = sqrt(typeextrastd/typecount - typeextramean*typeextramean);
					typecomstd = sqrt(typecomstd/typecount - typecommean*typecommean);

			fprintf(fp4,"#For type : %d\n",type[j-1]);	
			fprintf(fp4,"Total Completion Time : %lf  Average Completion Time : %lf   Completion time STD: %lf\n",typecomsum, typecommean, typecomstd);

			fprintf(fp4,"Total Extra Movement : %lf   Average Extra Movement : %lf    Extra Movement STD: %lf\n\n\n", typeextrasum, typeextramean, typeextrastd);
			
					typeextrasum = 0.0;
					typecomsum = 0.0;
					typeextrastd = 0.0;
					typecomstd = 0.0;
				}

			
				typeextrasum += extra[j];
				typecomsum += comtime[j];
				typeextrastd += extra[j] * extra[j];
				typecomstd += comtime[j] * comtime[j];
			
			}

	for( k = 0 ; k < TASKNUM ; k++){
		if( !strcmp(oldtaskname , task[k]) ){
			strcpy(temppath,"./ALL/");
			strcat(temppath,task[k]);
			fp2 = fopen( temppath,"a");

			fprintf(fp2,"##%s %d %d\n", filename,typecount,numoftype);

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

			fprintf(fp5,"Total Completion Time : %lf  Average Completion Time : %lf   Completion time STD: %lf\n",comsum,commean,comstd);

			fprintf(fp5,"Total Extra Movement : %lf   Average Extra Movement : %lf    Extra Movement STD: %lf\n",extrasum,extramean,extrastd);
			

			fprintf(fp5,"Front: %lf , Back:%lf , Both:%lf\n",
					oldonfront,oldonback,oldonboth);

			fprintf(fp5,"Efficency : %.2lf %%\n\n\n", (oldonboth/comsum)*100 );
	
			fprintf(fp3,"%s,%lf,%lf,%lf,%lf,%lf,%lf,%lf\n"
				,taskname,commean,comstd,extramean,extrastd,oldonfront,oldonback,oldonboth);
			//printf("Num of type = %d\n", numoftype );
	fclose(fp);
	fclose(fp3);
	fclose(fp4);

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
