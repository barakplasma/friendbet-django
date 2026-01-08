# Product Requirements Document: FriendBet

## Overview
A private prediction market platform for friend groups to create and bet on custom events using a points-based system, focused on prediction accuracy and maintaining betting privacy. Admin-controlled groups ensure curated participation. Designed for simple self-hosting on a VPS with minimal dependencies.

## Problem Statement
Friend groups want to make friendly predictions and bets on personal or world events, but existing platforms like Polymarket are public, use real money, and focus on major news events. Additionally, visible betting can create social pressure and bias. Friends need a casual, private space where individual bets remain confidential, allowing for genuine prediction signals, with admin oversight to maintain group quality. The solution must be simple to deploy and maintain on a single VPS without cloud service dependencies.

## Goals
- Enable private, admin-controlled prediction markets for friend groups
- Maintain bet privacy to ensure unbiased predictions
- Use points (no currency) to keep things casual and legal
- Maximize prediction accuracy through information aggregation
- Support time-stacked betting for more nuanced predictions
- Support Hebrew and English UI with proper RTL/LTR handling
- **Simple self-hosting on a VPS with no cloud dependencies**
- **Easy deployment, backup, and maintenance**

## Target Users
- Friend groups (5-20 people typically)
- Family members wanting friendly competition
- Coworkers making office predictions
- International friend groups (Hebrew/English speakers)
- Any curated social group that enjoys prediction challenges
- **Technically capable admin willing to self-host on a VPS**

## Core Features

### 1. Admin-Controlled Group Management
**User Stories:**
- As an admin, I can create a private group
- As an admin, I can invite users via email address
- As an admin, I can generate one-time use invite codes
- As an admin, I can remove members
- As a user, I can accept an email invitation or use a one-time code to join
- As a user, I can be part of multiple groups simultaneously

**Requirements:**
- **Only admins can create groups**
- Groups are completely private - no cross-group visibility
- Admin controls for all member management
- Multiple admins allowed per group
- Invitation methods:
  - Email invitation: sends link to specific email address (single use)
  - One-time code generation: admin creates code, shares manually, expires after one use
- Users start with a default point balance (e.g., 1000 points) when joining
- Admin dashboard showing all betting activity
- Only admins see admin controls/badges

### 2. Admin-Only Market Creation
**User Stories:**
- As an admin, I can create a yes/no prediction market for any event
- As an admin, I can set multiple resolution dates for time-stacked betting
- As an admin, I can edit market details before betting starts
- As an admin, I can designate a resolver (admin or member)

**Requirements:**
- **Only admins can create markets**
- Market fields: title, description, resolution criteria, multiple deadline dates
- Binary outcomes only (Yes/No) for MVP
- Admin designates themselves or another member as resolver
- **Multiple deadline dates for time-stacked betting**
- Draft and published states
- **UI displays in user's selected language (Hebrew/English)**
- **Market title and description stored in original language, displayed as-is to all users**
- Language indicator badge on markets to show which language content is in

### 3. Time-Stacked Private Betting System
**User Stories:**
- As a user, I can place multiple bets on the same market with different deadline dates
- As a user, if the event resolves before my earliest deadline, I win all stacked bets
- As a user, if the event resolves after a deadline passes, I lose that specific bet
- As a user, I can see current odds for each time period
- As an admin, I can view all bets for oversight purposes

**Example Scenario:**
*Market: "Will Abe propose to Betsy?"*
- Deadlines: 1 week, 1 month, 3 months
- User bets: 100 points on "Yes by 1 week", 200 points on "Yes by 1 month", 300 points on "Yes by 3 months"
- **If resolves Yes after 2 days:** User wins all three bets (600 points worth of winnings)
- **If resolves Yes after 3 weeks:** User loses the 1-week bet, wins the 1-month and 3-month bets
- **If resolves Yes after 2 months:** User loses 1-week and 1-month bets, wins only 3-month bet
- **If resolves No or never happens:** User loses all bets

**Requirements:**
- Admin defines multiple deadline dates when creating market
- Each deadline has its own odds pool (separate AMM for each time period)
- Users can bet on one, some, or all deadlines
- **Bet Privacy:** Individual bet amounts and positions hidden from all non-admin users
- Only aggregate odds visible per deadline to regular users
- Automated Market Maker (AMM) using constant product formula per deadline
- Real-time odds calculation based on current pool state for each deadline
- Display potential payout for each deadline before confirming bet
- Personal transaction history visible only to the user
- Minimum bet amount (e.g., 10 points) per deadline
- Cannot bet more points than current balance across all bets
- Admins have read-only access to all betting data
- **Points displayed without currency symbols** (e.g., "1000" not "$1000" or "₪1000")

