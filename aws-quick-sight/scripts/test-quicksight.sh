#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

require_cmd terraform
require_cmd aws
require_cmd jq

AWS_REGION="${AWS_REGION:-$(terraform output -raw aws_region 2>/dev/null || echo us-east-1)}"
ACCOUNT_ID="$(terraform output -raw aws_account_id)"
BUCKET_NAME="$(terraform output -raw s3_bucket_name)"
DATA_SET_ID="$(terraform output -raw quicksight_data_set_arn | awk -F'/' '{print $NF}')"
DATA_SOURCE_ID="$(terraform output -raw quicksight_data_source_arn | awk -F'/' '{print $NF}')"
ADMIN_EMAIL="$(terraform output -raw quicksight_admin_user_arn | awk -F'/' '{print $NF}')"

echo "==> QuickSight deployment smoke test"
echo "Account:  ${ACCOUNT_ID}"
echo "Region:   ${AWS_REGION}"
echo "Bucket:   ${BUCKET_NAME}"
echo

echo "==> 1. Verify sample CSV exists in S3"
aws s3 ls "s3://${BUCKET_NAME}/data/sales.csv" --region "${AWS_REGION}"
aws s3 cp "s3://${BUCKET_NAME}/data/sales.csv" - --region "${AWS_REGION}" | head -n 5
echo

echo "==> 2. Verify QuickSight admin user"
aws quicksight describe-user \
  --aws-account-id "${ACCOUNT_ID}" \
  --namespace default \
  --user-name "${ADMIN_EMAIL}" \
  --region "${AWS_REGION}" \
  | jq '{UserName: .User.UserName, Role: .User.Role, Active: .User.Active}'
echo

echo "==> 3. Verify QuickSight S3 data source"
aws quicksight describe-data-source \
  --aws-account-id "${ACCOUNT_ID}" \
  --data-source-id "${DATA_SOURCE_ID}" \
  --region "${AWS_REGION}" \
  | jq '{Name: .DataSource.Name, Type: .DataSource.Type, Status: .DataSource.Status}'
echo

echo "==> 4. Verify QuickSight dataset"
aws quicksight describe-data-set \
  --aws-account-id "${ACCOUNT_ID}" \
  --data-set-id "${DATA_SET_ID}" \
  --region "${AWS_REGION}" \
  | jq '{Name: .DataSet.Name, ImportMode: .DataSet.ImportMode, RowCountInfo: .DataSet.RowCountInfo}'
echo

echo "==> 5. Check latest SPICE ingestion"
INGESTIONS="$(aws quicksight list-ingestions \
  --aws-account-id "${ACCOUNT_ID}" \
  --data-set-id "${DATA_SET_ID}" \
  --region "${AWS_REGION}")"

echo "${INGESTIONS}" | jq '.Ingestions[] | {IngestionId, IngestionStatus, RowInfo}'

INGESTION_STATUS="$(echo "${INGESTIONS}" | jq -r '.Ingestions[0].IngestionStatus // "UNKNOWN"')"
if [[ "${INGESTION_STATUS}" != "COMPLETED" && "${INGESTION_STATUS}" != "RUNNING" && "${INGESTION_STATUS}" != "QUEUED" ]]; then
  echo "Warning: latest ingestion status is ${INGESTION_STATUS}" >&2
fi
echo

DASHBOARD_ARN="$(terraform output -raw quicksight_dashboard_arn 2>/dev/null || true)"
if [[ -n "${DASHBOARD_ARN}" && "${DASHBOARD_ARN}" != "null" ]]; then
  DASHBOARD_ID="${DASHBOARD_ARN##*/}"
  echo "==> 6. Verify QuickSight dashboard"
  aws quicksight describe-dashboard \
    --aws-account-id "${ACCOUNT_ID}" \
    --dashboard-id "${DASHBOARD_ID}" \
    --region "${AWS_REGION}" \
    | jq '{Name: .Dashboard.Name, Version: .Dashboard.Version, LastUpdatedTime: .Dashboard.LastUpdatedTime}'
  echo
  echo "Dashboard URL:"
  terraform output -raw quicksight_dashboard_url
  echo
fi

echo "==> QuickSight console:"
terraform output -raw quicksight_console_url
echo
echo "Smoke test completed."
