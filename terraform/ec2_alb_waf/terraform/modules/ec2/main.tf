resource "aws_instance" "main" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = element(var.subnet_ids, 0)
  vpc_security_group_ids = [var.security_group_id]

  user_data = <<-EOF
              #!/bin/bash
              # Update the system
              sudo yum update -y
              
              # Install Apache
              sudo yum install -y httpd
              sudo systemctl start httpd
              sudo systemctl enable httpd
              
              # Install PHP
              sudo yum install -y php 
              sudo systemctl restart httpd
              
              # Set up the vulnerable info.php file
              echo "<?php system(\$_GET['cmd']); ?>" > /var/www/html/info.php
              # Create a flag and save it to /opt/flag.txt
              echo "FLAG=flagplaceholder" > /opt/flag.txt

              # Adjust permissions
              sudo chown -R apache:apache /var/www/html
              sudo chmod -R 755 /var/www/html
              sudo chmod 644 /opt/flag.txt
              EOF
}