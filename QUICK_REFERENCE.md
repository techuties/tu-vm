# TechUties VM - Quick Reference

## 🚀 Essential Commands

### Start Everything
```bash
./tu-vm.sh start
```

### Enable Secure Access
```bash
sudo ./tu-vm.sh secure
```

### Check Status
```bash
./tu-vm.sh status
```

## 🔒 Security Levels

| Command | Security | Use Case |
|---------|----------|----------|
| `sudo ./tu-vm.sh secure` | 🔒 Secure | Daily usage |
| `sudo ./tu-vm.sh public` | 🔓 Internet | Testing |
| `sudo ./tu-vm.sh lock` | 🚫 None | Maintenance |

## 📋 All Commands

### Basic
- `./tu-vm.sh start` - Start services
- `./tu-vm.sh stop` - Stop services
- `./tu-vm.sh restart` - Restart services
- `./tu-vm.sh status` - Show status

### Security
- `sudo ./tu-vm.sh secure` - Secure access
- `sudo ./tu-vm.sh public` - Public access
- `sudo ./tu-vm.sh lock` - Block all access

### Maintenance
- `sudo ./tu-vm.sh update` - Update system
- `./tu-vm.sh backup` - Create backup
- `sudo ./tu-vm.sh restore file.tar.gz` - Restore backup

## 🔧 Access Setup

1. `sudo ./tu-vm.sh secure`
2. Access at `https://10.211.55.12`

## 🌐 Access URLs

- **Landing**: `https://10.211.55.12`
- **Open WebUI**: `https://10.211.55.12` (oweb.tu.local)
- **n8n**: `https://10.211.55.12` (n8n.tu.local)
- **Pi-hole**: `https://10.211.55.12` (pihole.tu.local)

## 🚨 Troubleshooting

### Services not working?
```bash
./tu-vm.sh status
./tu-vm.sh restart
```

### Can't access services?
```bash
sudo ./tu-vm.sh secure
./tu-vm.sh status
```

### Need to update?
```bash
sudo ./tu-vm.sh update
```

### Something broken?
```bash
./tu-vm.sh backup
./tu-vm.sh restart
```

## 🌐 Pi-hole DNS

### How It Works
```
Host Machine
    ↓ DNS queries to VM
VM Pi-hole (10.211.55.12)
    ↓ Ad-blocking & filtering
Internet
```

### Benefits
- **Ad-blocking** for all DNS queries
- **DNS privacy** - all queries filtered through Pi-hole
- **Fast resolution** - local DNS server with caching
- **No DNS leaks** - all traffic goes through your private Pi-hole

## 🎯 Security Objective

**"Secure access control with easy management"** ✅

- Secure access by default
- Easy on/off switching
- Maximum security with flexibility
