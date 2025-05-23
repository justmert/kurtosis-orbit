FROM node:18-bullseye-slim

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y git python3 make gcc g++ curl jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set token bridge version (can be overridden at build time)
ARG TOKEN_BRIDGE_BRANCH=v1.2.2

# Install Foundry (required for token bridge contracts)
RUN curl -L https://foundry.paradigm.xyz | bash
ENV PATH="${PATH}:/root/.foundry/bin"
RUN foundryup --install 1.0.0

# Set working directory
WORKDIR /workspace

# Clone the token bridge repository and checkout the specified branch
RUN git clone --no-checkout https://github.com/OffchainLabs/token-bridge-contracts.git ./ && \
    git checkout ${TOKEN_BRIDGE_BRANCH}

# Install dependencies and build
RUN yarn install && yarn cache clean
RUN yarn build

# Copy the deployment script
COPY deploy-token-bridge.sh /workspace/deploy-token-bridge.sh
RUN chmod +x /workspace/deploy-token-bridge.sh

# No entrypoint - allows running any command directly