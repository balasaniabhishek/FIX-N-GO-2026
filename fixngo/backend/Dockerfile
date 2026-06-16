FROM node:18-alpine

WORKDIR /app

# Copy package.json and package-lock.json first for better layer caching
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy the rest of the backend code
COPY . .

# Expose the port Cloud Run expects
EXPOSE 8080

# Start the server
CMD ["npm", "start"]
