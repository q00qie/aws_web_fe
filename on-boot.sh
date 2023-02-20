#!/bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo yum install git -y
sudo systemctl start httpd
sudo systemctl enable httpd
sudo usermod -a -G apache ec2-user
sudo chown -R ec2-user:apache /var/www
sudo chmod 2775 /var/www
sudo mkdir /efs
sudo chown -R ec2-user:apache /efs
sudo chmod 2775 /efs
sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport fs-0d38bb9f266af3306.efs.us-east-1.amazonaws.com:/ /efs
sudo echo "fs-0d38bb9f266af3306.efs.us-east-1.amazonaws.com:/ /efs nfs4 defaults,_netdev 0 0" >> /etc/fstab