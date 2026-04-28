#!/bin/bash

echo "=============================================="
echo "     PROJECT CONNECTIVITY DIAGNOSTICS"
echo "=============================================="

# ---------- AWS ----------
echo ""
echo "🔍 Checking AWS CLI..."
if command -v aws >/dev/null 2>&1; then
    echo "✔ AWS CLI installed: $(aws --version 2>&1)"
else
    echo "❌ AWS CLI NOT installed"
fi

echo ""
echo "🔍 Checking AWS credentials..."
if aws sts get-caller-identity >/dev/null 2>&1; then
    echo "✔ AWS credentials valid"
    aws sts get-caller-identity
else
    echo "❌ AWS credentials NOT configured or invalid"
fi

# ---------- GitHub ----------
echo ""
echo "🔍 Checking GitHub CLI..."
if command -v gh >/dev/null 2>&1; then
    echo "✔ GitHub CLI installed: $(gh --version | head -n 1)"
else
    echo "❌ GitHub CLI NOT installed"
fi

echo ""
echo "🔍 Checking GitHub authentication..."
if gh auth status >/dev/null 2>&1; then
    echo "✔ GitHub CLI authenticated"
else
    echo "❌ GitHub CLI NOT authenticated"
fi

echo ""
echo "🔍 Checking Git remote..."
if git remote -v >/dev/null 2>&1; then
    echo "✔ Git remotes found:"
    git remote -v
else
    echo "❌ No Git remotes configured"
fi

# ---------- GitHub Actions ----------
echo ""
echo "🔍 Checking GitHub Actions status..."
if gh workflow list >/dev/null 2>&1; then
    echo "✔ GitHub Actions workflows detected:"
    gh workflow list
else
    echo "❌ No workflows found or GitHub CLI not authenticated"
fi

# ---------- Docker ----------
echo ""
echo "🔍 Checking Docker..."
if command -v docker >/dev/null 2>&1; then
    echo "✔ Docker installed: $(docker --version)"
else
    echo "❌ Docker NOT installed"
fi

echo ""
echo "🔍 Checking Docker login..."
if docker info 2>/dev/null | grep -q "Username:"; then
    echo "✔ Docker logged in as: $(docker info 2>/dev/null | grep Username)"
else
    echo "❌ Docker NOT logged in"
fi

# ---------- Terraform ----------
echo ""
echo "🔍 Checking Terraform..."
if command -v terraform >/dev/null 2>&1; then
    echo "✔ Terraform installed: $(terraform version | head -n 1)"
else
    echo "❌ Terraform NOT installed"
fi

echo ""
echo "🔍 Checking Terraform init status..."
if [ -d ".terraform" ]; then
    echo "✔ Terraform initialized"
else
    echo "❌ Terraform NOT initialized (run: terraform init)"
fi

echo ""
echo "=============================================="
echo "     DIAGNOSTICS COMPLETE"
echo "=============================================="