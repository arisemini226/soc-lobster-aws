# AC-WF-001: Destroy workflow
File: .github/workflows/99-destroy-lab.yml
Trigger: workflow_dispatch with confirm input
Uses OIDC for AWS credentials
Has terraform destroy -auto-approve
Uploads artifact on failure
