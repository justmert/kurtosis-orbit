"""
Common service patterns and utilities for Kurtosis-Orbit.
This module contains reusable patterns following Kurtosis best practices.
"""

def create_http_ready_condition(port_id, method="eth_chainId", timeout="5m", interval="10s"):
    """
    Create a standardized HTTP ready condition for RPC services.
    
    Args:
        port_id: The port identifier to check
        method: RPC method to call (default: eth_chainId)
        timeout: Maximum time to wait
        interval: Check interval
    
    Returns:
        ReadyCondition for HTTP RPC services
    """
    return ReadyCondition(
        recipe=PostHttpRequestRecipe(
            port_id=port_id,
            endpoint="",
            content_type="application/json",
            body='{{"jsonrpc":"2.0","method":"{}","params":[],"id":1}}'.format(method)
        ),
        field="code",
        assertion="==",
        target_value=200,
        timeout=timeout,
        interval=interval
    )

def create_file_ready_condition(file_path, timeout="5m", interval="10s"):
    """
    Create a ready condition that waits for a file to exist.
    
    Args:
        file_path: Path to the file to wait for
        timeout: Maximum time to wait
        interval: Check interval
    
    Returns:
        ReadyCondition for file existence
    """
    return ReadyCondition(
        recipe=ExecRecipe(
            command=["test", "-f", file_path]
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout=timeout,
        interval=interval
    )

def create_process_ready_condition(process_name, timeout="2m", interval="5s"):
    """
    Create a ready condition that waits for a process to be running.
    
    Args:
        process_name: Name of the process to check
        timeout: Maximum time to wait
        interval: Check interval
    
    Returns:
        ReadyCondition for process existence
    """
    return ReadyCondition(
        recipe=ExecRecipe(
            command=["pgrep", process_name]
        ),
        field="code",
        assertion="==",
        target_value=0,
        timeout=timeout,
        interval=interval
    )

def wait_for_service_ready(plan, service_name, ready_condition, description="service to be ready"):
    """
    Wait for a service with proper logging and error handling.
    
    Args:
        plan: Kurtosis plan object
        service_name: Name of the service to wait for
        ready_condition: ReadyCondition to use
        description: Description for logging
    """
    plan.print("Waiting for {}...".format(description))
    
    plan.wait(
        service_name=service_name,
        recipe=ready_condition.recipe,
        field=ready_condition.field,
        assertion=ready_condition.assertion,
        target_value=ready_condition.target_value,
        timeout=ready_condition.timeout,
        interval=ready_condition.interval
    )
    
    plan.print("✅ {} is ready".format(description))

def create_node_config_artifact(plan, name, config_dict):
    """
    Create a configuration artifact for node services.
    
    Args:
        plan: Kurtosis plan object
        name: Name for the artifact
        config_dict: Dictionary containing configuration
    
    Returns:
        Configuration artifact
    """
    config_files = {}
    for filename, content in config_dict.items():
        config_files[filename] = struct(
            template=json.encode(content) if type(content) == type({}) else content,
            data={}
        )
    
    return plan.render_templates(
        name=name,
        config=config_files
    )

def validate_service_dependencies(dependencies):
    """
    Validate that required service dependencies are available.
    
    Args:
        dependencies: Dictionary of dependency_name: service_info pairs
    """
    for dep_name, dep_info in dependencies.items():
        if not dep_info:
            fail("Required dependency '{}' is not available".format(dep_name))
        
        if type(dep_info) == type({}) and "service" not in dep_info:
            fail("Dependency '{}' is missing service information".format(dep_name))

def create_standard_ports(rpc_port=8545, ws_port=8546, metrics_port=None):
    """
    Create standardized port configuration for blockchain services.
    
    Args:
        rpc_port: HTTP RPC port number
        ws_port: WebSocket port number  
        metrics_port: Optional metrics port
    
    Returns:
        Dictionary of port specifications
    """
    ports = {
        "rpc": PortSpec(
            number=rpc_port,
            transport_protocol="TCP",
            application_protocol="http",
            wait="30s"
        ),
        "ws": PortSpec(
            number=ws_port,
            transport_protocol="TCP", 
            application_protocol="ws",
            wait="30s"
        )
    }
    
    if metrics_port:
        ports["metrics"] = PortSpec(
            number=metrics_port,
            transport_protocol="TCP",
            wait="30s"
        )
    
    return ports

def create_persistent_storage(base_path, service_name):
    """
    Create standardized persistent storage path.
    
    Args:
        base_path: Base directory for persistent data
        service_name: Name of the service
    
    Returns:
        Persistent storage configuration
    """
    return {
        "persistent": {
            "chain": "{}/{}/data".format(base_path, service_name)
        }
    }