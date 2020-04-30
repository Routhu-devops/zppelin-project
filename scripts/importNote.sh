#!/bin/bash
set -x

if [ $# -lt 2 ] ; then
	echo "You must provide these parameters:"
	echo "   notebook JSON file name"
	echo "   Zeppelin URL"
	exit 1
fi

JSON_FILE=$1
ZEP_URL=$2

if [ ! -f ${JSON_FILE} ] ; then
	echo "ERROR: Invalid file name ${JSON_FILE}"
	exit 1
fi

if [ ! -d bin ] ; then
	echo "ERROR: Zeppelin directory bin/ does not exist!"
	exit 1
fi
echo "Check if zeppelin is running"
pgrep -f ZeppelinServer

NOTEBOOK_NAME=`cat /opt/zeppelin/spark-zeppelin/testScripts/resources/MeasureAgentBeanLoaderExamples.json | jq '.name'`
if [ "${NOTEBOOK_NAME}" == "null" ] ; then
	echo "ERROR: No notebook defined in ${JSON_FILE}"
	exit 1
fi
#Find Notebook name
#NOTEBOOK_NAME=`python /opt/zeppelin/spark-zeppelin/testScripts/runNote.py /opt/zeppelin/spark-zeppelin/testScripts/resources/MeasureAgentBeanLoaderExamples.json name`
#echo "NOTEBOOK_NAME"

#Importing Notebbok
echo "Importing notebook ${NOTEBOOK_NAME} from ${JSON_FILE} to ${ZEP_URL}"
echo -n "{\"notebookName\":${NOTEBOOK_NAME},\"result\":" > import.log

curl -X POST -d @/opt/zeppelin/spark-zeppelin/testScripts/resources/MeasureAgentBeanLoaderExamples.json http://${ZEP_URL}:8080/api/notebook/import >> import.log
echo "}" >> import.log

# use Jq to read JSON
NOTEBOOK_ID=`cat /opt/zeppelin/spark-zeppelin/import.log | jq '.result .body' | cut -d '"' -f 2`
if [ $? -ne 0 ] ; then
	echo "Import failed for notebook ${NOTEBOOK_NAME}"
	exit 1
fi
if [ ! -d logs ] ; then
    mkdir logs
fi
echo -n "<html><h2>Status</h2><body><p>" > logs/result_${NOTEBOOK_NAME}.html
echo "Import succeeded for ${NOTEBOOK_NAME} with new notebook URL: " >> logs/result_${NOTEBOOK_NAME}.html
echo "<a href=\"${ZEP_URL}/#/notebook/${NOTEBOOK_ID}\">${NOTEBOOK_ID}</a>" >> logs/result_${NOTEBOOK_NAME}.html
echo "</p></body></html>" >> logs/Examples.html

sleep 20
echo "Executing zeppelin Notebook"
NOTEBOOK_NAME=`cat /opt/zeppelin/spark-zeppelin/import.log | jq '.notebookName'`
if [ "${NOTEBOOK_NAME}" == "null" ] ; then
    echo "ERROR: No notebook defined in ${JSON_FILE}"
    exit 1
fi
# use Jq to read JSON
NOTEBOOK_ID=`cat /opt/zeppelin/spark-zeppelin/import.log | jq '.result .body' | cut -d '"' -f 2`
if [ $? -ne 0 ] ; then
    echo "Execution failed"
    exit 1
fi
echo "Executing notebook ${NOTEBOOK_NAME} from ${ZEP_URL}"

echo -n "{\"notebookName\":${NOTEBOOK_NAME},\"result\":" > run.log
curl -X POST ${ZEP_URL}:8080/api/notebook/job/${NOTEBOOK_ID} >> run.log
echo "}" >> run.log

echo -n "{\"notebookName\":${NOTEBOOK_NAME},\"result\":" > run1.log
curl -X GET ${ZEP_URL}:8080/api/notebook/job/${NOTEBOOK_ID}  >> run1.log
echo "}" >> run1.log
PARAGRAPH_IDS=`cat run1.log | jq '.result .body [] .id' | cut -d '"' -f 2`
i=0
for paragraph in "${PARAGRAPH_IDS}"; do
	echo "i == ${i}"
	echo "paragraph == ${paragraph}"
    PARAGRAPH_STATUS=`cat run1.log | jq '.result .body [] .status' | cut -d '"' -f 2`
	echo "PARAGRAPH_STATUS == ${PARAGRAPH_STATUS}"

    if [ "SUCCESS" != "${PARAGRAPH_STATUS}" ] ; then
        echo "Paragraph ${i} failed with status ${PARAGRAPH_STATUS}"
        exit 1
    fi
    echo "Paragraph ${i} succeeded with status ${PARAGRAPH_STATUS}"
    ((i++))
    exit 0
done
