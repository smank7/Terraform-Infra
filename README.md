### Infrastructure as Code with Terraform on Google Cloud Platform  

This repository contains Terraform configuration files for setting up networking resources on Google Cloud Platform (GCP). The objective is to create a Terraform configuration that enables the creation of multiple Virtual Private Clouds (VPCs) along with their associated resources within the same GCP project and region.  

### Steps  

#### 1. Install and Set Up gcloud CLI  
Ensure you have the **gcloud** command-line tool installed and configured with the appropriate credentials:  
1. `gcloud auth login`  
2. `gcloud auth application-default login`  
3. `gcloud config set project [PROJECT_ID]`  

#### 2. Install and Set Up Terraform  

To set up Terraform on Windows using Chocolatey:  
1. **Install Chocolatey** (if not already installed):  
   - Open a PowerShell prompt with administrative privileges and run:  
     ```powershell  
     Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))  
     ```  

2. **Install Terraform using Chocolatey**:  
   - Run the following command to install Terraform:  
     ```powershell  
     choco install terraform -y  
     ```  

3. **Verify Terraform Installation**:  
   - Open a new PowerShell window and check the installation:  
     ```powershell  
     terraform version  
     ```  

4. **Update Terraform (if needed)**:  
   - Update Terraform using:  
     ```powershell  
     choco update terraform -y  
     ```  

5. **Check Versions**:  
   - Check the versions of Terraform and Chocolatey:  
     ```powershell  
     choco --version  
     terraform --version  
     ```  

---

### Terraform Configuration Files  

- **`main.tf`**: Main Terraform configuration file defining networking resources.  
- **`variables.tf`**: File for declaring variables used in the configuration.  
- **`terraform.tfvars`**: Stores variable values (Note: Do not commit this file to version control).  

---

### Commands to Run Terraform Configuration Files  

1. **Initialize Terraform**:  
   ```bash  
   terraform init  
   ```  

2. **Plan the Infrastructure**:  
   ```bash  
   terraform plan  
   ```  

3. **Apply the Infrastructure**:  
   ```bash  
   terraform apply  
   ```  
   - Confirm the changes by typing `yes` when prompted.  

4. **Destroy the Infrastructure (Cleanup)**:  
   ```bash  
   terraform destroy  
   ```  
   - Confirm the destruction by typing `yes` when prompted.  
