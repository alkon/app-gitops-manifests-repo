# Thanos Receiver S3 Configuration Guide

This guide summarizes the correct configuration methods for enabling a Thanos Receiver Kubernetes pod to store metrics in an AWS S3 bucket. It covers two primary use cases: a production EKS cluster and a local `k3d` development cluster.

The core principle to understand is that **a Kubernetes pod's authentication method is separate from your local AWS CLI configuration.**

---

### User Creation Differences

The method of creating the identity for your `thanos-receiver` pod is fundamentally different between a local `k3d` cluster and a remote EKS cluster.

* **For the Local `k3d` Cluster:**
    * You must create a dedicated **IAM User** with **Programmatic Access**. The pod uses the static access keys from this user directly from a Kubernetes Secret.
* **For the Remote EKS Cluster:**
    * You **do not** create a dedicated IAM User. Instead, you create a **Kubernetes Service Account** within your EKS cluster. This service account is then linked to an IAM Role via IAM Roles for Service Accounts (IRSA).

---

## 1. Remote EKS Cluster (Production)

For a secure production environment, you should use **IAM Roles for Service Accounts (IRSA)**. This method allows the pod to assume a specific IAM role without needing static credentials.

### Authentication Method

The `thanos-receiver` pod's access is granted via a trusted relationship between your EKS cluster's OpenID Connect (OIDC) provider and an IAM role. The pod does **not** use your local `~/.aws/config` file.

### Your Local `~/.aws/config` File

Your local configuration is for **you, the human user**. You use it to run `aws` commands to manage your AWS account and Kubernetes cluster.

### Pod Configuration Steps

1.  **Create an IAM Role and S3 Access Policy:**
    * Create an IAM policy that grants the necessary S3 permissions for Thanos. An example policy is:

        ```json
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Action": ["s3:ListBucket", "s3:GetBucketLocation"],
              "Resource": "arn:aws:s3:::<your-bucket-name>"
            },
            {
              "Effect": "Allow",
              "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject",
                "s3:ListMultipartUploadParts",
                "s3:AbortMultipartUpload"
              ],
              "Resource": "arn:aws:s3:::<your-bucket-name>/*"
            }
          ]
        }
        ```
    * Attach this policy to an IAM role (e.g., `thanos-receiver-local-role`).

2.  **Define the IAM Role's Trust Policy:**
    * This is the most critical step for IRSA. The trust policy must allow your EKS cluster's OIDC provider to assume the role. It should look like this:

        ```json
        {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Principal": {
                "Federated": "arn:aws:iam::YOUR_AWS_ACCOUNT_ID:oidc-provider/OIDC_PROVIDER_URL"
              },
              "Action": "sts:AssumeRoleWithWebIdentity",
              "Condition": {
                "StringEquals": {
                  "OIDC_PROVIDER_URL:sub": "system:serviceaccount:NAMESPACE:thanos-receiver-sa"
                }
              }
            }
          ]
        }
        ```

3.  **Update the Kubernetes Manifest:**
    * Ensure your `serviceAccount` in your Kubernetes manifest includes the `eks.amazonaws.com/role-arn` annotation with the ARN of the IAM role you created.

---

## 2. Local `k3d` Cluster (Development)

This method is for local testing because `k3d` does not have a native OIDC provider that can integrate with AWS for IRSA.

### Authentication Method

The `thanos-receiver` pod's access is granted via static `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` credentials stored as a Kubernetes secret.

### Your Local `~/.aws/config` File

Your local configuration is still for **you, the human user**. It is not used by the pod.

### Pod Configuration Steps

1.  **Create a Dedicated IAM User:**
    * You create a new IAM user with programmatic access (Access Key and Secret Key) and attach the S3 policy from the previous section to this user.
    * Securely save the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` for this user.

2.  **Create a Kubernetes Secret:**
    * Use `kubectl` to create a generic secret in your `k3d` cluster with these credentials.
    * **Example:**
        ```bash
        kubectl create secret generic aws-creds \
          --namespace monitoring \
          --from-literal=AWS_ACCESS_KEY_ID=<your-access-key> \
          --from-literal=AWS_SECRET_ACCESS_KEY=<your-secret-key>
        ```

3.  **Update the Pod Manifest:**
    * Modify your `thanos-receiver` pod's manifest to mount this secret and expose the credentials as environment variables.
    * Your `thanos.yaml` configuration file would then tell Thanos to use these environment variables for authentication.

---

### **Key Takeaway**

The SSO configuration in your `~/.aws/config` file is for **human users** to securely access AWS services and run CLI commands. It is completely separate from the mechanisms used by a Kubernetes pod, which relies on either **IRSA** (for EKS) or **static credentials** (for `k3d`).```