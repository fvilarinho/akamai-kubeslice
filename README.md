## Akamai Kubeslice

### Introduction
This project has the intention to demonstrate the how to deploy Kubeslice Enterprise in a multicloud environment (LKE, EKS & AKS).

### Requirements
- [terraform 1.5.x](https://terraform.io)
- [kubectl 1.31.x](https://kubernetes.io/docs/reference/kubectl/kubectl)
- [helm 3.16.x](https://helm.sh/)
- [jq 1.7.x](https://jqlang.org/)
- [linode-cli 5.56.x](https://www.linode.com/products/cli/)
- [azure-cli 2.70.x](https://learn.microsoft.com/pt-br/cli/azure/install-azure-cli)
- [Akamai Cloud Computing account](https://cloud.linode.com) or any other Cloud Provider account
- `Any Linux Distribution` or
- `Windows 10 or later` or
- `MacOS Catalina or later`

All Terraform files use `variables` that are stored in the `iac/variables.tf`.

Please check this [link](https://developer.hashicorp.com/terraform/tutorials/configuration-language/variables) to know how to customize the variables.

### Requirements
Before the deployment, you need to complete your registration in this [link](https://docs.avesha.io/documentation/enterprise/1.14.0/get-started/prerequisites/prerequisites-kubeslice-registration).
After that, you'll receive an email with the credentials that must be added in the section license in your variables 
file.

### To deploy it
Just execute the command `deploy.sh` in your project directory. To undeploy, just execute the command `undeploy.sh` in 
your project directory.

### Documentation
Follow the documentation below to know more about Akamai:
- [Akamai Techdocs](https://techdocs.akamai.com)
- [Kubeslice](https://docs.avesha.io/documentation/enterprise/1.14.0/)

### Important notes
- **DON'T EXPOSE OR COMMIT ANY SENSITIVE DATA, SUCH AS CREDENTIALS, IN THE PROJECT.**

### Contact
**LinkedIn:**
- https://www.linkedin.com/in/fvilarinho

**e-Mail:**
- fvilarin@akamai.com
- fvilarinho@gmail.com
- fvilarinho@outlook.com
- me@vila.net.br

and that's all! Have fun!