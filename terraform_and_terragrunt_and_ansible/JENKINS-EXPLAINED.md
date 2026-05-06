# Jenkins - คู่มือฉบับสมบูรณ์

## สารบัญ

1. [Jenkins คืออะไร?](#1-jenkins-คืออะไร)
2. [ทำไมต้อง Jenkins?](#2-ทำไมต้อง-jenkins)
3. [สถาปัตยกรรมของ Jenkins](#3-สถาปัตยกรรมของ-jenkins)
4. [คำศัพท์ที่ต้องรู้](#4-คำศัพท์ที่ต้องรู้)
5. [การติดตั้ง Jenkins](#5-การติดตั้ง-jenkins)
6. [การเขียน Jenkinsfile](#6-การเขียน-jenkinsfile)
7. [ตัวอย่าง: Deploy Web App ตั้งแต่เริ่มต้น](#7-ตัวอย่าง-deploy-web-app-ตั้งแต่เริ่มต้น)
8. [ตัวอย่าง Pipeline แบบต่างๆ](#8-ตัวอย่าง-pipeline-แบบต่างๆ)
9. [Jenkins vs Bitbucket Pipelines vs GitHub Actions](#9-jenkins-vs-bitbucket-pipelines-vs-github-actions)
10. [Shared Libraries](#10-shared-libraries)
11. [Jenkins Plugins ที่ควรรู้](#11-jenkins-plugins-ที่ควรรู้)
12. [Security & Best Practices](#12-security--best-practices)
13. [สรุป](#13-สรุป)

---

## 1. Jenkins คืออะไร?

Jenkins เป็น **CI/CD Automation Server** แบบ open-source ที่เขียนด้วย Java ใช้สำหรับ:

- **Continuous Integration (CI):** Build และ Test โค้ดอัตโนมัติทุกครั้งที่มีการ push
- **Continuous Delivery (CD):** เตรียม artifact พร้อม deploy (รอ manual approve)
- **Continuous Deployment (CD):** Deploy อัตโนมัติไปจนถึง production โดยไม่ต้องรอ approve
- **Pipeline Orchestration:** จัดลำดับขั้นตอนทั้งหมดแบบ end-to-end

### หลักการทำงาน

```
Developer push code
        │
        ▼
┌──────────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│   Source     │ ──→ │  Build   │ ──→ │   Test   │ ──→ │  Deploy  │
│   (Git)     │     │  (Compile)│     │  (Unit,  │     │  (Server)│
│              │     │           │     │  E2E)    │     │           │
└──────────────┘     └──────────┘     └──────────┘     └──────────┘
                          ▲
                          │
                    Jenkins ควบคุมทั้งหมด
```

### จุดเด่นของ Jenkins

- **Self-hosted:** ติดตั้งบน server ของเราเอง ควบคุมได้เต็มที่
- **Plugin Ecosystem:** มีมากกว่า 1,800 plugins รองรับเกือบทุก tool
- **Pipeline as Code:** เขียน CI/CD เป็นโค้ด (Jenkinsfile) เก็บใน Git ได้
- **Distributed Builds:** กระจาย workload ไปหลาย agent/node
- **ไม่จำกัด build minutes:** ไม่มีค่าใช้จ่ายต่อ build (ต่างจาก cloud CI/CD)

---

## 2. ทำไมต้อง Jenkins?

### ปัญหาที่ Jenkins แก้ได้

```
ก่อนมี CI/CD:
  Developer A: "ผม build บนเครื่องผมได้นะ"
  Developer B: "แต่เครื่องผม build ไม่ผ่าน"
  Developer C: "ใครเป็นคน deploy ล่าสุด? deploy ยังไง?"
  Server:      💥 Production down เพราะ deploy ผิดขั้นตอน

หลังใช้ Jenkins:
  Push code → Jenkins build อัตโนมัติ
            → Test อัตโนมัติ
            → Deploy ตามขั้นตอนที่กำหนด
            → ทุกคนเห็น log เหมือนกัน
            → Rollback ได้ถ้ามีปัญหา
```

### เมื่อไหร่ควรใช้ Jenkins?

| สถานการณ์ | ใช้ Jenkins |
|-----------|:-----------:|
| ต้องการ CI/CD ที่ customize ได้ 100% | ✅ |
| ต้องการรัน pipeline บน private network | ✅ |
| มี compliance/security ที่ต้อง self-host | ✅ |
| ต้องการ pipeline ที่ซับซ้อน (multi-branch, matrix build) | ✅ |
| ต้องการ approval workflow หลายขั้น | ✅ |
| ไม่อยากจ่ายค่า build minutes | ✅ |
| ต้อง integrate กับ tool ภายในองค์กร | ✅ |

---

## 3. สถาปัตยกรรมของ Jenkins

### Master-Agent Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Jenkins Controller (Master)               │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │ Web UI   │  │ Scheduler│  │ Plugin   │  │ Config   │   │
│  │ Dashboard│  │ & Queue  │  │ Manager  │  │ & Creds  │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│                                                             │
│                    จัดการ + สั่งงาน                          │
│                    ไม่ควร build เอง                          │
└────────────────────────┬────────────────────────────────────┘
                         │ สั่งงานผ่าน JNLP / SSH
            ┌────────────┼────────────┐
            ▼            ▼            ▼
     ┌──────────┐ ┌──────────┐ ┌──────────┐
     │ Agent 1  │ │ Agent 2  │ │ Agent 3  │
     │ (Linux)  │ │ (Docker) │ │ (Windows)│
     │          │ │          │ │          │
     │ Build    │ │ Test     │ │ Build    │
     │ Java app │ │ Node app │ │ .NET app │
     └──────────┘ └──────────┘ └──────────┘
       ทำงานจริง    ทำงานจริง    ทำงานจริง
```

### แบบ Docker Agent (แนะนำ)

```
┌─────────────────────────────────────────────┐
│              Jenkins Controller              │
│                                             │
│  Pipeline ต้องการ build Node.js app         │
│          │                                   │
│          ▼                                   │
│  ┌─────────────────────────────┐            │
│  │ docker run node:20-alpine  │ ← สร้าง    │
│  │                             │   container │
│  │  npm install                │   ชั่วคราว  │
│  │  npm test                   │             │
│  │  npm run build              │             │
│  │                             │             │
│  └─────────────────────────────┘ ← ลบทิ้ง   │
│                                   เมื่อเสร็จ  │
└─────────────────────────────────────────────┘
```

---

## 4. คำศัพท์ที่ต้องรู้

| คำศัพท์ | ความหมาย | ตัวอย่าง |
|---------|----------|----------|
| **Controller** | เซิร์ฟเวอร์หลักที่รัน Jenkins | `http://jenkins.company.com:8080` |
| **Agent/Node** | เครื่องที่รัน build จริง | Linux VM, Docker container |
| **Pipeline** | ชุดขั้นตอนทั้งหมดตั้งแต่ต้นจนจบ | Build → Test → Deploy |
| **Stage** | กลุ่มของ step ที่เกี่ยวข้อง | `stage('Build')`, `stage('Test')` |
| **Step** | คำสั่งเดี่ยวใน stage | `sh 'npm install'` |
| **Jenkinsfile** | ไฟล์ Pipeline as Code | อยู่ root ของ repo |
| **Job/Project** | งานที่กำหนดไว้ใน Jenkins | `deploy-web-app` |
| **Build** | การรัน job แต่ละครั้ง | Build #42 |
| **Workspace** | โฟลเดอร์ทำงานบน agent | `/var/jenkins/workspace/my-app` |
| **Artifact** | ผลลัพธ์จาก build | `app.jar`, `build.zip` |
| **Trigger** | สิ่งที่เริ่ม pipeline | Webhook, Cron, Manual |
| **Credentials** | ข้อมูลลับที่ Jenkins เก็บ | SSH key, API token, password |
| **Plugin** | ส่วนเสริมเพิ่มความสามารถ | Docker, AWS, Slack plugins |
| **Shared Library** | โค้ดที่ใช้ร่วมกันข้าม pipeline | `vars/deployApp.groovy` |
| **Multibranch** | Pipeline ที่สร้างอัตโนมัติทุก branch | `main`, `develop`, `feature/*` |
| **Blue Ocean** | UI แบบ modern สำหรับ pipeline | Visual pipeline editor |

---

## 5. การติดตั้ง Jenkins

### Option A: Docker (แนะนำสำหรับเริ่มต้น)

```bash
# สร้าง volume เก็บข้อมูล Jenkins
docker volume create jenkins_home

# รัน Jenkins
docker run -d \
  --name jenkins \
  --restart=unless-stopped \
  -p 8080:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  jenkins/jenkins:lts

# ดู initial password
docker logs jenkins 2>&1 | grep -A 5 "initial"
# หรือ
docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword
```

### Option B: Docker Compose (สำหรับ production)

```yaml
# docker-compose.yml
version: '3.8'
services:
  jenkins:
    image: jenkins/jenkins:lts
    container_name: jenkins
    restart: unless-stopped
    ports:
      - "8080:8080"    # Web UI
      - "50000:50000"  # Agent communication
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - JAVA_OPTS=-Xmx2048m -Xms512m

volumes:
  jenkins_home:
```

```bash
docker compose up -d
```

### Option C: ติดตั้งบน Ubuntu/Debian

```bash
# ติดตั้ง Java
sudo apt update
sudo apt install -y fontconfig openjdk-17-jre

# เพิ่ม Jenkins repository
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" \
  | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# ติดตั้ง Jenkins
sudo apt update
sudo apt install -y jenkins

# เริ่ม service
sudo systemctl enable jenkins
sudo systemctl start jenkins

# ดู initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

### Initial Setup (ทุก option)

1. เปิด browser ไปที่ `http://localhost:8080`
2. ใส่ initial admin password
3. เลือก **Install suggested plugins** (ติดตั้ง plugin พื้นฐาน)
4. สร้าง admin user
5. ตั้งค่า Jenkins URL
6. พร้อมใช้งาน!

```
┌─────────────────────────────────────┐
│     Jenkins Setup Wizard            │
│                                     │
│  Step 1: Unlock Jenkins             │
│          ใส่ initial password       │
│                                     │
│  Step 2: Install Plugins            │
│          → Suggested plugins        │
│                                     │
│  Step 3: Create Admin User          │
│          Username: admin            │
│          Password: ********         │
│                                     │
│  Step 4: Configure URL              │
│          http://jenkins.local:8080  │
│                                     │
│  ✅ Jenkins is ready!               │
└─────────────────────────────────────┘
```

---

## 6. การเขียน Jenkinsfile

Jenkinsfile มี 2 แบบ: **Declarative** (แนะนำ) และ **Scripted**

### 6.1 Declarative Pipeline (แนะนำ)

```groovy
// Jenkinsfile
pipeline {
    // ─── agent: กำหนดว่ารันที่ไหน ───
    agent any                        // รันบน agent ไหนก็ได้
    // agent { docker 'node:20' }    // รันใน Docker container
    // agent { label 'linux' }       // รันบน agent ที่มี label 'linux'
    // agent none                    // กำหนดเองในแต่ละ stage

    // ─── options: ตั้งค่า pipeline ───
    options {
        timeout(time: 30, unit: 'MINUTES')  // timeout ทั้ง pipeline
        timestamps()                         // แสดง timestamp ใน log
        disableConcurrentBuilds()            // ไม่ให้รันพร้อมกัน
        buildDiscarder(logRotator(           // เก็บ build history
            numToKeepStr: '10'
        ))
    }

    // ─── environment: ตัวแปร ───
    environment {
        APP_NAME    = 'my-web-app'
        DEPLOY_ENV  = 'production'
        DOCKER_REG  = 'registry.example.com'
        // ดึง credentials จาก Jenkins
        DOCKER_CREDS = credentials('docker-registry-creds')
    }

    // ─── parameters: input จาก user ───
    parameters {
        string(name: 'BRANCH', defaultValue: 'main', description: 'Branch to build')
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'], description: 'Deploy environment')
        booleanParam(name: 'SKIP_TESTS', defaultValue: false, description: 'Skip tests')
    }

    // ─── triggers: เมื่อไหร่จะรัน ───
    triggers {
        githubPush()                  // เมื่อ push to GitHub
        cron('H 2 * * 1-5')          // จันทร์-ศุกร์ ตี 2
        pollSCM('H/5 * * * *')       // check Git ทุก 5 นาที
    }

    // ─── stages: ขั้นตอนการทำงาน ───
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                // หรือ
                // git branch: params.BRANCH, url: 'https://github.com/user/repo.git'
            }
        }

        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
            }
        }

        stage('Lint') {
            steps {
                sh 'npm run lint'
            }
        }

        stage('Test') {
            when {
                expression { !params.SKIP_TESTS }  // ข้ามถ้า SKIP_TESTS = true
            }
            steps {
                sh 'npm test -- --coverage'
            }
            post {
                always {
                    // เก็บ test report
                    junit 'reports/**/*.xml'
                    // เก็บ coverage report
                    publishHTML(target: [
                        reportDir: 'coverage',
                        reportFiles: 'index.html',
                        reportName: 'Coverage Report'
                    ])
                }
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build'
                // เก็บ artifact
                archiveArtifacts artifacts: 'dist/**/*', fingerprint: true
            }
        }

        stage('Docker Build & Push') {
            steps {
                script {
                    def image = docker.build("${DOCKER_REG}/${APP_NAME}:${BUILD_NUMBER}")
                    docker.withRegistry("https://${DOCKER_REG}", 'docker-registry-creds') {
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }

        stage('Deploy') {
            when {
                branch 'main'  // deploy เฉพาะ branch main
            }
            steps {
                sh "kubectl set image deployment/${APP_NAME} ${APP_NAME}=${DOCKER_REG}/${APP_NAME}:${BUILD_NUMBER}"
            }
        }
    }

    // ─── post: ทำหลังจบ pipeline ───
    post {
        success {
            echo '✅ Build succeeded!'
            // slackSend(color: 'good', message: "Build #${BUILD_NUMBER} succeeded")
        }
        failure {
            echo '❌ Build failed!'
            // slackSend(color: 'danger', message: "Build #${BUILD_NUMBER} failed")
        }
        always {
            cleanWs()  // ล้าง workspace
        }
    }
}
```

### 6.2 Scripted Pipeline (Advanced)

```groovy
// Jenkinsfile - Scripted Pipeline
// ใช้ Groovy เต็มรูปแบบ ยืดหยุ่นกว่า แต่เขียนยากกว่า
node('linux') {
    try {
        stage('Checkout') {
            checkout scm
        }

        stage('Build') {
            sh 'npm ci && npm run build'
        }

        stage('Test') {
            sh 'npm test'
        }

        stage('Deploy') {
            if (env.BRANCH_NAME == 'main') {
                sh 'deploy.sh production'
            } else if (env.BRANCH_NAME == 'develop') {
                sh 'deploy.sh staging'
            }
        }

        currentBuild.result = 'SUCCESS'
    } catch (Exception e) {
        currentBuild.result = 'FAILURE'
        throw e
    } finally {
        cleanWs()
    }
}
```

### 6.3 เปรียบเทียบ Declarative vs Scripted

| | Declarative | Scripted |
|--|-------------|----------|
| **Syntax** | มีโครงสร้างตายตัว | Groovy อิสระ |
| **ง่ายต่อการเรียนรู้** | ✅ ง่ายกว่า | ❌ ต้องรู้ Groovy |
| **Validation** | ตรวจ syntax ก่อนรัน | ไม่ตรวจ |
| **Flexibility** | จำกัดกว่า | ยืดหยุ่นมาก |
| **`when` conditions** | ✅ built-in | ต้องเขียน `if` เอง |
| **`post` actions** | ✅ built-in | ต้องเขียน `try/catch` เอง |
| **แนะนำ** | ✅ สำหรับ 90% ของ use cases | เมื่อ declarative ไม่พอ |

### 6.4 Syntax สำคัญ

#### when - กำหนดเงื่อนไข

```groovy
stage('Deploy to Prod') {
    when {
        // รันเฉพาะ branch main
        branch 'main'

        // รันเฉพาะเมื่อมี tag
        // tag pattern: 'v*'

        // รันเฉพาะเมื่อ parameter = true
        // expression { params.DEPLOY_PROD == true }

        // รันเฉพาะเมื่อ environment ตรง
        // environment name: 'DEPLOY_ENV', value: 'production'

        // รันเฉพาะเมื่อไฟล์เปลี่ยน
        // changeset '**/*.js'

        // รวม conditions (AND)
        // allOf { branch 'main'; environment name: 'ENV', value: 'prod' }

        // รวม conditions (OR)
        // anyOf { branch 'main'; branch 'release/*' }
    }
    steps {
        sh 'deploy.sh'
    }
}
```

#### input - Manual Approval

```groovy
stage('Deploy to Production') {
    steps {
        // หยุดรอ approval จาก user
        input message: 'Deploy to production?',
              ok: 'Yes, deploy!',
              submitter: 'admin,devops-team'

        sh 'deploy.sh production'
    }
}
```

#### parallel - รัน stage พร้อมกัน

```groovy
stage('Test') {
    parallel {
        stage('Unit Tests') {
            steps { sh 'npm run test:unit' }
        }
        stage('Integration Tests') {
            steps { sh 'npm run test:integration' }
        }
        stage('E2E Tests') {
            agent { docker 'cypress/included:latest' }
            steps { sh 'npm run test:e2e' }
        }
    }
}
```

#### matrix - Build หลาย combinations

```groovy
stage('Build Matrix') {
    matrix {
        axes {
            axis {
                name 'NODE_VERSION'
                values '18', '20', '22'
            }
            axis {
                name 'OS'
                values 'linux', 'windows'
            }
        }
        stages {
            stage('Build') {
                agent { docker "node:${NODE_VERSION}" }
                steps {
                    sh 'node --version && npm ci && npm test'
                }
            }
        }
    }
}
```

#### credentials - ใช้ข้อมูลลับ

```groovy
environment {
    // Username + Password → แยกเป็น _USR และ _PSW
    DOCKER_CREDS = credentials('docker-hub-creds')
    // ใช้: ${DOCKER_CREDS_USR} และ ${DOCKER_CREDS_PSW}

    // Secret text
    API_KEY = credentials('api-key-id')
    // ใช้: ${API_KEY}

    // SSH key
    SSH_KEY = credentials('ssh-key-id')
    // ใช้: ${SSH_KEY} (path to key file)
}

steps {
    // หรือใช้ withCredentials block
    withCredentials([
        usernamePassword(
            credentialsId: 'docker-hub-creds',
            usernameVariable: 'USER',
            passwordVariable: 'PASS'
        )
    ]) {
        sh 'docker login -u $USER -p $PASS'
    }

    // SSH key
    sshagent(['ec2-ssh-key']) {
        sh 'ssh ubuntu@server "uptime"'
    }
}
```

---

## 7. ตัวอย่าง: Deploy Web App ตั้งแต่เริ่มต้น

### สถานการณ์

```
เรามี Node.js web app ต้องการ:
1. Build → Test → Docker Build → Push to Registry → Deploy to Server

โครงสร้างโปรเจค:
├── Jenkinsfile          # Pipeline
├── Dockerfile           # Docker build
├── package.json         # Node.js dependencies
├── src/                 # Source code
│   └── index.js
├── tests/               # Tests
│   └── app.test.js
└── deploy/
    └── docker-compose.yml  # Production compose
```

### Step 1: สร้าง Dockerfile

```dockerfile
# Dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY src/ ./src/

FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app .
EXPOSE 3000
USER node
CMD ["node", "src/index.js"]
```

### Step 2: สร้าง docker-compose.yml สำหรับ production

```yaml
# deploy/docker-compose.yml
version: '3.8'
services:
  web-app:
    image: ${DOCKER_IMAGE}
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=${DATABASE_URL}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

### Step 3: เขียน Jenkinsfile

```groovy
pipeline {
    agent any

    environment {
        APP_NAME     = 'my-web-app'
        DOCKER_REG   = 'your-registry.com'  // หรือ Docker Hub username
        DOCKER_IMAGE = "${DOCKER_REG}/${APP_NAME}"
        SERVER_IP    = '13.212.xxx.xxx'
        SERVER_USER  = 'ubuntu'
    }

    options {
        timeout(time: 15, unit: 'MINUTES')
        timestamps()
        buildDiscarder(logRotator(numToKeepStr: '5'))
    }

    stages {
        // ── 1. Checkout Code ──
        stage('Checkout') {
            steps {
                checkout scm
                sh 'echo "Building commit: $(git rev-parse --short HEAD)"'
            }
        }

        // ── 2. Install & Lint ──
        stage('Install Dependencies') {
            agent { docker 'node:20-alpine' }
            steps {
                sh 'npm ci'
                sh 'npm run lint'
            }
        }

        // ── 3. Run Tests ──
        stage('Test') {
            agent { docker 'node:20-alpine' }
            steps {
                sh 'npm ci'
                sh 'npm test -- --coverage --reporters=default --reporters=jest-junit'
            }
            post {
                always {
                    junit 'junit.xml'
                }
            }
        }

        // ── 4. Build Docker Image ──
        stage('Docker Build') {
            steps {
                script {
                    env.IMAGE_TAG = "${BUILD_NUMBER}-${sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()}"
                    sh "docker build -t ${DOCKER_IMAGE}:${IMAGE_TAG} -t ${DOCKER_IMAGE}:latest ."
                }
            }
        }

        // ── 5. Push to Registry ──
        stage('Docker Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-registry-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh """
                        echo "\$DOCKER_PASS" | docker login ${DOCKER_REG} -u "\$DOCKER_USER" --password-stdin
                        docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                        docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        // ── 6. Deploy to Staging ──
        stage('Deploy Staging') {
            when { branch 'develop' }
            steps {
                sshagent(['server-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} '
                            export DOCKER_IMAGE=${DOCKER_IMAGE}:${IMAGE_TAG}
                            cd /opt/app
                            docker compose pull
                            docker compose up -d
                            sleep 5
                            curl -sf http://localhost:3000/health || exit 1
                        '
                    """
                }
                echo "Staging: http://${SERVER_IP}:3000"
            }
        }

        // ── 7. Deploy to Production (ต้อง approve) ──
        stage('Deploy Production') {
            when { branch 'main' }
            steps {
                // Manual approval
                input message: 'Deploy to production?',
                      ok: 'Deploy',
                      submitter: 'admin,lead-dev'

                sshagent(['prod-server-ssh-key']) {
                    sh """
                        ssh -o StrictHostKeyChecking=no ${SERVER_USER}@${SERVER_IP} '
                            export DOCKER_IMAGE=${DOCKER_IMAGE}:${IMAGE_TAG}
                            cd /opt/app

                            # Blue-Green deployment
                            docker compose pull
                            docker compose up -d --no-deps web-app

                            # Health check
                            for i in 1 2 3 4 5; do
                                if curl -sf http://localhost:3000/health; then
                                    echo "Health check passed"
                                    exit 0
                                fi
                                echo "Attempt \$i failed, retrying in 5s..."
                                sleep 5
                            done
                            echo "Health check failed, rolling back..."
                            docker compose rollback
                            exit 1
                        '
                    """
                }
            }
        }
    }

    post {
        success {
            echo "Build #${BUILD_NUMBER} succeeded!"
            // slackSend(color: 'good', message: "✅ ${APP_NAME} #${BUILD_NUMBER} deployed")
        }
        failure {
            echo "Build #${BUILD_NUMBER} failed!"
            // slackSend(color: 'danger', message: "❌ ${APP_NAME} #${BUILD_NUMBER} failed")
        }
        always {
            // ลบ Docker images ที่ build เพื่อประหยัดพื้นที่
            sh "docker rmi ${DOCKER_IMAGE}:${IMAGE_TAG} || true"
            cleanWs()
        }
    }
}
```

### Step 4: สร้าง Job ใน Jenkins

```
1. Jenkins Dashboard → New Item
2. ชื่อ: my-web-app
3. เลือก: Multibranch Pipeline
4. Branch Sources:
   - GitHub / Bitbucket / Git
   - Repository URL: https://github.com/you/my-web-app.git
   - Credentials: github-token
5. Build Configuration:
   - Script Path: Jenkinsfile
6. Scan Multibranch Pipeline Triggers:
   - Periodically: 1 minute (หรือใช้ webhook)
7. Save

→ Jenkins จะ scan ทุก branch ที่มี Jenkinsfile
→ สร้าง pipeline อัตโนมัติสำหรับแต่ละ branch
```

### Step 5: ตั้ง Webhook (Optional)

```
GitHub:
  Settings → Webhooks → Add webhook
  URL: http://jenkins.company.com:8080/github-webhook/
  Content type: application/json
  Events: Just the push event

Bitbucket:
  Settings → Webhooks → Add webhook
  URL: http://jenkins.company.com:8080/bitbucket-hook/
  Events: Repository push
```

### ผลลัพธ์ใน Jenkins UI

```
┌──────────────────────────────────────────────────────┐
│  my-web-app / main / #42                             │
│                                                      │
│  ┌──────────┐   ┌──────┐   ┌──────────────┐         │
│  │ Checkout │ → │ Test │ → │ Docker Build │         │
│  │  ✅ 3s   │   │ ✅ 45s│   │   ✅ 30s     │         │
│  └──────────┘   └──────┘   └──────────────┘         │
│                                    │                 │
│  ┌──────────────┐   ┌──────────────────────┐        │
│  │ Docker Push  │ → │ Deploy Production ⏸ │        │
│  │   ✅ 15s     │   │  Waiting for input   │        │
│  └──────────────┘   └──────────────────────┘        │
│                                                      │
│  [Deploy] [Abort]                                    │
└──────────────────────────────────────────────────────┘
```

---

## 8. ตัวอย่าง Pipeline แบบต่างๆ

### 8.1 Python/Django App

```groovy
pipeline {
    agent { docker 'python:3.12-slim' }

    stages {
        stage('Install') {
            steps {
                sh '''
                    python -m venv venv
                    . venv/bin/activate
                    pip install -r requirements.txt
                '''
            }
        }
        stage('Lint') {
            steps {
                sh '. venv/bin/activate && flake8 . && black --check .'
            }
        }
        stage('Test') {
            steps {
                sh '. venv/bin/activate && pytest --junitxml=report.xml --cov=app'
            }
            post { always { junit 'report.xml' } }
        }
        stage('Build & Deploy') {
            when { branch 'main' }
            agent any
            steps {
                sh 'docker build -t myapp:${BUILD_NUMBER} .'
                sh 'docker push myapp:${BUILD_NUMBER}'
            }
        }
    }
}
```

### 8.2 Terraform Infrastructure Pipeline

```groovy
pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['dev', 'staging', 'prod'])
        choice(name: 'ACTION', choices: ['plan', 'apply', 'destroy'])
    }

    environment {
        AWS_CREDS = credentials('aws-credentials')
        TF_DIR = "terraform/environments/${params.ENV}"
    }

    stages {
        stage('Terraform Init') {
            steps {
                dir(TF_DIR) {
                    sh 'terraform init'
                }
            }
        }

        stage('Terraform Plan') {
            steps {
                dir(TF_DIR) {
                    sh 'terraform plan -out=tfplan'
                }
            }
        }

        stage('Approval') {
            when { expression { params.ACTION != 'plan' } }
            steps {
                input message: "Apply ${params.ACTION} to ${params.ENV}?",
                      ok: "Yes, ${params.ACTION}!"
            }
        }

        stage('Terraform Apply') {
            when { expression { params.ACTION == 'apply' } }
            steps {
                dir(TF_DIR) {
                    sh 'terraform apply tfplan'
                }
            }
        }

        stage('Terraform Destroy') {
            when { expression { params.ACTION == 'destroy' } }
            steps {
                dir(TF_DIR) {
                    sh 'terraform destroy -auto-approve'
                }
            }
        }
    }
}
```

### 8.3 Monorepo Multi-Service

```groovy
pipeline {
    agent any

    stages {
        stage('Detect Changes') {
            steps {
                script {
                    env.FRONTEND_CHANGED = sh(
                        script: 'git diff --name-only HEAD~1 | grep "^frontend/" || true',
                        returnStdout: true
                    ).trim() ? 'true' : 'false'

                    env.BACKEND_CHANGED = sh(
                        script: 'git diff --name-only HEAD~1 | grep "^backend/" || true',
                        returnStdout: true
                    ).trim() ? 'true' : 'false'
                }
            }
        }

        stage('Build Services') {
            parallel {
                stage('Frontend') {
                    when { expression { env.FRONTEND_CHANGED == 'true' } }
                    agent { docker 'node:20' }
                    steps {
                        dir('frontend') {
                            sh 'npm ci && npm test && npm run build'
                        }
                    }
                }
                stage('Backend') {
                    when { expression { env.BACKEND_CHANGED == 'true' } }
                    agent { docker 'python:3.12' }
                    steps {
                        dir('backend') {
                            sh 'pip install -r requirements.txt && pytest'
                        }
                    }
                }
            }
        }

        stage('Deploy Changed Services') {
            when { branch 'main' }
            steps {
                script {
                    if (env.FRONTEND_CHANGED == 'true') {
                        sh 'docker build -t frontend:${BUILD_NUMBER} frontend/'
                        sh 'docker push frontend:${BUILD_NUMBER}'
                    }
                    if (env.BACKEND_CHANGED == 'true') {
                        sh 'docker build -t backend:${BUILD_NUMBER} backend/'
                        sh 'docker push backend:${BUILD_NUMBER}'
                    }
                }
            }
        }
    }
}
```

---

## 9. Jenkins vs Bitbucket Pipelines vs GitHub Actions

### ตารางเปรียบเทียบ

| หัวข้อ | Jenkins | GitHub Actions | Bitbucket Pipelines |
|--------|---------|---------------|-------------------|
| **ประเภท** | Self-hosted server | Cloud-native (GitHub) | Cloud-native (Bitbucket) |
| **Hosting** | ติดตั้งเอง | GitHub จัดการให้ | Atlassian จัดการให้ |
| **Config File** | `Jenkinsfile` (Groovy) | `.github/workflows/*.yml` | `bitbucket-pipelines.yml` |
| **ภาษา Config** | Groovy DSL | YAML | YAML |
| **Build Minutes** | ไม่จำกัด (self-host) | 2,000 นาที/เดือน (Free) | 50 นาที/เดือน (Free) |
| **Concurrent Builds** | ไม่จำกัด (ขึ้นกับ agent) | 20 (Free), 180 (Enterprise) | 1 (Free), 2+ (Standard) |
| **Self-hosted Runner** | ✅ เป็น default | ✅ รองรับ | ❌ ไม่รองรับ (ต้องใช้ Runner) |
| **Plugin/Marketplace** | 1,800+ plugins | 20,000+ Actions | จำกัด (ใช้ pipes) |
| **UI Dashboard** | ✅ ครบ (Blue Ocean) | ✅ ดี | ✅ พื้นฐาน |
| **Approval/Gate** | ✅ `input` step | ✅ Environments | ✅ Deployment permissions |
| **Secret Management** | ✅ Credentials store | ✅ GitHub Secrets | ✅ Repository variables |
| **Matrix Build** | ✅ | ✅ | ❌ |
| **Caching** | ✅ (workspace) | ✅ (`actions/cache`) | ✅ (`caches`) |
| **Artifacts** | ✅ | ✅ | ✅ |
| **Setup Complexity** | สูง (ต้องดูแล server) | ต่ำมาก (แค่สร้าง YAML) | ต่ำมาก (แค่สร้าง YAML) |
| **Maintenance** | ต้องดูแลเอง (update, backup) | ไม่ต้อง | ไม่ต้อง |
| **Cost** | ฟรี (แต่จ่ายค่า server) | ฟรี → $4/user/เดือน | ฟรี → $15/user/เดือน |

### เปรียบเทียบ Syntax

#### งานเดียวกัน: Build → Test → Deploy Node.js App

**Jenkins:**
```groovy
pipeline {
    agent { docker 'node:20' }
    stages {
        stage('Install') {
            steps { sh 'npm ci' }
        }
        stage('Test') {
            steps { sh 'npm test' }
        }
        stage('Build') {
            steps { sh 'npm run build' }
        }
        stage('Deploy') {
            when { branch 'main' }
            steps {
                sshagent(['server-key']) {
                    sh 'rsync -avz dist/ user@server:/var/www/app/'
                }
            }
        }
    }
}
```

**GitHub Actions:**
```yaml
# .github/workflows/ci.yml
name: CI/CD
on:
  push:
    branches: [main, develop]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm test
      - run: npm run build

  deploy:
    needs: build-and-test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run build
      - uses: burnett01/rsync-deployments@7
        with:
          switches: -avz
          path: dist/
          remote_path: /var/www/app/
          remote_host: ${{ secrets.SERVER_IP }}
          remote_user: ${{ secrets.SERVER_USER }}
          remote_key: ${{ secrets.SSH_KEY }}
```

**Bitbucket Pipelines:**
```yaml
# bitbucket-pipelines.yml
image: node:20

pipelines:
  default:
    - step:
        name: Install & Test
        caches:
          - node
        script:
          - npm ci
          - npm test

    - step:
        name: Build
        script:
          - npm run build
        artifacts:
          - dist/**

  branches:
    main:
      - step:
          name: Install, Test & Build
          caches:
            - node
          script:
            - npm ci
            - npm test
            - npm run build
          artifacts:
            - dist/**
      - step:
          name: Deploy
          deployment: production
          script:
            - pipe: atlassian/rsync-deploy:0.12.0
              variables:
                USER: $SERVER_USER
                SERVER: $SERVER_IP
                REMOTE_PATH: /var/www/app/
                LOCAL_PATH: dist/
```

### ข้อดีของ Jenkins เหนือ Cloud CI/CD

#### 1. ไม่มี Build Minutes Limit

```
GitHub Actions Free:  2,000 นาที/เดือน  → ถ้า build 10 นาที = 200 builds/เดือน
Bitbucket Free:       50 นาที/เดือน     → ถ้า build 10 นาที = 5 builds/เดือน
Jenkins:              ∞ (ไม่จำกัด)       → build กี่ครั้งก็ได้

ทีม 10 คน push วันละ 5 ครั้ง = 50 builds/วัน = 1,500 builds/เดือน
  GitHub Actions: ต้องจ่ายเพิ่ม
  Jenkins: ฟรี
```

#### 2. Full Control & Customization

```
Jenkins:
  ✅ ติดตั้ง plugin อะไรก็ได้
  ✅ customize UI ได้
  ✅ เขียน Groovy script ทำอะไรก็ได้
  ✅ integrate กับ tool ภายในองค์กร (LDAP, JIRA, custom tools)
  ✅ กำหนด hardware ของ agent เอง (GPU, high memory)

GitHub Actions / Bitbucket:
  ❌ ใช้ได้เฉพาะ features ที่ platform มีให้
  ❌ runner specs กำหนดโดย platform (2-core, 7GB RAM)
  ❌ ถ้า platform ล่ม → CI/CD ล่มตาม
```

#### 3. Security & Compliance

```
Jenkins (Self-hosted):
  ✅ Data อยู่บน server เรา → ไม่ออกนอกองค์กร
  ✅ รันใน private network → ไม่ต้อง expose อะไร
  ✅ Audit log ควบคุมเอง
  ✅ เหมาะกับ regulated industry (banking, healthcare)
  ✅ Air-gapped environment ได้

Cloud CI/CD:
  ⚠️ Code ถูก checkout บน cloud runner
  ⚠️ Secrets ส่งผ่าน cloud
  ⚠️ ขึ้นกับ vendor compliance (SOC2, etc.)
```

#### 4. Complex Pipeline

```
Jenkins สามารถทำ:
  ✅ Pipeline ที่มี 20+ stages ซับซ้อน
  ✅ Dynamic stage generation (สร้าง stage จาก loop)
  ✅ Cross-pipeline triggers (pipeline A เสร็จ → trigger pipeline B)
  ✅ Shared Libraries ใช้ร่วมกันทั้งองค์กร
  ✅ Pipeline ที่รัน terraform → ansible → deploy → test → rollback
  ✅ Multi-branch + Multi-repo pipeline

GitHub Actions / Bitbucket:
  ⚠️ จำกัด complexity (YAML ไม่ยืดหยุ่นเท่า Groovy)
  ⚠️ Reusable workflows มีข้อจำกัด
  ⚠️ Cross-repo trigger ทำได้แต่ซับซ้อน
```

#### 5. Distributed & Scalable

```
Jenkins:
  ┌──────────────┐
  │  Controller   │
  │              │
  │  สั่ง build  │──→ Agent Pool (Linux x 10)    → Java builds
  │  queue       │──→ Agent Pool (Docker x 5)    → Container builds
  │  distribute  │──→ Agent Pool (GPU x 2)       → ML model training
  │              │──→ Agent Pool (Windows x 3)   → .NET builds
  └──────────────┘

  scale agent ได้ตามต้องการ
  ใช้ Kubernetes plugin → auto-scale pods
```

### ข้อเสียของ Jenkins

| ข้อเสีย | รายละเอียด |
|---------|-----------|
| **ต้องดูแล server** | Update Jenkins, plugins, backup, monitor |
| **Setup ซับซ้อน** | ต้องติดตั้ง, config, ดูแล agents |
| **Plugin compatibility** | Plugin อาจ conflict กัน หรือ outdated |
| **Groovy learning curve** | ต้องเรียนรู้ Groovy DSL |
| **UI เก่า** | Classic UI ดูล้าสมัย (แก้ด้วย Blue Ocean) |
| **Single point of failure** | ถ้า Jenkins master ล่ม → ทุกอย่างหยุด |

### แล้วเลือกตัวไหนดี?

```
เลือก Jenkins เมื่อ:
  → องค์กรขนาดกลาง-ใหญ่
  → ต้องการ full control
  → มี compliance requirements
  → Pipeline ซับซ้อน
  → Build เยอะ ไม่อยากจ่ายค่า minutes
  → ต้อง integrate กับ internal tools

เลือก GitHub Actions เมื่อ:
  → ใช้ GitHub เป็น SCM อยู่แล้ว
  → ทีมเล็ก ไม่อยากดูแล server
  → Pipeline ไม่ซับซ้อนมาก
  → ต้องการ setup เร็ว

เลือก Bitbucket Pipelines เมื่อ:
  → ใช้ Atlassian ecosystem (Jira, Bitbucket, Confluence)
  → ทีมเล็ก pipeline ง่าย
  → ต้องการ integration กับ Jira

ใช้ร่วมกัน:
  → Jenkins เป็น main orchestrator
  → GitHub Actions ทำ lightweight checks (lint, format)
  → Best of both worlds
```

---

## 10. Shared Libraries

Shared Libraries คือการเขียน Groovy functions ที่ใช้ซ้ำได้ข้าม pipeline ทั้งองค์กร

### โครงสร้าง

```
jenkins-shared-library/      # Git repo แยก
├── vars/                     # Global functions (เรียกจาก Jenkinsfile ได้เลย)
│   ├── buildDocker.groovy
│   ├── deployToServer.groovy
│   ├── notifySlack.groovy
│   └── standardPipeline.groovy
├── src/                      # Classes (optional)
│   └── com/company/
│       └── Docker.groovy
└── resources/                # Static files
    └── scripts/
        └── deploy.sh
```

### ตัวอย่าง Shared Library

```groovy
// vars/buildDocker.groovy
def call(Map config) {
    def image = config.image ?: error("image is required")
    def tag = config.tag ?: env.BUILD_NUMBER
    def registry = config.registry ?: 'docker.io'

    stage('Docker Build') {
        sh "docker build -t ${registry}/${image}:${tag} ."
    }

    stage('Docker Push') {
        withCredentials([usernamePassword(
            credentialsId: config.credentialsId ?: 'docker-creds',
            usernameVariable: 'USER',
            passwordVariable: 'PASS'
        )]) {
            sh """
                echo "\$PASS" | docker login ${registry} -u "\$USER" --password-stdin
                docker push ${registry}/${image}:${tag}
            """
        }
    }

    return "${registry}/${image}:${tag}"
}
```

```groovy
// vars/notifySlack.groovy
def call(String status, String channel = '#deployments') {
    def color = status == 'SUCCESS' ? 'good' : 'danger'
    def icon = status == 'SUCCESS' ? '✅' : '❌'

    slackSend(
        channel: channel,
        color: color,
        message: "${icon} *${env.JOB_NAME}* #${env.BUILD_NUMBER} - ${status}\n${env.BUILD_URL}"
    )
}
```

### ใช้งาน Shared Library

```groovy
// Jenkinsfile ของแต่ละ project
@Library('my-shared-library') _   // โหลด shared library

pipeline {
    agent any
    stages {
        stage('Build & Push') {
            steps {
                script {
                    // เรียกใช้ function จาก shared library
                    def imageUrl = buildDocker(
                        image: 'my-app',
                        registry: 'registry.company.com',
                        tag: "${BUILD_NUMBER}"
                    )
                    echo "Built: ${imageUrl}"
                }
            }
        }
    }
    post {
        always {
            notifySlack(currentBuild.result ?: 'SUCCESS')
        }
    }
}
```

### ตัวอย่าง Standard Pipeline (Template)

```groovy
// vars/standardPipeline.groovy
// ใช้ template เดียวกันทุก project ในองค์กร
def call(Map config) {
    pipeline {
        agent any

        stages {
            stage('Checkout') {
                steps { checkout scm }
            }

            stage('Build') {
                agent { docker config.buildImage ?: 'node:20' }
                steps {
                    sh config.buildCommand ?: 'npm ci && npm run build'
                }
            }

            stage('Test') {
                agent { docker config.buildImage ?: 'node:20' }
                steps {
                    sh config.testCommand ?: 'npm test'
                }
            }

            stage('Docker Build & Push') {
                steps {
                    script {
                        buildDocker(
                            image: config.appName,
                            registry: config.registry ?: 'registry.company.com'
                        )
                    }
                }
            }

            stage('Deploy') {
                when { branch 'main' }
                steps {
                    script {
                        deployToServer(
                            server: config.deployServer,
                            app: config.appName
                        )
                    }
                }
            }
        }

        post {
            always { notifySlack(currentBuild.result ?: 'SUCCESS') }
        }
    }
}
```

```groovy
// Jenkinsfile ของแต่ละ project → สั้นมาก!
@Library('my-shared-library') _

standardPipeline(
    appName: 'user-service',
    buildImage: 'node:20',
    buildCommand: 'npm ci && npm run build',
    testCommand: 'npm test',
    deployServer: 'prod-server-01'
)
```

---

## 11. Jenkins Plugins ที่ควรรู้

### Essential Plugins

| Plugin | หน้าที่ | ใช้เมื่อไหร่ |
|--------|--------|-------------|
| **Pipeline** | เขียน Pipeline as Code | ทุก project |
| **Git** | เชื่อมต่อ Git repository | ทุก project |
| **Credentials Binding** | จัดการ secrets อย่างปลอดภัย | ทุก project |
| **Timestamper** | แสดง timestamp ใน build log | ทุก project |
| **Workspace Cleanup** | ล้าง workspace หลัง build | ทุก project |

### Build & Test

| Plugin | หน้าที่ |
|--------|--------|
| **Docker Pipeline** | Build, run Docker ใน pipeline |
| **NodeJS** | จัดการ Node.js versions |
| **JUnit** | แสดง test results |
| **Cobertura/JaCoCo** | แสดง code coverage |
| **HTML Publisher** | แสดง HTML reports |
| **Warnings Next Gen** | แสดง lint warnings |

### Deploy & Infrastructure

| Plugin | หน้าที่ |
|--------|--------|
| **SSH Agent** | ใช้ SSH key สำหรับ remote operations |
| **Publish Over SSH** | Deploy files ผ่าน SSH |
| **Kubernetes** | รัน agents บน K8s pods |
| **AWS Steps** | ใช้ AWS services |
| **Terraform** | รัน Terraform commands |
| **Ansible** | รัน Ansible playbooks |

### Notification & Integration

| Plugin | หน้าที่ |
|--------|--------|
| **Slack Notification** | ส่ง notification ไป Slack |
| **Email Extension** | ส่ง email notification |
| **GitHub Integration** | Webhook + status checks |
| **Bitbucket** | Bitbucket integration |
| **JIRA** | อัพเดท JIRA tickets |

### UI & Management

| Plugin | หน้าที่ |
|--------|--------|
| **Blue Ocean** | Modern UI สำหรับ pipeline |
| **Role-based Authorization** | จัดการ permissions |
| **Job DSL** | สร้าง jobs แบบ programmatic |
| **Configuration as Code (JCasC)** | Jenkins config เป็น YAML |

---

## 12. Security & Best Practices

### Credentials Management

```groovy
// ❌ อย่าทำ - hardcode secrets
environment {
    DB_PASS = 'my-secret-password'
    API_KEY = 'sk-1234567890'
}

// ✅ ใช้ Jenkins Credentials
environment {
    DB_PASS = credentials('db-password')
    API_KEY = credentials('api-key')
}

// ✅ หรือใช้ withCredentials block
steps {
    withCredentials([string(credentialsId: 'api-key', variable: 'API_KEY')]) {
        sh 'curl -H "Authorization: Bearer $API_KEY" https://api.example.com'
    }
}
```

### Pipeline Best Practices

```groovy
pipeline {
    agent any

    options {
        // 1. กำหนด timeout ป้องกัน pipeline ค้าง
        timeout(time: 30, unit: 'MINUTES')

        // 2. ไม่ให้รันพร้อมกัน (ป้องกัน race condition ตอน deploy)
        disableConcurrentBuilds()

        // 3. เก็บ build history ไม่ให้เยอะเกินไป
        buildDiscarder(logRotator(numToKeepStr: '10'))

        // 4. แสดง timestamp ใน log
        timestamps()

        // 5. Retry ถ้า checkout ล้มเหลว (network issue)
        retry(2)
    }

    stages {
        // 6. แยก stage ชัดเจน
        stage('Build') { steps { sh 'npm run build' } }
        stage('Test')  { steps { sh 'npm test' } }

        // 7. ใช้ when สำหรับ conditional stages
        stage('Deploy') {
            when { branch 'main' }
            steps { sh 'deploy.sh' }
        }
    }

    post {
        // 8. ล้าง workspace ทุกครั้ง
        always { cleanWs() }

        // 9. Notify เมื่อ fail
        failure { /* send notification */ }
    }
}
```

### Jenkins Configuration as Code (JCasC)

```yaml
# jenkins.yaml - ตั้งค่า Jenkins ทั้งหมดเป็น YAML
jenkins:
  systemMessage: "Jenkins - Production"
  numExecutors: 0  # ไม่ให้ master build

  securityRealm:
    ldap:
      configurations:
        - server: "ldap.company.com"

  authorizationStrategy:
    roleBased:
      roles:
        global:
          - name: "admin"
            permissions: ["Overall/Administer"]
          - name: "developer"
            permissions: ["Job/Build", "Job/Read"]

  nodes:
    - permanent:
        name: "build-agent-01"
        remoteFS: "/var/jenkins"
        launcher:
          ssh:
            host: "agent-01.company.com"
            credentialsId: "agent-ssh-key"

credentials:
  system:
    domainCredentials:
      - credentials:
          - usernamePassword:
              id: "docker-creds"
              username: "deploy-user"
              password: "${DOCKER_PASSWORD}"
```

### Backup Strategy

```bash
# สิ่งที่ต้อง backup:
# 1. JENKINS_HOME directory (ทุกอย่างอยู่ที่นี่)
#    - jobs/          → job configs & build history
#    - plugins/       → installed plugins
#    - credentials.xml → credentials (encrypted)
#    - config.xml     → global config

# Docker volume backup
docker run --rm \
  -v jenkins_home:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/jenkins-backup-$(date +%Y%m%d).tar.gz /data

# Restore
docker run --rm \
  -v jenkins_home:/data \
  -v $(pwd):/backup \
  alpine sh -c "cd /data && tar xzf /backup/jenkins-backup-20240101.tar.gz --strip 1"
```

---

## 13. สรุป

### Jenkins ในภาพรวม

```
┌──────────────────────────────────────────────────────────────┐
│                     Jenkins = CI/CD Server                   │
│                                                              │
│  Input:                                                      │
│    Git push / Webhook / Cron / Manual trigger                │
│                                                              │
│  Process:                                                    │
│    Jenkinsfile → Stages → Steps                              │
│    Build → Test → Package → Deploy → Verify → Notify         │
│                                                              │
│  Output:                                                     │
│    Artifacts, Docker images, Deployed application             │
│    Test reports, Notifications                                │
│                                                              │
│  จุดเด่น:                                                    │
│    ✅ Self-hosted → ควบคุมเต็มที่                              │
│    ✅ ไม่จำกัด build minutes                                   │
│    ✅ Plugin ecosystem ใหญ่ที่สุด                              │
│    ✅ Pipeline ซับซ้อนได้ (Groovy)                             │
│    ✅ Shared Libraries → มาตรฐานทั้งองค์กร                    │
│    ✅ Security & Compliance ready                             │
│                                                              │
│  ข้อควรระวัง:                                                 │
│    ⚠️ ต้องดูแล server เอง                                     │
│    ⚠️ Setup ซับซ้อนกว่า cloud CI/CD                            │
│    ⚠️ ต้องเรียน Groovy DSL                                    │
└──────────────────────────────────────────────────────────────┘
```

### เปรียบเทียบ 3 บรรทัด

```
Jenkins:             "ฉันคุม server เอง ทำอะไรก็ได้ ไม่จำกัด"
GitHub Actions:      "ฉันง่ายและเร็ว แค่ push YAML ก็ใช้ได้"
Bitbucket Pipelines: "ฉันทำงานกับ Jira ได้ดีที่สุด"
```

### Quick Start Checklist

```
□ ติดตั้ง Jenkins (Docker recommended)
□ ตั้งค่า admin user
□ ติดตั้ง plugins (Pipeline, Git, Docker, SSH Agent, Credentials)
□ เพิ่ม Credentials (SSH keys, Docker registry, AWS)
□ สร้าง Jenkinsfile ใน repo
□ สร้าง Multibranch Pipeline job
□ ตั้ง webhook จาก Git provider
□ ทดสอบ push code → pipeline รันอัตโนมัติ
□ เพิ่ม notification (Slack/Email)
□ ตั้ง backup schedule
```
