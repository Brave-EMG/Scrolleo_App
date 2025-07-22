#!/bin/bash

# Arrêt du script si une erreur survient
set -e

# Installation des dépendances
echo "Installing dependencies..."
npm install

# Vérification de la présence des variables d'environnement requises
echo "Checking environment variables..."
required_vars=("NODE_ENV" "PORT" "POSTGRES_HOST" "POSTGRES_USER" "POSTGRES_PASSWORD" "POSTGRES_DB" "JWT_SECRET" "AWS_ACCESS_KEY_ID" "AWS_SECRET_ACCESS_KEY" "AWS_REGION" "S3_BUCKET")

for var in "${required_vars[@]}"; do
  if [ -z "${!var}" ]; then
    echo "Error: $var is not set"
    exit 1
  fi
done

echo "All required environment variables are set"

# Build completed
echo "Build completed successfully"
