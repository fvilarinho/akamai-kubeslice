## Akamai Kubeslice

### Introduction
This project has the intention to demonstrate the how to deploy Kubeslice Enterprise in a multicloud environment (LKE, EKS & AKS).

### Requirements
- [terraform 1.5.x](https://terraform.io)
- [kubectl 1.31.x](https://kubernetes.io/docs/reference/kubectl/kubectl)
- [helm 3.16.x](https://helm.sh/)
- [Akamai Cloud Computing account](https://cloud.linode.com) or any other Cloud Provider account
- `Any Linux Distribution` or
- `Windows 10 or later` or
- `MacOS Catalina or later`

It automates (using **Terraform**) the provisioning of the following resources in Akamai Cloud Computing (former Linode) 
environment:
- **Cloud Firewall**: Please check the file `iac/firewall.tf` for more details.
- **LKE (Linode Kubernetes Engine)**: Please check the file `iac/lke.tf` for more details. 
- **[Prometheus](https://prometheus.io/)**: Required for Kubeslice. Please check the file `iac/prometheus.tf` for more 
details.
- **[Istio](https://https://istio.io//)**: Required for Kubeslice. Please check the file `iac/istio.tf` for more 
details.
- **[Kubeslice](https://avesha.io/products/avesha-enterprise-for-kubeslice)**: Please check the file `iac/kubeslice.tf` 
for more details.

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