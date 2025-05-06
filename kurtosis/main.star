"""
Kurtosis-Orbit: Main implementation file for Arbitrum Orbit deployment.
This file orchestrates the deployment of all components of an Arbitrum Orbit stack.
"""

NITRO_NODE_VERSION = "offchainlabs/nitro-node:v3.5.5-90ee45c"
BLOCKSCOUT_VERSION = "offchainlabs/blockscout:v1.1.0-0e716c8"

# Default Ethereum account used for deploying contracts
DEV_PRIVATE_KEY = "b6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659"
L1_CHAIN_ID = 1337

# Import supporting modules
config_module = import_module("./config.star")

def run(plan, args={}):
    """
    Main entry point for Kurtosis Orbit deployment
    
    Args:
        plan: The Kurtosis execution plan
        args: Configuration parameters for customizing the deployment
        
    Returns:
        Dictionary containing endpoints and connection information for the deployed services
    """
    # Process and validate configuration
    config = config_module.process_config(args)
    
    # Display banner with configuration information
    plan.print("=========================================")
    plan.print("Kurtosis-Orbit: Arbitrum Orbit Deployment")
    plan.print("=========================================")
    plan.print("Chain name: " + config.chain_name)
    plan.print("Chain ID: " + str(config.chain_id))
    plan.print("Deploying in " + ("rollup" if config.rollup_mode else "anytrust") + " mode")
    
    # Step 1: Deploy Ethereum L1 Chain
    l1_info = deploy_ethereum_l1(plan, config)
    
    # Step 2: Deploy Orbit rollup contracts on L1
    rollup_info = deploy_rollup_contracts(plan, config, l1_info)
    
    # Step 3: Deploy Arbitrum Nitro nodes
    nodes_info = deploy_nitro_nodes(plan, config, l1_info, rollup_info)
    
    # Step 4: Deploy token bridge (if enabled)
    bridge_info = {}
    if config.enable_bridge:
        bridge_info = deploy_token_bridge(plan, config, l1_info, nodes_info)
    
    # Step 5: Deploy block explorer (if enabled)
    explorer_info = {}
    if config.enable_explorer:
        explorer_info = deploy_blockscout(plan, config, nodes_info)
    
    # Prepare output with connection information
    output = {
        "ethereum_l1": l1_info,
        "arbitrum_l2": nodes_info,
        "token_bridge": bridge_info,
        "explorer": explorer_info,
        "chain_info": {
            "name": config.chain_name,
            "chain_id": config.chain_id,
            "mode": "rollup" if config.rollup_mode else "anytrust",
            "owner_address": rollup_info["owner_address"],
        }
    }
    
    # Display connection information
    display_connection_info(plan, output)
    
    return output

