#!/bin/bash

set -euo pipefail

sodar_core_app_django_secret_key=$(pwgen 40)
sodar_core_app_superuser_password=$(pwgen 40)
postgres_client_password=$(pwgen 40)
minio_access_key=$(pwgen 40)
minio_secret_key=$(pwgen 40)

cat <<EOF
postgres_client_password: "$postgres_client_password"
minio_access_key: "$minio_access_key"
minio_secret_key: "$minio_secret_key"
varfish_upload_s3_access_key: "$minio_access_key"
varfish_upload_s3_secret_key: "$minio_secret_key"
sodar_core_app_django_secret_key: "$sodar_core_app_django_secret_key"
sodar_core_app_superuser_password: "$sodar_core_app_superuser_password"
EOF
