# Bash Scripting Practice - Docker

Ubuntu 20.04 environment with all necessary tools for Bash scripting practice.

## Requirements

- Docker
- Docker Compose

## Quick Start

### 1. Build the image

```bash
cd docker
docker-compose build
```

### 2. Start the container

```bash
docker-compose up -d
```

### 3. Access the container

```bash
docker-compose exec bash-practice bash
```

Or using docker directly:

```bash
docker exec -it bash-scripting-ubuntu bash
```

### 4. Work on your scripts

Inside the container you'll be in `/workspace/` where you'll see all your folders:

```bash
ls -la
# You'll see: exercise1/ exercise2/ exercise3/ exercise4/ docker/ etc.

cd exercise+
./the_script.sh
```
## Structure

```
exercises/
├── docker/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── README.md
├── exercise1/
├── exercise2/
├── exercise3/
├── exercise4/
└── .env_example
```

## Included Tools

- Bash, Git, Curl, Wget
- Cron (for scheduled tasks)
- Nginx and Apache2
- Vim, Nano
- Systemctl
- Mailutils
- Sysstat (for monitoring)
- Tar, Gzip