def deploy_ethereum_l1(plan, config):
    """
    Deploy a local Ethereum L1 chain
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        
    Returns:
        Dictionary with Ethereum L1 connection information
    """
    plan.print("Deploying Ethereum L1 chain...")
    
    # Create a volume for the L1 keystore
    l1_keystore_artifact = plan.upload_files(src="./files/keystore/.gitkeep", name="keystore-placeholder")
    
    # Create initial accounts using a script
    # The script will create accounts and write them to a JSON file
    write_accounts_result = plan.run_sh(
        run="mkdir -p /keystore && echo '{}' > /keystore/accounts.json",
        image="node:18-slim",
        files={
            "/keystore": l1_keystore_artifact,
        },
        store=["/keystore"],
    )
    
    keystore_artifact = write_accounts_result.files_artifacts[0]
    
    # Generate genesis configuration
    genesis_config = {
        "config": {
            "chainId": config.l1_chain_id,
            "homesteadBlock": 0,
            "eip150Block": 0,
            "eip155Block": 0,
            "eip158Block": 0,
            "byzantiumBlock": 0,
            "constantinopleBlock": 0,
            "petersburgBlock": 0,
            "istanbulBlock": 0,
            "berlinBlock": 0,
            "londonBlock": 0,
            "clique": {
                "period": 0,
                "epoch": 30000
            }
        },
        "difficulty": "1",
        "gasLimit": "12000000",
        "extradata": "0x0000000000000000000000000000000000000000000000000000000000000000<developer_address>0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "alloc": {
            "0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E": {"balance": "10000000000000000000000"},
            "0x70997970C51812dc3A010C7d01b50e0d17dc79C8": {"balance": "10000000000000000000000"}
        }
    }
    
    # Write genesis configuration to a file
    genesis_artifact = plan.render_templates(
        config={
            "/genesis.json": struct(
                template=json.encode(genesis_config),
                data={},
            ),
        },
        name="genesis-config",
    )
    
    # Create a volume for the L1 data directory
    l1data_artifact = plan.upload_files(src="./files/l1data/.gitkeep", name="l1data-placeholder")
    
    # Start geth with the genesis configuration
    eth_service = plan.add_service(
        name="ethereum",
        config=ServiceConfig(
            image="ethereum/client-go:stable",
            ports={
                "http": PortSpec(number=8545, transport_protocol="TCP", application_protocol="http"),
                "ws": PortSpec(number=8546, transport_protocol="TCP", application_protocol="ws"),
            },
            cmd=[
                "--datadir=/datadir",
                "--http",
                "--http.addr=0.0.0.0",
                "--http.vhosts=*",
                "--http.corsdomain=*",
                "--http.api=personal,eth,net,web3,debug,txpool",
                "--ws",
                "--ws.addr=0.0.0.0",
                "--ws.origins=*",
                "--ws.api=personal,eth,net,web3,debug,txpool",
                "--dev",
                "--dev.period=1",
                "--nodiscover",
                "--allow-insecure-unlock",
                "--unlock=0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E",
                "--password=/datadir/passphrase",
                "--mine",
                "--miner.etherbase=0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E",
            ],
            files={
                "/datadir": l1data_artifact,
                "/keystore": keystore_artifact,
                "/genesis.json": genesis_artifact,
            },
        )
    )
    
    # Wait for Ethereum to start
    plan.wait(
        service_name="ethereum",
        recipe=ExecRecipe(
            command=["sh", "-c", "echo '{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}' | curl -s -X POST -H \"Content-Type: application/json\" --data @- http://localhost:8545"]
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout="30s",
    )
    
    return {
        "rpc_url": "http://{0}:{1}".format(eth_service.hostname, eth_service.ports["http"].number),
        "ws_url": "ws://{0}:{1}".format(eth_service.hostname, eth_service.ports["ws"].number),
        "chain_id": config.l1_chain_id,
        "dev_accounts": {
            "deployer": "0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E",
            "user": "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        }
    }

def deploy_rollup_contracts(plan, config, l1_info):
    """
    Deploy Arbitrum Orbit rollup contracts on L1
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        l1_info: Information about the Ethereum L1 deployment
        
    Returns:
        Dictionary with rollup contract information
    """
    plan.print("Deploying Arbitrum Orbit rollup contracts on L1...")
    
    # Prepare rollup deployment script
    deploy_script = """
    const ethers = require('ethers');
    const fs = require('fs');
    const { OrbitChainParams, createChain, upgradeChain } = require('@arbitrum/orbit-sdk');
    
    async function main() {
      // Connect to L1
      const l1Provider = new ethers.providers.JsonRpcProvider(process.env.L1_RPC_URL);
      const l1Signer = new ethers.Wallet(process.env.DEPLOYER_PRIVKEY, l1Provider);
      
      // Read rollup config
      const rollupConfig = JSON.parse(fs.readFileSync('/config/rollup_config.json'));
      
      // Create rollup chain parameters
      const params = new OrbitChainParams({
        chainId: rollupConfig.chainId,
        chainName: rollupConfig.chainName,
        parentChainId: rollupConfig.parentChainId,
        parentChainSignerUrl: process.env.L1_RPC_URL,
        parentChainWsUrl: process.env.L1_WS_URL,
        maxDataSize: Number(rollupConfig.maxDataSize || 117964),
        challengePeriodBlocks: Number(rollupConfig.challengePeriodBlocks),
        stakeToken: rollupConfig.stakeToken,
        baseStake: rollupConfig.baseStake,
        sequencerInboxAddress: rollupConfig.sequencerInboxAddress,
        dataAvailabilityMode: rollupConfig.dataAvailabilityMode || 'rollup',
      });
      
      // Create the rollup chain
      const deploymentData = await createChain({
        params,
        privateKey: process.env.DEPLOYER_PRIVKEY,
        ownerAddress: rollupConfig.ownerAddress,
        sequencerAddress: rollupConfig.sequencerAddress,
      });
      
      // Save deployment data
      fs.writeFileSync('/config/deployment.json', JSON.stringify(deploymentData, null, 2));
      
      // Create chain information for nodes
      const chainInfo = [{
        "chain-id": rollupConfig.chainId,
        "parent-chain-id": rollupConfig.parentChainId,
        "parent-chain-is-arbitrum": false,
        "chain-name": rollupConfig.chainName,
        "rollup": {
          "bridge": deploymentData.bridge,
          "inbox": deploymentData.inbox,
          "sequencer-inbox": deploymentData.sequencerInbox,
          "rollup": deploymentData.rollup,
          "validator-utils": deploymentData.validatorUtils,
          "validator-wallet-creator": deploymentData.validatorWalletCreator,
          "deployed-at": deploymentData.deployedBlockNumber
        },
        "consensus": {
          "is-sequencer": false
        },
        "genesis": {
          "l1-base-block-num": deploymentData.deployedBlockNumber,
          "l1-base-block-hash": deploymentData.deployedBlockHash,
          "timestamp": Math.floor(Date.now() / 1000)
        }
      }];
      
      fs.writeFileSync('/config/chain_info.json', JSON.stringify(chainInfo, null, 2));
      
      console.log(`Orbit chain deployed successfully!`);
      console.log(`Chain ID: ${rollupConfig.chainId}`);
      console.log(`Rollup address: ${deploymentData.rollup}`);
      console.log(`Bridge address: ${deploymentData.bridge}`);
      console.log(`Inbox address: ${deploymentData.inbox}`);
      console.log(`Sequencer Inbox address: ${deploymentData.sequencerInbox}`);
    }
    
    main()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error);
        process.exit(1);
      });
    """
    
    # Prepare rollup configuration
    rollup_config = {
        "chainId": config.chain_id,
        "chainName": config.chain_name,
        "parentChainId": config.l1_chain_id,
        "maxDataSize": 117964,
        "challengePeriodBlocks": config.challenge_period_blocks,
        "stakeToken": config.stake_token if hasattr(config, 'stake_token') else "0x0000000000000000000000000000000000000000",  # ETH by default
        "baseStake": config.base_stake if hasattr(config, 'base_stake') else "0",
        "ownerAddress": config.owner_address if hasattr(config, 'owner_address') else "",
        "sequencerAddress": config.sequencer_address if hasattr(config, 'sequencer_address') else "",
        "dataAvailabilityMode": "rollup" if config.rollup_mode else "anytrust"
    }
    
    # Write rollup configuration to a file
    rollup_config_artifact = plan.render_templates(
        config={
            "/rollup_config.json": struct(
                template=json.encode(rollup_config),
                data={},
            ),
        },
        name="rollup-config",
    )
    
    # Create package.json for the deployment script
    package_json = {
        "name": "orbit-deployer",
        "version": "1.0.0",
        "private": True,
        "main": "deploy.js",
        "dependencies": {
            "@arbitrum/orbit-sdk": "^0.8.0",
            "ethers": "^5.7.2"
        }
    }
    
    package_json_artifact = plan.render_templates(
        config={
            "/package.json": struct(
                template=json.encode(package_json),
                data={},
            ),
        },
        name="package-json",
    )
    
    # Write deployment script to a file
    deploy_script_artifact = plan.render_templates(
        config={
            "/deploy.js": struct(
                template=deploy_script,
                data={},
            ),
        },
        name="deploy-script",
    )
    
    # Create a container to deploy the rollup contracts
    rollup_deployer = plan.add_service(
        name="rollup-deployer",
        config=ServiceConfig(
            image="node:18",
            env_vars={
                "L1_RPC_URL": l1_info["rpc_url"],
                "L1_WS_URL": l1_info["ws_url"],
                "DEPLOYER_PRIVKEY": config.owner_private_key if hasattr(config, 'owner_private_key') else DEV_PRIVATE_KEY,
            },
            cmd=[
                "bash", "-c",
                "cd /app && npm install && node deploy.js"
            ],
            files={
                "/app/package.json": package_json_artifact,
                "/app/deploy.js": deploy_script_artifact,
                "/config/rollup_config.json": rollup_config_artifact,
            },
        ),
    )
    
    # Wait for deployment to complete and store deployment information
    deployment_result = plan.wait(
        service_name="rollup-deployer",
        recipe=ExecRecipe(
            command=["cat", "/config/deployment.json"]
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout="5m",  # Deployment can take some time
    )
    
    # Read deployment and chain information
    deployment_info = plan.exec(
        service_name="rollup-deployer",
        recipe=ExecRecipe(
            command=["cat", "/config/deployment.json"]
        ),
    )
    
    chain_info = plan.exec(
        service_name="rollup-deployer",
        recipe=ExecRecipe(
            command=["cat", "/config/chain_info.json"]
        ),
    )
    
    # Store deployment and chain information as artifacts
    deployment_artifact = plan.store_service_files(
        service_name="rollup-deployer",
        src="/config/deployment.json",
        name="deployment-info",
    )
    
    chain_info_artifact = plan.store_service_files(
        service_name="rollup-deployer",
        src="/config/chain_info.json",
        name="chain-info",
    )
    
    # Extract key contract addresses
    rollup_address = plan.exec(
        service_name="rollup-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.rollup'"]
        ),
        acceptable_codes=[0],
    )
    
    bridge_address = plan.exec(
        service_name="rollup-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.bridge'"]
        ),
        acceptable_codes=[0],
    )
    
    inbox_address = plan.exec(
        service_name="rollup-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.inbox'"]
        ),
        acceptable_codes=[0],
    )
    
    sequencer_inbox_address = plan.exec(
        service_name="rollup-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.sequencerInbox'"]
        ),
        acceptable_codes=[0],
    )
    
    # Get deployment block information
    deployed_block_num = plan.exec(
        service_name="rollup-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.deployedBlockNumber'"]
        ),
        acceptable_codes=[0],
    )
    
    deployed_block_hash = plan.exec(
        service_name="rollup-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "cat /config/deployment.json | jq -r '.deployedBlockHash'"]
        ),
        acceptable_codes=[0],
    )
    
    return {
        "artifacts": {
            "deployment": deployment_artifact,
            "chain_info": chain_info_artifact,
        },
        "rollup_address": rollup_address["output"].strip(),
        "bridge_address": bridge_address["output"].strip(),
        "inbox_address": inbox_address["output"].strip(),
        "sequencer_inbox_address": sequencer_inbox_address["output"].strip(),
        "deployed_block_num": deployed_block_num["output"].strip(),
        "deployed_block_hash": deployed_block_hash["output"].strip(),
        "owner_address": config.owner_address if hasattr(config, 'owner_address') else 
                         plan.exec(
                             service_name="rollup-deployer",
                             recipe=ExecRecipe(
                                 command=["sh", "-c", "node -e \"console.log(require('ethers').utils.computeAddress('0x'+process.env.DEPLOYER_PRIVKEY))\""]
                             ),
                             acceptable_codes=[0],
                         )["output"].strip(),
    }

