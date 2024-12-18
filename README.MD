# Terraform EKS Deployment with Docker Image and RDS

## Descripción del Proyecto
Este proyecto implementa un clúster **EKS** en AWS utilizando **Terraform**, despliega una imagen **Docker** personalizada en un servicio **LoadBalancer** que muestra una página *"Hola Mundo"* en **Apache**, y configura una base de datos **RDS PostgreSQL** con conexión a los nodos del clúster EKS.

---

## Requisitos
- Cuenta de **AWS** configurada.  
- **Docker** instalado.  
- **Terraform** instalado.  
- **AWS CLI** configurado con acceso.  

---

## Tecnologías Utilizadas
- **Terraform**: Provisionamiento de infraestructura.  
- **AWS EKS**: Servicio de Kubernetes gestionado.  
- **AWS RDS**: Base de datos relacional.  
- **Docker**: Construcción y publicación de la imagen.  
- **Kubernetes**: Despliegue y gestión de la aplicación. 