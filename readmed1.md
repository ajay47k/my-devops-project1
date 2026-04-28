# 🚀 My DevOps Journey — simple-flask-app

> A complete end-to-end CI/CD pipeline built from scratch using GitHub Actions, Docker, Terraform, and AWS ECS Fargate.

---

## 📖 The Story

This project documents a real-world DevOps learning journey — building a fully automated CI/CD pipeline for a Python Flask application, from zero to a live deployment on AWS. Every error, every fix, and every lesson learned is part of the story.

---

## 🏗️ What We Built

```
Developer pushes code
        ↓
GitHub Actions triggers automatically
        ↓
CI Pipeline → runs pytest tests
        ↓
CD Pipeline → builds Docker image → pushes to AWS ECR
        ↓
Terraform → provisions ECS Fargate infrastructure
        ↓
Flask app is LIVE on AWS! 🌐
```

---

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| **Python + Flask** | Web application |
| **Gunicorn** | Production WSGI server |
| **Docker** | Containerization |
| **GitHub Actions** | CI/CD automation |
| **AWS ECR** | Docker image registry |
| **AWS ECS Fargate** | Container orchestration |
| **Terraform** | Infrastructure as Code |
| **AWS CloudWatch** | Logging and monitoring |
| **AWS IAM** | Security and permissions |

---

## 📁 Project Structure

```
my-devops-project1/
├── .github/
│   └── workflows/
│       ├── ci.yml          ← Continuous Integration pipeline
│       └── cd.yml          ← Continuous Delivery pipeline
├── simple-flask-app/
│   ├── app.py              ← Flask application
│   ├── Dockerfile          ← Container definition
│   ├── docker-compose.yml  ← Local development
│   ├── requirements.txt    ← Python dependencies
│   └── tests/
│       └── test_app.py     ← Pytest test suite
└── terraform/
    └── main.tf             ← AWS infrastructure definition
```
---

## ⚙️ CI Pipeline — Continuous Integration

**File:** `.github/workflows/ci.yml`

**Triggers on:** Every push and pull request to `main` branch

**What it does:**
1. Checks out the code
2. Sets up Python 3.9
3. Installs dependencies from `requirements.txt`
4. Runs `pytest` test suite automatically

**Key lesson learned:** Workflow files must be at repo root (`.github/workflows/`), not inside subdirectories. The `PYTHONPATH` environment variable must be set so pytest can find the Flask app module.

```yaml
- name: Run tests with pytest
  run: pytest
  env:
    PYTHONPATH: .
```

---

## 🚢 CD Pipeline — Continuous Delivery

**File:** `.github/workflows/cd.yml`

**Triggers on:** Every push to `main` branch

**What it does:**

### Job 1: Build and Push Docker Image
1. Authenticates with AWS using IAM credentials
2. Logs into Amazon ECR
3. Builds Docker image from `./simple-flask-app`
4. Tags image with the Git commit SHA (unique, traceable)
5. Pushes image to ECR repository

### Job 2: Deploy via Terraform
1. Sets up Terraform
2. Runs `terraform init`
3. Runs `terraform apply` — passes ECR image URI as variable
4. ECS service is updated with the new image

---

## 🏛️ Infrastructure — Terraform

**File:** `terraform/main.tf`

### Resources Created

| Resource | Name | Purpose |
|---|---|---|
| ECS Cluster | `simple-flask-app-staging` | Container orchestration |
| ECS Task Definition | `simple-flask-app` | Container configuration |
| ECS Service | `simple-flask-app-staging` | Runs and maintains containers |
| IAM Role | `ecsTaskExecutionRole-staging` | ECS permissions to pull from ECR |
| Security Group | `flask-app-sg` | Network access rules |
| CloudWatch Log Group | `/ecs/simple-flask-app` | Application logs |

### Key Design Decisions
- **Fargate** — serverless containers, no EC2 management
- **Default VPC** — simple setup using existing AWS networking
- **Public IP** — direct access for staging environment
- **Port 5000** — Flask/Gunicorn application port

---

## 🔐 AWS IAM Setup

### IAM User: `github-actions-deploy`

Policies attached:
- `AmazonEC2ContainerRegistryPowerUser` — push images to ECR
- `AWSAppRunnerFullAccess` — originally planned, migrated to ECS
- `AmazonECS_FullAccess` — create/manage ECS resources
- `IAMFullAccess` — create task execution roles
- `AmazonVPCFullAccess` — create security groups
- `CloudWatchFullAccess` — create log groups

### GitHub Secrets Required
```
AWS_ACCESS_KEY_ID      ← IAM user access key
AWS_SECRET_ACCESS_KEY  ← IAM user secret key
```

