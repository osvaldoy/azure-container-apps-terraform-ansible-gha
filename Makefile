TF=infra/terraform

.PHONY: tf-fmt tf-validate tf-plan tf-apply

tf-fmt:
	cd $(TF) && terraform fmt -recursive

tf-validate:
	cd $(TF) && terraform init -backend=false && terraform validate

tf-plan:
	cd $(TF) && terraform init -backend=false && terraform plan -var-file=envs/dev.tfvars

tf-apply:
	cd $(TF) && terraform init && terraform apply -auto-approve -var-file=envs/dev.tfvars
