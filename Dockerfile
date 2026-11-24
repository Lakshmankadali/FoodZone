# ---------- Stage 1: build the React app ----------
FROM node:22-alpine AS build
WORKDIR /app

# Copy only the package files first, so Docker can reuse the
# "npm ci" layer when only the source code changes
COPY package.json package-lock.json ./
RUN npm ci

# Copy the rest of the source code and build it into /app/dist
COPY . .
RUN npm run build

# ---------- Stage 2: serve the built files with nginx ----------
FROM nginx:stable-alpine

# Our nginx settings (React routing, health check, caching)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Take ONLY the built files from stage 1. Node.js and the source code stay behind
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

# Docker checks the container is healthy by calling /health every 30 seconds
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD wget -qO- http://localhost/health || exit 1