---

## 🐛 Real Bugs We Fixed — The Learning Journey

This was a real debugging session. Here are the actual problems we hit and how we fixed them:

### 1. Workflows Not Triggering
**Problem:** `.github/workflows/` was inside `simple-flask-app/` subfolder  
**Fix:** Moved workflows to repository root and used `working-directory` in CI

### 2. Wrong AWS Region
**Problem:** Code deployed to `us-east-1` but ECR was in `us-east-2` (Ohio)  
**Fix:** Changed `AWS_REGION: us-east-2` in `cd.yml` and `terraform/main.tf`

### 3. ECR Repository Not Found
**Problem:** `simple-flask-app` ECR repo didn't exist  
**Fix:** Manually created ECR repository in AWS Console (us-east-2)

### 4. pytest Not Found
**Problem:** `pytest: command not found` — not in requirements.txt  
**Fix:** Added `pytest` to `requirements.txt`

### 5. ModuleNotFoundError: No module named 'app'
**Problem:** pytest couldn't find `app.py` when running from `tests/` directory  
**Fix:** Added `PYTHONPATH: .` to pytest step in `ci.yml`

### 6. App Runner Deprecated
**Problem:** AWS App Runner stopped accepting new customers April 30, 2026  
**Fix:** Migrated to **AWS ECS Fargate** — the recommended modern approach

### 7. IAM Permission Errors
**Problem:** Multiple `AccessDeniedException` errors during Terraform apply  
**Fix:** Added required IAM policies step by step based on actual error messages

### 8. Terraform State Not Persisted
**Problem:** Each CD run started fresh — caused "already exists" errors  
**Fix (temporary):** Manual AWS cleanup between runs  
**Fix (permanent):** S3 remote backend (Chapter 7!)

### 9. Port Mismatch
**Problem:** Gunicorn listening on `8080`, security group open on `5000`  
**Fix:** Updated Dockerfile to bind on `5000`, consistent across all configs

### 10. CloudWatch Log Group Conflicts
**Problem:** Log group already existed, Terraform tried to recreate it  
**Fix:** Used `awslogs-create-group: "true"` in container definition, removed separate log group resource

---

## ✅ Final State — What's Working

```
✅ CI Pipeline  — pytest runs on every push
✅ Docker Build — image built and pushed to ECR on every push to main
✅ Terraform    — ECS infrastructure provisioned automatically
✅ ECS Fargate  — Flask app running as a container
✅ CloudWatch   — Application logs streaming live
✅ Public IP    — App accessible via HTTP
```

---

## 📊 Architecture Diagram

```
GitHub Repository (main branch)
         │
         │ git push
         ▼
┌─────────────────────────────┐
│      GitHub Actions          │
│  ┌──────────┐ ┌──────────┐  │
│  │    CI    │ │    CD    │  │
│  │ (pytest) │ │ (deploy) │  │
│  └──────────┘ └────┬─────┘  │
└───────────────────┼─────────┘
                    │
          ┌─────────┼──────────┐
          │         │          │
          ▼         ▼          ▼
       AWS ECR   Terraform   AWS IAM
    (image store) (IaC)    (permissions)
          │         │
          └────┬────┘
               │
               ▼
        AWS ECS Fargate
        ┌─────────────┐
        │ Flask App   │
        │ Port 5000   │──────► CloudWatch Logs
        │ Gunicorn    │
        └─────────────┘
               │
               ▼
         Public Internet
         http://<IP>:5000
```

---

## 🔑 Key Lessons Learned

1. **Workflow file location matters** — must be at exact path `.github/workflows/`
2. **Region consistency is critical** — one wrong region breaks everything
3. **IAM permissions are granular** — add only what you need, add it incrementally
4. **Terraform needs state** — without remote state, pipelines break on re-runs
5. **Port consistency** — Dockerfile, security group, and task definition must all agree
6. **`working-directory`** — use it when your code isn't at the repo root
7. **Cloud services change** — App Runner was deprecated, always have a Plan B
8. **Read error messages carefully** — AWS errors tell you exactly what's missing

---

## 🚀 What's Next — Chapter 7

- [ ] S3 Remote Backend for Terraform state (fixes the re-run problem!)
- [ ] DynamoDB state locking (prevents concurrent runs)
- [ ] Manual approval gates for production
- [ ] Staging vs Production environment separation
- [ ] Terraform modules for reusability

---

## 👨‍💻 Author

**ajay47k** — Learning DevOps one pipeline at a time 🚀

*Built while following "Cloud DevOps Engineers Automate Practices" — Chapter 6*