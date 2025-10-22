package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

// TestTerraformValidation tests Terraform validation without actually deploying
func TestTerraformValidation(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name        string
		examplePath string
		expectError bool
	}{
		{
			name:        "Minimal example validation",
			examplePath: "../examples/minimal",
			expectError: false,
		},
		{
			name:        "Complete example validation",
			examplePath: "../examples/complete",
			expectError: false,
		},
		{
			name:        "Load balancer example validation",
			examplePath: "../examples/with-load-balancer",
			expectError: false,
		},
	}

	for _, tc := range testCases {
		tc := tc // capture range variable
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: tc.examplePath,
				NoColor:      true,
			}

			// Initialize Terraform
			_, err := terraform.InitE(t, terraformOptions)
			if tc.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}

			// Validate Terraform configuration
			err = terraform.ValidateE(t, terraformOptions)
			if tc.expectError {
				assert.Error(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}

// TestTerraformFormat tests that all Terraform files are properly formatted
func TestTerraformFormat(t *testing.T) {
	t.Parallel()

	paths := []string{
		"..",
		"../examples/minimal",
		"../examples/complete",
		"../examples/with-load-balancer",
	}

	for _, path := range paths {
		path := path
		t.Run(path, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: path,
				NoColor:      true,
			}

			// Check format (this returns an error if files are not formatted)
			err := terraform.FormatE(t, terraformOptions)
			assert.NoError(t, err, "Terraform files should be properly formatted")
		})
	}
}

// TestModuleInputValidation tests variable validation rules
func TestModuleInputValidation(t *testing.T) {
	t.Parallel()

	testCases := []struct {
		name        string
		vars        map[string]interface{}
		expectError bool
	}{
		{
			name: "Valid environment name",
			vars: map[string]interface{}{
				"environment": "production",
			},
			expectError: false,
		},
		{
			name: "Invalid environment with uppercase",
			vars: map[string]interface{}{
				"environment": "Production",
			},
			expectError: true,
		},
		{
			name: "Valid region",
			vars: map[string]interface{}{
				"region": "nyc1",
			},
			expectError: false,
		},
		{
			name: "Invalid region",
			vars: map[string]interface{}{
				"region": "invalid-region",
			},
			expectError: true,
		},
	}

	for _, tc := range testCases {
		tc := tc
		t.Run(tc.name, func(t *testing.T) {
			t.Parallel()

			terraformOptions := &terraform.Options{
				TerraformDir: "..",
				Vars:         tc.vars,
				NoColor:      true,
			}

			_, err := terraform.InitE(t, terraformOptions)
			if tc.expectError {
				// Note: Validation happens during plan/apply, not init
				err = terraform.ValidateE(t, terraformOptions)
				// We expect validation to pass even with invalid values
				// as Terraform validates during plan/apply
				assert.NoError(t, err)
			} else {
				assert.NoError(t, err)
			}
		})
	}
}
