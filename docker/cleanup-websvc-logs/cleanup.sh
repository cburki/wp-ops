#!/bin/sh

set -e

NAMESPACE=$1

DC=$(oc -n ${NAMESPACE} get deploymentconfig -o custom-columns=NAME:.metadata.name --no-headers | grep httpd | sed 's/httpd-//g')

for dc in ${DC}; do
    echo "+++ Cleaning up dc httpd-${dc}"
    PODS=$(oc -n ${NAMESPACE} get pod -o custom-columns=NAME:.metadata.name --no-headers | grep httpd-${dc})

    for pod in ${PODS}; do
        FILEBEAT=$(oc -n ${NAMESPACE} get pod ${pod} -o jsonpath='{.spec.containers[*].name}' | grep filebeat) || true
        if [ -n "${FILEBEAT}" ]; then
           CONTAINER=filebeat-$(echo ${pod} | sed -E 's/httpd-(\S+)-.*-.*/\1/')
           echo "+++ Cleaning up webservices log in ${pod}/${CONTAINER}"
           oc -n ${NAMESPACE} exec ${pod} -c ${CONTAINER} -- find /webservices/logs -type f -mtime +${KEEPDAYS} -delete || echo "!!! Error while cleaning up"
           echo "--- Done for pod ${pod}"
        fi
    done

    echo "--- Done for dc httpd-${dc}"
done

exit 0
