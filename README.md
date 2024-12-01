### Infrastructure as Code with Terraform on Google Cloud Platform  

This repository contains Terraform configuration files for setting up networking resources on Google Cloud Platform (GCP). The objective is to create a Terraform configuration that enables the creation of multiple Virtual Private Clouds (VPCs) along with their associated resources within the same GCP project and region.  

### Steps  

#### 1. Install and Set Up gcloud CLI  
Ensure you have the **gcloud** command-line tool installed and configured with the appropriate credentials:  
1. `gcloud auth login`  
2. `gcloud auth application-default login`  
3. `gcloud config set project [PROJECT_ID]`  

#### 2. Install and Set Up Terraform  

1. **Install Terraform**:  
   - Download and install Terraform from the official [Terraform website](https://www.terraform.io/downloads).  
   - Follow the installation instructions for your operating system.  

2. **Verify Terraform Installation**:  
   - Open a terminal and check the installation:  
     ```bash  
     terraform version  
     ```  

3. **Update Terraform** (if needed):  
   - Check for updates and follow the official installation guide to install the latest version.  

### Terraform Configuration Files  

- **`main.tf`**: Main Terraform configuration file defining networking resources.  
- **`variables.tf`**: File for declaring variables used in the configuration.  
- **`terraform.tfvars`**: Stores variable values (Note: Do not commit this file to version control).  

### Testing with Jest  

This repository includes Jest test cases for validating the functionality of the Terraform configuration.  

1. **Install Jest**:  
   - Ensure Node.js is installed on your system.  
   - Install Jest as a development dependency:  
     ```bash  
     npm install jest --save-dev  
     ```  

2. **Run Tests**:  
   - Execute the Jest tests to validate the configuration:  
     ```bash  
     npm test  
     ```  

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
