# COSC2759 Assignment 2

## Student details

- Full Names: 
    1. Justin Theofilus Yonathan 
    2. Pandya Limawan
- Student IDs: 
    1. 4115477 
    2. 4115252

## Table of Contents

1. [Student Details](#student-details)
2. [Solution Design](#solution-design)
   - [Overview](#overview)
3. [Infrastructure](#infrastructure)
   - [Architecture](#architecture)
   - [Resiliency Improvements](#resiliency-improvements)
4. [Key Data Flows](#key-data-flows)
5. [Deployment Process](#deployment-process)
   - [Steps to Deploy](#steps-to-deploy)
6. [Prerequisites](#prerequisites)
7. [Description of the GitHub Actions Workflow](#description-of-the-github-actions-workflow)
   - [Triggering Mechanism](#triggering-mechanism)
8. [Backup Process: Deploying from a Shell Script](#backup-process-deploying-from-a-shell-script)
9. [Validating that the App is Working](#validating-that-the-app-is-working)
10. [Contents of This Repo](#contents-of-this-repo)


## Solution design

### Overview

The Foo app is deployed on AWS EC2 instances using Docker, Terraform, and Ansible. The goal is to ensure resilient, automated, and scalable deployment process with multipe EC2 instances of the application. a load balancer for traffic distribution, and a separate EC2 instance for the PostgreSQL database.

Key tools used:
- **Terraform**: For infrastructure provisioning.
- **Ansible**: For configuring instances and deploying the app and database.
- **Docker**: To containerise the app and database.
- **GitHub Actions**: For automating the deployment process.
  
## Infrastructure

### Architecture

- **App Instances**: Two EC2 instances running the app container.
- **Load Balancer**: Balances incoming traffic between the two EC2 instances.
- **Database Instance**: A separate EC2 instance running PostgreSQL.
- **Remote Backend**: Terraform uses S3 bucket for storing state, ensuring consistency and resiliency in infrastructure management.

<img src="/img/architecture-diagram.jpeg" style="height: 70px;"/>

### Resiliency Improvements

The app is deployed on two EC2 instances behind a load balancer, ensuring high availabiliy. The use of a separate EC2 instance for the database isolates the application logic from data storage, further improving the fault tolerance of the app.

## Key data flows

## Deployment process

### Steps to Deploy

## Prerequisites

## Description of the GitHub Actions workflow

### Triggering Mechanism

## Backup Process: Deploying from a Shell Script

## Validating that the App is Working

## Contents of This repo


