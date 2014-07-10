#!/bin/bash
#script for scraping movie IDs and name ids from IMDb. This script recusively crawls IMDb pages and extracts related movie/people/character ids and stores them in txt files.
#USAGE:	-getid  => gets movie ids into list_(imdb|name|character)_id.txt
#		-getinfo=> gets data(XML/JSON/JSONP) and puts in store_data
#		-print  => prints current id/info status
#
#Added functionality to get data from omdbapi in JSON/XML format. Tweak custom URL according to need.
#Added functionality to get data from myapifilms in JSON/XML/JSONP format. Tweak custom URL according to need.
#CAUTION: DON'T RUN -getid and -getinfo together in same argument rather use separate windows!!
########################################################################
#CONFIG
########################################################################
#get rootdir - set all paths in releavance to this dir
filepath=`readlink -f $0`;
rootdir=${filepath%/*};
#echo $rootdir;

#text file locations
list_imdb_id="$rootdir/list_imdb_id.txt"; #media ids
list_name_id="$rootdir/list_name_id.txt"; #people ids
list_char_id="$rootdir/list_char_id.txt"; #character ids

#data storage - JSON/XML
store_format="JSON";
store_data="$rootdir/data";

query_imdb="www.imdb.com/";
query_omdbapi="http://www.omdbapi.com/?r=$store_format&plot=full&tomatoes=true"; #&i=id #all info together #searches only by id/title
query_myapifilms="http://www.myapifilms.com/imdb?actors=F&actorTrivia=0&format=$store_format&aka=1&business=1&filmography=0&movieTrivia=1&technical=1&seasons=1&trailer=1&uniqueName=1";

########################################################################
#Existance Checks
########################################################################
if [ -f $list_imdb_id ];
then true; #echo "Found $list_imdb_id";
else
	echo "Creating $list_imdb_id";
	touch $list_imdb_id;
	#fill $list_imdb_id with some movie ids to start - wget imdb main page and add as many found
	wget "www.imdb.com" -O "$rootdir/index.html";
	cat "$rootdir/index.html" | grep -o -P "tt[0123456789][0123456789][0123456789][0123456789][0123456789][0123456789][0123456789]" > "$list_imdb_id"
	rm "$rootdir/index.html";
fi;

if [ -f $list_name_id ];
then true; #echo "Found $list_name_id";
else
	echo "Creating $list_name_id";
	touch $list_name_id;
	#fill $list_name_id with some name ids to start - wget imdb main page and add as many found
	wget "www.imdb.com" -O "$rootdir/index.html";
	cat "$rootdir/index.html" | grep -o -P "nm[0123456789][0123456789][0123456789][0123456789][0123456789][0123456789][0123456789]" > "$list_name_id"
	rm "$rootdir/index.html";
fi;

if [ -f $list_char_id ];
then true; #echo "Found $list_char_id";
else
	echo "Creating $list_char_id";
	touch $list_char_id;
	#fill $list_char_id with some character ids to start - wget imdb main page and add as many found
	wget "www.imdb.com" -O "$rootdir/index.html";
	cat "$rootdir/index.html" | grep -o -P "ch[0123456789][0123456789][0123456789][0123456789][0123456789][0123456789][0123456789]" > "$list_char_id";
	rm "$rootdir/index.html";
fi;

if [ -d $store_data ];
then true;	#echo "Found $store_data";
else
	echo "Creating $store_data";
	mkdir $store_data;
fi;

#echo "Ready to run! ARGS: -getid/-getinfo/-print";
#echo "You selected $1";

########################################################################
#ARGUMENTS
########################################################################

case "$1" in
########################################################################
'-getid')
	#selecting queryurl and list of ids to query
	if [ "$2" = "title" ]; #search by titles
	then
		queryurl=$query_imdb"title/";
		list_ids=$list_imdb_id;
	elif [ "$2" = "people" ]; #search by people
	then
		queryurl=$query_imdb"name/";
		list_ids=$list_name_id;
	elif [ "$2" = "character" ]; #search by characters
	then
		queryurl=$query_imdb"character/";
		list_ids=$list_char_id;
	else 					#default = Invalid/none
		queryurl=$query_imdb"title/";
		list_ids=$list_imdb_id;
	fi

	while read line;
	do
		#displayinfo
		wc -l $list_imdb_id; #KEEP TRACK HOW MANY MOVIE IDS LISTED TILL NOW.
		wc -l $list_name_id; #KEEP TRACK HOW MANY people IDS LISTED TILL NOW.
		wc -l $list_char_id; #KEEP TRACK HOW MANY people IDS LISTED TILL NOW.
		echo "Total data:"; ls $store_data | wc -l;

		#get some movie ids from list_imdb_id and search those pages for more, put new uniq ones back.

		echo "Getting ids from IMDb.com...";
		echo "QUERYURL: $queryurl$line";

		#getting the IMDb page for id in $line from listid.txt
		wget "$queryurl$line" --user-agent="User-Agent: Mozilla/5.0 (Windows NT 5.1; rv:23.0) Gecko/20100101 Firefox/23.0" -O "$rootdir/index.html";
		#getting * relevant ids from the page
		cat "$rootdir/index.html" | grep -o -P "tt[0123456789][0123456789][0123456789][0123456789][0123456789][0123456789][0123456789]" >> temp_imdb_id; #temp holds found ids
		cat "$rootdir/index.html" | grep -o -P "nm[0123456789][0123456789][0123456789][0123456789][0123456789][0123456789][0123456789]" >> temp_name_id; #temp holds found ids
		cat "$rootdir/index.html" | grep -o -P "ch[0123456789][0123456789][0123456789][0123456789][0123456789][0123456789][0123456789]" >> temp_char_id; #temp holds found ids

		#sorting/cleaning= only keeping uniq ids
		cat "$list_imdb_id" >> temp_imdb_id; #adding list to temp and uniq-fying
		sort temp_imdb_id | uniq > "$list_imdb_id";

		cat "$list_name_id" >> temp_name_id;
		sort temp_name_id | uniq > "$list_name_id";

		cat "$list_char_id" >> temp_char_id;
		sort temp_char_id | uniq > "$list_char_id";

		#remove temps
		rm temp_*;

		#sleep random 0-30secs #reduces server load
		sleeptime=$RANDOM;
		let "sleeptime %=30";
		echo "Sleeping for "$sleeptime;
		sleep $sleeptime;

		echo "\n\n"
		clear;
		#cleanup
		rm "$rootdir/index.html"; #[this file is html from IMDb, not relevant]
	done < "$list_ids";
;;
########################################################################
'-getinfo')
	#gets info by imdb_ids
	#get movie-id from $list_imdb_id, get info for that id from api
	while read line;
	do
		#queryurl=$query_omdbapi"&i=$line";
		queryurl=$query_myapifilms"&idIMDB=$line";
		##displayinfo
		wc -l $list_imdb_id; #KEEP TRACK HOW MANY MOVIE IDS LISTED TILL NOW.
		#wc -l $list_name_id; #KEEP TRACK HOW MANY people IDS LISTED TILL NOW.
		#wc -l $list_char_id; #KEEP TRACK HOW MANY people IDS LISTED TILL NOW.
		echo "Total data:"; ls $store_data | wc -l;

		#check if file exists @XMLholder
		if [ -f "$store_data/$line.$store_format" ];
		then
			echo "File:$line.$store_format already Exists!\n\n";
		else
			echo "Getting info from omdbapi.com...";
			echo "QUERYURL: $queryurl";
			#get file from imdbapi.org
			wget --user-agent="User-Agent: Mozilla/5.0 (Windows NT 5.1; rv:23.0) Gecko/20100101 Firefox/23.0" $queryurl -O "$store_data/$line.$store_format"; #custom=>imdbapi-doc
			echo "File:$line.$store_format saved.";

			#sleep random 0-30secs #reduces server load
			sleeptime=$RANDOM;
			let "sleeptime %=30";
			echo "Sleeping for "$sleeptime
			sleep $sleeptime;
		fi
		echo "\n\n"
		clear;
	done < "$list_imdb_id";
;;
########################################################################
'-print')
	#displayinfo
	wc -l $list_imdb_id #KEEP TRACK HOW MANY MOVIE IDS LISTED TILL NOW.
	wc -l $list_name_id #KEEP TRACK HOW MANY people IDS LISTED TILL NOW.
	wc -l $list_char_id #KEEP TRACK HOW MANY people IDS LISTED TILL NOW.
	echo "Total data:"; ls $store_data | wc -l
;;
########################################################################
*)
	echo "None/Invalid argument. Please check usage."
;;
########################################################################
esac