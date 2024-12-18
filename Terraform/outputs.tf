# Mostrar el endpoint de la base de datos RDS
output "rds_endpoint" {
  description = "Endpoint de la base de datos RDS PostgreSQL"
  value       = aws_db_instance.rds_postgres.endpoint
}

# Mostrar el nombre del clúster EKS
output "eks_cluster_name" {
  description = "Nombre del clúster EKS"
  value       = aws_eks_cluster.eks_cluster.name
}

# Output para mostrar las subnets
output "eks_subnets" {
  description = "IDs de las subnets seleccionadas para el clúster EKS"
  value       = local.selected_subnet_ids
}