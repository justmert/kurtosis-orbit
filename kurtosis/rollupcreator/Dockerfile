FROM node:18-bullseye-slim

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y git curl jq python3 make gcc g++ && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set Nitro contracts version (can be overridden at build time)
ARG NITRO_CONTRACTS_BRANCH=v2.1.1-beta.0

# Set working directory
WORKDIR /app

# Clone the nitro-contracts repository and checkout the specified branch
RUN git clone --no-checkout https://github.com/OffchainLabs/nitro-contracts.git ./ && \
    git checkout ${NITRO_CONTRACTS_BRANCH} && \
    rm -rf .git && \
    git init && \
    git add . && \
    git -c user.name="user" -c user.email="user@example.com" commit -m "Initial commit"

# Install dependencies and build
RUN npm install && npm cache clean --force
RUN npm run build

# Install Orbit SDK
RUN npm install @arbitrum/orbit-sdk@latest ethers@5.7.2

# Copy deployment scripts
COPY deploy_orbit.js /app/scripts/deploy_orbit.js
COPY create_rollup.js /app/scripts/create_rollup.js

# Create a simple entry point script
RUN echo '#!/bin/sh\nnode /app/scripts/deploy_orbit.js\n' > /app/create-rollup.sh && \
    chmod +x /app/create-rollup.sh

# Set entrypoint to the create rollup script
ENTRYPOINT ["/app/create-rollup.sh"]