# Baby SSH Tunnel - Automatic Setup Script

![Version](https://img.shields.io/badge/version-1.0-blue)
![License](https://img.shields.io/badge/license-MIT-green)

Created by **babydev** | Telegram: [@babydevpro](https://t.me/babydevpro)

## 📖 Description

Baby SSH Tunnel is an automated script for setting up and managing SSH tunnels between Iran and Kharej (foreign) servers. It supports both **Direct Tunnels** and **Reverse Tunnels** using AutoSSH for reliability and automatic reconnection.

## ✨ Features

- 🚀 **Fully Automated Setup** - No manual configuration needed
- 🔄 **AutoSSH Integration** - Automatic reconnection on connection loss
- 🔒 **Passwordless SSH** - Uses SSH keys for secure authentication
- 🛡️ **Automatic Firewall Configuration** - Opens required ports automatically
- 📊 **System Management** - Easy monitoring and control of tunnels
- 🔧 **Both Tunnel Types**:
  - Direct Tunnel (Iran → Kharej)
  - Reverse Tunnel (Kharej → Iran)
- ⚙️ **Systemd Services** - Tunnels run as system services with auto-start
- 📝 **Live Logs** - Real-time monitoring of tunnel status
- 🔄 **Cron Auto-Restart** - Ensures tunnel stability

## 🖥️ Supported Operating Systems

- Ubuntu 18.04+
- Debian 9+
- CentOS 7+
- RHEL 7+
- Rocky Linux 8+
- AlmaLinux 8+

## 📋 Requirements

- Root access on both servers
- SSH access between servers
- Ports that you want to forward (will be configured automatically)

## 🚀 Installation

### Quick Install

```bash
wget https://github.com/babydevpro/baby-ssh-tunnle/releases/download/beta/baby-tunnel.sh
chmod +x baby-tunnel.sh
./baby-tunnel.sh
