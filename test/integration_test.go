package test

import (
	"fmt"
	"testing"
	"time"

	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestTerraformMinimalExample tests the minimal example configuration
func TestTerraformMinimalExample(t *testing.T) {
	t.Parallel()

	// Generate a random name suffix to avoid conflicts
	uniqueID := random.UniqueId()
	expectedName := fmt.Sprintf("test-%s", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/minimal",
		Vars: map[string]interface{}{
			"environment": expectedName,
		},
		NoColor: true,
	})

	// Clean up resources at the end of the test
	defer terraform.Destroy(t, terraformOptions)

	// Deploy the infrastructure
	terraform.InitAndApply(t, terraformOptions)

	// Validate outputs exist
	dropletIP := terraform.Output(t, terraformOptions, "droplet_ip")
	assert.NotEmpty(t, dropletIP, "Droplet IP should not be empty")

	// Validate IP format
	assert.Regexp(t, `^(\d{1,3}\.){3}\d{1,3}$`, dropletIP, "Should be valid IP address")
}

// TestTerraformCompleteExample tests the complete example with all features
func TestTerraformCompleteExample(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	expectedEnvironment := fmt.Sprintf("test-%s", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/complete",
		Vars: map[string]interface{}{
			"environment": expectedEnvironment,
		},
		NoColor: true,
		// Increase timeout for complex deployments
		MaxRetries:         3,
		TimeBetweenRetries: 10 * time.Second,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Test outputs
	summary := terraform.OutputMap(t, terraformOptions, "summary")
	assert.NotNil(t, summary, "Summary output should not be nil")
	assert.NotEqual(t, "0", summary["droplets_count"], "Should have created droplets")

	// Test droplet IPs
	dropletIPs := terraform.OutputMap(t, terraformOptions, "droplet_public_ips")
	assert.NotEmpty(t, dropletIPs, "Should have droplet IPs")

	// Test load balancer
	lbIP := terraform.Output(t, terraformOptions, "load_balancer_ip")
	assert.NotEmpty(t, lbIP, "Load balancer IP should not be empty")
}

// TestTerraformLoadBalancerExample tests the load balancer example
func TestTerraformLoadBalancerExample(t *testing.T) {
	t.Parallel()

	uniqueID := random.UniqueId()
	expectedEnvironment := fmt.Sprintf("test-%s", uniqueID)

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/with-load-balancer",
		Vars: map[string]interface{}{
			"environment": expectedEnvironment,
		},
		NoColor:            true,
		MaxRetries:         3,
		TimeBetweenRetries: 10 * time.Second,
	})

	defer terraform.Destroy(t, terraformOptions)

	terraform.InitAndApply(t, terraformOptions)

	// Validate load balancer IP
	lbIP := terraform.Output(t, terraformOptions, "load_balancer_ip")
	assert.NotEmpty(t, lbIP, "Load balancer IP should not be empty")
	assert.Regexp(t, `^(\d{1,3}\.){3}\d{1,3}$`, lbIP, "Should be valid IP address")

	// Validate summary
	summary := terraform.OutputMap(t, terraformOptions, "summary")
	assert.Equal(t, "true", summary["load_balancer_created"], "Load balancer should be created")
	assert.Equal(t, "3", summary["droplets_count"], "Should have 3 droplets")
}

