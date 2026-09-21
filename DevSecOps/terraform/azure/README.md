# Azure production target (optional)

This Terraform stack provisions the **production-shaped** counterparts of the local lab:

| Lab | Azure |
|-----|-------|
| `localhost:5000` registry | Azure Container Registry |
| kind cluster | AKS |
| Ansible Vault → K8s Secret | Azure Key Vault |

## Usage

```bash
cd terraform/azure
az login
terraform init
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars
terraform plan
terraform apply   # costs money — destroy when done: terraform destroy
```

## Wiring Jenkins (conceptual)

1. Push images to ACR instead of `localhost:5000`
2. Deploy Helm to AKS (`az aks get-credentials`)
3. Sync app secrets from Key Vault (CSI driver or External Secrets — v2)

Do **not** apply unless you accept Azure billing.
