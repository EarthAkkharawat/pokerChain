# Use the official Node.js 20.10.0 image as the base image
FROM node:20.10.0

# Set the working directory inside the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json to the working directory
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code to the working directory
COPY . .

# Expose the port on which your application will run (adjust as needed)
EXPOSE 3000

# Command to run your application
CMD ["npm", "start"]
