#!/bin/bash

# ==========================================
# Script de despliegue de entorno Minikube
# Autor: Estudiante ITU Estefania Arrieta- Computación en la Nube
# Fecha: 2025-05-02
# Descripción: Despliega entorno K8s con contenido web estático desde repositorios Git.
# ==========================================

# --- Variables iniciales (modificables) ---
REPO_WEB="https://github.com/ArrietaEstefania/static-website"
REPO_MANIFESTS="https://github.com/ArrietaEstefania/static-website-k8s"
DIR_WEB="../devops-web"
DIR_MANIFESTS="."
MOUNT_STRING="$(realpath $DIR_WEB)"
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
if [ ! -d "$DIR_WEB" ]; then
    git clone "$REPO_WEB" "$DIR_WEB"
else
    cd "$DIR_WEB" || exit 1
    git fetch
    git checkout master
    git pull origin master || echo "⚠️ No se pudo hacer pull"
    cd - > /dev/null || exit 1
fi

# Repositorio de los manifiestos (ya estamos en él)
git fetch
if git rev-parse --verify main >/dev/null 2>&1; then
    git checkout main
    git pull origin main || echo "⚠️ No se pudo hacer pull"
else
    echo "⚠️ La rama 'main' no existe en este repositorio."
fi

# --- Paso 3: Iniciar Minikube con volumen montado ---
echo "🚀 Iniciando Minikube con perfil '$PERFIL'..."

minikube start -p "$PERFIL" --driver=docker \
  --mount --mount-string="$MOUNT_STRING:/mnt/static-website"

# --- Paso 4: Habilitar métricas ---
echo "📊 Habilitando el servidor de métricas..."
minikube addons enable metrics-server -p "$PERFIL"

# --- Paso 5: Aplicar los manifiestos ordenadamente ---
echo "📂 Aplicando manifiestos desde $DIR_MANIFESTS..."

kubectl apply -f namespace/
kubectl apply -f pvc/
kubectl apply -f deployment/
kubectl apply -f service/
kubectl apply -f hpa/

# --- Paso 6: Exponer el servicio ---
echo "🌐 Exponiendo servicio web en Minikube..."

minikube service static-web-service -n "$NAMESPACE" -p "$PERFIL"

echo "✅ Entorno desplegado con éxito."
