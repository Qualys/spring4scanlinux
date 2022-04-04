#!/bin/sh

if [ $# -eq 0 ]; then
	BASEDIR="/"
	NETDIR_SCAN=false
elif [ $# -eq 1 ]; then
	BASEDIR=$1
	if [ ! -d $BASEDIR ];then
		echo "Please enter valid directory path";
		exit 1;
	fi;
	NETDIR_SCAN=false
elif [ $# -eq 2 ]; then
	BASEDIR=$1
	NETDIR_SCAN=$2
	if [ ! -d $BASEDIR ]; then
		echo "Please enter valid directory path";
		exit 1;
	fi;
else
	echo "Too many parameters passed in."
	echo "sh ./spring_findings.sh [base_dir] [network_filesystem_scan<true/false>]"
	echo "example: sh ./spring_findings.sh /home false"
	echo "(default: [base_dir]=/ [network_filesystem_scan]=false)"
	exit 1
fi

grepFromWarFile() {
	if test=$($1 $2 | grep -E "spring\-(beans\-|core|webflux|webmvc|boot).*.jar"); then 
		for j in $test; do 
            echo 'Path= '$2'/'$j;
		done; 
		echo "------------------------------------------------------------------------"; 
	fi; 
};

analyzeWarFiles() 
{
	echo "Script version: 1.0 (scans jar/war files)" ;
    
	id=$(id)
	if ! (echo $id | grep "uid=0")>/dev/null
	then
	echo "Please run the script as root user for complete results.." >> /usr/local/qualys/cloud-agent/spring_findings.stderr
	fi;
	
	if [ $NETDIR_SCAN = true ];then
		wars=$(find ${BASEDIR} -type f -regextype posix-egrep -iregex ".+\.(jar|war)$" 2> /dev/null);
	else
		wars=$(find ${BASEDIR} -type f -regextype posix-egrep -iregex ".+\.(jar|war)$" ! -fstype nfs ! -fstype nfs4 ! -fstype cifs ! -fstype smbfs ! -fstype gfs ! -fstype gfs2 ! -fstype safenetfs ! -fstype secfs ! -fstype gpfs ! -fstype smb2 ! -fstype vxfs ! -fstype vxodmfs ! -fstype afs -print 2>/dev/null);

	fi
	for i in $wars; do 
		if [ "$1" -eq 0 ] && [ "$2" -eq 0 ]; then 
			grep_cmd="zip -sf";
		else 
			grep_cmd="jar -tf";
		fi; 
		grepFromWarFile "$grep_cmd" $i;
		
		if temp=$(echo $i | grep ".*jar$"); then
			if [ "$1" -eq 0 ] && [ "$2" -eq 0 ]; then
				if test=$(zip -sf $i 2> /dev/null | grep "spring-cloud-function-core" | grep "pom.xml"); then
					ve=$(unzip -p $i $test 2> /dev/null | grep '<description>Spring Cloud Function Core</description>' -A5 | grep '<version>.*</version>' |   cut -d ">" -f 2 | cut -d "<" -f 1 );if [ -z "$ve" ]; then echo 'Path= $i, SpringCloudCore Version: Unknown'; else echo "Path= $i, SpringCloudCore Version: "$ve; fi;
					echo "------------------------------------------------------------------------";
				fi;
			else 
				if test=$(jar -tf $i 2> /dev/null | grep "spring-cloud-function-core" | grep "pom.xml"); then
					ve=$(jar -xf  $i $test 2> /dev/null; cat -v $test | grep '<description>Spring Cloud Function Core</description>' -A5 | grep '<version>.*</version>' |   cut -d ">" -f 2 | cut -d "<" -f 1 );if [ -z "$ve" ]; then echo 'Path= $i, SpringCloudCore Version: Unknown'; else echo "Path= $i, SpringCloudCore Version: "$ve; fi;
					echo "------------------------------------------------------------------------";
					rm -rf META-INF/;
				fi;
			fi;
		fi;
	done; 
};
if [ ! -d "/usr/local/qualys/cloud-agent/" ]; then 
    mkdir -p "/usr/local/qualys/cloud-agent/";
    chmod 750 "/usr/local/qualys/cloud-agent/";
fi; 

zip -v 2>/dev/null 1>/dev/null; isZip=$?;
unzip -v 2>/dev/null 1>/dev/null; isUnZip=$?;
	
analyzeWarFiles $isZip $isUnZip > /usr/local/qualys/cloud-agent/spring_findings.stdout 2>/usr/local/qualys/cloud-agent/spring_findings.stderr;

if [ $NETDIR_SCAN = true ];then
	springJar=$(find / -name "*.jar" -type f 2> /dev/null | grep -E "spring\-(beans\-|core|webflux|webmvc|boot).*.jar");
else
	springJar=$(find / -name "*.jar" -type f ! -fstype nfs ! -fstype nfs4 ! -fstype cifs ! -fstype smbfs ! -fstype gfs ! -fstype gfs2 ! -fstype safenetfs ! -fstype secfs ! -fstype gpfs ! -fstype smb2 ! -fstype vxfs ! -fstype vxodmfs ! -fstype afs -print 2> /dev/null | grep -E "spring\-(beans\-|core|webflux|webmvc|boot).*.jar");
fi

for i in $springJar;do  
	echo $i >> /usr/local/qualys/cloud-agent/spring_findings.stdout; 
done;
