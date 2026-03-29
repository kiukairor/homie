# Copy to terraform.tfvars and fill in — never commit terraform.tfvars to Git
# cp terraform.tfvars.example terraform.tfvars

# OCI credentials — from OCI Console → Identity → Users → API Keys
oci_tenancy_ocid     = "ocid1.tenancy.oc1..aaaaaaaalv6t6gykwg6sy6zdkr7mqtdcu7mdcyuyslb7rtavdwft4epzyslq"
oci_user_ocid        = "ocid1.user.oc1..aaaaaaaayygj5c5a6ecvpd6424eifnizagd6km4goivjxcw454wtlflgcbnq"
oci_fingerprint      = "0d:4e:b3:ff:cd:83:ff:d3:fe:bd:cb:0b:1e:e3:fe:26"
oci_private_key_path = "/home/quentin_al/.oci/oci_api_key.pem"
oci_region           = "uk-london-1"
oci_compartment_id   = "ocid1.tenancy.oc1..aaaaaaaalv6t6gykwg6sy6zdkr7mqtdcu7mdcyuyslb7rtavdwft4epzyslq"  # or same as tenancy_ocid for root
oci_namespace        = "lrjcxx7ddd3v"  # OCI Console → Object Storage → Namespace

# OCI S3-compat keys for Terraform state
# OCI Console → Identity → Users → Customer Secret Keys → Generate
oci_access_key = "00426b9a4f2cf3aaa7aa0ec10172a6e36bfc28d1"
oci_secret_key = "YXflCAOVDic9R1FCYOog8VzJji5FqVSnoB9925AgtbA="

# SSH — your local public key
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBifuaTzM1RTJyY3eAoKWVMGnNb3vhql7w5YOVY1LigD homie-oracle"

# App
domain            = "homie.kiukairor.com"
certmanager_email = "quentin.alamelou@gmail.com"
github_repo       = "https://github.com/kiukairor/homie.git"
