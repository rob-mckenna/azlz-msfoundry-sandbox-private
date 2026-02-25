## Summary

- Describe what this PR changes.

## Validation

- [ ] I tested these changes locally or in CI.
- [ ] I updated docs/workflows if behavior changed.

## Infrastructure Safety (Terraform)

- [ ] If this PR changes Terraform (`infrastructure/terraform/**`), I will run/apply via `.github/workflows/deploy-infrastructure.yml` (not `ci-cd.yml`).
- [ ] I reviewed the Terraform plan and confirmed there are no unintended destroy/replacement actions.
- [ ] If destructive changes are intentional, I will explicitly set `allow_destroy_changes=true` in the workflow dispatch and document why in this PR.
