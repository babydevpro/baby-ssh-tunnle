#!/bin/bash

# ==========================================
# Baby SSH Tunnel - Auto Setup Script
# Creator: babydev
# Telegram: @babydevpro
# ==========================================

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Banner
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << "EOF"
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║   ____        _             ____ ____  _   _                 ║
║  | __ )  __ _| |__  _   _  / ___/ ___|| | | |                ║
║  |  _ \ / _` | '_ \| | | | \___ \___ \| |_| |                ║
║  | |_) | (_| | |_) | |_| |  ___) |__) |  _  |                ║
║  |____/ \__,_|_.__/ \__, | |____/____/|_| |_|                ║
║                     |___/                                    ║
║                                                              ║
║              _____                       _                   ║
║             |_   _|   _ _ __  _ __   ___| |                  ║
║               | || | | | '_ \| '_ \ / __| |                  ║
║               | || |_| | | | | | | |  __| |                  ║
║               |_| \__,_|_| |_|_| |_|\___|_|                  ║
║                                                              ║
╠══════════════════════════════════════════════════════════════╣
║  Creator: babydev                                            ║
║  Telegram: @babydevpro                                       ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}Error: This script must be run as root${NC}"
        exit 1
    fi
}

# Detect OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
        VERSION=$VERSION_ID
    else
        echo -e "${RED}Cannot detect OS${NC}"
        exit 1
    fi
}

# Install required packages
install_requirements() {
    echo -e "${YELLOW}Installing required packages...${NC}"
    
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        apt update
        apt install -y autossh openssh-server ufw lsof cron
    elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "rocky" ]] || [[ "$OS" == "almalinux" ]]; then
        yum install -y epel-release
        yum install -y autossh openssh-server firewalld lsof cronie
        systemctl enable --now crond
    else
        echo -e "${RED}Unsupported OS${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Requirements installed successfully${NC}"
}

# Configure firewall
configure_firewall() {
    local port=$1
    echo -e "${YELLOW}Configuring firewall for port $port...${NC}"
    
    if command -v ufw &> /dev/null; then
        ufw allow $port/tcp
        echo -e "${GREEN}UFW: Port $port allowed${NC}"
    elif command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=$port/tcp
        firewall-cmd --reload
        echo -e "${GREEN}Firewalld: Port $port allowed${NC}"
    else
        echo -e "${YELLOW}No firewall detected, skipping...${NC}"
    fi
}

# Enable GatewayPorts
enable_gateway_ports() {
    echo -e "${YELLOW}Enabling GatewayPorts in SSH config...${NC}"
    
    if grep -q "^GatewayPorts" /etc/ssh/sshd_config; then
        sed -i 's/^GatewayPorts.*/GatewayPorts yes/' /etc/ssh/sshd_config
    else
        echo "GatewayPorts yes" >> /etc/ssh/sshd_config
    fi
    
    # Restart SSH service
    if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
        systemctl restart sshd.service || systemctl restart ssh.service
    else
        systemctl restart sshd
    fi
    
    echo -e "${GREEN}GatewayPorts enabled and SSH restarted${NC}"
}

# Generate SSH key
generate_ssh_key() {
    echo -e "${YELLOW}Generating SSH key...${NC}"
    
    if [ -f ~/.ssh/id_rsa ]; then
        echo -e "${CYAN}SSH key already exists. Do you want to regenerate? (yes/no)${NC}"
        read -r regenerate
        if [[ "$regenerate" == "yes" ]]; then
            rm -f ~/.ssh/id_rsa ~/.ssh/id_rsa.pub
            ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
            echo -e "${GREEN}New SSH key generated${NC}"
        fi
    else
        ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
        echo -e "${GREEN}SSH key generated${NC}"
    fi
}

# Copy SSH key to remote server
copy_ssh_key() {
    local remote_ip=$1
    local remote_port=$2
    
    echo -e "${YELLOW}Copying SSH key to remote server...${NC}"
    echo -e "${CYAN}You will need to enter the remote server password${NC}"
    
    ssh-copy-id -p $remote_port root@$remote_ip
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SSH key copied successfully${NC}"
        return 0
    else
        echo -e "${RED}Failed to copy SSH key${NC}"
        return 1
    fi
}

# Test SSH connection
test_ssh_connection() {
    local remote_ip=$1
    local remote_port=$2
    
    echo -e "${YELLOW}Testing SSH connection...${NC}"
    
    ssh -p $remote_port -o BatchMode=yes -o ConnectTimeout=5 root@$remote_ip exit
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}SSH connection successful (passwordless)${NC}"
        return 0
    else
        echo -e "${RED}SSH connection failed${NC}"
        return 1
    fi
}

# Setup Direct Tunnel (Iran to Kharej)
setup_direct_tunnel() {
    show_banner
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}   Direct Tunnel Setup (Iran->Kharej)  ${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    # Get remote server info
    echo -e "${YELLOW}Enter Kharej server IP:${NC}"
    read -r kharej_ip
    
    echo -e "${YELLOW}Enter Kharej SSH port [default: 22]:${NC}"
    read -r kharej_port
    kharej_port=${kharej_port:-22}
    
    # Get ports to forward
    echo -e "${YELLOW}How many ports do you want to forward?${NC}"
    read -r port_count
    
    declare -a local_ports
    declare -a remote_ports
    
    for ((i=1; i<=port_count; i++)); do
        echo -e "${YELLOW}Port $i - Enter local port (on Iran server):${NC}"
        read -r local_port
        local_ports+=($local_port)
        
        echo -e "${YELLOW}Port $i - Enter remote port (on Kharej server) [default: same as local]:${NC}"
        read -r remote_port
        remote_port=${remote_port:-$local_port}
        remote_ports+=($remote_port)
        
        # Configure firewall
        configure_firewall $local_port
    done
    
    # Install requirements
    install_requirements
    
    # Generate and copy SSH key
    generate_ssh_key
    copy_ssh_key $kharej_ip $kharej_port
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to setup SSH key. Exiting...${NC}"
        return 1
    fi
    
    # Test connection
    test_ssh_connection $kharej_ip $kharej_port
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}SSH connection test failed. Please check and try again.${NC}"
        return 1
    fi
    
    # Create systemd service
    echo -e "${YELLOW}Creating systemd service...${NC}"
    
    cat > /etc/systemd/system/baby-tunnel-direct.service << EOF
[Unit]
Description=Baby SSH Direct Tunnel (Iran -> Kharej)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Environment="AUTOSSH_GATETIME=0"
ExecStart=/usr/bin/autossh -M 0 -N -o "ServerAliveInterval=60" -o "ServerAliveCountMax=3" -o "ExitOnForwardFailure=yes" -p $kharej_port \\
EOF
    
    # Add port forwards
    for ((i=0; i<${#local_ports[@]}; i++)); do
        echo "  -L 0.0.0.0:${local_ports[$i]}:localhost:${remote_ports[$i]} \\" >> /etc/systemd/system/baby-tunnel-direct.service
    done
    
    echo "  root@$kharej_ip" >> /etc/systemd/system/baby-tunnel-direct.service
    
    cat >> /etc/systemd/system/baby-tunnel-direct.service << EOF
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start service
    systemctl daemon-reload
    systemctl enable baby-tunnel-direct.service
    systemctl start baby-tunnel-direct.service
    
    echo -e "${GREEN}Direct tunnel setup completed!${NC}\n"
    echo -e "${CYAN}Service name: baby-tunnel-direct.service${NC}"
    echo -e "${CYAN}Check status: systemctl status baby-tunnel-direct${NC}"
    echo -e "${CYAN}View logs: journalctl -u baby-tunnel-direct -f${NC}"
    echo -e "${CYAN}Restart: systemctl restart baby-tunnel-direct${NC}\n"
    
    # Show status
    sleep 2
    systemctl status baby-tunnel-direct --no-pager
    
    echo -e "\n${YELLOW}Press any key to continue...${NC}"
    read -n 1
}

# Setup Reverse Tunnel (Kharej to Iran) using AutoSSH
setup_reverse_tunnel() {
    show_banner
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}   Reverse Tunnel Setup (Kharej->Iran) ${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    # Get remote server info
    echo -e "${YELLOW}Enter Iran server IP:${NC}"
    read -r iran_ip
    
    echo -e "${YELLOW}Enter Iran SSH port [default: 22]:${NC}"
    read -r iran_port
    iran_port=${iran_port:-22}
    
    # Enable GatewayPorts on Iran server (remote)
    echo -e "${YELLOW}Do you want to enable GatewayPorts on Iran server now? (yes/no)${NC}"
    echo -e "${CYAN}Note: You need SSH access to Iran server for this${NC}"
    read -r enable_gw
    
    if [[ "$enable_gw" == "yes" ]]; then
        ssh -p $iran_port root@$iran_ip "grep -q '^GatewayPorts' /etc/ssh/sshd_config && sed -i 's/^GatewayPorts.*/GatewayPorts yes/' /etc/ssh/sshd_config || echo 'GatewayPorts yes' >> /etc/ssh/sshd_config; systemctl restart sshd"
        echo -e "${GREEN}GatewayPorts enabled on Iran server${NC}"
    fi
    
    # Get ports to forward
    echo -e "${YELLOW}How many ports do you want to forward?${NC}"
    read -r port_count
    
    declare -a ports
    
    for ((i=1; i<=port_count; i++)); do
        echo -e "${YELLOW}Enter port $i to forward:${NC}"
        read -r port
        ports+=($port)
        
        # Configure firewall on local server
        configure_firewall $port
    done
    
    # Install requirements
    install_requirements
    
    # Generate and copy SSH key
    generate_ssh_key
    copy_ssh_key $iran_ip $iran_port
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Failed to setup SSH key. Exiting...${NC}"
        return 1
    fi
    
    # Test connection
    test_ssh_connection $iran_ip $iran_port
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}SSH connection test failed. Please check and try again.${NC}"
        return 1
    fi
    
    # Create systemd service for reverse tunnel using autossh
    echo -e "${YELLOW}Creating systemd service for reverse tunnel...${NC}"
    
    cat > /etc/systemd/system/baby-tunnel-reverse.service << EOF
[Unit]
Description=Baby SSH Reverse Tunnel (Kharej -> Iran)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
Environment="AUTOSSH_GATETIME=0"
ExecStart=/usr/bin/autossh -M 0 -N -o "ServerAliveInterval=60" -o "ServerAliveCountMax=3" -o "ExitOnForwardFailure=yes" -p $iran_port \\
EOF
    
    # Add reverse port forwards
    for port in "${ports[@]}"; do
        echo "  -R 0.0.0.0:$port:localhost:$port \\" >> /etc/systemd/system/baby-tunnel-reverse.service
    done
    
    echo "  root@$iran_ip" >> /etc/systemd/system/baby-tunnel-reverse.service
    
    cat >> /etc/systemd/system/baby-tunnel-reverse.service << EOF
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable and start service
    systemctl daemon-reload
    systemctl enable baby-tunnel-reverse.service
    systemctl start baby-tunnel-reverse.service
    
    # Setup cron job for auto-restart
    echo -e "${YELLOW}Setting up cron job for tunnel stability...${NC}"
    
    # Remove old cron jobs for this service
    crontab -l 2>/dev/null | grep -v "baby-tunnel-reverse" | crontab -
    
    # Add new cron job (restart every hour)
    (crontab -l 2>/dev/null; echo "0 */1 * * * systemctl restart baby-tunnel-reverse.service") | crontab -
    
    echo -e "${GREEN}Reverse tunnel setup completed!${NC}\n"
    echo -e "${CYAN}Service name: baby-tunnel-reverse.service${NC}"
    echo -e "${CYAN}Check status: systemctl status baby-tunnel-reverse${NC}"
    echo -e "${CYAN}View logs: journalctl -u baby-tunnel-reverse -f${NC}"
    echo -e "${CYAN}Restart: systemctl restart baby-tunnel-reverse${NC}"
    echo -e "${CYAN}Cron job: Automatic restart every hour${NC}\n"
    
    # Show status
    sleep 2
    systemctl status baby-tunnel-reverse --no-pager
    
    echo -e "\n${YELLOW}Press any key to continue...${NC}"
    read -n 1
}

# Manage Direct Tunnel
manage_direct_tunnel() {
    while true; do
        show_banner
        echo -e "${CYAN}========================================${NC}"
        echo -e "${CYAN}     Manage Direct Tunnel              ${NC}"
        echo -e "${CYAN}========================================${NC}\n"
        
        echo -e "${GREEN}1)${NC} View Tunnel Status"
        echo -e "${GREEN}2)${NC} View Tunnel Logs (Live)"
        echo -e "${GREEN}3)${NC} Restart Tunnel"
        echo -e "${GREEN}4)${NC} Stop Tunnel"
        echo -e "${GREEN}5)${NC} Start Tunnel"
        echo -e "${GREEN}6)${NC} Remove Tunnel"
        echo -e "${GREEN}7)${NC} Edit Tunnel Configuration"
        echo -e "${GREEN}0)${NC} Back to Main Menu"
        echo ""
        echo -e "${YELLOW}Enter your choice:${NC}"
        read -r choice
        
        case $choice in
            1)
                systemctl status baby-tunnel-direct --no-pager
                echo -e "\n${YELLOW}Press any key to continue...${NC}"
                read -n 1
                ;;
            2)
                echo -e "${CYAN}Press Ctrl+C to exit logs${NC}"
                sleep 2
                journalctl -u baby-tunnel-direct -f
                ;;
            3)
                systemctl restart baby-tunnel-direct
                echo -e "${GREEN}Tunnel restarted${NC}"
                sleep 2
                ;;
            4)
                systemctl stop baby-tunnel-direct
                echo -e "${YELLOW}Tunnel stopped${NC}"
                sleep 2
                ;;
            5)
                systemctl start baby-tunnel-direct
                echo -e "${GREEN}Tunnel started${NC}"
                sleep 2
                ;;
            6)
                echo -e "${RED}Are you sure you want to remove the tunnel? (yes/no)${NC}"
                read -r confirm
                if [[ "$confirm" == "yes" ]]; then
                    systemctl stop baby-tunnel-direct
                    systemctl disable baby-tunnel-direct
                    rm -f /etc/systemd/system/baby-tunnel-direct.service
                    systemctl daemon-reload
                    echo -e "${GREEN}Tunnel removed${NC}"
                fi
                sleep 2
                ;;
            7)
                nano /etc/systemd/system/baby-tunnel-direct.service
                systemctl daemon-reload
                echo -e "${YELLOW}Configuration updated. Restart tunnel to apply changes.${NC}"
                sleep 2
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

# Manage Reverse Tunnel
manage_reverse_tunnel() {
    while true; do
        show_banner
        echo -e "${CYAN}========================================${NC}"
        echo -e "${CYAN}     Manage Reverse Tunnel             ${NC}"
        echo -e "${CYAN}========================================${NC}\n"
        
        echo -e "${GREEN}1)${NC} View Tunnel Status"
        echo -e "${GREEN}2)${NC} View Tunnel Logs (Live)"
        echo -e "${GREEN}3)${NC} Restart Tunnel"
        echo -e "${GREEN}4)${NC} Stop Tunnel"
        echo -e "${GREEN}5)${NC} Start Tunnel"
        echo -e "${GREEN}6)${NC} Remove Tunnel"
        echo -e "${GREEN}7)${NC} Edit Tunnel Configuration"
        echo -e "${GREEN}8)${NC} View/Edit Cron Jobs"
        echo -e "${GREEN}0)${NC} Back to Main Menu"
        echo ""
        echo -e "${YELLOW}Enter your choice:${NC}"
        read -r choice
        
        case $choice in
            1)
                systemctl status baby-tunnel-reverse --no-pager
                echo -e "\n${YELLOW}Press any key to continue...${NC}"
                read -n 1
                ;;
            2)
                echo -e "${CYAN}Press Ctrl+C to exit logs${NC}"
                sleep 2
                journalctl -u baby-tunnel-reverse -f
                ;;
            3)
                systemctl restart baby-tunnel-reverse
                echo -e "${GREEN}Tunnel restarted${NC}"
                sleep 2
                ;;
            4)
                systemctl stop baby-tunnel-reverse
                echo -e "${YELLOW}Tunnel stopped${NC}"
                sleep 2
                ;;
            5)
                systemctl start baby-tunnel-reverse
                echo -e "${GREEN}Tunnel started${NC}"
                sleep 2
                ;;
            6)
                echo -e "${RED}Are you sure you want to remove the tunnel? (yes/no)${NC}"
                read -r confirm
                if [[ "$confirm" == "yes" ]]; then
                    systemctl stop baby-tunnel-reverse
                    systemctl disable baby-tunnel-reverse
                    rm -f /etc/systemd/system/baby-tunnel-reverse.service
                    crontab -l 2>/dev/null | grep -v "baby-tunnel-reverse" | crontab -
                    systemctl daemon-reload
                    echo -e "${GREEN}Tunnel removed${NC}"
                fi
                sleep 2
                ;;
            7)
                nano /etc/systemd/system/baby-tunnel-reverse.service
                systemctl daemon-reload
                echo -e "${YELLOW}Configuration updated. Restart tunnel to apply changes.${NC}"
                sleep 2
                ;;
            8)
                crontab -e
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

# View listening ports
view_listening_ports() {
    show_banner
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}        Listening Ports                 ${NC}"
    echo -e "${CYAN}========================================${NC}\n"
    
    lsof -i -P -n | grep LISTEN
    
    echo -e "\n${YELLOW}Press any key to continue...${NC}"
    read -n 1
}

# System tools menu
system_tools_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}========================================${NC}"
        echo -e "${CYAN}          System Tools                 ${NC}"
        echo -e "${CYAN}========================================${NC}\n"
        
        echo -e "${GREEN}1)${NC} View Listening Ports"
        echo -e "${GREEN}2)${NC} Enable GatewayPorts"
        echo -e "${GREEN}3)${NC} Test SSH Connection"
        echo -e "${GREEN}4)${NC} Generate New SSH Key"
        echo -e "${GREEN}5)${NC} View All Tunnels Status"
        echo -e "${GREEN}6)${NC} Firewall Management"
        echo -e "${GREEN}0)${NC} Back to Main Menu"
        echo ""
        echo -e "${YELLOW}Enter your choice:${NC}"
        read -r choice
        
        case $choice in
            1)
                view_listening_ports
                ;;
            2)
                enable_gateway_ports
                echo -e "\n${YELLOW}Press any key to continue...${NC}"
                read -n 1
                ;;
            3)
                echo -e "${YELLOW}Enter remote IP:${NC}"
                read -r remote_ip
                echo -e "${YELLOW}Enter SSH port [default: 22]:${NC}"
                read -r remote_port
                remote_port=${remote_port:-22}
                test_ssh_connection $remote_ip $remote_port
                echo -e "\n${YELLOW}Press any key to continue...${NC}"
                read -n 1
                ;;
            4)
                generate_ssh_key
                echo -e "\n${YELLOW}Press any key to continue...${NC}"
                read -n 1
                ;;
            5)
                echo -e "${CYAN}Direct Tunnel:${NC}"
                systemctl status baby-tunnel-direct --no-pager 2>/dev/null || echo "Not configured"
                echo ""
                echo -e "${CYAN}Reverse Tunnel:${NC}"
                systemctl status baby-tunnel-reverse --no-pager 2>/dev/null || echo "Not configured"
                echo -e "\n${YELLOW}Press any key to continue...${NC}"
                read -n 1
                ;;
            6)
                firewall_menu
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

# Firewall management menu
firewall_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}========================================${NC}"
        echo -e "${CYAN}       Firewall Management              ${NC}"
        echo -e "${CYAN}========================================${NC}\n"
        
        echo -e "${GREEN}1)${NC} Add Port to Firewall"
        echo -e "${GREEN}2)${NC} Remove Port from Firewall"
        echo -e "${GREEN}3)${NC} View Firewall Status"
        echo -e "${GREEN}4)${NC} Enable Firewall"
        echo -e "${GREEN}5)${NC} Disable Firewall"
        echo -e "${GREEN}0)${NC} Back"
        echo ""
        echo -e "${YELLOW}Enter your choice:${NC}"
        read -r choice
        
        case $choice in
            1)
                echo -e "${YELLOW}Enter port number to allow:${NC}"
                read -r port
                configure_firewall $port
                echo -e "\n${YELLOW}Press any key to continue...${NC}"
                read -n 1
                ;;
            2)
                echo -e "${YELLOW}Enter port number to remove:${NC}"
                read -r port
                if command -v ufw &> /dev/null; then
                    ufw delete allow $port/tcp
                elif command -v firewall-cmd &> /dev/null; then
                    firewall-cmd --permanent --remove-port=$port/tcp
                    firewall-cmd --reload
                fi
                echo -e "${GREEN}Port $port removed from firewall${NC}"
                echo -e "\n${YELLOW}Press any key to continue...${NC}"
                read -n 1
                ;;
            3)
                if command -v ufw &> /dev/null; then
                    ufw status verbose
                elif command -v firewall-cmd &> /dev/null; then
                    firewall-cmd --list-all
                fi
                echo -e "\n${YELLOW}Press any key to continue...${NC}"
                read -n 1
                ;;
            4)
                if command -v ufw &> /dev/null; then
                    ufw --force enable
                elif command -v firewall-cmd &> /dev/null; then
                    systemctl enable --now firewalld
                fi
                echo -e "${GREEN}Firewall enabled${NC}"
                sleep 2
                ;;
            5)
                echo -e "${RED}Are you sure? This may lock you out! (yes/no)${NC}"
                read -r confirm
                if [[ "$confirm" == "yes" ]]; then
                    if command -v ufw &> /dev/null; then
                        ufw disable
                    elif command -v firewall-cmd &> /dev/null; then
                        systemctl stop firewalld
                        systemctl disable firewalld
                    fi
                    echo -e "${YELLOW}Firewall disabled${NC}"
                fi
                sleep 2
                ;;
            0)
                break
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

# Main menu
main_menu() {
    while true; do
        show_banner
        echo -e "${CYAN}========================================${NC}"
        echo -e "${CYAN}            Main Menu                   ${NC}"
        echo -e "${CYAN}========================================${NC}\n"
        
        echo -e "${GREEN}1)${NC} Setup Direct Tunnel (Iran -> Kharej)"
        echo -e "${GREEN}2)${NC} Setup Reverse Tunnel (Kharej -> Iran)"
        echo -e "${GREEN}3)${NC} Manage Direct Tunnel"
        echo -e "${GREEN}4)${NC} Manage Reverse Tunnel"
        echo -e "${GREEN}5)${NC} System Tools"
        echo -e "${GREEN}6)${NC} About"
        echo -e "${GREEN}0)${NC} Exit"
        echo ""
        echo -e "${YELLOW}Enter your choice:${NC}"
        read -r choice
        
        case $choice in
            1)
                setup_direct_tunnel
                ;;
            2)
                setup_reverse_tunnel
                ;;
            3)
                manage_direct_tunnel
                ;;
            4)
                manage_reverse_tunnel
                ;;
            5)
                system_tools_menu
                ;;
            6)
                show_banner
                echo -e "${CYAN}Baby SSH Tunnel - Automatic Setup Script${NC}"
                echo -e "${CYAN}Version: 1.0${NC}"
                echo -e "${CYAN}Creator: babydev${NC}"
                echo -e "${CYAN}Telegram: @babydevpro${NC}\n"
                echo -e "${GREEN}This script automates the setup of SSH tunnels${NC}"
                echo -e "${GREEN}between Iran and Kharej servers using AutoSSH.${NC}\n"
                echo -e "${YELLOW}Press any key to continue...${NC}"
                read -n 1
                ;;
            0)
                echo -e "${GREEN}Thank you for using Baby SSH Tunnel!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice${NC}"
                sleep 1
                ;;
        esac
    done
}

# Main execution
check_root
detect_os
main_menu