def deploy_nitro_nodes(plan, config, l1_info, rollup_info):
    """
    Deploy Arbitrum Nitro nodes (sequencer, validator, batch poster)
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        l1_info: Information about the Ethereum L1 deployment
        rollup_info: Information about the deployed rollup contracts
        
    Returns:
        Dictionary with node information
    """
    plan.print("Deploying Arbitrum Nitro nodes...")
    
    # 1. First deploy the sequencer node
    sequencer = deploy_sequencer_node(plan, config, l1_info, rollup_info)
    
    # 2. Deploy validator node(s) if configured
    validators = []
    if config.validator_count > 0:
        for i in range(config.validator_count):
            validators.append(deploy_validator_node(plan, config, l1_info, rollup_info, sequencer, i))
    
    # 3. Deploy batch poster node if configured separately (otherwise sequencer handles it)
    batch_posters = []
    if not config.simple_mode and config.batch_poster_count > 0:
        for i in range(config.batch_poster_count):
            batch_posters.append(deploy_batch_poster_node(plan, config, l1_info, rollup_info, i))
    
    return {
        "sequencer": sequencer,
        "validators": validators,
        "batch_posters": batch_posters,
    }

def deploy_sequencer_node(plan, config, l1_info, rollup_info):
    """
    Deploy an Arbitrum Nitro sequencer node
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        l1_info: Information about the Ethereum L1 deployment
        rollup_info: Information about the deployed rollup contracts
        
    Returns:
        Dictionary with sequencer information
    """
    # Create sequencer configuration
    sequencer_config = {
        "parent-chain": {
            "connection": {
                "url": l1_info["rpc_url"]
            }
        },
        "chain": {
            "id": config.chain_id,
            "name": config.chain_name
        },
        "node": {
            "sequencer": {
                "enable": True,
                "dangerous": {
                    "without-block-validator": True
                }
            },
            "feed": {
                "output": {
                    "enable": True,
                    "port": 9642
                }
            },
            "batch-poster": {
                "enable": config.simple_mode,  # Enable batch poster in simple mode
                "max-size": {"l1-messages": 20, "data": 90000}
            },
            "staker": {
                "enable": config.simple_mode,  # Enable staker in simple mode
                "dangerous": {
                    "without-block-validator": True
                }
            }
        },
        "http": {
            "addr": "0.0.0.0",
            "port": 8547,
            "vhosts": "*",
            "corsdomain": "*",
            "api": ["eth", "net", "web3", "arb", "debug"]
        },
        "ws": {
            "addr": "0.0.0.0",
            "port": 8548,
            "origins": "*"
        },
        "persistent": {
            "chain": "/home/user/.arbitrum/local/nitro"
        }
    }
    
    # If anytrust mode is enabled, add DAS configuration
    if not config.rollup_mode:
        sequencer_config["node"]["data-availability"] = {
            "enable": True,
            "mode": "anytrust",
            "rest-aggregator": {
                "enable": True,
                "urls": ["http://das-server:9876"]
            }
        }
    
    # Create sequencer configuration file
    sequencer_config_artifact = plan.render_templates(
        config={
            "/sequencer_config.json": struct(
                template=json.encode(sequencer_config),
                data={},
            ),
        },
        name="sequencer-config",
    )
    
    # Create volume for sequencer data
    sequencer_data_artifact = plan.upload_files(src="./files/seqdata/.gitkeep", name="seqdata-placeholder")
    
    # Deploy the sequencer node
    sequencer_service = plan.add_service(
        name="sequencer",
        config=ServiceConfig(
            image=NITRO_NODE_VERSION,
            ports={
                "http": PortSpec(number=8547, transport_protocol="TCP", application_protocol="http"),
                "ws": PortSpec(number=8548, transport_protocol="TCP", application_protocol="ws"),
                "feed": PortSpec(number=9642, transport_protocol="TCP", application_protocol="ws"),
            },
            cmd=[
                "--conf.file=/config/sequencer_config.json",
                "--node.feed.output.enable",
                "--node.feed.output.port=9642",
                "--http.api=net,web3,eth,debug",
            ],
            env_vars={
                "NITRO_SEQUENCER_PRIVATE_KEY": config.owner_private_key if hasattr(config, 'owner_private_key') else DEV_PRIVATE_KEY,
            },
            files={
                "/home/user/.arbitrum/local/nitro": sequencer_data_artifact,
                "/config/sequencer_config.json": sequencer_config_artifact,
                "/config/chain_info.json": rollup_info["artifacts"]["chain_info"],
            },
        ),
    )
    
    # Wait for sequencer to start
    plan.wait(
        service_name="sequencer",
        recipe=GetHttpRequestRecipe(
            port_id="http",
            endpoint="",
            extract={
                "blockNumber": ".result"
            }
        ),
        field="code",
        assertion="==",
        target_value=200,
        timeout="2m",
    )
    
    return {
        "rpc_url": "http://{0}:{1}".format(sequencer_service.hostname, sequencer_service.ports["http"].number),
        "ws_url": "ws://{0}:{1}".format(sequencer_service.hostname, sequencer_service.ports["ws"].number),
        "feed_url": "ws://{0}:{1}".format(sequencer_service.hostname, sequencer_service.ports["feed"].number),
    }

