#!/bin/bash

set -o nounset
set -o errexit
set -o pipefail

OCP_VERSION=4.11
OCS_VERSION=4.11
CLUSTER_NAME=$(cat "${SHARED_DIR}/CLUSTER_NAME")
CLUSTER_DOMAIN="${CLUSTER_DOMAIN:-release-ci.cnv-qe.rhood.us}"
LOGS_FOLDER="${ARTIFACT_DIR}/ocs-tests"
LOGS_CONFIG="${LOGS_FOLDER}/ocs-tests-config.yaml"
CLUSTER_PATH="${ARTIFACT_DIR}/ocs-tests"


mkdir -p "${LOGS_FOLDER}"
mkdir -p "${CLUSTER_PATH}/auth"
mkdir -p "${CLUSTER_PATH}/data"

cp -v "${KUBECONFIG}"              "${CLUSTER_PATH}/auth/kubeconfig"
cp -v "${KUBEADMIN_PASSWORD_FILE}" "${CLUSTER_PATH}/auth/kubeadmin-password"

# Create ocs-tests config overwrite file
cat > "${LOGS_CONFIG}" << __EOF__
---
RUN:
  log_dir: "${LOGS_FOLDER}"
__EOF__


set -x
START_TIME=$(date "+%s")

run-ci --color=yes tests/ -m acceptance -k '' \
  --ocsci-conf "${LOGS_CONFIG}" \
  --ocs-version "${OCS_VERSION}" \
  --ocp-version "${OCP_VERSION}" \
  --cluster-path "${CLUSTER_PATH}" \
  --cluster-name "${CLUSTER_NAME}" \
  --junit-xml "${CLUSTER_PATH}/junit.xml" || /bin/true

FINISH_TIME=$(date "+%s")
DIFF_TIME=$((FINISH_TIME-START_TIME))
set +x

if [[ ${DIFF_TIME} -le 3600 ]]; then
    echo ""
    echo " 🚨  The tests finished too quickly (took only: ${DIFF_TIME} sec), pausing here to give us time to debug"
    echo "  😴 😴 😴"
    sleep 7200
    exit 1
else
    echo "Finished in: ${DIFF_TIME} sec"
fi
