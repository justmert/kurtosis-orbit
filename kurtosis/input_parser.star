"""
Configuration parser for Kurtosis-Orbit package.

This module handles parsing and validating the input configuration passed to the Kurtosis package.
It provides default values for all parameters and validates user-provided values.
"""

DEFAULT_CHAIN_NAME = "OrbitDevChain"
DEFAULT_CHAIN_ID = 412346  # Random ID outside normal ranges
DEFAULT_L1_CHAIN_ID = 1337  # Standard local testnet chain ID
DEFAULT_ROLLUP_MODE = "rollup"  # Rollup or AnyTrust
DEFAULT_CHALLENGE_PERIOD_BLOCKS = 20  # For dev/test environments
DEFAULT_STAKE_TOKEN = "0x0000000000000000000000000000000000000000"  # ETH as stake token
DEFAULT_BASE_STAKE = "0x0"  # Minimum stake amount required (in wei)
DEFAULT_VALIDATOR_COUNT = 1  # Number of validators to run
DEFAULT_ENABLE_BRIDGE = True  # Enable token bridge
DEFAULT_ENABLE_EXPLORER = False  # Disable block explorer by default to save resources
DEFAULT_NITRO_IMAGE = "offchainlabs/nitro-node:v3.5.5-90ee45c"  # Latest stable version

# Generate a default private key for dev purposes if user doesn't provide one
# NOTE: This is NOT secure for production, only for development and testing
DEFAULT_OWNER_PRIVATE_KEY = "0x8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63"

def new_orbit_config():
    """
    Create a new OrbitConfig object with default values.
    
    Returns:
        A new OrbitConfig object
    """
    return struct(
        # Chain identifiers
        chain_name = DEFAULT_CHAIN_NAME,
        chain_id = DEFAULT_CHAIN_ID,
        l1_chain_id = DEFAULT_L1_CHAIN_ID,
        
        # Rollup configuration
        rollup_mode = DEFAULT_ROLLUP_MODE,
        challenge_period_blocks = DEFAULT_CHALLENGE_PERIOD_BLOCKS,
        stake_token = DEFAULT_STAKE_TOKEN,
        base_stake = DEFAULT_BASE_STAKE,
        
        # Key management
        owner_private_key = DEFAULT_OWNER_PRIVATE_KEY,
        owner_address = "",  # Will be derived from private key
        sequencer_address = "",  # Same as owner by default
        
        # Services configuration
        validator_count = DEFAULT_VALIDATOR_COUNT,
        enable_bridge = DEFAULT_ENABLE_BRIDGE,
        enable_explorer = DEFAULT_ENABLE_EXPLORER,
        
        # Docker images
        nitro_image = DEFAULT_NITRO_IMAGE,
        
        # Optional prefunding
        prefund_addresses = [],
        
        # AnyTrust specific configuration (not used in rollup mode)
        anytrust_config = struct(
            enable_local_das = True,
            das_members = []
        )
    )

def parse_input(args):
    """
    Parse and validate input arguments from the user.
    
    Args:
        args: Dictionary of arguments passed to the Kurtosis package
    
    Returns:
        OrbitConfig object with parsed and validated configuration
    """
    config = new_orbit_config()
    
    # Extract values from Orbit config if present
    orbit_args = args.get("orbit_config", {})
    
    # Parse chain identifiers
    if "chain_name" in orbit_args:
        config.chain_name = orbit_args["chain_name"]
    
    if "chain_id" in orbit_args:
        config.chain_id = int(orbit_args["chain_id"])
        
    if "l1_chain_id" in orbit_args:
        config.l1_chain_id = int(orbit_args["l1_chain_id"])
        
    # Parse rollup configuration
    if "rollup_mode" in orbit_args:
        mode = orbit_args["rollup_mode"].lower()
        if mode in ["rollup", "anytrust"]:
            config.rollup_mode = mode
        else:
            fail("Invalid rollup_mode: must be 'rollup' or 'anytrust'")
            
    if "challenge_period_blocks" in orbit_args:
        config.challenge_period_blocks = int(orbit_args["challenge_period_blocks"])
        
    if "stake_token" in orbit_args:
        config.stake_token = orbit_args["stake_token"]
        
    if "base_stake" in orbit_args:
        config.base_stake = orbit_args["base_stake"]
        
    # Parse key management
    if "owner_private_key" in orbit_args:
        config.owner_private_key = orbit_args["owner_private_key"]
    
    # Owner address will be derived from private key in the deploy script
    
    if "sequencer_address" in orbit_args:
        config.sequencer_address = orbit_args["sequencer_address"]
    else:
        # By default, sequencer is the owner
        config.sequencer_address = config.owner_address
    
    # Parse service configuration
    if "validator_count" in orbit_args:
        config.validator_count = int(orbit_args["validator_count"])
        
    if "enable_bridge" in orbit_args:
        config.enable_bridge = bool(orbit_args["enable_bridge"])
        
    if "enable_explorer" in orbit_args:
        config.enable_explorer = bool(orbit_args["enable_explorer"])
        
    if "nitro_image" in orbit_args:
        config.nitro_image = orbit_args["nitro_image"]
        
    # Parse prefund addresses
    if "prefund_addresses" in orbit_args:
        config.prefund_addresses = orbit_args["prefund_addresses"]
        
    # Parse AnyTrust configuration if needed
    if config.rollup_mode == "anytrust":
        anytrust_args = orbit_args.get("anytrust_config", {})
        
        anytrust_config = {}
        if "enable_local_das" in anytrust_args:
            anytrust_config["enable_local_das"] = bool(anytrust_args["enable_local_das"])
            
        if "das_members" in anytrust_args:
            anytrust_config["das_members"] = anytrust_args["das_members"]
            
        config.anytrust_config = struct(**anytrust_config)
    
    return config