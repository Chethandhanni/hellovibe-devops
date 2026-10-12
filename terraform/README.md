\# Terraform Infrastructure



\## Environments



This project uses reusable Terraform modules for the development and production environments.



\- `environments/dev`: Development infrastructure.

\- `environments/prod`: Production infrastructure.

\- `modules/networking`: Virtual network and subnet configuration.

\- `modules/observability`: Log Analytics workspace.

\- `modules/app`: Managed identity, Azure Container Apps, and Key Vault.



\## Remote State Backend



Both environments use the AzureRM backend with partial configuration. Backend settings are intentionally not committed to the repository.



\### Backend Setup



1\. Create a dedicated Azure Storage Account and Blob container for Terraform state.

2\. Enable storage account security controls, including encryption and restricted network access.

3\. Grant the deployment identity only the permissions required to access the state container and manage infrastructure.

4\. Initialize each environment with its own backend configuration file:



&#x20;  ```powershell

&#x20;  terraform -chdir=terraform/environments/dev init -backend-config="C:\\secure\\dev-backend.hcl"



&#x20;  terraform -chdir=terraform/environments/prod init -backend-config="C:\\secure\\prod-backend.hcl"

&#x20;  ```



5\. Keep backend configuration files outside the repository. Do not commit credentials or sensitive values.



\### Example Backend Configuration



Create a separate file for each environment, containing the appropriate values:



```hcl

resource\_group\_name  = "REPLACE\_WITH\_STATE\_RESOURCE\_GROUP"

storage\_account\_name = "REPLACE\_WITH\_STATE\_STORAGE\_ACCOUNT"

container\_name       = "tfstate"

key                  = "dev.terraform.tfstate"

use\_azuread\_auth     = true

```



For production, use a separate state key, such as `prod.terraform.tfstate`.



\### State Protection and Locking



\- Azure Blob Storage provides state locking and consistency protection through blob leases.

\- Enable blob versioning and soft delete to help recover from accidental changes.

\- Restrict access to the storage account and state container.

\- Use separate state files for development and production.

\- Never commit Terraform state files, plan files, credentials, or secrets to Git.



\### Validation



The environments have been formatted, initialized with the backend disabled for local validation, and validated. Production Terraform tests verify the configured scaling, Key Vault security settings, and resource-group tags.



Remote state initialization and Azure deployment must be tested separately using an authorized Azure subscription.

