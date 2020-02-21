#!/bin/bash

#========================== Initialization ====================================
# Output all to log and screen.
exec &> >(tee -a "alfresco-installer.log")

# Color variables
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgre=${txtbld}$(tput setaf 2) #  green
bldblu=${txtbld}$(tput setaf 4) #  blue
txtrst=$(tput sgr0)             # Reset
warn=${bldred}"!!WARNING!!"${txtrst}

echoblue () {
  echo "${bldblu}$1${txtrst}"
}
echogreen () {
  echo "${bldgre}$1${txtrst}"
}
echored () {
  echo "${bldred}$1${txtrst}"
}
readblue () {
	read -p "${bldblu}$1${txtrst}" $2
}
readgreen () {
	read -p "${bldgre}$1${txtrst}" $2
}
readred () {
	read -p "${bldred}$1${txtrst}" $2
}

installJava () {
  readblue "What is the Java home folder name? [jdk]" java_root
  case $java_root in
    "" ) java_root=jdk; break;;
    * ) break;;
  esac

  java_path=$2/$java_root      #Java

	echogreen "Installing Java to $java_path"

	cd $2

	# Install java and configure it.
	tar zxf $1/openjdk-11.*
	mv $2/jdk-11.* $java_path
	echo "export PATH=$PATH:$java_path/bin" >> ~/.bash_profile
	echo "export JAVA_HOME=$java_path" >> ~/.bash_profile
	source ~/.bash_profile
}

#========================== Initialization END ================================

echogreen "===================================================================="
echogreen ""
echogreen "Project:     Alfresco 6.2 Enterprise RHEL 7 Installer"
echogreen "Company:		Alfresco"
echogreen "Developer:	Richard Holt, Jr. (Chad)"
echogreen "https://github.com/rholtalfresco/ACS62-Installer-RHEL"
echogreen ""
echogreen "===================================================================="

#========================== Variables =========================================

readblue "Where would you like to install Alfresco? [~]" alf_home
case $alf_home in
	"" ) alf_home=~; break;;
  * ) break;;
esac

sh_dir=$(pwd)

# Set root directory names

readblue "What is the ACS home folder name? [ACS]" alf_root
case $alf_root in
	"" ) alf_root=ACS; break;;
  * ) break;;
esac

readblue "What is the Tomcat home folder name? [tomcat]" tomcat_root
case $tomcat_root in
	"" ) tomcat_root=tomcat; break;;
  * ) break;;
esac

readblue "What is the ActiveMQ home folder name? [activemq]" amq_root
case $amq_root in
	"" ) amq_root=activemq; break;;
  * ) break;;
esac

readblue "What is the ASMS home folder name? [alfresco-search-services]" solr_root
case $solr_root in
	"" ) solr_root=alfresco-search-services; break;;
  * ) break;;
esac

installer_root=installers            # Installer

# Set paths to the root directories
alf_path=$alf_home/$alf_root                  # ACS
tomcat_path=$alf_home/$alf_root/$tomcat_root  # Tomcat
amq_path=$alf_home/$alf_root/$amq_root        # ActiveMQ
solr_path=$alf_home/$alf_root/$solr_root      # Solr
installer_path=$sh_dir/$installer_root        # Installer

# catalina.properties custom line.
shared_loader_string="shared.loader=$tomcat_root/shared/classes,$tomcat_root/shared/lib/*.jar" 

# IP address for local computer
local_ip=$(ifconfig eth0 | sed -n 's/.*inet \([0-9.]\+\)\s.*/\1/p') 

#========================== Variables END =====================================

#========================== End User Agreement ================================

echogreen ""
readgreen "Please accept the Alfresco End User Agreement to install"
echogreen ""
cat $installer_path/AlfrescoEndUserAgreement.txt
while true; do
  readblue "Do you accept the Alfresco End User Agreement? [y]" yn
  case $yn in
  	"" | [Yy] ) break;;
    * ) echored "You need to accept to continue";;
  esac
