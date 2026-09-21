# DevSecOps Lab

Lab local pour un pipeline DevSecOps de bout en bout :  
**code → Gradle → scans SAST/SCA/secrets → image Docker → Trivy (gate avant push) → registry → Helm → Kyverno → Grafana**, avec sauvegardes automatiques et Azure documenté comme cible production.

## Architecture (2 niveaux)


| Niveau         | Où                                                                 | Rôle                                            |
| -------------- | ------------------------------------------------------------------ | ----------------------------------------------- |
| **Lab local**  | GitLab.com → Jenkins → registry locale → kind → Prometheus/Grafana | Ce que tu fais tourner                          |
| **Cible prod** | ACR + AKS + Key Vault (Terraform)                                  | Même artefacts, autre runtime — apply optionnel |


```
Poste_dev ──push/MR──► GitLab ──webhook──► Jenkins
                                              │
                     Gitleaks → Semgrep → Trivy(fs) → Gradle → Docker build
                                              │
                                    Trivy(image) HIGH/CRITICAL ──fail──► STOP
                                              │ pass
                                         docker push
                                              │
                                    Helm → kind (PSS + NetPol + Kyverno)
                                              │
                                         Prometheus → Grafana
```



### Rôle de chaque outil


| Outil                 | Rôle unique                                               |
| --------------------- | --------------------------------------------------------- |
| **Git / GitLab**      | Source de vérité, MR, branches protégées, webhook Jenkins |
| **Gradle**            | Build + tests de l’API Spring Boot                        |
| **Docker**            | Image multi-stage, digest pin, user non-root              |
| **Jenkins**           | CI/CD as code — **aucun push si Trivy échoue**            |
| **Ansible + Vault**   | Bootstrap lab ; secrets uniquement chiffrés               |
| **Kubernetes (kind)** | Runtime + PSS restricted + NetworkPolicy + Kyverno        |
| **Grafana**           | Observabilité app + cluster                               |
| **Azure (Terraform)** | Cible AKS / ACR / Key Vault (documentée)                  |
| **Backup scripts**    | Snapshots auto + restore (hors Git)                       |




## Démarrage rapide (lab local)



### Prérequis

- Windows 10/11, Docker Desktop, Git
- Python 3 + Ansible (`pip install ansible`)
- (recommandé) `kubectl`, `kind`, `helm` — ou laisse Ansible les installer



### 1. Secrets Ansible Vault

```powershell
# Copier le template et renseigner les valeurs
Copy-Item ansible\group_vars\all\vault.yml.example ansible\group_vars\all\vault.yml

# Créer un mot de passe Vault local (JAMAIS commité)
Set-Content -Path "$env:USERPROFILE\.ansible-vault-devsecops" -Value "change-me-strong-password"

# Chiffrer le fichier
ansible-vault encrypt ansible\group_vars\all\vault.yml --vault-password-file "$env:USERPROFILE\.ansible-vault-devsecops"
```



### 2. Bootstrap du lab

**Windows (Docker Compose) :**

```powershell
.\scripts\bootstrap.ps1
# Optionnel cluster + policies :
.\scripts\bootstrap.ps1 -WithKind
```

**Ansible (WSL / Linux — recommandé) :**

```powershell
ansible-playbook -i ansible/inventory/local.yml ansible/playbooks/bootstrap-lab.yml `
  --vault-password-file "$env:USERPROFILE\.ansible-vault-devsecops"
```

Cela démarre Jenkins + registry (`docker/lab-compose.yml`), et avec `-WithKind` / tags Ansible : cluster kind, Kyverno, namespace `demo-dev`.

### 3. Pipeline

Configurer le job Jenkins pour pointer sur ce dépôt (voir `jenkins/casc/`).  
Le `Jenkinsfile` bloque le **push** tant que Trivy image signale des vulnérabilités **HIGH/CRITICAL**.

### 4. Monitoring

Après install de `kube-prometheus-stack` (playbook ou `monitoring/install.sh`) :

```powershell
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
```



### 5. Sauvegardes

```powershell
# Watcher (snapshot après ~30s sans écriture)
.\backup\watch.ps1

# Restore
.\backup\restore.ps1 -Snapshot 2026-09-21_16-20-00
```

Voir [docs/backup.md](docs/backup.md).

## Sécurité 

1. **Secrets** — Ansible Vault uniquement ; rien en clair dans Git
2. **CI / supply chain** — Gitleaks → Semgrep → Trivy fs → **Trivy image avant push** → Checkov → SBOM
3. **Runtime** — PSS `restricted` + NetworkPolicy deny-all + Kyverno + SA dédié

Détails : [docs/security.md](docs/security.md) · Architecture : [docs/architecture.md](docs/architecture.md)

## Structure du dépôt

```
apps/demo-api/          # API Spring Boot + Gradle + Dockerfile durci
jenkins/                # Jenkinsfile + JCasC
ansible/                # Bootstrap + Vault
helm/demo-api/          # Chart sécurisé
security/policies/      # Kyverno ClusterPolicies
monitoring/             # Dashboards Grafana
backup/                 # Snapshot / watch / restore
terraform/azure/        # AKS + ACR + Key Vault (cible)
docs/                   # Architecture, sécurité, backup
```



## Limites honnêtes (v1)

- Azure **non branché** par défaut (Terraform prêt, apply optionnel)
- Pas de HashiCorp Vault / Cosign / ArgoCD / SonarQube / DAST en v1
- Backups **locales** (pas offsite)
- Jenkins = CI principale (pas GitLab CI en parallèle)



