provider "aws" {
  region = "us-east-1"
}

# Criando repositório no Amazon ECR
resource "aws_ecr_repository" "php_api" {
  name = "php-api"
}

# Criando Cluster no ECS
resource "aws_ecs_cluster" "php_cluster" {
  name = "php-api-cluster"
}

# Criando Grupo de Segurança para permitir tráfego HTTP
resource "aws_security_group" "ecs_sg" {
  name        = "ecs_security_group"
  description = "Permitir tráfego HTTP"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Criando Fargate Service
resource "aws_ecs_task_definition" "php_task" {
  family                   = "php-api-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "php-api",
      image     = "${aws_ecr_repository.php_api.repository_url}:latest",
      memory    = 512,
      cpu       = 256,
      essential = true,
      portMappings = [{
        containerPort = 80,
        hostPort      = 80
      }]
    }
  ])
}

resource "aws_ecs_service" "php_service" {
  name            = "php-api-service"
  cluster         = aws_ecs_cluster.php_cluster.id
  task_definition = aws_ecs_task_definition.php_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.public.*.id
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }
}provider "aws" {
  region = "us-east-1"
}

# Criando repositórios no ECR
resource "aws_ecr_repository" "backend" {
  name = "php-backend"
}

resource "aws_ecr_repository" "frontend" {
  name = "php-frontend"
}

# Criando Banco de Dados no RDS PostgreSQL
resource "aws_db_instance" "postgres" {
  allocated_storage    = 20
  engine              = "postgres"
  instance_class      = "db.t3.micro"
  db_name             = "mydb"
  username           = "admin"
  password           = "SuperSenhaSegura123"
  publicly_accessible = false
  skip_final_snapshot = true
}

# Criando Cluster no ECS
resource "aws_ecs_cluster" "php_cluster" {
  name = "php-ecs-cluster"
}

# Criando Backend Service
resource "aws_ecs_task_definition" "backend_task" {
  family                   = "php-backend-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "php-backend",
      image     = "${aws_ecr_repository.backend.repository_url}:latest",
      memory    = 512,
      cpu       = 256,
      essential = true,
      environment = [
        { name = "DB_HOST", value = aws_db_instance.postgres.address },
        { name = "DB_NAME", value = "mydb" },
        { name = "DB_USER", value = "admin" },
        { name = "DB_PASS", value = "SuperSenhaSegura123" }
      ],
      portMappings = [{
        containerPort = 80,
        hostPort      = 80
      }]
    }
  ])
}

# Criando Frontend Service
resource "aws_ecs_task_definition" "frontend_task" {
  family                   = "php-frontend-task"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = "php-frontend",
      image     = "${aws_ecr_repository.frontend.repository_url}:latest",
      memory    = 512,
      cpu       = 256,
      essential = true,
      portMappings = [{
        containerPort = 80,
        hostPort      = 80
      }]
    }
  ])
}