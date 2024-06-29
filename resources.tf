resource "aws_instance" "jenkins" {
  ami = "ami-0e001c9271cf7f3b9"
  instance_type = "t2.large"
  key_name = "aws-keypair"

  tags = {
    Name = "jenkins"
  }

  vpc_security_group_ids = [
    aws_security_group.jenkins.id
  ]

  root_block_device {
    volume_size = 30
    volume_type = "gp2"
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key =  file("aws-keypair.pem")
    host = self.public_ip
  }

  provisioner "file" {
    source = "ansible/jenkins_setup.yml"
    destination = "/home/ubuntu/jenkins_setup.yml"
  }

  provisioner "file" {
    source = "plugins.txt"
    destination = "/home/ubuntu/plugins.txt"
  }

  provisioner "file" {
    source = "jcasc.yml"
    destination = "/home/ubuntu/jcasc.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "until cloud-init status --wait; do echo 'Waiting for cloud-init...'; sleep 5; done",
      "sudo apt-get update -y",
      "sudo apt install software-properties-common -y",
      "sudo apt-add-repository --yes --update ppa:ansible/ansible",
      "sudo apt install ansible -y",
      "ansible --version",
      "ansible-playbook --version",
      "export ANSIBLE_HOST_KEY_CHECKING=false",
      "ansible-playbook /home/ubuntu/jenkins_setup.yml",
      "sudo systemctl restart jenkins"
    ]
  }
}

resource "aws_security_group" "jenkins" {
  name = "jenkins"
  description = "Security group for Jenkins server"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8080
    to_port = 8083
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 9000
    to_port = 9000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8001
    to_port = 8001
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port = 9966
    to_port = 9966
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}