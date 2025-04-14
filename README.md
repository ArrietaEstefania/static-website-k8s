# 📦 Despliegue de Aplicación Web Estática en Kubernetes con Minikube

Este proyecto muestra cómo **desplegar una aplicación web estática** en un entorno local de **Kubernetes usando Minikube**.

---

## 📁 Estructura del proyecto

```
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
```

> 📌 El sitio web personalizado se encuentra en el repositorio hermano: `devops-web/`

---

## ⚙️ Requisitos previos

- **Docker Desktop**
- **Minikube**
- **kubectl**
- **Git**
- **Navegador web**

---

## 🚀 Instrucciones para levantar el entorno

### 📥 1. Clonar los repositorios

```bash
git clone https://github.com/<tu-usuario>/devops-web.git
git clone https://github.com/<tu-usuario>/devops-k8s.git
cd devops-k8s
```

---

### 🚀 2. Iniciar Minikube con un perfil dedicado

```bash
minikube start -p cloud-proyecto --driver=docker --mount --mount-string="/c/Users/54261/Desktop/CloudTrabajo/devops-web:/mnt/static-website"
```

---

### 📊 3. Activar metrics-server

```bash
minikube addons enable metrics-server -p cloud-proyecto
```

---

### 📂 4. Aplicar los manifiestos (en orden)

```bash
minikube profile cloud-proyecto  # Activar el perfil para kubectl

kubectl apply -f namespace/
kubectl apply -f pvc/
kubectl apply -f deployment/
kubectl apply -f service/
kubectl apply -f hpa/
```

---

### 🧪 Verificación del entorno

```bash
kubectl get all -n static-site-ns
kubectl top pods -n static-site-ns    # Requiere unos minutos para activarse
```

---

### 🌐 Acceder al sitio web desde el navegador

```bash
minikube service static-web-service -n static-site-ns -p cloud-proyecto
```

---

### 📈 Verificar Autoescalado (HPA)

El **HorizontalPodAutoscaler (HPA)** está configurado para escalar entre **1 y 3 réplicas** de NGINX si el uso de CPU supera el **50%**.

Ver el estado del HPA:

```bash
kubectl get hpa -n static-site-ns
```

---

### 🗑️ Borrar todo

```bash
minikube delete -p cloud-proyecto
```

---

## 🔧 Comandos útiles de Git

Guardar cambios:

```bash
git status                          # Verificar qué archivos cambiaron
git add .                           # Agregar todos los cambios
git commit -m "Actualizo manifiestos y documentación"
git push origin main                # Subir los cambios al branch principal
```

Descargar cambios del repositorio remoto:

```bash
git pull origin main
```

---

## 📚 Documentación oficial de Kubernetes

- 📖 [Documentación de Kubernetes](https://kubernetes.io/es/docs/)
- 📖 [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- 📖 [Documentación de Minikube](https://minikube.sigs.k8s.io/docs/)

---

## ✅ Listo para correr 🚀
