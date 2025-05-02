#!/bin/bash
set -e

# ==========================================
# Script de despliegue de entorno Minikube
# Autor: Estudiante ITU - Computación en la Nube
# ==========================================

# --- Variables configurables ---
REPO_WEB="https://github.com/ArrietaEstefania/static-website"
REPO_MANIFESTS="https://github.com/ArrietaEstefania/static-website-k8s"
DIR_WEB="../devops-web"
DIR_MANIFESTS="."
MOUNT_STRING="$(realpath $DIR_WEB)"
PERFIL="cloud-proyecto"
NAMESPACE="static-site-ns"

# --- Validar si estamos en WSL sobre disco de Windows ---
if [[ "$(pwd)" == /mnt/c/* ]]; then
    echo "⚠️ Estás ejecutando el script en /mnt/c/. Esto puede generar problemas de permisos en WSL. Recomendado mover el proyecto a ~/ en Ubuntu."
fi

# --- Paso 1: Verificar herramientas ---
echo "🔍 Verificando herramientas requeridas..."

command -v git >/dev/null 2>&1 || { echo "⚠️ Git no está instalado. Instalando..."; sudo apt update && sudo apt install -y git; }
command -v docker >/dev/null 2>&1 || { echo "🚫 Docker no está disponible. Asegurate de tener Docker Desktop corriendo."; exit 1; }
command -v minikube >/dev/null 2>&1 || { echo "🚫 Minikube no está instalado. Instalalo desde https://minikube.sigs.k8s.io/docs/"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "🚫 kubectl no está instalado. Instalalo desde https://kubernetes.io/docs/tasks/tools/"; exit 1; }

# --- Paso 2: Clonar o actualizar repos ---
echo "📁 Clonando o actualizando repositorios..."

# Web
if [ ! -d "$DIR_WEB" ]; then
    git clone "$REPO_WEB" "$DIR_WEB"
else
    cd "$DIR_WEB" || exit 1
    git fetch
    git checkout master
    git pull origin master || echo "⚠️ No se pudo hacer pull (¿problemas de permisos?)"
    cd - >/dev/null || exit 1
fi

# Manifiestos
git fetch
if git show-ref --verify --quiet refs/heads/main; then
    git checkout main
    git pull origin main || echo "⚠️ No se pudo hacer pull"
else
    echo "⚠️ La rama 'main' no existe."
fi

# --- Paso 3: Iniciar Minikube sin sudo ---
echo "🚀 Iniciando Minikube con perfil '$PERFIL'..."

minikube start -p "$PERFIL" --driver=docker \
  --mount --mount-string="$MOUNT_STRING:/mnt/static-website" || {
    echo "❌ Falló el inicio de Minikube. Abortando despliegue."
    exit 1
}

# --- Paso 4: Habilitar métricas ---
echo "📊 Habilitando el servidor de métricas..."
minikube addons enable metrics-server -p "$PERFIL"

# --- Paso 5: Aplicar manifiestos si el clúster está activo ---
echo "📂 Aplicando manifiestos desde $DIR_MANIFESTS..."

if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "❌ El clúster Kubernetes no está activo. No se pueden aplicar los manifiestos."
    exit 1
fi

kubectl apply -f namespace/
kubectl apply -f pvc/
kubectl apply -f deployment/
kubectl apply -f service/
kubectl apply -f hpa/

# --- Paso 6: Exponer el servicio ---
echo "🌐 Exponiendo servicio web en Minikube..."
minikube service static-web-service -n "$NAMESPACE" -p "$PERFIL"

echo "✅ Entorno desplegado con éxito."