done

#========================== End User Agreement END ============================

#========================== ACS Install =======================================

echogreen "Installing ACS to $alf_path"

# This will be where the ACS root will be located
cd $alf_home

# Make and enter the ACS root
mkdir $alf_root
cd $alf_path

# Unzip ACS Distribution zip
unzip -qqo $installer_path/alfresco-content-services-distribution-6.2.0.zip

# Make the extra folders and paths
mkdir $alf_path/modules $alf_path/modules/share $alf_path/modules/platform

#========================== ACS END ===========================================

#========================== Tomcat Install ====================================

echogreen "Installing Tomcat to $tomcat_path"

# Untar Tomcat
tar zxf $installer_path/apache-tomcat-8*
mv apache-tomcat-8* $tomcat_root

# Make the extra folders and paths
mkdir $tomcat_path/shared $tomcat_path/shared/classes $tomcat_path/shared/lib

cp -avr $alf_path/web-server/lib/* $tomcat_path/lib/
#cp -avr $installer_path/mysql-connector-java-5.1.48-bin.jar $tomcat_path/lib/

# Customize the catalina.properties
sed -i "s~shared.loader=~$shared_loader_string~g" $tomcat_path/conf/catalina.properties

# Delete and copy the alfresco web to tomcat
rm -rf $tomcat_path/webapps/*
cp -avr $alf_path/web-server/webapps/* $tomcat_path/webapps/
cp -avr $alf_path/web-server/conf/* $tomcat_path/conf/
cp -avr $alf_path/web-server/shared/classes/* $tomcat_path/shared/classes/

# Setup the alfresco-global.properties
mv $tomcat_path/shared/classes/alfresco-global.properties.sample $tomcat_path/shared/classes/alfresco-global.properties
echo "" >> $tomcat_path/shared/classes/alfresco-global.properties
echo "localname=$local_ip" >> $tomcat_path/shared/classes/alfresco-global.properties
cat $installer_path/alfresco-global.properties.standard >> $tomcat_path/shared/classes/alfresco-global.properties

#========================== Tomcat END ========================================

#========================== ActiveMQ Install ==================================

echogreen "Installing ActiveMQ to $amq_path"

# Untar ActiveMQ
tar zxf $installer_path/apache-activemq-5*
mv apache-activemq-5* $amq_root

#========================== ActiveMQ END ======================================

#========================== ASMS Install ======================================

echogreen "Installing ASMS to $solr_path"

# Unzip ASMS
unzip -qqo $installer_path/alfresco-search-services*
#mv alfresco-search-services* $solr_root

# Customize solrcore.properties
sed -i "s/alfresco.secureComms=https/alfresco.secureComms=none/" $solr_path/solrhome/templates/rerank/conf/solrcore.properties

#========================== ASMS END ==========================================

#========================== Java Install ======================================

if ![ -x "$(command -v java)" ]; then
	readred "${warn} Java not installed. Would you like to install Java? [y] ${warn}" yn
    case $yn in
    	"" | [Yy]* ) installJava $installer_path $alf_path ; break;;
		[Nn]* ) exit 1;;
    * ) echored "${warn} Please state Yes or No. Java is needed to run Alfresco. ${warn}";;
	esac
fi

#========================== Java END ==========================================

#========================== Additional Configuration ==========================

echogreen "Applying AMPs"
cd $alf_path/bin/
$alf_path/jdk/bin/java -jar alfresco-mmt.jar install $alf_path/amps/alfresco-share-services.amp $tomcat_path/webapps/alfresco.war

#========================== Additional Configuration END ======================

#========================== Solr Initial Start ================================

echogreen "Starting SOLR for the first time"
$solr_path/solr/bin/solr start -a "-Dcreate.alfresco.defaults=alfresco,archive"

echogreen "Stopping SOLR"
$solr_path/solr/bin/solr stop

#========================== Solr Initial Start END ============================