### 4. Market Resolution
**User Stories:**
- As a resolver, I can mark a market as Yes, No, or N/A (cancelled)
- As a resolver, I specify the resolution date if Yes
- As a user, I can see my winnings automatically added to my balance
- As an admin, I can review disputed resolutions

**Requirements:**
- Only designated resolver can resolve markets
- For Yes resolution: resolver specifies when the event occurred
- System automatically calculates which deadline bets won/lost based on resolution date
- Resolution triggers automatic payout calculation for all relevant bets
- Option to cancel market (returns all points to bettors across all deadlines)
- 24-hour dispute period where admins can override resolution
- Clear resolution audit trail visible to admins
- Individual winnings/losses remain private to each user

### 5. Leaderboard & Profile
**User Stories:**
- As a user, I can see group leaderboard ranked by total points
- As a user, I can view my betting history and stats
- As a user, I can see other members' total points only (not betting details)

**Requirements:**
- Group leaderboard showing: rank, username, total points (no currency symbols)
- **No public betting history or positions visible**
- User personal stats (private view): total markets bet on, personal win rate, biggest win/loss, points in format "1000"
- Point balance prominently displayed
- No activity feed or social elements
- All numeric displays without currency symbols

### 6. Points Management
**User Stories:**
- As an admin, I can reset everyone's points to starting balance
- As an admin, I can manually adjust individual user points
- As a user, I receive periodic point bonuses to stay active

**Requirements:**
- Weekly/monthly point stipend (e.g., 100 points) to prevent depletion
- Admin controls for point adjustments with logged reasons
- Option to reset entire group's points at season intervals
- Negative balances allowed (can go into "debt")
- All point values displayed without currency symbols

### 7. Hebrew & English UI with RTL/LTR
**User Stories:**
- As a user, I can select Hebrew or English as my interface language
- As a user, I see proper text direction based on my language choice
- As a user, I can create markets in any language (content language independent of UI language)
- As a user, I see market content in its original language regardless of my UI language

**Requirements:**
- **Full UI localization for Hebrew and English** (buttons, labels, navigation, system messages)
- **User-created content (market titles, descriptions) stored and displayed in original language**
- User can switch UI language without affecting market content display
- Full RTL (Right-to-Left) support for Hebrew UI
- Full LTR (Left-to-Right) support for English UI
- Language badge on markets indicating content language (visual indicator)
- Date/time formatting respects user's selected locale
- Number formatting for points (clean, no separators)
- BiDi (Bidirectional) text handling for mixed content
- Language selection in user settings

## Technical Requirements

### Recommended Backend-as-a-Service: **PocketBase**

**Rationale:**
- ✅ **Single binary deployment** - easiest self-hosting (just upload one file)
- ✅ **Built-in SQLite** - no separate database server needed
- ✅ **Built-in OAuth** - Google, GitHub, Microsoft supported out of box
- ✅ **Real-time subscriptions** - WebSocket support for live odds updates
- ✅ **Built-in admin UI** - manage data without custom admin panel
- ✅ **File storage** - for user avatars (local filesystem)
- ✅ **Backup = copy one file** - SQLite database is portable
- ✅ **Custom business logic** - extend with Go or JavaScript hooks
- ✅ **Zero cloud dependencies** - everything runs on your VPS
- ✅ **Automatic REST + Realtime API** - less backend code to write

**Alternative Considered:**
- **Directus**: More complex, requires separate PostgreSQL/MySQL, heavier infrastructure
- **Convex**: Cloud-only service, not self-hostable
- **Supabase**: Can self-host but more complex (PostgreSQL, PostgREST, GoTrue, etc.)

**PocketBase is the clear winner for simple VPS self-hosting.**

### Recommended Frontend Framework: **Angular 17+ (Standalone Components)**

**Rationale:**
- ✅ **Standalone components** - simpler, no NgModules needed (Angular 17+)
- ✅ **Built-in i18n** - excellent internationalization support
- ✅ **Material UI** - mature, comprehensive component library
- ✅ **Strong typing** - TypeScript throughout
- ✅ **Built-in routing** - no additional library needed
- ✅ **Signals (Angular 16+)** - modern reactivity for real-time odds
- ✅ **Build optimization** - good production bundle sizes
- ✅ **RTL support** - Material UI has excellent RTL/BiDi support

**Angular Standalone Components API** eliminates much of Angular's traditional complexity while keeping its strengths.

### Architecture

**Single VPS Deployment:**
```
VPS (Ubuntu/Debian)
├── PocketBase binary (backend + database)
├── Angular dist/ (static files served by PocketBase)
├── pb_data/ (SQLite database + avatars)
└── Nginx (optional reverse proxy)
```

