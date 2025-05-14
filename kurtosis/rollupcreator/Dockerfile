FROM node:18-bullseye-slim

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y git docker.io python3 make gcc g++ curl jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set Nitro contracts version (can be overridden at build time)
ARG NITRO_CONTRACTS_BRANCH=main

# Set working directory
WORKDIR /workspace  

# Clone the nitro-contracts repository and checkout the specified branch
RUN git clone --no-checkout https://github.com/OffchainLabs/nitro-contracts.git ./ && \
    git checkout ${NITRO_CONTRACTS_BRANCH}

# Install dependencies and build
RUN yarn install && yarn cache clean

# Install Foundry
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="${PATH}:/root/.foundry/bin"
RUN foundryup --install 1.0.0

# Set up config and build
RUN touch scripts/config.ts
RUN yarn build:all
