# Kurtosis-Orbit

> Deploy and manage Arbitrum Orbit chains with ease using Kurtosis

Kurtosis-Orbit is a comprehensive deployment tool that allows you to spin up complete Arbitrum Orbit rollup environments in minutes. Built on top of [Kurtosis](https://kurtosis.com/), it provides a simple, reproducible way to deploy L2 chains for development, testing, and experimentation.

## ✨ Features

- **🚀 One-command deployment** - Deploy a complete Orbit stack with a single command
- **🔧 Highly configurable** - Customize chain parameters, rollup mode, and infrastructure settings
- **🔑 Pre-funded accounts** - Development accounts with ETH ready for immediate testing
- **🌉 Bridge integration** - Built-in token bridge between L1 and L2
- **📊 Monitoring ready** - Optional Blockscout explorer for transaction monitoring
- **🐳 Docker** - Run locally with Docker

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

## 📖 Documentation

- **[Getting Started Guide](./docs/getting-started.md)** - Step-by-step deployment walkthrough
- **[Installation Guide](./docs/installation.md)** - Detailed installation instructions
- **[Configuration Reference](./docs/configuration.md)** - All available configuration options
- **[Account Management](./docs/accounts.md)** - Working with development accounts
- **[Architecture Overview](./docs/architecture.md)** - How Kurtosis-Orbit works
- **[Troubleshooting](./docs/troubleshooting.md)** - Common issues and solutions
- **[Analytics System](./analytics/README.md)** - Download tracking and usage statistics

## 📊 Analytics & Usage Tracking

Kurtosis-Orbit includes an optional analytics system that helps us understand how the project is being used and improve the user experience. The analytics system tracks:

- **Download counts** from various sources (GitHub, Kurtosis registry, etc.)
- **Deployment success rates** and common failure patterns
- **Usage patterns** to identify popular configurations
- **Performance metrics** to optimize deployment times

### Privacy First

- All tracking is **completely anonymous**
- IP addresses are **hashed with salt** for privacy
- **No personal information** is collected or stored
- Users can **opt-out** at any time via configuration

### View Live Analytics

Check out the live analytics dashboard at: [analytics.kurtosis-orbit.dev](https://analytics.kurtosis-orbit.dev)

### Disable Analytics

To disable analytics tracking, add this to your configuration:

```yaml
orbit_config:
  enable_analytics: false
```

Or set the environment variable:
```bash
export KURTOSIS_ORBIT_ANALYTICS=false
```

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- [Kurtosis Documentation](https://docs.kurtosis.com/)
- [Arbitrum Documentation](https://docs.arbitrum.io/)
- [Arbitrum Orbit](https://arbitrum.io/orbit)
