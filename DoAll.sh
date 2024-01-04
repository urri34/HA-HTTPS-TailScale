#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NOCOLOR='\033[0m'
date>>$0.log

##################
## CONTAINER_ID ##
##################
echo -e "${GREEN}[OK]:${NOCOLOR} Getting container id for tailscale ..."
Command="docker ps"
echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
Return=`bash -c "$Command" 2>&1 | tee -a $0.log`
CONTAINER_ID=`echo "$Return"|grep tailscale|cut -f1 -d" "|head -1|strings`
if [[ ${#CONTAINER_ID} -eq 12 ]]
then
	echo -e "${GREEN}[OK]:${NOCOLOR} Container ID is $CONTAINER_ID"|tee -a $0.log
else
	echo -e "${RED}[KO]:${NOCOLOR} Container ID is not a valid 12 digits id \"$CONTAINER_ID\""|tee -a $0.log
	exit 1
fi

##################
## TAILSCALE_IP ##
##################
echo -e "${GREEN}[OK]:${NOCOLOR} Getting tailscale ip ..."
IPRX='([1-9]?[0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])'
Command="docker exec -it $CONTAINER_ID /opt/tailscale ip"
echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
Return=`bash -c "$Command" 2>&1 | tee -a $0.log`
TAILSCALE_IP=`echo "$Return"|head -1|strings`
if [[ $TAILSCALE_IP =~ ^$IPRX\.$IPRX\.$IPRX\.$IPRX$ ]]; then
  echo -e "${GREEN}[OK]:${NOCOLOR} Taiscale IP address is $TAILSCALE_IP"|tee -a $0.log
else
  echo -e "${RED}[KO]:${NOCOLOR} Taiscale IP address is not valid \"$TAILSCALE_IP\""|tee -a $0.log
  exit 1
fi

#####################
## TAILSCALE_REVIP ##
#####################
echo -e "${GREEN}[OK]:${NOCOLOR} Getting tailscale reverse ip ..."
TAILSCALE_REVIP=`echo $TAILSCALE_IP|awk -F. '{print $4"."$3"."$2"."$1}'`
if [[ $TAILSCALE_REVIP =~ ^$IPRX\.$IPRX\.$IPRX\.$IPRX$ ]]; then
  echo -e "${GREEN}[OK]:${NOCOLOR} Taiscale reverse IP address is $TAILSCALE_REVIP"|tee -a $0.log
else
  echo -e "${RED}[KO]:${NOCOLOR} Taiscale reverse IP address is not valid \"$TAILSCALE_REVIP\""|tee -a $0.log
  exit 1
fi

#####################
## TAILSCALE_FQDN1 ##
#####################
echo -e "${GREEN}[OK]:${NOCOLOR} Getting tailscale fqdn (using method 1) ..."
Command="docker exec -it $CONTAINER_ID /usr/bin/nslookup $TAILSCALE_IP 100.100.100.100"
echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
Return=`bash -c "$Command" 2>&1 | tee -a $0.log`
TAILSCALE_FQDN1=`echo "$Return"|grep $TAILSCALE_REVIP|tr -s " "|cut -f3 -d" "|head -1|strings`
if [[ `echo $TAILSCALE_FQDN1|grep ".ts.net"|wc -l` -eq 1 ]]
then
  echo -e "${GREEN}[OK]:${NOCOLOR} Taiscale FQDN1 is $TAILSCALE_FQDN1"|tee -a $0.log
else
  echo -e "${RED}[KO]:${NOCOLOR} Taiscale FQDN1 is not valid \"$TAILSCALE_FQDN1\""|tee -a $0.log
  exit 1
fi

#####################
## TAILSCALE_FQDN2 ##
#####################
echo -e "${GREEN}[OK]:${NOCOLOR} Getting tailscale fqdn (using method 2) ..."
Command="docker exec -it $CONTAINER_ID /opt/tailscale cert"
echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
Return=`bash -c "$Command" 2>&1 | tee -a $0.log`
TAILSCALE_FQDN2=`echo "$Return"|grep "For domain, use"|cut -f2 -d"\""|head -1|strings`
if [[ `echo $TAILSCALE_FQDN2|grep ".ts.net"|wc -l` -eq 1 ]]
then
  echo -e "${GREEN}[OK]:${NOCOLOR} Taiscale FQDN2 is $TAILSCALE_FQDN2"|tee -a $0.log
else
  echo -e "${RED}[KO]:${NOCOLOR} Taiscale FQDN2 is not valid \"$TAILSCALE_FQDN\""|tee -a $0.log
  exit 1
fi

########################################
## TAILSCALE_FQDN1 VS TAILSCALE_FQDN2 ##
########################################
echo -e "${GREEN}[OK]:${NOCOLOR} Comparing tailscale fqdn (using both methods) ..."
if [[ $TAILSCALE_FQDN1 == $TAILSCALE_FQDN2 ]]
then
  echo -e "${GREEN}[OK]:${NOCOLOR} Taiscale FQDN1 is Taiscale FQDN2"|tee -a $0.log
else
  echo -e "${RED}[KO]:${NOCOLOR} Taiscale FQDN1 is not FQDN2"|tee -a $0.log
  exit 1
fi

##################
## GENETARE CRT ##
##################
if [[ -f $TAILSCALE_FQDN1.crt ]]
then
	echo -e "${GREEN}[OK]:${NOCOLOR} Deleting old $TAILSCALE_FQDN1.crt ..."
	Command="rm -f $TAILSCALE_FQDN1.crt"
	echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
	Return=`bash -c "$Command" 2>&1 | tee -a $0.log`
fi
echo -e "${GREEN}[OK]:${NOCOLOR} Generating $TAILSCALE_FQDN1.crt ..."
Command="docker exec -it $CONTAINER_ID /opt/tailscale cert --cert-file - $TAILSCALE_FQDN1"
echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
Return=`bash -c "$Command" 2>&1 | tee -a $0.log > $TAILSCALE_FQDN1.crt`
if [[ -f $TAILSCALE_FQDN1.crt ]]
then
	echo -e "${GREEN}[OK]:${NOCOLOR} Generated $TAILSCALE_FQDN1.crt ..."
	Command="ls -la $TAILSCALE_FQDN1.crt"
	echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
	Return=`bash -c "$Command" 2>&1 | tee -a $0.log`
	echo -e "${GREEN}[OK]:${NOCOLOR} $Return"
else
	echo -e "${GREEN}[OK]:${NOCOLOR} Unable to generate $TAILSCALE_FQDN1.crt"
	exit 1
fi

##################
## GENETARE KEY ##
##################
if [[ -f $TAILSCALE_FQDN1.key ]]
then
	echo -e "${GREEN}[OK]:${NOCOLOR} Deleting old $TAILSCALE_FQDN1.key ..."
	Command="rm -f $TAILSCALE_FQDN1.key"
	echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
	Return=`bash -c "$Command" 2>&1 | tee -a $0.log`
fi
echo -e "${GREEN}[OK]:${NOCOLOR} Generating $TAILSCALE_FQDN1.key ..."
Command="docker exec -it $CONTAINER_ID /opt/tailscale cert --key-file - $TAILSCALE_FQDN1"
echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
Return=`bash -c "$Command" 2>&1 | tee -a $0.log > $TAILSCALE_FQDN1.key`
if [[ -f $TAILSCALE_FQDN1.key ]]
then
	echo -e "${GREEN}[OK]:${NOCOLOR} Generated $TAILSCALE_FQDN1.key ..."
	Command="ls -la $TAILSCALE_FQDN1.key"
	echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
	Return=`bash -c "$Command" 2>&1 | tee -a $0.log`
	echo -e "${GREEN}[OK]:${NOCOLOR} $Return"
else
	echo -e "${GREEN}[OK]:${NOCOLOR} Unable to generate $TAILSCALE_FQDN1.key"
	exit 1
fi

##################
## GENETARE PEM ##
##################
if [[ -f $TAILSCALE_FQDN1.pem ]]
then
	echo -e "${GREEN}[OK]:${NOCOLOR} Deleting old $TAILSCALE_FQDN1.pem ..."
	Command="rm -f $TAILSCALE_FQDN1.pem"
	echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
	Return=`bash -c "$Command" 2>&1 | tee -a $0.log`
fi
echo -e "${GREEN}[OK]:${NOCOLOR} Generating $TAILSCALE_FQDN1.pem ..."
Command="/usr/bin/openssl pkcs8 -topk8 -nocrypt -in $TAILSCALE_FQDN1.key -out $TAILSCALE_FQDN1.pem"
echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
Return=`bash -c "$Command" 2>&1 | tee -a $0.log`
if [[ -f $TAILSCALE_FQDN1.pem ]]
then
	echo -e "${GREEN}[OK]:${NOCOLOR} Generated $TAILSCALE_FQDN1.pem ..."
	Command="ls -la $TAILSCALE_FQDN1.pem"
	echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
	Return=`bash -c "$Command" 2>&1 | tee -a $0.log`
	echo -e "${GREEN}[OK]:${NOCOLOR} $Return"
	echo -e "${GREEN}[OK]:${NOCOLOR} Deleting old $TAILSCALE_FQDN1.key ..."
	Command="rm -f $TAILSCALE_FQDN1.key"
	echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
	Return=`bash -c "$Command" 2>&1 | tee -a $0.log`
else
	echo -e "${GREEN}[OK]:${NOCOLOR} Unable to generate $TAILSCALE_FQDN1.pem"
	exit 1
fi

##################################
## INSERT IN CONFIGURATION.YAML ##
##################################
## CREATE DIR ##
if [[ ! -d /config/certs ]]
then
	echo -e "${GREEN}[OK]:${NOCOLOR} Creating /config/certs ..."
	Command="mkdir /config/certs"
	echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
	Return=`bash -c "$Command" 2>&1 | tee -a $0.log`
fi
## MOVE CRT ##
echo -e "${GREEN}[OK]:${NOCOLOR} Moving $TAILSCALE_FQDN1.crt ..."
Command="mv $TAILSCALE_FQDN1.crt /config/certs/$TAILSCALE_FQDN1.crt"
echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
Return=`bash -c "$Command" 2>&1 | tee -a $0.log`
## MOVE PEM ##
echo -e "${GREEN}[OK]:${NOCOLOR} Moving $TAILSCALE_FQDN1.pem ..."
Command="mv $TAILSCALE_FQDN1.pem /config/certs/$TAILSCALE_FQDN1.pem"
echo -e "${GREEN}[OK]:${NOCOLOR} Executing: \"$Command\""|tee -a $0.log
Return=`bash -c "$Command" 2>&1 | tee -a $0.log`
##INSERT
echo -e "${GREEN}[OK]:${NOCOLOR} Inserting in configuration.yaml ..."
if [[ `cat /config/configuration.yaml|grep "ssl_certificate:"|head -1|strings|wc -l` -eq 1 ]]
then
	echo -e "${YELLOW}[WR]:${NOCOLOR} ssl_certificate already present in configuration.yaml"
	line=`cat /config/configuration.yaml|grep "ssl_certificate:"|head -1|strings`
	echo -e "${YELLOW}[WR]:${NOCOLOR} \"$line\""
	rep="  ssl_certificate: /config/certs/$TAILSCALE_FQDN1.crt"
	sed "s|$line|$ret|g" config/configuration.yaml
	
	if [ `cat /config/configuration.yaml|grep "ssl_key:"|head -1|strings|wc -l` -eq 1 ]
	then
		echo -e "${YELLOW}[WR]:${NOCOLOR} ssl_key already present in configuration.yaml"
		line=`cat /config/configuration.yaml|grep "ssl_key:"|head -1|strings`
		echo -e "${YELLOW}[WR]:${NOCOLOR} \"$line\""
		rep="  ssl_key: /config/certs/$TAILSCALE_FQDN1.key"
		#sed "s|\$line|${rep}|" /config/configuration.yaml
	else
		echo "${RED}[KO]:${NOCOLOR} Inconsistent presence of ssl_certificate but not of ssl_key in /config/configuration.yaml"
	fi
else
	echo "ssl_certificate not present in configuration.yaml"
	line=`cat /config/configuration.yaml|grep "ssl_certificate:"|head -1|strings`
	rep="  ssl_certificate: /config/certs/$TAILSCALE_FQDN1.crt"
	sed -i.bak "s/${line}/${rep}/g" /config/configuration.yaml
	if [ `cat /config/configuration.yaml|grep "ssl_key:"|head -1|strings|wc -l` -eq 1 ]
	then
		echo "ssl_key already present in configuration.yaml"
		line=`cat /config/configuration.yaml|grep "ssl_key:"|head -1|strings`
		rep="  ssl_key: /config/certs/$TAILSCALE_FQDN1.key"
		sed -i.bak "s/${line}/${rep}/g" /config/configuration.yaml
	else
		echo "${RED}[KO]:${NOCOLOR}Inconsistent presence of ssl_certificate but not of ssl_key in /config/configuration.yaml"
	fi
fi