# 🔄 Skillloop - Skill Barter Platform

> 🚀 **Swap services without fiat currency!** A decentralized platform where users can exchange skills and services using skill tokens instead of traditional money.

## 🌟 Overview

Skillloop is a blockchain-based skill bartering platform built on Stacks where users can:
- 📝 Offer their skills and services
- 🔍 Request skills from other users  
- 💰 Pay with skill tokens instead of fiat currency
- ⭐ Build reputation through completed services
- 📊 Review and rate skill providers

## 🎯 Core Features

### 👤 User Profiles
- Create personalized profiles with username and bio
- Track skill tokens, completed services, and reputation
- Start with 100 skill tokens upon registration

### 🛠️ Skill Management  
- List skills with title, description, category, and duration
- Set skill token requirements for each service
- Activate/deactivate skill listings

### 🤝 Service Requests
- Browse and request available skills
- Send messages to skill providers
- Track request status (pending → accepted → completed)

### 💎 Token Economy
- Earn skill tokens by completing services
- Spend tokens to request services from others
- Build reputation score through successful completions

### ⭐ Review System
- Rate services from 1-5 stars
- Leave detailed comments and feedback
- Build trust within the community

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
git clone <your-repo>
cd skillloop
clarinet check
```

### 📋 Usage Examples

#### 1️⃣ Create Your Profile
```clarity
(contract-call? .Skillloop create-profile "john_dev" "Full-stack developer with 5 years experience")
```

#### 2️⃣ List a Skill
```clarity
(contract-call? .Skillloop create-skill 
  "Website Development" 
  "I'll build a responsive website using modern frameworks"
  "Programming"
  u20
  u50)
```

#### 3️⃣ Request a Service
```clarity
(contract-call? .Skillloop request-skill u1 "Need a portfolio website for my business")
```

#### 4️⃣ Accept & Complete Requests
```clarity
;; Accept request
(contract-call? .Skillloop accept-request u1)

;; Mark as completed
(contract-call? .Skillloop complete-skill u1)
```

#### 5️⃣ Leave a Review
```clarity
(contract-call? .Skillloop add-review u1 u5 "Excellent work! Highly recommended")
```

## 📖 Read-Only Functions

- `get-skill` - View skill details
- `get-user-profile` - Check user information  
- `get-skill-request` - View request status
- `get-skill-review` - Read reviews
- `get-skill-counter` - Total skills created
- `get-request-counter` - Total requests made

## 🔧 Contract Architecture

### Data Structures
- **Skills**: Store skill offerings with provider info
- **Requests**: Track service requests and their status  
- **Profiles**: User information and token balances
- **Reviews**: Rating and feedback system

### Token Flow
1. 🆕 New users receive 100 skill tokens
2. 💸 Tokens are spent when requesting services
3. 💰 Tokens are earned when completing services
4. 📈 Reputation increases with successful completions

## 🛡️ Security Features

- ✅ Authorization checks for all operations
- ✅ Balance validation before transactions
- ✅ Status validation for state changes
- ✅ Ownership verification for skill management

## 🎨 Future Enhancements

- 🏷️ Skill categories and filtering
- 🔍 Advanced search functionality  
- 💬 Built-in messaging system
- 🏆 Achievement badges and levels
- 📱 Mobile-friendly interface

## 📄 License

MIT License - Build amazing things! 🚀

---

**Ready to start bartering skills?** 🤝 Join the Skillloop community and turn your expertise into valuable connections!