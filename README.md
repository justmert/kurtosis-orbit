# Kurtosis-Orbit

> Deploy and manage Arbitrum Orbit chains with ease using Kurtosis

Kurtosis-Orbit is a comprehensive deployment tool that allows you to spin up complete Arbitrum Orbit rollup environments in minutes. Built on top of [Kurtosis](https://kurtosis.com/), it provides a simple, reproducible way to deploy L2 chains for development, testing, and experimentation.

## ✨ Features

- **🚀 One-command deployment** - Deploy a complete Orbit stack with a single command
- **🔧 Highly configurable** - Customize chain parameters, rollup mode, and infrastructure settings
- **🔑 Pre-funded accounts** - Development accounts with ETH ready for immediate testing
- **🌉 Bridge integration** - Built-in token bridge between L1 and L2
- **📊 Monitoring ready** - Optional Blockscout explorer for transaction monitoring
- **🐳 Docker & Kubernetes** - Run locally with Docker or scale on Kubernetes

## 🚀 Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) with 8GB+ RAM allocated
- [Kurtosis CLI](https://docs.kurtosis.com/install) installed

### Deploy Your First Orbit Chain

```bash
# Start Kurtosis engine
kurtosis engine start

# Deploy default Orbit chain
kurtosis run github.com/justmert/kurtosis-orbit

# Access your chain (ports will be shown in output)
# Example: http://localhost:PORT for RPC access
```

### Deploy with Custom Configuration

```bash
# Create custom config
cat << EOF > my-config.yml
orbit_config:
  chain_name: "MyDevChain"
  chain_id: 999888
  enable_explorer: true
EOF

# Deploy with custom settings
kurtosis run github.com/justmert/kurtosis-orbit --args-file my-config.yml
```

## 🏗️ What You Get

After deployment, you'll have a complete Arbitrum Orbit environment including:

- **L1 Ethereum chain** (local Geth + Lighthouse)
- **Arbitrum Orbit L2 chain** (sequencer + validator)
- **Token bridge** for L1 ↔ L2 transfers
- **Pre-funded accounts** with 1000 ETH each
- **Optional block explorer** (Blockscout)

## 🔑 Development Accounts

Ready-to-use accounts for testing:

| Account | Address | Private Key | Purpose |
|---------|---------|-------------|---------|
| Funnel | `0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E` | `b6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659` | General testing |
| Sequencer | `0xe2148eE53c0755215Df69b2616E552154EdC584f` | `cb5790da63720727af975f42c79f69918580209889225fa7128c92402a6d3a65` | Sequencer operations |

> ⚠️ **Warning**: These are development keys only. Never use for real value!

## 📖 Documentation

- **[Getting Started Guide](./docs/getting-started.md)** - Step-by-step deployment walkthrough
- **[Installation Guide](./docs/installation.md)** - Detailed installation instructions
- **[Configuration Reference](./docs/configuration.md)** - All available configuration options
- **[Account Management](./docs/accounts.md)** - Working with development accounts
- **[Architecture Overview](./docs/architecture.md)** - How Kurtosis-Orbit works
- **[Troubleshooting](./docs/troubleshooting.md)** - Common issues and solutions

## 🛠️ Use Cases

- **Arbitrum Development** - Test your dApps on a local Orbit chain
- **Integration Testing** - Validate cross-chain functionality
- **Research & Education** - Learn about Arbitrum rollup architecture
- **Protocol Experimentation** - Try different rollup configurations

## 🤝 Contributing

We welcome contributions! Please feel free to submit issues, feature requests, or pull requests.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Kurtosis Documentation](https://docs.kurtosis.com/)
- [Arbitrum Documentation](https://docs.arbitrum.io/)
- [Arbitrum Orbit](https://arbitrum.io/orbit)
