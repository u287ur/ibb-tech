# ---------- STAGE 1: Build the app ----------
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# 🧩 Inject VITE_API_BASE_URL at build time
ARG VITE_API_BASE_URL
ENV VITE_API_BASE_URL=$VITE_API_BASE_URL

# Copy the full source code and build the app
COPY . .
RUN npm run build

# ---------- STAGE 2: Serve the app (no NGINX) ----------
FROM node:18-alpine

# Set working directory
WORKDIR /app

# Install 'serve' to serve static files
RUN npm install -g serve

# Copy build output from the previous stage
COPY --from=builder /app/dist ./dist

# Expose port 8080 for the container
EXPOSE 8080

# Start the app using 'serve'
CMD ["serve", "-s", "dist", "-l", "8080"]
