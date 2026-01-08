# ⚡ Serverless Alerting Backend

![Project Status](https://img.shields.io/badge/status-active-success.svg)
![Terraform](https://img.shields.io/badge/Terraform-7B42BC?style=flat&logo=terraform&logoColor=white)
![AWS](https://img.shields.io/badge/AWS-232F3E?style=flat&logo=amazon-aws&logoColor=white)
![DynamoDB](https://img.shields.io/badge/DynamoDB-4053D6?style=flat&logo=amazon-dynamodb&logoColor=white)

## 📖 Project Overview
This project is the **Serverless Backend** for a distributed monitoring system. It acts as the central intelligence hub that ingests real-time metrics, stores historical data in a NoSQL database, and triggers asynchronous alerts (via Email/SMS) when critical thresholds are breached.

It is designed to be **highly scalable** and **cost-efficient** by utilizing AWS managed services instead of managing servers.

## 🏗 Architecture
The infrastructure is provisioned entirely via **Terraform** (IaC).

1.  **Storage:** AWS DynamoDB (NoSQL) stores metrics with a composite key (`host_id` + `timestamp`) for efficient time-series querying.
2.  **Notifications:** AWS SNS (Simple Notification Service) handles the "Fan-out" alerting pattern, decoupling the alerting logic from the subscriber methods (Email/SMS/Lambda).

```mermaid
graph LR
    Input[Input Source] -->|Write Data| DB[(DynamoDB Table)]
    Input -->|Trigger Alert| SNS[SNS Topic]
    SNS -->|Push| Email[Email Subscriber]
    
    style DB fill:#4053D6,stroke:#333,stroke-width:2px,color:white
    style SNS fill:#FF9900,stroke:#333,stroke-width:2px,color:white
