resource "null_resource" "sleep" {}

############# Give some time for the bastion host socks5 proxy to be ready ############

resource "time_sleep" "wait_200_seconds" {
  depends_on = [null_resource.sleep]
  create_duration = "200s"
}

resource "mysql_user" "application_user" {
  depends_on	     = [time_sleep.wait_200_seconds]
  user               = var.application_db_user
  host               = "%"
  auth_plugin        = "AWSAuthenticationPlugin"
}

resource "mysql_grant" "application_user" {
  depends_on = [mysql_user.application_user]
  user       = var.application_db_user
  host       = "%"
  database   = var.database_name
  privileges = ["ALL"]
}
         
