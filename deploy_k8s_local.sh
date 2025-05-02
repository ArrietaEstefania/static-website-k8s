#!/bin/bash

# ==========================================
# Script de despliegue de entorno Minikube
# Autor: Estudiante ITU Estefania Arrieta- Computación en la Nube
# Fecha: 2025-05-02
# Descripción: Despliega entorno K8s con contenido web estático desde repositorios Git.
# ==========================================

# --- Verificar que no se ejecute con sudo ---
if [ "$(id -u)" = "0" ]; then
   echo "❌ Este script no debe ejecutarse con sudo o como root."
   echo "   Por favor, ejecuta el script sin sudo: ./deploy_k8s_local.sh"
   exit 1
fi

# --- Variables iniciales (modificables) ---
REPO_WEB="https://github.com/ArrietaEstefania/static-website"
REPO_MANIFESTS="https://github.com/ArrietaEstefania/static-website-k8s"
DIR_WEB="../devops-web"
DIR_MANIFESTS="."
MOUNT_STRING="$(realpath $DIR_WEB 2>/dev/null || echo $DIR_WEB)"
PERFIL="cloud-proyecto"
NAMESPACE="static-site-ns"

# --- Verificar si estamos en WSL y en una ruta de Windows ---
if grep -q Microsoft /proc/version && [[ "$PWD" == "/mnt/"* ]]; then
    echo "⚠️ Estás ejecutando el script desde una ruta de Windows montada en WSL ($PWD)."
    echo "   Esto puede causar problemas de permisos. Considera mover el proyecto a tu directorio home de Ubuntu."
    read -p "¿Continuar de todos modos? (s/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Ss]$ ]]; then
        exit 1
    fi
fi

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

# --- Paso 3: Detener Minikube si ya existe ---
echo "🛑 Deteniendo Minikube si está ejecutándose..."
minikube status -p "$PERFIL" &>/dev/null && minikube stop -p "$PERFIL"

# --- Paso 4: Iniciar Minikube con volumen montado ---
echo "🚀 Iniciando Minikube con perfil '$PERFIL'..."

# Intentar iniciar minikube y guardar el resultado
if ! minikube start -p "$PERFIL" --driver=docker --mount --mount-string="$MOUNT_STRING:/mnt/static-website"; then
    echo "❌ Error al iniciar Minikube. Abortando."
    exit 1
fi

# --- Paso 5: Habilitar métricas ---
echo "📊 Habilitando el servidor de métricas..."
minikube addons enable metrics-server -p "$PERFIL"

# --- Paso 6: Aplicar los manifiestos ordenadamente ---
echo "📂 Aplicando manifiestos desde $DIR_MANIFESTS..."

# Asegurarse de que kubectl esté configurado para usar el perfil de minikube
eval $(minikube -p "$PERFIL" docker-env)

# Aplicar manifiestos en orden
kubectl apply -f namespace/
kubectl apply -f pvc/
kubectl apply -f deployment/
kubectl apply -f service/
kubectl apply -f hpa/

# --- Paso 7: Esperar a que los pods estén listos ---
echo "⏳ Esperando a que los pods estén listos..."
kubectl wait --namespace="$NAMESPACE" \
    --for=condition=ready pod \
    --selector=app=static-web \
    --timeout=120s

# --- Paso 8: Exponer el servicio ---
echo "🌐 Exponiendo servicio web en Minikube..."
minikube service static-web-service -n "$NAMESPACE" -p "$PERFIL"

echo "✅ Entorno desplegado con éxito."