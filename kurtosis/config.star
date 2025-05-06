"""
Configuration module for Kurtosis-Orbit.
This module handles processing and validation of user-provided configuration parameters.
"""

# Default configuration values
DEFAULT_CONFIG = {
    "chain_name": "Orbit-Dev-Chain",
    "chain_id": 412346,
    "l1_chain_id": 1337,
    "rollup_mode": True,  # True for rollup, False for anytrust
    "challenge_period_blocks": 20,
    "owner_private_key": "b6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659",  # Dev private key
    "owner_address": "",  # Will be computed from private key if not provided
    "sequencer_address": "",  # Will use owner address if not provided
    "simple_mode": True,  # True for simple mode with one node doing everything
    "validator_count": 1,
    "batch_poster_count": 0,  # Only used if simple_mode is False
    "simple_validator": True,  # True for validator without block validator
    "enable_bridge": True,
    "enable_explorer": False,
    "stake_token": "0x0000000000000000000000000000000000000000",  # ETH by default
    "base_stake": "0"
}

def process_config(args):
    """
    Process and validate user-provided configuration parameters
    
    Args:
        args: Dictionary containing user-provided configuration parameters
        
    Returns:
        Configuration object containing validated parameters
    """
    # Start with default configuration
    config_dict = dict(DEFAULT_CONFIG)
    
    # Override with user-provided parameters
    for key, value in args.items():
        if key in config_dict:
            config_dict[key] = value
    
    # Create a struct from the dictionary
    config = struct(**config_dict)
    
    # Validate configuration
    validate_config(config)
    
    # Set derived parameters
    config = set_derived_parameters(config)
    
    return config

def validate_config(config):
    """
    Validate the configuration parameters
    
    Args:
        config: Configuration object
    """
    # Validate chain ID
    if config.chain_id <= 0:
        fail("Chain ID must be greater than 0")
    
    # Validate L1 chain ID
    if config.l1_chain_id <= 0:
        fail("L1 chain ID must be greater than 0")
    
    # Validate challenge period
    if config.challenge_period_blocks <= 0:
        fail("Challenge period blocks must be greater than 0")
    
    # Validate batch poster count
    if config.batch_poster_count < 0:
        fail("Batch poster count must be non-negative")
    
    # Validate validator count
    if config.validator_count < 0:
        fail("Validator count must be non-negative")
    
    # Validate owner private key
    if len(config.owner_private_key) != 64:
        fail("Owner private key must be 64 characters (32 bytes) long without '0x' prefix")

def set_derived_parameters(config):
    """
    Set derived parameters based on existing configuration
    
    Args:
        config: Configuration object
        
    Returns:
        Updated configuration object
    """
    # Create a dictionary from the config struct
    config_dict = {k: getattr(config, k) for k in dir(config) if not k.startswith("_")}
    
    # If owner address is not provided, compute it from private key
    if not config_dict["owner_address"]:
        # In a real implementation, we would compute the address from the private key
        # For now, use a default address corresponding to the default private key
        if config_dict["owner_private_key"] == DEFAULT_CONFIG["owner_private_key"]:
            config_dict["owner_address"] = "0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E"
    
    # If sequencer address is not provided, use owner address
    if not config_dict["sequencer_address"]:
        config_dict["sequencer_address"] = config_dict["owner_address"]
    
    # Return a new struct with the updated values
    return struct(**config_dict)