"""
Configuration module with validation and nitro-testnode alignment.
"""

# Standard test mnemonic used by nitro-testnode (same as Hardhat/Ganache)
L1_MNEMONIC = "indoor dish desk flag debris potato excuse depart ticket judge file exit"

# 👤 EXAMPLE USER ACCOUNTS (generated from username):
# =====================================================

# === USER_ALICE ===
# Address:     0xC3c76AaAA7C483c5099aeC225bA5E4269373F16b
# Private Key: 0x5c5c2c164ead6e3f0aa2e8db343277538e644edf994cdf048ca5ca633c822d5e

# === USER_BOB ===
# Address:     0x2EB27d9F51D90C45ea735eE3b68E9BE4AE2aB61f
# Private Key: 0xab65119bd544c8557915190bd5254f6462372c6633b4aba337c38ca59bb11793

# === USER_CHARLIE ===
# Address:     0x940Cfa73a2453C0551059291F680c2779A089d92
# Private Key: 0x631510336d296d16760c135afdba16256a3c9cc7d5a99dd4ec1941c738382e10

# === USER_DAVID ===
# Address:     0x061D1D7DB2087D1dBCc7a551b96727746948017A
# Private Key: 0xd3d398862cb51dc21c2cbcddd411080101c6c2b5b12aacd8050ade241868e4f3

# === USER_EVE ===
# Address:     0xF2425902e61c32569075cA534c3C1a0Ae367EA0D
# Private Key: 0x8cad62e2f7ee3f66664fdb44c5e39ffb929466484d639974a6a1c344af21a614

# Derived from mnemonic
STANDARD_ACCOUNTS = {
    "funnel": {
        "private_key": "b6b15c8cb491557369f3c7d2c287b053eb229daa9c22138887752191c9520659",
        "address": "0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E"
    },
    "sequencer": {
        "private_key": "cb5790da63720727af975f42c79f69918580209889225fa7128c92402a6d3a65",
        "address": "0xe2148eE53c0755215Df69b2616E552154EdC584f"
    },
    "validator": {
        "private_key": "182fecf15bdf909556a0f617a63e05ab22f1493d25a9f1e27c228266c772a890",
        "address": "0x6A568afe0f82d34759347bb36F14A6bB171d2CBe"
    },
    "l3owner": {
        "private_key": "ecdf21cb41c65afb51f91df408b7656e2c8739a5877f2814add0afd780cc210e",
        "address": "0x863c904166E801527125D8672442D736194A3362"
    },
    "l3sequencer": {

        "private_key": "90f899754eb42949567d3576224bf533a20857bf0a60318507b75fcb3edc6f5f",
        "address": "0x3E6134aAD4C4d422FF2A4391Dc315c4DDf98D1a5"
    },
    "l2owner": {
        "private_key": "dc04c5399f82306ec4b4d654a342f40e2e0620fe39950d967e1e574b32d4dd36",
        "address": "0x5E1497dD1f08C87b2d8FE23e9AAB6c1De833D927"
    },
}

# Default configuration aligned with nitro-testnode
DEFAULT_CONFIG = {
    "chain_name": "Orbit-Dev-Chain",
    "chain_id": 412346,
    "l1_chain_id": 1337,
    "rollup_mode": True,
    "challenge_period_blocks": 20,
    "stake_token": "0x0000000000000000000000000000000000000000",
    "base_stake": "0",
    "owner_private_key": STANDARD_ACCOUNTS["l2owner"]["private_key"],
    "owner_address": STANDARD_ACCOUNTS["l2owner"]["address"],
    "sequencer_private_key": STANDARD_ACCOUNTS["sequencer"]["private_key"],
    "sequencer_address": STANDARD_ACCOUNTS["sequencer"]["address"],
    "validator_private_key": STANDARD_ACCOUNTS["validator"]["private_key"],
    "validator_address": STANDARD_ACCOUNTS["validator"]["address"],
    "simple_mode": True,
    "validator_count": 1,
    "enable_bridge": True,
    "enable_explorer": True,
    "enable_timeboost": False,
    "pre_fund_accounts": ["funnel", "sequencer", "validator", "l2owner"],
    "prefund_addresses": [],  # **Added** – allow user-specified prefund addresses
    "nitro_image": "offchainlabs/nitro-node:v3.5.5-90ee45c",
    "nitro_contracts_branch": "v2.1.1-beta.0",
    "token_bridge_branch": "v1.2.2",
}

