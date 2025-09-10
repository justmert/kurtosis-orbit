"""
Analytics tracking module for Kurtosis-Orbit.

This module provides functions to track deployment events and usage statistics
for the Kurtosis-Orbit package. It sends anonymous usage data to help improve
the project and provide insights to maintainers.
"""

def track_deployment_start(plan, config):
    """
    Track the start of a deployment.
    
    Args:
        plan: Kurtosis execution plan
        config: Deployment configuration
    """
    # Prepare tracking data
    tracking_data = {
        "event": "deployment_start",
        "chain_name": config.get("chain_name", "unknown"),
        "chain_id": config.get("chain_id", 0),
        "enable_bridge": config.get("enable_bridge", False),
        "enable_explorer": config.get("enable_explorer", False),
        "rollup_mode": config.get("rollup_mode", True),
    }
    
    # Send tracking data (non-blocking)
    _send_tracking_data(plan, "deployment_start", tracking_data)

def track_deployment_success(plan, config, duration_ms=None):
    """
    Track successful deployment completion.
    
    Args:
        plan: Kurtosis execution plan
        config: Deployment configuration
        duration_ms: Deployment duration in milliseconds
    """
    tracking_data = {
        "event": "deployment_success",
        "duration_ms": duration_ms if duration_ms != None else 0,
        "success": True,
    }
    
    _send_tracking_data(plan, "deployment_success", tracking_data)

def track_deployment_failure(plan, config, error_message=None, duration_ms=None):
    """
    Track deployment failure.
    
    Args:
        plan: Kurtosis execution plan
        config: Deployment configuration
        error_message: Error message (if any)
        duration_ms: Duration before failure in milliseconds
    """
    tracking_data = {
        "event": "deployment_failure",
        "success": False,
        "error_message": error_message if error_message != None else "",
        "duration_ms": duration_ms if duration_ms != None else 0,
    }
    
    _send_tracking_data(plan, "deployment_failure", tracking_data)

def track_download(plan, method="kurtosis", source="github", version="latest"):
    """
    Track package download/usage.
    
    Args:
        plan: Kurtosis execution plan
        method: Download method (kurtosis, git, etc.)
        source: Download source (github, direct, etc.)
        version: Package version
    """
    tracking_data = {
        "event": "download",
        "method": method,
        "source": source,
        "version": version,
    }
    
    _send_tracking_data(plan, "download", tracking_data)

def _hash_config(config):
    """
    Create a privacy-preserving hash of the configuration.
    
    Args:
        config: Configuration dictionary
        
    Returns:
        String: Simple hash of configuration
    """
    # Create a simplified config identifier
    chain_id = config.get("chain_id", 0)
    bridge = config.get("enable_bridge", False)
    explorer = config.get("enable_explorer", False)
    rollup = config.get("rollup_mode", True)
    
    # Create a simple identifier string
    config_str = "{}_{}_{}_{}".format(chain_id, bridge, explorer, rollup)
    return config_str

def _send_tracking_data(plan, event_type, data):
    """
    Send tracking data to analytics server (non-blocking).
    
    Args:
        plan: Kurtosis execution plan
        event_type: Type of event to track
        data: Data to send
    """
    # Analytics server endpoints
    endpoint = "https://kurtosis-orbit-analytics.vercel.app/api/track/run"
    if event_type == "download":
        endpoint = "https://kurtosis-orbit-analytics.vercel.app/api/track/download"
    
    # Create JSON payload
    json_data = _dict_to_json(data)
    
    # Build curl command properly
    curl_cmd = "curl -X POST '{}' -H 'Content-Type: application/json' -H 'User-Agent: kurtosis-orbit/1.0' --connect-timeout 5 --max-time 10 --silent --fail -d '{}' > /dev/null 2>&1 || true".format(endpoint, json_data)
    
    # Execute tracking command (best effort, don't fail deployment on tracking errors)
    plan.run_sh(
        description="Sending anonymous usage analytics",
        run=curl_cmd,
        image="curlimages/curl:latest"
    )

def _dict_to_json(data):
    """
    Convert dictionary to JSON string (simple implementation).
    
    Args:
        data: Dictionary to convert
        
    Returns:
        String: JSON representation
    """
    # Simple JSON serialization for basic data types
    items = []
    for key, value in data.items():
        if type(value) == "string":
            # Escape quotes in the value
            escaped_value = value.replace('"', '\\"')
            items.append('"{}":"{}"'.format(key, escaped_value))
        elif type(value) == "bool":
            items.append('"{}":{}'.format(key, "true" if value else "false"))
        elif type(value) == "int":
            items.append('"{}":{}'.format(key, value))
        elif value == None:
            items.append('"{}":null'.format(key))
        else:
            # Convert to string for other types
            items.append('"{}":"{}"'.format(key, str(value)))
    
    return "{" + ",".join(items) + "}"

def is_analytics_enabled(config):
    """
    Check if analytics tracking is enabled.
    
    Args:
        config: Configuration dictionary
        
    Returns:
        Boolean: True if analytics is enabled
    """
    # Check for opt-out environment variable or config setting
    return config.get("enable_analytics", True)
