variable "region" {
  default = "eu-west-2"
}

variable "env" {
  default = "test"
}

variable "availability_zones" {
  default =  ["eu-west-2a","eu-west-2b","eu-west-2c"]
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "POSTGRES_DB" {
  default = "cms"
}

variable "POSTGRES_USER" {
  default = "webapp"
}

variable "DJANGO_DB_USER" {
  default = "webapp"
}

variable "instance_class" {
  default = "db.t2.micro"
}

variable "engine_version" {
  default = "11.6"
}

variable "DJANGO_DANGEROUS_DEBUG" {
  default = 0
}

variable "DJANGO_DB_ENGINE" {
  default = "django.db.backends.postgresql" 
}

variable "DJANGO_DB_PORT" {
  default = 5432 
}

variable "DJANGO_DB_CONN_MAX_AGE" {
  default = 60
}

variable "django_super_user" {
  default = "admin"
}

variable "django_super_user_email" {
  default = "admin@example.com"
}


variable "container_port" {
  default = 8000
}

variable "desired_count" {
  default = 1
}

variable "app_name" {
  default = "webapp"
}

variable "ecs_cluster_name" {
  default = "webapp_cluster"
}

variable "app_image_repository" {
  default = "repository"
}



variable "app_image_version" {
  default = "latest"
}

variable "DJANGO_DB_HOST" {
  default = "127.0.0.1"
}

variable "DJANGO_DB_NAME" {
  default = "cms"
}


variable "PORT" {
  default = "8000"
}

variable "db_allocated_storage" {
  default = 20
}

variable "project" {
  default = "st_botolph"
}

variable "network_mode" {
  default = "awsvpc"
}

variable "task_cpu" {
  default = "256"
}

variable "task_mem" {
  default = "512"
}

variable "health_check_path" {
  default = "/"
}


variable "DJANGO_EMAIL_HOST" {
  default = "email-smtp.eu-west-2.amazonaws.com"
}

variable "DJANGO_EMAIL_HOST_USER" {
  default = "django"
}

variable "DJANGO_EMAIL_PORT" {
  default = 25
}

variable "AWS_S3_USE_SSL" {
  default = "True"
}




