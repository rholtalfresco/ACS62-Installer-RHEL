#!/bin/bash

local_ip=$(ifconfig eth0 | sed -n 's/.*inet \([0-9.]\+\)\s.*/\1/p')
installer_path=../installers
alf_root=ACS62Testing
tomcat_root=tomcat
amq_root=activemq
solr_root=alfresco-search-services
shared_loader_string="shared.loader=$tomcat_root/shared/classes,$tomcat_root/shared/lib/*.jar"

#Does all of this in the home directory
cd ~

mkdir $alf_root

cd $alf_root
unzip $installer_path/alfresco-content-services-distribution-6.2.0.zip
tar zxvf $installer_path/apache-tomcat-8*
mv apache-tomcat-8* $tomcat_root
tar zxvf $installer_path/apache-activemq-5*
mv apache-activemq-5* $amq_root
unzip $installer_path/alfresco-search-services*
#mv alfresco-search-services* $solr_root

#Comment if java is already installed
tar zxvf $installer_path/openjdk-11.*
mv jdk-11.* jdk
export PATH=$PATH:./jdk/bin

mkdir modules modules/share modules/platform

cd tomcat
tomcat_root=$(pwd)
mkdir shared shared/classes shared/lib

sed -i "s~shared.loader=~$shared_loader_string~g" conf/catalina.properties
cp -avr ../$installer_path/mysql-connector-java-5.1.48-bin.jar ./lib/
rm -rf ./webapps/*
cp -avr ../web-server/webapps/* ./webapps/
cp -avr ../web-server/conf/* ./conf/
#cp -avr ../web-server/lib/* ./lib/
cp -avr ../web-server/shared/classes/* ./shared/classes/
mv ./shared/classes/alfresco-global.properties.sample ./shared/classes/alfresco-global.properties
echo "" >> ./shared/classes/alfresco-global.properties
echo "localname=$local_ip" >> ./shared/classes/alfresco-global.properties
cat ../$installer_path/alfresco-global.properties.standard >> ./shared/classes/alfresco-global.properties

cd ../bin/
../jdk/bin/java -jar alfresco-mmt.jar install ../amps/alfresco-share-services.amp $tomcat_root/webapps/alfresco.war

cd ../$solr_root
solr_root=$(pwd)

cd $solr_root/solrhome/templates/rerank/conf/
sed -i "s/alfresco.secureComms=https/alfresco.secureComms=none/" solrcore.properties

$solr_root/solr/bin/solr start -a "-Dcreate.alfresco.defaults=alfresco,archive"
$solr_root/solr/bin/solr stop