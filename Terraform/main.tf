provider "aws" {
  region = "us-east-1"
}

# Data source para obtener la VPC existente
data "aws_vpc" "selected_vpc" {
  id = "vpc-0ec7d9563353ba7b2" 
}

# Data source para obtener las subnets asociadas a la VPC
data "aws_subnets" "selected_subnets" {
    filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected_vpc.id]
  }
    filter {
    name   = "availability-zone"
    values = ["us-east-1a", "us-east-1b"] # Zonas compatibles
  }
}

# Security Group para EKS Nodes
resource "aws_security_group" "eks_nodes_sg" {
  name        = "eks-nodes-sg"
  description = "Permite trafico entre EKS y RDS"
  vpc_id      = data.aws_vpc.selected_vpc.id

  # Permitir tráfico dentro del clúster
  ingress {
    description = "Allow all communication between cluster nodes"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Permitir acceso al puerto 5432 (PostgreSQL) desde la VPC
  ingress {
    description = "Allow EKS nodes to connect to RDS"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected_vpc.cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group para RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Permite conexion desde EKS nodes"

  ingress {
    description = "PostgreSQL Access from VPC CIDR"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected_vpc.cidr_block]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Base de datos RDS PostgreSQL
resource "aws_db_instance" "rds_postgres" {
  allocated_storage    = 20
  engine               = "postgres"
  engine_version       = "17.2"
  instance_class       = "db.t3.micro"
  db_name              = "mydatabase"
  username             = "harrypotter"
  password             = var.db_password # Uso de la variable
  publicly_accessible  = true
  skip_final_snapshot  = true
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  tags = {
    Name = "rds-postgres"
  }
}


# Seleccionar las dos primeras subnets
locals {
  selected_subnet_ids = slice(data.aws_subnets.selected_subnets.ids, 0, 2)
}

# Rol IAM para EKS
resource "aws_iam_role" "eks_role" {
  name = "eksClusterRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

# Política IAM para el rol de EKS
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Crear el clúster EKS usando las subnets
resource "aws_eks_cluster" "eks_cluster" {
  name     = "eks-cluster"
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids = local.selected_subnet_ids
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_policy]
}

# Rol IAM para los nodos del EKS
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Adjuntar políticas necesarias al rol de Node Group
resource "aws_iam_role_policy_attachment" "node_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = local.selected_subnet_ids

  remote_access {
    ec2_ssh_key = "Jenkisec2"
    source_security_group_ids = [aws_security_group.eks_nodes_sg.id]
  }

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  instance_types = ["t3.small"]

  depends_on = [aws_eks_cluster.eks_cluster]
}