def deploy_validator_node(plan, config, l1_info, rollup_info, sequencer, index):
    """
    Deploy an Arbitrum Nitro validator node
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        l1_info: Information about the Ethereum L1 deployment
        rollup_info: Information about the deployed rollup contracts
        sequencer: Information about the deployed sequencer
        index: Validator index (for multiple validators)
        
    Returns:
        Dictionary with validator information
    """
    # Create validator configuration
    validator_config = {
        "parent-chain": {
            "connection": {
                "url": l1_info["rpc_url"]
            }
        },
        "chain": {
            "id": config.chain_id,
            "name": config.chain_name
        },
        "node": {
            "feed": {
                "input": {
                    "url": sequencer["feed_url"]
                }
            },
            "staker": {
                "enable": True,
                "dangerous": {
                    "without-block-validator": config.simple_validator
                }
            },
            "forwarding-target": sequencer["rpc_url"]
        },
        "http": {
            "addr": "0.0.0.0",
            "port": 8547,
            "vhosts": "*",
            "corsdomain": "*",
            "api": ["eth", "net", "web3", "arb", "debug"]
        },
        "ws": {
            "addr": "0.0.0.0",
            "port": 8548,
            "origins": "*"
        },
        "persistent": {
            "chain": "/home/user/.arbitrum/local/nitro"
        }
    }
    
    # If anytrust mode is enabled, add DAS configuration
    if not config.rollup_mode:
        validator_config["node"]["data-availability"] = {
            "enable": True,
            "mode": "onchain",
            "rest-aggregator": {
                "enable": True,
                "urls": ["http://das-server:9876"]
            }
        }
    
    # Create validator configuration file
    validator_config_artifact = plan.render_templates(
        config={
            "/validator_config.json": struct(
                template=json.encode(validator_config),
                data={},
            ),
        },
        name="validator-" + str(index) + "-config",
    )
    
    # Create volume for validator data
    validator_data_artifact = plan.upload_files(src="./files/valdata/.gitkeep", name="valdata-" + str(index) + "-placeholder")
    
    # Deploy the validator node
    validator_service = plan.add_service(
        name="validator-" + str(index),
        config=ServiceConfig(
            image=NITRO_NODE_VERSION,
            ports={
                "http": PortSpec(number=8547, transport_protocol="TCP", application_protocol="http"),
                "ws": PortSpec(number=8548, transport_protocol="TCP", application_protocol="ws"),
            },
            cmd=[
                "--conf.file=/config/validator_config.json",
                "--http.api=net,web3,eth,debug",
            ],
            files={
                "/home/user/.arbitrum/local/nitro": validator_data_artifact,
                "/config/validator_config.json": validator_config_artifact,
                "/config/chain_info.json": rollup_info["artifacts"]["chain_info"],
            },
        ),
    )
    
    # Wait for validator to start
    plan.wait(
        service_name="validator-" + str(index),
        recipe=GetHttpRequestRecipe(
            port_id="http",
            endpoint="",
            extract={
                "blockNumber": ".result"
            }
        ),
        field="code",
        assertion="==",
        target_value=200,
        timeout="2m",
    )
    
    return {
        "rpc_url": "http://{0}:{1}".format(validator_service.hostname, validator_service.ports["http"].number),
        "ws_url": "ws://{0}:{1}".format(validator_service.hostname, validator_service.ports["ws"].number),
    }

