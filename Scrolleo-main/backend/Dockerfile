FROM node:18.17.1-alpine

# Installation des dépendances système nécessaires
RUN apk add --no-cache bash

WORKDIR /app

# Copie des fichiers nécessaires
COPY package*.json ./
COPY build.sh ./

# Rendre le script de build exécutable
RUN chmod +x build.sh

# Installation des dépendances
RUN npm ci

# Copie du reste des fichiers
COPY . .

# Exposition du port
EXPOSE 10000

# Exécution du script de build puis démarrage de l'application
CMD ["sh", "-c", "./build.sh && npm start"]
