BEGIN{
	FS = ","
	OldID = 0
	TotalUser = 0
	NameSet[1] = "GrabBoth"
	NameSet[2] = "GrabBack"
	NameSet[3] = "GrabFront"
	NameSet[4] = "DragBoth"
	NameSet[5] = "DragBack"
	NameSet[6] = "DragFront"
	NameSet[7] = "DragHybrid"
	NameSet[8] = "StretchBoth"
	NameSet[9] = "StretchBack"
	NameSet[10] = "StretchFront"
	NameSet[11] = "StretchHybrid"
	NameSet[12] = "RotateFlip"
	NameSet[13] = "RotateTorque"
	
	print "\n----------------------------"
}

{  #Define Variables
	UserID			= $1
	TaskName			= $2
	Time				= $3
	CompleteTime	= $4
	Front				= $5
	Back				= $6
	Device			= $7
	AvgExtra			= $8
}

( OldID != UserID ){
	User[UserID] = 0
	OldID = UserID
	TotalUser ++
	
	if ( TotalUser > 1 ){
		print "UserID:", UserID-1, "Total Task:", User[UserID-1]
		printf ( "Lose : " )
		for ( i=1 ; i<=13 ; i++){
			if ( Task[NameSet[i]] == 0 ) printf( "%s ",NameSet[i])
		}
		printf ( "\nExtra: " )
		for ( i=1 ; i<=13 ; i++){
			if ( Task[NameSet[i]] > 1 ) printf( "%s ",NameSet[i])
			Task[NameSet[i]] = 0
		}
		
		print "\n----------------------------"
	}
}

{
	User[UserID] ++
	Task[TaskName] ++
	
	if (CompleteTime < 0 || Front < 0 || Back < 0 || Device < 0 || AvgExtra < 0) {
		print TaskName, "< 0"
	}
	if (Device > CompleteTime) {
		print TaskName, "Finger on Device > Complete Time"
	}
}

END{
		print "UserID:", UserID, "Total Task:", User[UserID]
		printf ( "Lose : " )
		for ( i=1 ; i<=13 ; i++){
			if ( Task[NameSet[i]] == 0 ) printf( "%s ",NameSet[i])
		}
		printf ( "\nExtra: " )
		for ( i=1 ; i<=13 ; i++){
			if ( Task[NameSet[i]] > 1 ) printf( "%s ",NameSet[i])
			Task[NameSet[i]] = 0
		}
		
		print "\n----------------------------"
		print "Total User:",TotalUser

}