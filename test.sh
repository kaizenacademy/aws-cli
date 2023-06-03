#!/bin/bash

ami_id="ami-0715c1897453cabd1"
key_name="my-laptop-key"
name="hello"
region="us-east-1"

# aws ec2 run-instances --image-id $ami_id --instance-type t2.micro --key-name $key_name --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name}]" --region $region

vpc_name="kaizen"
vpc_cidr="10.0.0.0/16"

vpc_id=$(aws ec2 create-vpc --cidr-block $vpc_cidr --tag-specification "ResourceType=vpc,Tags=[{Key=Name,Value=$vpc_name}]" --region $region --query Vpc.VpcId --output text)

subnet_id=$(aws ec2 create-subnet --vpc-id $vpc_id --cidr-block 10.0.1.0/24 --region $region --query Subnet.SubnetId --output text)

ig_id=$(aws ec2 create-internet-gateway --region $region --query InternetGateway.InternetGatewayId --output text)

aws ec2 attach-internet-gateway --vpc-id $vpc_id --region $region --internet-gateway-id $ig_id

rt=$(aws ec2 create-route-table --vpc-id $vpc_id --region $region --query RouteTable.RouteTableId --output text)

aws ec2 create-route --route-table-id $rt --destination-cidr-block 0.0.0.0/0 --gateway-id $ig_id --region $region

aws ec2 associate-route-table --subnet-id $subnet_id --route-table-id $rt --region $region

hello=$(aws ec2 create-security-group --description "Demo Security Group" --vpc-id $vpc_id --region $region --group-name hello --query GroupId --output text)

aws ec2 create-tags --resources $hello --tags Key=Name,Value=hello --region $region

aws ec2 authorize-security-group-ingress --group-id $hello --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $region
aws ec2 authorize-security-group-ingress --group-id $hello --protocol tcp --port 80 --cidr 0.0.0.0/0 --region $region

aws ec2 run-instances --image-id $ami_id --instance-type t2.micro --key-name $key_name  --security-group-ids $hello --subnet-id $subnet_id --associate-public-ip-address --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$name}]" --region $region