def process_config(args):
    """
    Process and validate user configuration.
    """
    # Start with defaults
    config_dict = dict(DEFAULT_CONFIG)
    
    # Merge user config with enhanced handling
    if "orbit_config" in args:
        orbit_config = args["orbit_config"]
        for key, value in orbit_config.items():
            if key == "rollup_mode":
                # Accept boolean or string for rollup_mode
                if type(value) == type(True):
                    config_dict["rollup_mode"] = value
                elif str(value).lower() == "anytrust":
                    config_dict["rollup_mode"] = False
                else:
                    config_dict["rollup_mode"] = True  # treat any other value as "rollup"
            elif key in config_dict:
                config_dict[key] = value
            else:
                print("WARNING: Unrecognized config field '{}'; ignoring.".format(key))
        
        # Validate key/address consistency after merging
        if "owner_private_key" in orbit_config and "owner_address" not in orbit_config:
            fail("owner_address must be provided if owner_private_key is overridden, or else the chain owner address will not match the new key.")
        if "sequencer_private_key" in orbit_config and "sequencer_address" not in orbit_config:
            fail("sequencer_address must be provided if sequencer_private_key is overridden.")
        if "validator_private_key" in orbit_config and "validator_address" not in orbit_config:
            fail("validator_address must be provided if validator_private_key is overridden.")
    
    # Validate configuration
    validate_config(config_dict)
    
    # Generate dynamic values
    config_dict["jwt_secret"] = generate_jwt_secret()
    config_dict["val_jwt_secret"] = generate_jwt_secret()
    
    # Set derived values
    if not config_dict.get("owner_private_key"):
        config_dict["owner_private_key"] = STANDARD_ACCOUNTS["l2owner"]["private_key"]
        config_dict["owner_address"] = STANDARD_ACCOUNTS["l2owner"]["address"]
    
    return struct(**config_dict)

def validate_config(config):
    """
    Validate configuration parameters.
    """
    # Chain ID validation
    if config["chain_id"] <= 0:
        fail("chain_id must be positive")
    
    if config["l1_chain_id"] <= 0:
        fail("l1_chain_id must be positive")
    
    if config["chain_id"] == config["l1_chain_id"]:
        fail("L2 chain_id must be different from L1 chain_id")
    
    # Challenge period validation
    if config["challenge_period_blocks"] <= 0:
        fail("challenge_period_blocks must be positive")
    
    # Validator count validation
    if config["validator_count"] < 0:
        fail("validator_count must be non-negative")
    
    if config["validator_count"] > 1:
        print("WARNING: Multiple validators not fully supported. Using 1 validator.")
        config["validator_count"] = 1
    
    # Enhanced mode validation
    if not config["rollup_mode"]:
        print("WARNING: AnyTrust mode selected. Make sure a data availability service is configured. (Local DAS support is not yet implemented.)")
        if config.get("anytrust_config") == None:
            fail("AnyTrust mode requires an 'anytrust_config' with DAS settings.")
    
    # Timeboost validation
    if config.get("enable_timeboost"):
        print("WARNING: Timeboost is experimental and may not be fully functional.")

def generate_jwt_secret():
    """
    Generate a deterministic JWT secret for development.
    In production, this should use proper randomness.
    """
    # Using a fixed value for deterministic development environment
    return "0x" + ("0" * 64)

def get_prefunded_accounts_json(config):
    """
    Generate JSON for prefunding accounts in L1 genesis.
    """
    accounts = {}
    
    # Fund standard accounts
    for acc_name in config.pre_fund_accounts:
        if acc_name in STANDARD_ACCOUNTS:
            accounts[STANDARD_ACCOUNTS[acc_name]["address"]] = {
                "balance": "1000000000000000000000"  # 1000 ETH
            }
    
    # Always fund the deployer account
    accounts["0x3f1Eae7D46d88F08fc2F8ed27FCb2AB183EB2d0E"] = {
        "balance": "1000000000000000000000000000000000"  # Large balance
    }
    
    # Add any custom prefund addresses
    if config.prefund_addresses:
        for addr in config.prefund_addresses:
            if addr.startswith("0x") and len(addr) == 42:
                accounts[addr] = {"balance": "100000000000000000000"}  # 100 ETH
            else:
                print("WARNING: Invalid address format '{}'; skipping prefund.".format(addr))
    
    return json.encode(accounts)