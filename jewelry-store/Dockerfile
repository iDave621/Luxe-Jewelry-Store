# Build stage
FROM node:16-alpine as build

WORKDIR /app

# Accept build arguments for API URLs
ARG REACT_APP_API_BASE_URL=/api
ARG REACT_APP_AUTH_BASE_URL=/auth

# Set as environment variables for the build
ENV REACT_APP_API_BASE_URL=$REACT_APP_API_BASE_URL
ENV REACT_APP_AUTH_BASE_URL=$REACT_APP_AUTH_BASE_URL

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Build the application
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy the built app from the build stage
COPY --from=build /app/build /usr/share/nginx/html

# Copy nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