**Tech Stack:**
- **Backend:** PocketBase (Go-based, single binary)
- **Database:** SQLite (embedded in PocketBase)
- **Frontend:** Angular 17+ Standalone Components
- **UI Library:** Angular Material 17+
- **Authentication:** PocketBase OAuth (Google, GitHub, Microsoft)
- **Real-time:** PocketBase WebSocket subscriptions
- **Hosting:** Single VPS (DigitalOcean, Linode, Hetzner, etc.)
- **Web Server:** PocketBase built-in server (or Nginx reverse proxy)

### PocketBase Collections (Database Schema)

**users** (built-in collection, extended):
```
username, email, avatar, preferred_language (he/en), 
oauth2_provider, created, updated
```

**groups:**
```
id, name, admin_ids (relation[users]), default_language, created
```

**group_memberships:**
```
id, user_id (relation[users]), group_id (relation[groups]), 
points_balance (number), joined_at (date)
```

**invite_codes:**
```
id, group_id (relation[groups]), code (text, unique), 
email (email, optional), used (bool), 
created_by (relation[users]), created, used_at (date), 
used_by (relation[users])
```

**markets:**
```
id, group_id (relation[groups]), creator_id (relation[users]), 
resolver_id (relation[users]), title (text), description (text), 
resolution_criteria (text), deadline_dates (json), 
close_date (date), status (select: draft/active/closed/resolved), 
resolution (select: yes/no/cancelled), resolution_date (date),
resolved_at (date), content_language (select: he/en), created
```

**bets:**
```
id, market_id (relation[markets]), user_id (relation[users]), 
deadline_date (date), outcome (select: yes/no), amount (number), 
shares_received (number), created
```

**transactions:**
```
id, user_id (relation[users]), group_id (relation[groups]), 
amount (number), type (select: bet/win/loss/stipend/adjustment), 
related_market_id (relation[markets]), 
related_deadline_date (date), created
```

### PocketBase Custom Business Logic

**Hooks needed (JavaScript or Go extensions):**
1. **AMM calculation** - calculate odds and shares when bet placed
2. **Market resolution** - calculate all payouts when market resolved
3. **Stipend cron job** - periodic point distribution
4. **Bet privacy enforcement** - hide bet details from non-admins
5. **Invite code validation** - one-time use enforcement
6. **Admin permission checks** - verify admin status for protected actions

### Authentication
- **PocketBase OAuth 2.0** (built-in)
- Supported providers: Google, GitHub, Microsoft
- Configured via PocketBase admin UI
- JWT-based session management (handled by PocketBase)
- Automatic account linking by email

### Real-time Updates
- **PocketBase real-time subscriptions** via WebSocket
- Subscribe to market odds changes
- Subscribe to leaderboard updates
- Angular Signals for reactive UI updates

### Deployment & Self-Hosting

**Initial Setup (15 minutes):**
```bash
# 1. Download PocketBase
wget https://github.com/pocketbase/pocketbase/releases/download/v0.x.x/pocketbase_linux_amd64.zip
unzip pocketbase_linux_amd64.zip

# 2. Run PocketBase
./pocketbase serve --http="0.0.0.0:8080"

# 3. Access admin UI
# Open http://your-vps-ip:8080/_/
# Create admin account, configure OAuth providers

# 4. Build Angular app
ng build --configuration production

# 5. Copy dist to PocketBase pb_public
cp -r dist/friendbet/* pb_public/

# 6. Restart PocketBase
./pocketbase serve
```

**Production Setup (with Nginx):**
```nginx
server {
    listen 80;
    server_name friendbet.yourdomain.com;
    
    location / {
        proxy_pass http://localhost:8090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

**Systemd Service:**
```ini
[Unit]
Description=FriendBet PocketBase
After=network.target

[Service]
Type=simple
User=pocketbase
WorkingDirectory=/opt/friendbet
ExecStart=/opt/friendbet/pocketbase serve
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

**Backup Strategy:**
```bash
# Backup entire database (single file)
cp pb_data/data.db backups/data-$(date +%Y%m%d).db

# Or use PocketBase backup command
./pocketbase backup backup.zip

# Automated daily backups
0 2 * * * /opt/friendbet/backup.sh
```

### Security & Privacy
- OAuth-only authentication (via PocketBase)
- Collection-level rules in PocketBase for bet privacy
- Admin-only API rules for viewing bet details
- HTTPS via Let's Encrypt (Certbot)
- Rate limiting via Nginx
- PocketBase audit logging (built-in)
- Environment variables for OAuth secrets

### Internationalization (i18n)

**Angular i18n Implementation:**
```typescript
// Compile-time i18n (Angular native)
// Two separate builds: one for Hebrew, one for English
ng build --configuration production,en
ng build --configuration production,he

// Or runtime i18n (using @angular/localize + custom loader)
// Single build, runtime language switching
```

