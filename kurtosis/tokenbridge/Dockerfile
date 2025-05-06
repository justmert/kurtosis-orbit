FROM node:18-bullseye-slim

# Install necessary dependencies
RUN apt-get update && \
    apt-get install -y git docker.io python3 make gcc g++ curl jq && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set token bridge version (can be overridden at build time)
ARG TOKEN_BRIDGE_BRANCH=v1.2.2

# Set working directory
WORKDIR /workspace

# Clone the token bridge repository and checkout the specified branch
RUN git clone --no-checkout https://github.com/OffchainLabs/token-bridge-contracts.git ./ && \
    git checkout ${TOKEN_BRIDGE_BRANCH} && \
    rm -rf .git && \
    git init && \
    git add . && \
    git -c user.name="user" -c user.email="user@example.com" commit -m "Initial commit"

# Install dependencies and build
RUN yarn install && yarn cache clean
RUN yarn build

# Set entrypoint to yarn for easy command execution
ENTRYPOINT ["yarn"]