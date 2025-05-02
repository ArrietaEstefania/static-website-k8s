#!/bin/bash
set -e

# ==========================================
# Script de despliegue de entorno Minikube
# Autor: Estudiante ITU Estefania Arrieta - Computación en la Nube
# Fecha: 2025-05-02
# Descripción: Despliega entorno K8s con contenido web estático desde repositorios Git.
# ==========================================

# --- Variables iniciales ---
REPO_WEB="https://github.com/ArrietaEstefania/static-website"
REPO_MANIFESTS="https://github.com/ArrietaEstefania/static-website-k8s"
DIR_WEB="../devops-web"
DIR_MANIFESTS="."  # Ya estás en devops-k8s
MOUNT_STRING="$(realpath $DIR_WEB)"
PERFIL="cloud-proyecto" 
NAMESPACE="static-site-ns"

# --- Paso 1: Validar herramientas ---
echo "🔍 Verificando herramientas requeridas..."

for cmd in git docker minikube kubectl; do
  if ! command -v $cmd >/dev/null; then
    echo "❌ $cmd no está instalado. Abortando."
    exit 1
  fi
done

# --- Paso 2: Clonar o actualizar repositorios ---
echo "📁 Clonando o actualizando repositorios..."

# Clonar o actualizar sitio web
if [ ! -d "$DIR_WEB" ]; then
    git clone "$REPO_WEB" "$DIR_WEB"
else
    git config --global --add safe.directory "$(realpath $DIR_WEB)"
    cd "$DIR_WEB" || exit 1
    default_branch=$(git remote show origin | awk '/HEAD branch/ {print $NF}')
    git pull origin "$default_branch" || echo "⚠️ No se pudo hacer pull"
    cd - > /dev/null
fi

# --- Paso 3: Iniciar Minikube ---
echo "🚀 Iniciando Minikube con perfil '$PERFIL'..."

if ! docker info >/dev/null 2>&1; then
    echo "🚫 Tu usuario no tiene permisos sobre Docker."
    echo "👉 Ejecutá: sudo usermod -aG docker \$USER && newgrp docker"
    exit 1
fi

minikube start -p "$PERFIL" --driver=docker \
  --mount --mount-string="$MOUNT_STRING:/mnt/static-website"

# --- Paso 4: Esperar a que el clúster esté listo ---
echo "⏳ Esperando a que Kubernetes esté listo..."
for i in {1..10}; do
    if kubectl cluster-info >/dev/null 2>&1; then
        echo "✅ Clúster activo."
        break
    else
        echo "⌛ Esperando clúster... ($i/10)"
        sleep 5
    fi
done

# --- Paso 5: Habilitar métricas ---
echo "📊 Habilitando el servidor de métricas..."
minikube addons enable metrics-server -p "$PERFIL"

# --- Paso 6: Aplicar manifiestos ---
echo "📂 Aplicando manifiestos desde $DIR_MANIFESTS..."

kubectl apply -f namespace/
kubectl apply -f pvc/
kubectl apply -f deployment/
kubectl apply -f service/
kubectl apply -f hpa/

# --- Paso 7: Exponer servicio ---
echo "🌐 Exponiendo servicio web..."
minikube service static-web-service -n "$NAMESPACE" -p "$PERFIL"

echo "✅ Entorno desplegado con éxito."
