# Build Stage
FROM node:20-alpine AS build
WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm install

# Copy source and build
COPY . .
RUN npm run build -- --configuration production

# Final Runtime Stage (Nginx)
FROM nginx:alpine
# Copy build output to nginx folder
# Note: Angular 17+ typically builds to dist/mhlangafin/browser
COPY --from=build /app/dist/mhlangafin/browser /usr/share/nginx/html

# Custom nginx config to handle Angular routing
RUN echo 'server { \
    listen 80; \
    location / { \
        root /usr/share/nginx/html; \
        index index.html index.htm; \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
