variable "save_to" {
    default = ""
}

data "archive_file" "generate_zip" {
  type        = "zip"
  output_path = (var.save_to != "" ? "${var.save_to}/beegfs.zip" : "${path.module}/dist/beegfs.zip")
  source_dir = "../"
  excludes    = ["terraform.tfstate", "terraform.tfvars.template", "terraform.tfvars", "provider.tf", ".terraform", "images" , "orm" , ".git" , "localonly.ior_mpiio_setup.tf" , "terraform.tfstate.backup" , "scripts/passwordless_ssh.sh" , "scripts/ior_install.sh" , "scripts/restart.sh" ]
}
