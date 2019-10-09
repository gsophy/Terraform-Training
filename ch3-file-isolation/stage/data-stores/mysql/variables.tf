variable "db_password" {
  description = "The password for the database"
  type = "string"
}

##  Set the db_password in your environment variables
##  Using the following command:
##  TF_VAR_db_password="[type your password here]"