**Translation Files:**
- `src/locale/messages.en.xlf` (English UI strings)
- `src/locale/messages.he.xlf` (Hebrew UI strings)
- Market content NOT translated (stored as-is)

**Language Switching:**
```typescript
// User preference stored in PocketBase users collection
// On login, load user's preferred_language
// Set Angular LOCALE_ID dynamically
// Apply dir="rtl" or dir="ltr" to <html> tag
```

## UI/UX Requirements

### Key Screens
1. **Group Dashboard:** Active markets with language badges, leaderboard preview, personal point balance
2. **Market Detail:** Description (original language), multiple deadline odds, time-stacked bet placement
3. **Admin: Create Market:** Form with multiple deadline inputs, language selector for content
4. **Admin: Invite Users:** Email invitation form and one-time code generator
5. **Leaderboard:** Rankings showing usernames and total points
6. **Profile:** Personal stats, private betting history, UI language settings
7. **Admin Panel:** Full betting visibility, resolution oversight, point management

### Angular Material Components
- `mat-card` for market cards
- `mat-table` for leaderboards and bet history
- `mat-form-field` for all inputs
- `mat-button`, `mat-raised-button`, `mat-fab`
- `mat-toolbar` for navigation
- `mat-sidenav` for admin panel
- `mat-tabs` for deadline selection in betting
- `mat-chip` for deadline badges and language indicators
- `mat-dialog` for confirmations
- `mat-expansion-panel` for market details
- `mat-select` for language switching
- `mat-badge` for language indicators on markets

### Design Principles
- **Desktop-first:** Optimized for 1920x1080 and 1366x768
- **Material Design 3** guidelines
- Clear odds display per deadline
- Prominent privacy indicators
- Time-stacked betting UI clearly shows multiple deadlines
- Clean, minimal aesthetic - no social elements
- Real-time updates via PocketBase subscriptions
- Responsive down to 768px
- **Full RTL support** - UI mirrors completely for Hebrew
- **Language badge on markets** showing content language
- No currency symbols anywhere

### RTL/LTR Considerations
- Automatic UI direction switching based on selected language
- UI layout mirroring for RTL (navigation, buttons, forms)
- Market content displays in original direction (BiDi handling)
- Material UI's CDK Bidi module
- Test with mixed Hebrew/English content

## Success Metrics

### Primary Metric: Prediction Accuracy
- **Brier Score** per market, per deadline, per group
- **Calibration curves** showing odds vs. outcomes
- Market resolution accuracy rate per deadline
- Individual user Brier scores over time
- Time-prediction accuracy

### Secondary Metric: Engagement (Fun Factor)
- User sentiment/satisfaction surveys
- Voluntary participation rate
- Markets created per admin
- Return usage rate
- Time-stacked betting usage rate

### Self-Hosting Metrics
- Deployment time (target: under 30 minutes)
- Database size over time
- VPS resource usage (RAM, CPU, disk)
- Backup success rate

## Self-Hosting Documentation

### Minimum VPS Requirements
- **RAM:** 1GB (2GB recommended)
- **CPU:** 1 vCPU (2 vCPU recommended)
- **Storage:** 20GB SSD
- **OS:** Ubuntu 22.04 or Debian 11+
- **Cost:** ~$5-10/month (DigitalOcean, Linode, Hetzner)

### Installation Guide (Included)
1. VPS setup and security (SSH keys, firewall)
2. PocketBase installation and configuration
3. OAuth provider setup (Google, GitHub, Microsoft)
4. Angular build and deployment
5. Nginx reverse proxy setup
6. SSL certificate (Let's Encrypt)
7. Automated backups setup
8. Systemd service configuration
9. Monitoring and maintenance

### Backup & Restore
```bash
# Backup (automated daily)
./pocketbase backup backup-$(date +%Y%m%d).zip

# Restore
unzip backup-20260108.zip -d pb_data_restore/
./pocketbase serve --dir=pb_data_restore
```

### Updates
```bash
# Update PocketBase
wget [new version]
./pocketbase update

# Update Angular app
ng build --prod
rsync -av dist/friendbet/ user@vps:/opt/friendbet/pb_public/
```

## Out of Scope (V1)
- Real money transactions
- Multi-outcome markets
- Cross-group markets
- Mobile native apps
- External API for integrations
- Social features (comments, sharing, activity feeds)
- Push notifications
- Public profiles
- Self-service group/market creation
- Languages beyond Hebrew and English
- Cloud deployments (AWS, GCP, Azure)
- Docker/Kubernetes (keep it simple)

## Future Considerations
- Additional languages (Arabic, Spanish, etc.)
- Advanced accuracy metrics dashboard
- Market templates
- Tournament/season mode
- Export betting history
