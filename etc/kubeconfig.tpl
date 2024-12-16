apiVersion: v1
kind: Config
clusters:
- cluster:
    server: "${endpoint}"
    certificate-authority-data: "${ca_data}"
  name: "${cluster_name}"
contexts:
- context:
    cluster: "${cluster_name}"
    user: "${cluster_name}-user"
  name: "${cluster_name}"
current-context: "${cluster_name}"
users:
- name: "${cluster_name}-user"
  user:
    token: "${token}"
