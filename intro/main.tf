terraform {
  required_providers {  #Providers chahiye (can be multiple providers )
    aws = {    # AWS ka provider chaiye
      source = "hashicorp/aws"
      version = "5.82.2"  # Iss version ka AWS ka provider chahiya ,terraform download karke laao.
    }
  }
}

provider "aws" {
  # Configuration options
}