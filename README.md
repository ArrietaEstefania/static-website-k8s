Este proyecto muestra cómo desplegar una aplicación web estática en un entorno local de Kubernetes usando Minikube

---

## 📁 Estructura del proyecto

CloudTrabajo/
├── devops-web/             # Sitio web (contenido HTML estático)
└── devops-k8s/             # Manifiestos Kubernetes
    ├── namespace/
    │   └── namespace.yaml
    ├── pvc/
    │   ├── pv.yaml
    │   └── pvc.yaml
    ├── deployment/
    │   └── web-deployment.yaml
    ├── service/
    │   └── web-service.yaml
    ├── hpa/
    │   └── hpa.yaml
    └── README.md


> El sitio web personalizado se encuentra en el repositorio hermano: `devops-web/`


## ⚙️ Requisitos previos

- Docker Desktop
- Minikube
- kubectl
- Git
- Navegador web


## 🚀 Instrucciones para levantar el entorno

# 1. Clonar los repositorios

```bash
#1.clonar repositorio

git clone https://github.com/<tu-usuario>/devops-web.git
git clone https://github.com/<tu-usuario>/devops-k8s.git
cd devops-k8s

#2. Iniciar Minikube con un perfil dedicado

minikube start -p cloud-proyecto --driver=docker --mount --mount-string="/c/Users/54261/Desktop/CloudTrabajo/devops-web:/mnt/static-website"

#3. Activar metrics-server

minikube addons enable metrics-server -p cloud-proyecto

#4. Aplicar los manifiestos (en orden)

minikube profile cloud-proyecto  # activar el perfil para kubectl

kubectl apply -f namespace/
kubectl apply -f pvc/
kubectl apply -f deployment/
kubectl apply -f service/
kubectl apply -f hpa/

#🧪 Verificación del entorno

kubectl get all -n static-site-ns
kubectl top pods -n static-site-ns     # requiere unos minutos para activarse

#Acceder al sitio web desde el navegador:

minikube service static-web-service -n static-site-ns -p cloud-proyecto
#📈 Autoescalado
#El HorizontalPodAutoscaler (HPA) está configurado para escalar entre 1 y 3 réplicas de NGINX si el uso de CPU supera el 50%.
#Podés verificar el estado del HPA con:

kubectl get hpa -n static-site-ns


#Si querés borrar todo:

minikube delete -p cloud-proyecto
