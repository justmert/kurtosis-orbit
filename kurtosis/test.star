def run(plan):
    plan.print("Starting minimal test...")
    
    # Just run a simple Node container
    test_service = plan.add_service(
        name = "test-node",
        config = ServiceConfig(
            image = "node:18",
            entrypoint = ["/bin/sh", "-c"],
            cmd = ["echo 'TEST RUNNING' && node --version && mkdir -p /app && echo '{\"success\":true}' > /app/test.json && sleep 30"]
        )
    )
    
    # Wait a moment
    plan.print("Service created, waiting...")
    plan.wait(
        service_name = "test-node",
        recipe = ExecRecipe(
            command = ["test", "-f", "/app/test.json"]
        ),
        field = "code",
        assertion = "==",
        target_value = 0,
        timeout = "30s"
    )
    
    # Check the result
    result = plan.exec(
        service_name = "test-node",
        recipe = ExecRecipe(
            command = ["cat", "/app/test.json"]
        )
    )
    
    plan.print("Test result: " + result["output"])
    
    return {"success": True}