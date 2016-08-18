#!/bin/bash
set -o

# extract the SWT jars
SWT_ZIP=/opt/idart/swt.zip
if [ -f $SWT_ZIP ];
then
   echo "Extracting $SWT_ZIP."
   unzip -o $SWT_ZIP -d ./lib
   rm $SWT_ZIP
fi

CLASSPATH=$CLASSPATH:/usr/lib/

for jarfile in /opt/idart/lib/*.jar
do
	CLASSPATH=$CLASSPATH:$jarfile
done

/opt/idart/wait-for-it.sh --timeout=90 idart-postgres:5432

java -cp $CLASSPATH:/opt/idart/Pharmacy.jar -Djava.library.path=/opt/idart/ -Xms128m -Xmx1024m org.celllife.idart.start.PharmacyApplication
