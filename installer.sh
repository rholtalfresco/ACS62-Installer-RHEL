#!/bin/bash

###############################################################################
#
# Company:		Alfresco
# Developer:	Richard Holt, Jr. (Chad)
#
###############################################################################

# Output all to log.
exec >> alfresco-installer.log 2>&1 

# Variables
alf_home=~
sh_dir=$(pwd)

alf_root=ACS62Testing # ACS root folder name
tomcat_root=tomcat # Tomcat root folder name
amq_root=activemq # activemq root folder name
solr_root=alfresco-search-services # solr root folder name

installer_path=$sh_dir/installers # Path to where the zips and other needed files are
alf_path=$alf_home/$alf_root # Path to where Alfresco's root is
tomcat_path=$alf_home/$alf_root/$tomcat_root # Path to where Tomcat's root is
amq_path=$alf_home/$alf_root/$amq_root # Path to where ActiveMQ's root is
solr_path=$alf_home/$alf_root/$solr_root # Path to where Solr's root is

shared_loader_string="shared.loader=$tomcat_root/shared/classes,$tomcat_root/shared/lib/*.jar" # catalina.properties custom line.

local_ip=$(ifconfig eth0 | sed -n 's/.*inet \([0-9.]\+\)\s.*/\1/p') # IP address for local computer
java_version=$(java -version) # See if java is installed

# Testing
echo $java_version

# This will be where the ACS root will be located
cd $alf_home

# Make and enter the ACS root
mkdir $alf_root
cd $alf_path

# Unzip ACS Distribution zip
unzip $installer_path/alfresco-content-services-distribution-6.2.0.zip

# Untar Tomcat
tar zxvf $installer_path/apache-tomcat-8*
mv apache-tomcat-8* $tomcat_root

# Untar ActiveMQ
tar zxvf $installer_path/apache-activemq-5*
mv apache-activemq-5* $amq_root

# Unzip ASS
unzip $installer_path/alfresco-search-services*
if [ "alfresco-search-services" = "$solr_root" ]; then
	mv alfresco-search-services* $solr_root
fi

# Testing
#if [ "-bash: java: command not found" = "$java_version" ]; then
#	tar zxvf $installer_path/openjdk-11.*
#	mv jdk-11.* jdk
#	export PATH=$PATH:~/$alf_root/jdk/bin
#fi

# Make the extra folders and paths
mkdir $alf_path/modules $alf_path/modules/share $alf_path/modules/platform $tomcat_path/shared $tomcat_path/shared/classes $tomcat_path/shared/lib

sed -i "s~shared.loader=~$shared_loader_string~g" $tomcat_path/conf/catalina.properties
cp -avr $installer_path/mysql-connector-java-5.1.48-bin.jar $tomcat_path/lib/
rm -rf $tomcat_path/webapps/*
cp -avr $alf_path/web-server/webapps/* $tomcat_path/webapps/
cp -avr $alf_path/web-server/conf/* $tomcat_path/conf/
#cp -avr $alf_path/web-server/lib/* $tomcat_path/lib/
cp -avr $alf_path/web-server/shared/classes/* $tomcat_path/shared/classes/
mv $tomcat_path/shared/classes/alfresco-global.properties.sample $tomcat_path/shared/classes/alfresco-global.properties
echo "" >> $tomcat_path/shared/classes/alfresco-global.properties
echo "localname=$local_ip" >> $tomcat_path/shared/classes/alfresco-global.properties
cat $installer_path/alfresco-global.properties.standard >> $tomcat_path/shared/classes/alfresco-global.properties

cd $alf_path/bin/
$alf_path/jdk/bin/java -jar alfresco-mmt.jar install $alf_path/amps/alfresco-share-services.amp $tomcat_path/webapps/alfresco.war

sed -i "s/alfresco.secureComms=https/alfresco.secureComms=none/" $solr_path/solrhome/templates/rerank/conf/solrcore.properties

$solr_path/solr/bin/solr start -a "-Dcreate.alfresco.defaults=alfresco,archive"
$solr_path/solr/bin/solr stop