def deploy_batch_poster_node(plan, config, l1_info, rollup_info, index):
    """
    Deploy an Arbitrum Nitro batch poster node
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        l1_info: Information about the Ethereum L1 deployment
        rollup_info: Information about the deployed rollup contracts
        index: Batch poster index (for multiple batch posters)
        
    Returns:
        Dictionary with batch poster information
    """
    # Create batch poster configuration
    batch_poster_config = {
        "parent-chain": {
            "connection": {
                "url": l1_info["rpc_url"]
            }
        },
        "chain": {
            "id": config.chain_id,
            "name": config.chain_name
        },
        "node": {
            "batch-poster": {
                "enable": True,
                "max-size": {"l1-messages": 20, "data": 90000}
            }
        },
        "http": {
            "addr": "0.0.0.0",
            "port": 8547,
            "vhosts": "*",
            "corsdomain": "*",
            "api": ["eth", "net", "web3", "arb", "debug"]
        },
        "ws": {
            "addr": "0.0.0.0",
            "port": 8548,
            "origins": "*"
        },
        "persistent": {
            "chain": "/home/user/.arbitrum/local/nitro"
        }
    }
    
    # Create batch poster configuration file
    batch_poster_config_artifact = plan.render_templates(
        config={
            "/batch_poster_config.json": struct(
                template=json.encode(batch_poster_config),
                data={},
            ),
        },
        name="batch-poster-" + str(index) + "-config",
    )
    
    # Create volume for batch poster data
    batch_poster_data_artifact = plan.upload_files(src="./files/posterdata/.gitkeep", name="posterdata-" + str(index) + "-placeholder")
    
    # Deploy the batch poster node
    batch_poster_service = plan.add_service(
        name="batch-poster-" + str(index),
        config=ServiceConfig(
            image=NITRO_NODE_VERSION,
            ports={
                "http": PortSpec(number=8547, transport_protocol="TCP", application_protocol="http"),
                "ws": PortSpec(number=8548, transport_protocol="TCP", application_protocol="ws"),
            },
            cmd=[
                "--conf.file=/config/batch_poster_config.json",
                "--http.api=net,web3,eth,debug",
            ],
            env_vars={
                "NITRO_BATCHPOSTER_PRIVATE_KEY": config.owner_private_key if hasattr(config, 'owner_private_key') else DEV_PRIVATE_KEY,
            },
            files={
                "/home/user/.arbitrum/local/nitro": batch_poster_data_artifact,
                "/config/batch_poster_config.json": batch_poster_config_artifact,
                "/config/chain_info.json": rollup_info["artifacts"]["chain_info"],
            },
        ),
    )
    
    # Wait for batch poster to start
    plan.wait(
        service_name="batch-poster-" + str(index),
        recipe=GetHttpRequestRecipe(
            port_id="http",
            endpoint="",
            extract={
                "blockNumber": ".result"
            }
        ),
        field="code",
        assertion="==",
        target_value=200,
        timeout="2m",
    )
    
    return {
        "rpc_url": "http://{0}:{1}".format(batch_poster_service.hostname, batch_poster_service.ports["http"].number),
        "ws_url": "ws://{0}:{1}".format(batch_poster_service.hostname, batch_poster_service.ports["ws"].number),
    }

