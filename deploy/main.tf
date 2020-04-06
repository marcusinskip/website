// Terraform configuration to define AWS cloud infrastructure for St Botolphs College CMS application



// ECR repository definition
// The code would need to be amended to use a different repository 
// The terraform will need to be reapplied after the container image has been up

resource "aws_ecr_repository" "ecr_repo" {
  name                 = "ecr_repo"
  image_tag_mutability = "MUTABLE"
}



// s3 bucket definition

// Create a random name to be used in the bucket definition

resource "random_string" "s3_name" {
  length  = 12
  lower   = false
  upper   = false
  number  = true
  special = false
}

// Creating the s3 bucket

resource "aws_s3_bucket" "s3_image_store" {
   bucket = "${var.env}-${var.app_name}-random_string.s3_name.result"
   region = var.region
   acl    = "private"
   
   tags = {
     "Name" = var.app_name
     "Environment" = var.env
     "Project"     = var.project
    }
}

// s3 IAM definition


data "aws_iam_policy_document" "s3_image_store_bucket_policy" {
  statement {
    sid = ""
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.s3_image_store.bucket}"
    ]
  }
  statement {
    sid = ""
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.s3_image_store.bucket}/*"
    ]
  }
}

// IAM policies to be attached to the ecs container,  this is largely redundant 
// As Django will be making the connection directly

resource "aws_iam_policy" "s3_policy" {
  name   = "s3_policy"
  policy = data.aws_iam_policy_document.s3_image_store_bucket_policy.json
}

resource "aws_iam_role_policy_attachment" "ecs_role_s3_image_store_bucket_policy_attach" {
  role       = aws_iam_role.ecs_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}


// ECS cluster definition

resource "aws_ecs_cluster" "cluster" {
  name = "${var.env}-ecs-cluster"
}

// VPC definition involving public and private subnets

resource "aws_vpc" "vpc" {
  cidr_block          = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
}

// Public subnet definition dynamically generating the CIDR blocks

resource "aws_subnet" "public_subnets" {
  count                    = length(var.availability_zones)
  vpc_id                   = aws_vpc.vpc.id
  cidr_block               = cidrsubnet(var.vpc_cidr_block,8,count.index)
  availability_zone        = element(var.availability_zones, count.index)
  map_public_ip_on_launch  = true
  
  tags = {
     "Name"         = "Public subnet - ${element(var.availability_zones, count.index)}"
     "Environment" = var.env
     "Project"     = var.project
  }
  
}

// Private subnet definition definition dynamically generating the CIDR blocks 
// taking the public subnets into consideration

resource "aws_subnet" "private_subnets" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index + length(var.availability_zones))
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false

  tags = {
    "Name" = "Private subnet - ${element(var.availability_zones, count.index)}"
    "Environment" = var.env
    "Project"     = var.project
  }
}

// NAT Gateways to be used by the private subnets one for each AZ

resource "aws_eip" "nat_eip" {
  count = length(var.availability_zones)
  vpc   = true
}


resource "aws_nat_gateway" "nat_gw" {
  count         = length(var.availability_zones)
  subnet_id     = element(aws_subnet.public_subnets.*.id, count.index)
  allocation_id = element(aws_eip.nat_eip.*.id, count.index)

  tags = {
    "Name" = "NAT - ${element(var.availability_zones, count.index)}"
     "Environment" = var.env
     "Project"     = var.project
  }
}

// Private route table 

resource "aws_route_table" "private_rt" {
  count  = length(var.availability_zones)
  vpc_id = aws_vpc.vpc.id

  tags = {
    "Name" = "Private route table - ${element(var.availability_zones, count.index)}"
    "Environment" = var.env
  }
}

// Route to NAT gateway from the private subnets

resource "aws_route" "route_nat_gateway" {
  count = length(var.availability_zones)

  route_table_id         = element(aws_route_table.private_rt.*.id, count.index)
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.nat_gw.*.id, count.index)
}

resource "aws_route_table_association" "private" {
  count = length(var.availability_zones)

  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private_rt.*.id, count.index)
}

// Internet Gateway definition

resource "aws_internet_gateway" "ig" {
  vpc_id                   = aws_vpc.vpc.id

}

resource "aws_route_table" "public_rt" {
  vpc_id                  = aws_vpc.vpc.id
  tags = {
    "Name"                = "$var.env-public_route_table"
    "Environment" = var.env
    "Project"     = var.project
  }
}

// Route from public subnets to the IG

resource "aws_route" "public_egress" {
  route_table_id           = aws_route_table.public_rt.id
  destination_cidr_block   = "0.0.0.0/0"
  gateway_id               = aws_internet_gateway.ig.id
}

// Appropriate association to the route definition

resource "aws_route_table_association" "public_rt_assoc" {
  count = length(var.availability_zones)
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

// Security group definition

// SG to allow traffic to the RDS database for the ECS instances

resource "aws_security_group" "sg" {
  name        = "database-sg"
  description = "Allow database traffic"
  vpc_id      = aws_vpc.vpc.id

  tags = {
    "Name" = "database-sg"
    "Environment" = var.env
    "Project"     = var.project
  }
}


resource "aws_db_subnet_group" "db_instance_subnet" {
  name       = "main"
  subnet_ids = aws_subnet.private_subnets.*.id

  tags = {
    "Name" = "DB subnet group"
    "Environment" = var.env
    "Project"     = var.project
  }
}

resource "aws_security_group_rule" "allow_ingress" {
  type        = "ingress"
  from_port   = 5432
  to_port     = 5432
  protocol    = "tcp"
  cidr_blocks = aws_subnet.private_subnets.*.cidr_block

  security_group_id = aws_security_group.sg.id
}

resource "aws_security_group_rule" "allow_egress" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = aws_subnet.private_subnets.*.cidr_block

  security_group_id = aws_security_group.sg.id
}

// RDS definition

// Generate dynamic password

resource "random_string" "POSTGRES_PASSWORD" {
  length  = 24
  lower   = true
  upper   = true
  number  = true
  special = false
}

// Generate dynamic password

resource "random_string" "DJANGO_SECRET_KEY" {
  length  = 24
  lower   = true
  upper   = true
  number  = true
  special = false
}

// Generate dynamic password


resource "random_string" "django_su_secret" {
  length  = 24
  lower   = true
  upper   = true
  number  = true
  special = false
}

// Create DB instance

resource "aws_db_instance" "db_instance" {
  identifier           = "${var.env}-${var.POSTGRES_DB}"
  allocated_storage    = var.db_allocated_storage
  storage_type         = "gp2"
  engine               = "postgres"
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  name                 = var.POSTGRES_DB
  username             = var.POSTGRES_USER
  password            = random_string.POSTGRES_PASSWORD.result
  db_subnet_group_name = aws_db_subnet_group.db_instance_subnet.id
  publicly_accessible  = false
  skip_final_snapshot  = true

  vpc_security_group_ids = [aws_security_group.sg.id]

  tags = {
    "Name" = "${var.env}-${var.POSTGRES_DB}"
    "Environment" = var.env
    "Project"     = var.project
    
  }

  depends_on = [random_string.POSTGRES_PASSWORD]
  
  
}

// Generate IAM user for s3 access from Django

resource "aws_iam_user" "s3_user" {
  name = var.DJANGO_EMAIL_HOST_USER
}

// Generate the IAM policy for required access

resource "aws_iam_user_policy" "s3_user_policy" {
  name = "s3_user_policy"
  user = aws_iam_user.s3_user.name

    policy = <<EOF
{
  "Statement": [
    {
      "Action": [
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject",
      "s3:PutObjectAcl"
      ],
      "Effect": "Allow",
      "Resource": [
      "arn:aws:s3:::${aws_s3_bucket.s3_image_store.bucket}",
      "arn:aws:s3:::${aws_s3_bucket.s3_image_store.bucket}/*"
      ]
    }
  ]
}

EOF
}

// Generate required keys

resource "aws_iam_access_key" "s3_user_ak" {
  user    = aws_iam_user.s3_user.name
  pgp_key = "123456789"
}


// AWS Cloudwatch log group definition

resource "aws_cloudwatch_log_group" "cw_log_group" {
  name = var.app_name
  retention_in_days = 1
}


// IAM Role definition

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}


resource "aws_iam_role" "webapp" {
  name = var.app_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}


resource "aws_iam_role_policy" "webapp_app" {
  name = "${var.app_name}-put-logs"
  role = aws_iam_role.webapp.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:*"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}


resource "aws_iam_role" "webapp_role" {
  name               = "webapp_task_execution_role"
  assume_role_policy = file("policies/ecs_task_execution_role.json")
}

data "aws_iam_policy_document" "ecs_service_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "ecs_cloudwatch_role_policy" {
  name = "${var.app_name}-ecs-logs"
  policy = file("policies/ecs_cloudwatch_role_policy.json")
  role = aws_iam_role.webapp_role.id
}

resource "aws_iam_role" "ecs_role" {
  name               = "ecs_role"
  assume_role_policy = data.aws_iam_policy_document.ecs_service_role.json
} 


// ECS task templates for setup that runs migrations and create superuser 

data "template_file" "webapp_setup_task" {
  template = file("templates/ecs_task_setup.tpl")
  vars = {
     image_repo             = aws_ecr_repository.ecr_repo.repository_url
     image_version          = var.app_image_version
     command                = "from django.contrib.auth.models import User; User.objects.create_superuser('${var.django_super_user}', '${var.django_super_user_email}','random_string.django_su_secret.result')"
     app_name               = var.app_name
     region                 = var.region
     DJANGO_DB_HOST         = aws_db_instance.db_instance.address
     DJANGO_DB_NAME         = var.DJANGO_DB_NAME
     DJANGO_DB_PASSWORD     = random_string.POSTGRES_PASSWORD.result
     PORT                   = var.PORT
     DJANGO_SECRET_KEY      = random_string.DJANGO_SECRET_KEY.result
     DJANGO_DANGEROUS_DEBUG = var.DJANGO_DANGEROUS_DEBUG 
     DJANGO_DB_ENGINE       = var.DJANGO_DB_ENGINE
     DJANGO_DB_CONN_MAX_AGE = var.DJANGO_DB_CONN_MAX_AGE
     DJANGO_DB_PORT         = var.DJANGO_DB_PORT
     DJANGO_DB_USER         = var.DJANGO_DB_USER
     container_port         = var.container_port
     DJANGO_EMAIL_HOST      = var.DJANGO_EMAIL_HOST
     DJANGO_EMAIL_HOST_USER = var.DJANGO_EMAIL_HOST_USER
     DJANGO_EMAIL_HOST_PASSWORD = aws_iam_access_key.s3_user_ak.ses_smtp_password_v4
     DJANGO_EMAIL_PORT      = var.DJANGO_EMAIL_PORT
     DJANGO_AWS_S3_HOST     = "s3-${aws_s3_bucket.s3_image_store.region}.amazonaws.com"
     DJANGO_AWS_ACCESS_KEY_ID   = aws_iam_access_key.s3_user_ak.id
     DJANGO_AWS_SECRET_ACCESS_KEY  = aws_iam_access_key.s3_user_ak.secret
     DJANGO_AWS_STORAGE_BUCKET_NAME = aws_s3_bucket.s3_image_store.id
     DJANGO_AWS_S3_ENDPOINT_URL = "http://s3-${aws_s3_bucket.s3_image_store.region}.amazonaws.com/${aws_s3_bucket.s3_image_store.id}"
     DJANGO_AWS_S3_REGION_NAME = aws_s3_bucket.s3_image_store.region
     
  }
}

// ECS task templates for container without setup tasks 

data "template_file" "webapp_task" {
  template = file("templates/ecs_task.tpl")
  vars = {
     image_repo             = aws_ecr_repository.ecr_repo.repository_url
     image_version          = var.app_image_version
     app_name               = var.app_name
     region                 = var.region
     DJANGO_DB_HOST         = aws_db_instance.db_instance.address
     DJANGO_DB_NAME         = var.DJANGO_DB_NAME
     DJANGO_DB_PASSWORD     = random_string.POSTGRES_PASSWORD.result
     PORT                   = var.PORT
     DJANGO_SECRET_KEY      = random_string.DJANGO_SECRET_KEY.result
     DJANGO_DANGEROUS_DEBUG = var.DJANGO_DANGEROUS_DEBUG 
     DJANGO_DB_ENGINE       = var.DJANGO_DB_ENGINE
     DJANGO_DB_CONN_MAX_AGE = var.DJANGO_DB_CONN_MAX_AGE
     DJANGO_DB_PORT         = var.DJANGO_DB_PORT
     DJANGO_DB_USER         = var.DJANGO_DB_USER
     container_port         = var.container_port
     DJANGO_EMAIL_HOST      = var.DJANGO_EMAIL_HOST
     DJANGO_EMAIL_HOST_USER = var.DJANGO_EMAIL_HOST_USER
     DJANGO_EMAIL_HOST_PASSWORD = aws_iam_access_key.s3_user_ak.ses_smtp_password_v4
     DJANGO_EMAIL_PORT      = var.DJANGO_EMAIL_PORT
     DJANGO_AWS_S3_HOST     = "s3-${aws_s3_bucket.s3_image_store.region}.amazonaws.com"
     DJANGO_AWS_ACCESS_KEY_ID   = aws_iam_access_key.s3_user_ak.id
     DJANGO_AWS_SECRET_ACCESS_KEY  = aws_iam_access_key.s3_user_ak.secret
     DJANGO_AWS_STORAGE_BUCKET_NAME = aws_s3_bucket.s3_image_store.id
     DJANGO_AWS_S3_ENDPOINT_URL = "http://s3-${aws_s3_bucket.s3_image_store.region}.amazonaws.com/${aws_s3_bucket.s3_image_store.id}"
     DJANGO_AWS_S3_REGION_NAME = aws_s3_bucket.s3_image_store.region
     
  }
}

// Using previously defined templates to execute the tasks for container to run setup tasks

resource "aws_ecs_task_definition" "webapp_setup" {
  family                   = "${var.env}_webapp_setup"
  container_definitions    = data.template_file.webapp_setup_task.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = var.network_mode
  cpu                      = var.task_cpu
  memory                   = var.task_mem
  execution_role_arn       = aws_iam_role.webapp_role.arn
  task_role_arn            = aws_iam_role.webapp_role.arn
  
  depends_on = [aws_db_instance.db_instance]
}


// Using previously defined templates to execute the tasks for container without setup tasks

resource "aws_ecs_task_definition" "webapp" {
  family                   = "${var.env}_webapp"
  container_definitions    = data.template_file.webapp_task.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = var.network_mode
  cpu                      = var.task_cpu
  memory                   = var.task_mem
  execution_role_arn       = aws_iam_role.webapp_role.arn
  task_role_arn            = aws_iam_role.webapp_role.arn
  
  depends_on = [aws_db_instance.db_instance]
}


// ECS service definition for the two ECS containers defined previously

resource "aws_ecs_service" "webapp" {
  name            = "${var.env}-${var.app_name}"
  task_definition = aws_ecs_task_definition.webapp.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"
  cluster         = aws_ecs_cluster.cluster.id

  load_balancer {
    target_group_arn = aws_lb_target_group.webapp_lb_tg.id
    container_name   = var.app_name
    container_port   = "8000"
  }

  network_configuration {
    security_groups = [aws_security_group.sg.id,aws_security_group.ecs_service_sg.id]
    subnets         = aws_subnet.private_subnets.*.id
  }

}

// Security group access between ALB and ECS definition

resource "aws_security_group" "ecs_service_sg" {
  name        = "${var.app_name}-ecs-service-sg"
  description = "Controls access to the ${var.app_name} service"
  vpc_id      = aws_vpc.vpc.id
  
}

// Security group allowing access from port 80 to port 8000 container port

resource "aws_security_group_rule" "allow_access_from_lb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 8000
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_service_sg.id
  source_security_group_id = aws_security_group.lb_sg.id
}

resource "aws_security_group_rule" "allow_all_outbound_ecs" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.ecs_service_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

// ALB definition

resource "aws_lb" "webapp_lb" {
  name     = "${var.app_name}-alb"
  internal = false

  security_groups = [aws_security_group.lb_sg.id]
  subnets         = aws_subnet.public_subnets.*.id
}

// ALB target group definition

resource "aws_lb_target_group" "webapp_lb_tg" {
  name_prefix = var.app_name

  protocol    = "HTTP"
  port        = "80"
  vpc_id      = aws_vpc.vpc.id
  target_type = "ip"

  health_check {
    path = var.health_check_path
  }

}

// ALB listeners definition

resource "aws_lb_listener" "webapp_lb_listener" {
  load_balancer_arn = aws_lb.webapp_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.webapp_lb_tg.arn
    type             = "forward"
  }
}

// ALB security group definition

resource "aws_security_group" "lb_sg" {
  name        = "${var.app_name}-lb-sg"
  description = "Controls access to the ${var.app_name} ALB"
  vpc_id      = aws_vpc.vpc.id

  lifecycle {
    create_before_destroy = true
  }
}

// Security group to allow access to port 80

resource "aws_security_group_rule" "allow_all_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb_sg.id

}

resource "aws_security_group_rule" "allow_all_outbound" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.lb_sg.id
}

