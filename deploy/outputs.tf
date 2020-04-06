// Elastic Container registery

output "app_image_repository" {
  value = aws_ecr_repository.ecr_repo.repository_url
}

// Public subnets

output "public_subnets" {
  value = aws_subnet.public_subnets.*.id
}

// Private subnets

output "private_subnets" {
  value = aws_subnet.private_subnets.*.id
}

// RDS address

output "DJANGO_DB_HOST" {
 value = aws_db_instance.db_instance.address
}

// DB instance name for DJango

output "DJANGO_DB_NAME" {
 value = aws_db_instance.db_instance.name
}

// Super user password

output "super_user_pw" {
  value = random_string.django_su_secret.result
}
