BEGIN{
	FS = ","
	old = 0
	max = 0
}

( old != $1 ){
	#if (line[$1] != "")
	line[$1] = ""
	if ($1 > max) max = $1
	old = $1
}

{
	if (NR == 1) line[$1] = sprintf("%s%s", line[$1], $0)
	else line[$1] = sprintf("%s\n%s", line[$1], $0)
}

END{
	for (i=1 ; i<=max ;i++){
		printf("%s",line[i]);	
	}
	
}