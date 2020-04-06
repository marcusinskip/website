[
  {
    "name": "${app_name}-setup",
    "image": "${image_repo}:${image_version}",
    "command": ["sh", "-c", "sleep 5 && ./manage.py migrate && ./manage.py shell -c ${command}"],
    "memory": 300,
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${app_name}",
        "awslogs-region": "${region}",
        "awslogs-stream-prefix": "${app_name}-setup"
      }
    },
     "environment": [
           {
        "name": "DJANGO_DB_HOST",
        "value": "${DJANGO_DB_HOST}"
      },
      {
        "name": "DJANGO_DB_NAME",
        "value": "${DJANGO_DB_NAME}"
      },
      {
        "name": "DJANGO_DB_USER",
        "value": "${DJANGO_DB_USER}"
      },
      {
        "name": "DJANGO_DB_PASSWORD",
        "value": "${DJANGO_DB_PASSWORD}"
      },
      {
        "name": "PORT",
        "value": "${PORT}"
      },
      {
        "name": "DJANGO_SECRET_KEY",
        "value": "${DJANGO_SECRET_KEY}"
      },
      {
        "name": "DJANGO_DANGEROUS_DEBUG",
        "value": "${DJANGO_DANGEROUS_DEBUG}"
      },
      {
        "name": "DJANGO_DB_ENGINE",
        "value": "${DJANGO_DB_ENGINE}"
      },
      {
        "name": "DJANGO_DB_CONN_MAX_AGE",
        "value": "${DJANGO_DB_CONN_MAX_AGE}"
      },
      {
        "name": "DJANGO_DB_PORT",
        "value": "${DJANGO_DB_PORT}"
      }
      {
        "name": "DJANGO_EMAIL_HOST",
        "value": "${DJANGO_EMAIL_HOST}"
      },
      {
        "name": "DJANGO_EMAIL_HOST_USER",
        "value": "${DJANGO_EMAIL_HOST_USER}"
      },
      {
        "name": "DJANGO_EMAIL_HOST_PASSWORD",
        "value": "${DJANGO_EMAIL_HOST_PASSWORD}"
      },
      {
        "name": "DJANGO_EMAIL_PORT",
        "value": "${DJANGO_EMAIL_PORT}"
      },
      {
        "name": "DJANGO_AWS_S3_HOST",
        "value": "${DJANGO_AWS_S3_HOST}"
      },
      {
        "name": "DJANGO_AWS_ACCESS_KEY_ID",
        "value": "${DJANGO_AWS_ACCESS_KEY_ID}"
      },
      {
        "name": "DJANGO_AWS_SECRET_ACCESS_KEY",
        "value": "${DJANGO_AWS_SECRET_ACCESS_KEY}"
      },
      {
        "name": "DJANGO_AWS_STORAGE_BUCKET_NAME",
        "value": "${DJANGO_AWS_STORAGE_BUCKET_NAME}"
      },
      {
        "name": "DJANGO_AWS_S3_ENDPOINT_URL",
        "value": "${DJANGO_AWS_S3_ENDPOINT_URL}"
      },
      {
        "name": "DJANGO_AWS_S3_REGION_NAME",
        "value": "${DJANGO_AWS_S3_REGION_NAME}"
      }
    ]
  }
]
