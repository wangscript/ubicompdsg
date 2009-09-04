BEGIN {
	FS = ","
	OldName = ""
	str = ""
	bow = 3600
	OldBothTime = 0
}

{ # Define Variables
	TaskName 	 = $1
	TaskType 	 = $2
	Round		 = $3
	CompleteTime = $4
	Extra		 = $5
	FrontTime	 = $6
	BackTime	 = $7
	BothTime	 = $8 
}

( OldName != TaskName ){
	
	if (TotalCT[OldName] < OldBothTime){
		str = sprintf("%s\n%s Finger on Deviece < Total Time", str, TaskName)
	}
	
	if (NR != 1){
		if (str != ""){ 
			printf ("%s\n", str)
			print "============"
		}
	}
	
	TotalCT[TaskName] = 0;
	OldName = TaskName
	str = ""
}

{
	if (CompleteTime < 0 || Extra < 0 || FrontTime < 0 || BackTime < 0 || BothTime < 0) {
		str = sprintf("%s\n%s %d < 0", str, TaskName, Round)
	}
	if (CompleteTime > bow || Extra > bow || FrontTime > bow || BackTime > bow || BothTime > bow) {
		str = sprintf("%s\n%s %d 爆了", str, TaskName, Round)
	}
	
	TotalCT[TaskName] += CompleteTime
	OldBothTime = BothTime
}

END {
	if (TotalCT[TaskName] < OldBothTime){
		str = sprintf("%s\n%s Finger on Deviece < Total Time", str, TaskName)
	}
	
	if (str != ""){ 
		printf ("%s\n", str)
		print "============"
	}
}