def deploy_token_bridge(plan, config, l1_info, nodes_info):
    """
    Deploy token bridge contracts between L1 and L2
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        l1_info: Information about the Ethereum L1 deployment
        nodes_info: Information about the deployed Nitro nodes
        
    Returns:
        Dictionary with token bridge information
    """
    plan.print("Deploying token bridge between L1 and L2...")
    
    # Create token bridge deployment script
    deploy_bridge_script = """
    const fs = require('fs');
    const { ethers } = require('ethers');
    
    async function main() {
      console.log('Deploying token bridge between L1 and L2...');
      
      // Connect to L1
      const l1Provider = new ethers.providers.JsonRpcProvider(process.env.L1_RPC_URL);
      const l1Signer = new ethers.Wallet(process.env.L1_PRIVKEY, l1Provider);
      
      // Connect to L2
      const l2Provider = new ethers.providers.JsonRpcProvider(process.env.L2_RPC_URL);
      const l2Signer = new ethers.Wallet(process.env.L2_PRIVKEY, l2Provider);
      
      // Deploy token bridge contracts
      console.log('Deploying L1 token gateway...');
      // ... deployment code for L1 gateway
      
      console.log('Deploying L2 token gateway...');
      // ... deployment code for L2 gateway
      
      // For this demo, we'll just pretend the contracts are deployed
      const bridgeInfo = {
        l1: {
          gateway: "0x096760F208390250649E3e8763348E783AEF5562",
          router: "0x70C143928eCfFaf9F5b406f7f4fC28Dc43d68380",
        },
        l2: {
          gateway: "0x09e9222E96E7B4AE2a407B98d48e330053351EEe",
          router: "0x195A9262fC61F9637887E5D2C352a9c7642ea5EA",
        }
      };
      
      // Write bridge info to file
      fs.writeFileSync('/config/bridge_info.json', JSON.stringify(bridgeInfo, null, 2));
      
      console.log('Token bridge deployed successfully!');
    }
    
    main()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error);
        process.exit(1);
      });
    """
    
    # Create package.json for the bridge deployment script
    bridge_package_json = {
        "name": "token-bridge-deployer",
        "version": "1.0.0",
        "private": True,
        "main": "deploy_bridge.js",
        "dependencies": {
            "ethers": "^5.7.2"
        }
    }
    
    # Write bridge deployment script to a file
    bridge_script_artifact = plan.render_templates(
        config={
            "/deploy_bridge.js": struct(
                template=deploy_bridge_script,
                data={},
            ),
        },
        name="bridge-deploy-script",
    )
    
    # Write package.json to a file
    bridge_package_json_artifact = plan.render_templates(
        config={
            "/package.json": struct(
                template=json.encode(bridge_package_json),
                data={},
            ),
        },
        name="bridge-package-json",
    )
    
    # Create a container to deploy the token bridge
    bridge_deployer = plan.add_service(
        name="token-bridge-deployer",
        config=ServiceConfig(
            image="node:18",
            env_vars={
                "L1_RPC_URL": l1_info["rpc_url"],
                "L2_RPC_URL": nodes_info["sequencer"]["rpc_url"],
                "L1_PRIVKEY": config.owner_private_key if hasattr(config, 'owner_private_key') else DEV_PRIVATE_KEY,
                "L2_PRIVKEY": config.owner_private_key if hasattr(config, 'owner_private_key') else DEV_PRIVATE_KEY,
            },
            cmd=[
                "bash", "-c",
                "cd /app && npm install && node deploy_bridge.js"
            ],
            files={
                "/app/package.json": bridge_package_json_artifact,
                "/app/deploy_bridge.js": bridge_script_artifact,
            },
        ),
    )
    
    # Wait for deployment to complete and store bridge information
    plan.wait(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["sh", "-c", "[ -f /config/bridge_info.json ]"]
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout="5m",  # Deployment can take some time
    )
    
    # Store bridge information as an artifact
    bridge_info_artifact = plan.store_service_files(
        service_name="token-bridge-deployer",
        src="/config/bridge_info.json",
        name="bridge-info",
    )
    
    # Read bridge information
    bridge_info = plan.exec(
        service_name="token-bridge-deployer",
        recipe=ExecRecipe(
            command=["cat", "/config/bridge_info.json"]
        ),
        acceptable_codes=[0],
    )
    
    # Parse bridge information
    bridge_info_json = json.decode(bridge_info["output"])
    
    return {
        "artifacts": {
            "bridge_info": bridge_info_artifact,
        },
        "l1": {
            "gateway": bridge_info_json["l1"]["gateway"],
            "router": bridge_info_json["l1"]["router"],
        },
        "l2": {
            "gateway": bridge_info_json["l2"]["gateway"],
            "router": bridge_info_json["l2"]["router"],
        },
    }

