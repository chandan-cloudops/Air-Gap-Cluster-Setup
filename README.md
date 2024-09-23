# Air-Gap Kubernetes Cluster Setup

This guide outlines the process for setting up an air-gapped Kubernetes cluster, including infrastructure provisioning using Terraform and further configuration.

## Step 1: Provisioning Infrastructure

To begin, navigate to the directory containing your Terraform configuration files, and run the following commands to initialize and provision the required infrastructure.

### Steps:
1. **Navigate to the Infrastructure Directory:**
   Open your terminal and navigate to the directory where your Terraform configuration files are located:

   ```bash
   cd infrastructure
   ```

2. **Initialize Terraform:**
   Run the following command to initialize Terraform, which downloads necessary provider plugins and sets up the working environment:

   ```bash
   terraform init
   ```

3. **Plan the Infrastructure:**
   Next, generate an execution plan to verify the resources that will be created or modified:

   ```bash
   terraform plan
   ```

4. **Apply the Plan:**
   Once you're satisfied with the execution plan, apply it to create the infrastructure:

   ```bash
   terraform apply --auto-approve
   ```

### Result:
Running the above steps will provision the following infrastructure:
- A Virtual Private Cloud (VPC)
- Public and private subnets
- Security groups
- Bastion host in the public subnet
- Kubernetes master and worker nodes in the private subnet

Once Terraform completes the infrastructure setup, proceed with the following steps detailed in the corresponding documentation to install and configure Kubernetes and other required components on the air-gapped cluster.

