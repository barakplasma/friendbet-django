# FriendBet - Private Prediction Market Platform

A private prediction market platform for friend groups to create and bet on custom events using a points-based system, focused on prediction accuracy and maintaining betting privacy.

## Overview

FriendBet enables private, admin-controlled prediction markets where:
- Individual bets remain confidential (only admins see all betting data)
- Points-based system (no real money)
- Time-stacked betting with multiple deadline dates
- Bilingual support (Hebrew & English) with proper RTL/LTR handling
- Simple self-hosting on a single VPS

## Tech Stack

- **Backend:** PocketBase (single binary, embedded SQLite, built-in OAuth)
- **Frontend:** Angular 17+ with Material UI and standalone components
- **Database:** SQLite (embedded in PocketBase)
- **Authentication:** OAuth 2.0 (Google, GitHub, Microsoft)
- **Real-time:** PocketBase WebSocket subscriptions

## Project Structure

```
friendbet/
├── frontend/          # Angular application
│   └── angular/       # Angular project
├── backend/           # PocketBase backend
│   ├── pb_data/      # SQLite database and uploads
│   ├── pb_public/    # Static files (Angular dist)
│   └── hooks/        # Custom business logic
├── deploy/           # Deployment scripts and infrastructure
├── CLAUDE.md         # Full PRD with detailed requirements
├── todo.md           # Development task breakdown
└── README.md         # This file
```

## Quick Start

### Prerequisites
- Node.js 18+ and npm
- Angular CLI (`npm install -g @angular/cli`)
- PocketBase (download from https://pocketbase.io/docs/)

### Development Setup

1. **Set up PocketBase backend:**
   ```bash
   cd backend
   wget https://github.com/pocketbase/pocketbase/releases/download/v0.23.5/pocketbase_linux_amd64.zip
   unzip pocketbase_linux_amd64.zip
   ./pocketbase serve
   ```
   - Access admin UI at http://localhost:8090/_/
   - Create admin account
   - Configure OAuth providers

2. **Set up Angular frontend:**
   ```bash
   cd frontend/angular
   npm install
   ng serve
   ```
   - Access app at http://localhost:4200

3. **Build for production:**
   ```bash
   cd frontend/angular
   ng build --configuration production
   cp -r dist/* /path/to/backend/pb_public/
   ```

## Key Features

### MVP Features (P0)
- ✅ Admin-controlled group management
- ✅ Private time-stacked betting system
- ✅ Market creation with multiple deadlines
- ✅ Automated Market Maker (AMM) for odds calculation
- ✅ Market resolution with automatic payouts
- ✅ Leaderboard and personal stats
- ✅ Bilingual UI (Hebrew/English) with RTL/LTR support
- ✅ OAuth authentication
- ✅ Real-time updates

### Privacy Features
- Individual bets hidden from non-admin users
- Only aggregate odds visible to regular users
- Admin-only access to detailed betting data
- No public betting history or positions

### Deployment
- Single VPS deployment (1GB RAM minimum)
- Automated backups
- SSL/HTTPS support
- Systemd service for auto-restart

## Development Status

See `todo.md` for complete task breakdown and implementation status.

### Current Phase: Foundation Setup
- [x] Project structure initialized
- [ ] PocketBase backend setup
- [ ] Angular frontend setup
- [ ] i18n configuration

## Documentation

- **PRD:** See `CLAUDE.md` for complete product requirements
- **Tasks:** See `todo.md` for development task breakdown
- **Deployment:** See `deploy/README.md` for deployment instructions

## License

Private project for friend groups.

## Contributing

This is a private project. See deployment documentation for self-hosting instructions.