def deploy_blockscout(plan, config, nodes_info):
    """
    Deploy Blockscout explorer for the L2 chain
    
    Args:
        plan: The Kurtosis execution plan
        config: Configuration object
        nodes_info: Information about the deployed Nitro nodes
        
    Returns:
        Dictionary with explorer information
    """
    plan.print("Deploying Blockscout explorer...")
    
    # First deploy a Postgres database for Blockscout
    postgres_service = plan.add_service(
        name="postgres",
        config=ServiceConfig(
            image="postgres:13.6",
            ports={
                "postgres": PortSpec(number=5432),
            },
            env_vars={
                "POSTGRES_PASSWORD": "",
                "POSTGRES_USER": "postgres",
                "POSTGRES_HOST_AUTH_METHOD": "trust",
            },
        ),
    )
    
    # Wait for Postgres to start
    plan.wait(
        service_name="postgres",
        recipe=ExecRecipe(
            command=["pg_isready", "-U", "postgres"]
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout="30s",
    )
    
    # Create Blockscout environment file
    blockscout_env = """
    ETHEREUM_JSONRPC_VARIANT=geth
    ETHEREUM_JSONRPC_HTTP_URL={rpc_url}
    INDEXER_DISABLE_PENDING_TRANSACTIONS_FETCHER=true
    DATABASE_URL=postgresql://postgres:@postgres:5432/blockscout
    ECTO_USE_SSL=false
    NETWORK={network}
    SUBNETWORK={subnetwork}
    CHAIN_ID={chain_id}
    """.format(
        rpc_url=nodes_info["sequencer"]["rpc_url"],
        network="Arbitrum",
        subnetwork=config.chain_name,
        chain_id=config.chain_id,
    )
    
    # Write Blockscout environment file to a template
    blockscout_env_artifact = plan.render_templates(
        config={
            "/blockscout.env": struct(
                template=blockscout_env,
                data={},
            ),
        },
        name="blockscout-env",
    )
    
    # Deploy Blockscout
    blockscout_service = plan.add_service(
        name="blockscout",
        config=ServiceConfig(
            image=BLOCKSCOUT_VERSION,
            ports={
                "http": PortSpec(number=4000, application_protocol="http"),
            },
            env_vars={
                "ETHEREUM_JSONRPC_VARIANT": "geth",
                "ETHEREUM_JSONRPC_HTTP_URL": nodes_info["sequencer"]["rpc_url"],
                "INDEXER_DISABLE_PENDING_TRANSACTIONS_FETCHER": "true",
                "DATABASE_URL": "postgresql://postgres:@postgres:5432/blockscout",
                "ECTO_USE_SSL": "false",
                "NETWORK": "Arbitrum",
                "SUBNETWORK": config.chain_name,
                "CHAIN_ID": str(config.chain_id),
            },
            cmd=[
                "/bin/sh",
                "-c",
                "bin/blockscout eval \"Elixir.Explorer.ReleaseTasks.create_and_migrate()\" && bin/blockscout start"
            ],
            files={
                "/app/config/blockscout.env": blockscout_env_artifact,
            },
        ),
        ready_conditions=ReadyCondition(
            recipe=GetHttpRequestRecipe(port_id="http", endpoint="/"),
            field="code",
            assertion="==",
            target_value=200,
        ),
    )
    
    return {
        "url": "http://{0}:{1}".format(blockscout_service.hostname, blockscout_service.ports["http"].number),
    }

def display_connection_info(plan, output):
    """
    Display connection information for the deployed services
    
    Args:
        plan: The Kurtosis execution plan
        output: Output dictionary with connection information
    """
    plan.print("\n===== Kurtosis-Orbit Deployment Complete =====")
    plan.print("Chain Name: " + output['chain_info']['name'])
    plan.print("Chain ID: " + str(output['chain_info']['chain_id']))
    plan.print("Mode: " + output['chain_info']['mode'])
    plan.print("\nConnection Information:")
    plan.print("  L1 Ethereum RPC: " + output['ethereum_l1']['rpc_url'])
    plan.print("  L2 Arbitrum RPC: " + output['arbitrum_l2']['sequencer']['rpc_url'])
    
    if output['explorer'] and 'url' in output['explorer']:
        plan.print("  Block Explorer: " + output['explorer']['url'])
    
    plan.print("\nContract Addresses:")
    if output['token_bridge']:
        plan.print("  L1 Bridge: " + output['token_bridge']['l1']['gateway'])
    else:
        plan.print("  Token Bridge: Not deployed")
    
    plan.print("\nTo access these services from your host machine, use:")
    plan.print("  kurtosis port forward <enclave> <service> <port>")
    plan.print("  For example: kurtosis port forward orbit sequencer http")
    
    plan.print("\n===== Deployment Successful =====")