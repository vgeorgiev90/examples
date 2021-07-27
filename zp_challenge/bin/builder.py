#!/usr/bin/env python3

import boto3
import argparse
import json
import docker
from sys import exit
from os import path
import base64
from datetime import datetime
from subprocess import call



local_repo = "localhost/my-project:latest"
terraform_path = "../infra/terraform/"

def Parser():
    parser = argparse.ArgumentParser()
    parser.add_argument('cmd', choices=['create-repo', 'image-build', 'get-config', 'info'], help='sub-command')
    parser.add_argument('--options', '-o', nargs=1, help='Arguments for the sub-command')
    return parser


def generate_config():
    template_base_config = {
          "environment" : "",
          "access_ip" : "",
          "cluster_name" : "",
          "database_name" : "",
          "master_password" : "",
          "application_db_user" : "",
          "acm_certificate_arn" : "",
          "public_key" : "",
          "cpu_limit" : "256",
          "memory_limit" : "512",
          "application_image" : "",
          "django_user" : "",
          "django_password" : "",
          "django_email" : ""
        }
    message = """This command will generate base configuration for terraform and save it as terraform.tfvars.json"
                 Feel free to go trough the modules and check all supported variables
              """
    print(message)
    if path.exists(terraform_path + 'terraform.tfvars.json'):
        t = datetime.now()
        datestamp = t.strftime("%Y-%m-%d_%H_%M")
        print("Existing variables file found.. backing it up..")
        call(["mv", terraform_path + 'terraform.tfvars.json', terraform_path + 'terraform.tfvars-backup-' + datestamp])
        print("Creating new variables file, dont forget to fill it in")

    choice = input("Do you want clean template yes|no ? ")
    if choice == 'yes':
        with open(terraform_path + 'terraform.tfvars.json', 'w') as f:
            json.dump(template_base_config, f, indent=2)
        

def print_info():
    message = """Sub-command explanations:
    
create-repo    -->   Used to create AWS ECR registry which will hold our projet image(this will create repo-config.json with repository details, dont delete it)
image-build    -->   Used to build and push our project image to the ECR registry
get-config     -->   Used to create brand new terraform.tfvars.json, keep in mind that you will have to fill in all the values

Example usage:

./builder.py create-repo --options awesome-repo     -->   This will create ecr registry with name awesome-repo

./builder.py image-build --options v1               -->   This will build our project image and tag with the ECR repo uri and tag: v1

./builder.py get-config                             -->   Will backup our existing terraform.tfvars.json(if exists) and create brand new one, keep in mind that you will have to switch terraform workspace manually

./builder.py info                                   -->   Print this message

General Notes:

Keep in mind that there are couple of hardcoded paths inside the script so either check and modify those carefully or keep the same directory structure

"""
    call(["clear"])
    print(message)



class ECR():

    def __init__(self):
        self.client = boto3.client('ecr')


    def create_repo(self, name):
        if path.exists('repo-config.json'):
            print("You already have repo created with name: %s" % name)
            exit(0)

        response = self.client.create_repository(
                    repositoryName = name
                )

        data = {
                    'repositoryArn': response['repository']['repositoryArn'],
                    'registryId': response['repository']['registryId'],
                    'repositoryName': response['repository']['repositoryName'],
                    'repositoryUri': response['repository']['repositoryUri'],
                }

        with open('repo-config.json', 'w') as f:
            json.dump(data, f)
        print("Repository created: %s" % response['repository']['repositoryUri'])


    def get_auth_token(self):
        token = self.client.get_authorization_token()
        username, password = base64.b64decode(token['authorizationData'][0]['authorizationToken']).decode().split(':')
        registry = token['authorizationData'][0]['proxyEndpoint']
        return registry, username, password



class Docker():

    def __init__(self):
        self.client = docker.from_env()

    def repo_login(self, registry, username, password):
        self.client.login(username, password, registry=registry)
        print("Logged in to: %s" % registry)

    def image_build(self, tag):
        with open('repo-config.json', 'r') as f:
            config = json.load(f)

        project_path = "../project/mysite"
        call(["clear"])
        print("<-------------------------------------------------------------------->")
        print("Building image from: %s as %s" % (project_path, local_repo))
        self.image, build_log = self.client.images.build(path=project_path, tag=local_repo, rm=True)
        with open('latest-build.log', 'w') as f:
            for line in build_log:
                json.dump(line, f)
        repo_uri = config['repositoryUri']
        print("<-------------------------------------------------------------------->")
        print("Tagging image as: %s:%s" % (repo_uri, tag) )
        self.image.tag(repo_uri, tag=tag)
        print("<-------------------------------------------------------------------->")
        print("Pushing tagged image: %s:%s" % (repo_uri, tag))
        self.client.images.push(repo_uri, tag=tag)
        choice = input("Do you want to update the application_image terraform variable yes|no ? ")
        if choice == 'yes':
            with open(terraform_path + 'terraform.tfvars.json', 'r') as f:
                data = json.load(f)
            data['application_image'] = "%s:%s" % (repo_uri, tag)
            with open(terraform_path + 'terraform.tfvars.json', 'w') as f:
                json.dump(data, f, indent=2)
        else:
            print("Image is now pushed to the registry")






ecr = ECR()
d = Docker()


parser = Parser()
args = parser.parse_args()

if args.cmd:
    if args.cmd == 'create-repo': 
        if args.options:
            repo_name = args.options[0]
            ecr.create_repo(repo_name)
        else:
            print("You must specify repository name with -o NAME")

    elif args.cmd == 'image-build': 
        if args.options:
            image_tag = args.options[0]
            registry, username, password = ecr.get_auth_token()
            d.repo_login(registry, username, password)
            d.image_build(image_tag)
        else:
            print("You must specify tag with -o TAG_NAME")
    
    elif args.cmd == 'get-config':
        generate_config()

    elif args.cmd == 'info':
        print_info()
