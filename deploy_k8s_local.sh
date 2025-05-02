#!/bin/bash
set -e

# ==========================================
# Script de despliegue de entorno Minikube
# Autor: Estudiante ITU Estefania Arrieta - Computación en la Nube
# Fecha: 2025-05-02
# Descripción: Despliega entorno K8s con contenido web estático desde repositorios Git.
# ==========================================

# --- Variables iniciales (modificables) ---
REPO_WEB="https://github.com/ArrietaEstefania/static-website"
REPO_MANIFESTS="https://github.com/ArrietaEstefania/static-website-k8s"
DIR_WEB="devops-web"
DIR_MANIFESTS="devops-k8s"
MOUNT_STRING="$(realpath ../$DIR_WEB)"
PERFIL="cloud-proyecto" 
NAMESPACE="static-site-ns"

# --- Paso 1: Validar dependencias ---
echo "🔍 Verificando herramientas requeridas..."

command -v git >/dev/null 2>&1 || {
    echo "⚠️ Git no está instalado. Instalándolo..."
    sudo apt update && sudo apt install -y git
}

command -v docker >/dev/null 2>&1 || {
    echo "🚫 Docker no está disponible. Por favor abrí Docker Desktop y reintentá."
    exit 1
}

command -v minikube >/dev/null 2>&1 || {
    echo "🚫 Minikube no está instalado. Instalalo desde https://minikube.sigs.k8s.io/docs/"
    exit 1
}

command -v kubectl >/dev/null 2>&1 || {
    echo "🚫 kubectl no está instalado. Instalalo desde https://kubernetes.io/docs/tasks/tools/"
    exit 1
}

# --- Paso 2: Clonar o actualizar repositorios ---
echo "📁 Clonando o actualizando repositorios..."

# Repositorio del sitio web
if [ ! -d "../$DIR_WEB" ]; then
    git clone "$REPO_WEB" "../$DIR_WEB"
else
    git config --global --add safe.directory "$(realpath ../$DIR_WEB)"
    cd "../$DIR_WEB" || exit 1
    git pull origin main || echo "⚠️ No se pudo hacer pull, verifique la rama"
    cd - > /dev/null
fi

# Repositorio de manifiestos K8s
if [ ! -d "../$DIR_MANIFESTS" ]; then
    git clone "$REPO_MANIFESTS" "../$DIR_MANIFESTS"
else
    git config --global --add safe.directory "$(realpath ../$DIR_MANIFESTS)"
    cd "../$DIR_MANIFESTS" || exit 1
    git pull origin main || echo "⚠️ No se pudo hacer pull, verifique la rama"
    cd - > /dev/null
fi

# --- Paso 3: Iniciar Minikube con volumen montado ---
echo "🚀 Iniciando Minikube con perfil '$PERFIL'..."

# Verificar si el usuario tiene permisos sobre Docker
if ! docker info >/dev/null 2>&1; then
    echo "🚫 Tu usuario no tiene permisos sobre Docker."
    echo "👉 Ejecutá: sudo usermod -aG docker \$USER && newgrp docker"
    exit 1
fi

minikube start -p "$PERFIL" --driver=docker \
  --mount --mount-string="$MOUNT_STRING:/mnt/static-website"

# --- Paso 4: Habilitar métricas ---
echo "📊 Habilitando el servidor de métricas..."

minikube addons enable metrics-server -p "$PERFIL"

# --- Paso 5: Aplicar manifiestos ---
echo "📂 Aplicando manifiestos desde $DIR_MANIFESTS..."

cd "../$DIR_MANIFESTS" || exit 1

kubectl apply -f namespace/
kubectl apply -f pvc/
kubectl apply -f deployment/
kubectl apply -f service/
kubectl apply -f hpa/

# --- Paso 6: Exponer el servicio ---
echo "🌐 Exponiendo servicio web en Minikube..."

minikube service static-web-service -n "$NAMESPACE" -p "$PERFIL"

echo "✅ Entorno desplegado con éxito."
