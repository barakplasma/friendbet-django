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

### Architecture Requirements

**Single VPS Deployment:**
```
VPS (Ubuntu/Debian)
├── Backend application + database
├── Frontend static files
├── Data storage (database + avatars)
└── Web server / reverse proxy
```

### Database Schema

**users:**
- id, username, email, avatar, preferred_language (he/en)
- oauth2_provider, created, updated

**groups:**
- id, name, admin_ids (array of user ids), default_language, created

**group_memberships:**
- id, user_id (foreign key), group_id (foreign key)
- points_balance (number), joined_at (date)

**invite_codes:**
- id, group_id (foreign key), code (text, unique)
- email (email, optional), used (boolean)
- created_by (foreign key), created, used_at (date), used_by (foreign key)

**markets:**
- id, group_id (foreign key), creator_id (foreign key)
- resolver_id (foreign key), title (text), description (text)
- resolution_criteria (text), deadline_dates (json/array)
- close_date (date), status (enum: draft/active/closed/resolved)
- resolution (enum: yes/no/cancelled), resolution_date (date)
- resolved_at (date), content_language (enum: he/en), created

**bets:**
- id, market_id (foreign key), user_id (foreign key)
- deadline_date (date), outcome (enum: yes/no), amount (number)
- shares_received (number), created

**transactions:**
- id, user_id (foreign key), group_id (foreign key)
- amount (number), type (enum: bet/win/loss/stipend/adjustment)
- related_market_id (foreign key), related_deadline_date (date), created

### Business Logic Requirements

**Core algorithms needed:**
1. **AMM calculation** - calculate odds and shares when bet placed
2. **Market resolution** - calculate all payouts when market resolved
3. **Stipend distribution** - periodic point distribution to users
4. **Bet privacy enforcement** - hide bet details from non-admins
5. **Invite code validation** - one-time use enforcement
6. **Admin permission checks** - verify admin status for protected actions

### Authentication Requirements
- OAuth 2.0 authentication (Google, GitHub, Microsoft providers)
- JWT-based session management
- Automatic account linking by email
- Secure session handling

### Real-time Updates Requirements
- WebSocket support for live updates
- Subscribe to market odds changes
- Subscribe to leaderboard updates
- Reactive UI updates

### Deployment Requirements

**Initial Setup:**
- Simple installation process (under 30 minutes target)
- Single VPS capable of running full stack
- Minimal configuration required

**Production Setup:**
- Web server or reverse proxy configuration
- Process management (systemd or similar)
- SSL/HTTPS support
- Automated backup system

**Backup Strategy:**
- Database backup automation
- Easy restore process
- Minimal downtime during backups

### Security & Privacy Requirements
- OAuth-only authentication
- Role-based access control (admin vs user)
- Privacy rules for bet visibility
- HTTPS/TLS encryption
- Rate limiting
- Audit logging
- Secure environment variable handling

### Internationalization (i18n) Requirements

**UI Localization:**
- Full translation support for Hebrew and English
- Runtime language switching capability
- Translation files for UI strings
- User-created content stored in original language (not translated)

**Language Handling:**
- User preference storage
- Dynamic locale switching
- RTL/LTR text direction support
- BiDi (Bidirectional) text handling
- Locale-specific date/time formatting

## UI/UX Requirements

### Key Screens
1. **Group Dashboard:** Active markets with language badges, leaderboard preview, personal point balance
2. **Market Detail:** Description (original language), multiple deadline odds, time-stacked bet placement
3. **Admin: Create Market:** Form with multiple deadline inputs, language selector for content
4. **Admin: Invite Users:** Email invitation form and one-time code generator
5. **Leaderboard:** Rankings showing usernames and total points
6. **Profile:** Personal stats, private betting history, UI language settings
7. **Admin Panel:** Full betting visibility, resolution oversight, point management

### UI Components
- Card-based layout for markets
- Table views for leaderboards and bet history
- Form fields for all inputs
- Buttons and navigation elements
- Toolbar for navigation
- Panel-based admin interface
- Tab-based deadline selection in betting
- Badge/chip elements for deadline and language indicators
- Dialog modals for confirmations
- Expandable panels for market details
- Language selection interface

### Design Principles
- **Desktop-first:** Optimized for 1920x1080 and 1366x768
- Modern design guidelines
- Clear odds display per deadline
- Prominent privacy indicators
- Time-stacked betting UI clearly shows multiple deadlines
- Clean, minimal aesthetic - no social elements
- Real-time updates for odds and leaderboards
- Responsive down to 768px
- **Full RTL support** - UI mirrors completely for Hebrew
- **Language badge on markets** showing content language
- No currency symbols anywhere

### RTL/LTR Considerations
- Automatic UI direction switching based on selected language
- UI layout mirroring for RTL (navigation, buttons, forms)
- Market content displays in original direction (BiDi handling)
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

### Installation Guide Requirements
1. VPS setup and security (SSH keys, firewall)
2. Backend installation and configuration
3. OAuth provider setup (Google, GitHub, Microsoft)
4. Frontend build and deployment
5. Web server/reverse proxy setup
6. SSL certificate (Let's Encrypt)
7. Automated backups setup
8. Process management configuration
9. Monitoring and maintenance

### Backup & Restore Requirements
- Automated daily backup process
- Simple restore procedure
- Minimal downtime during backup operations

### Update Requirements
- Simple update process for backend
- Simple deployment process for frontend updates
- Zero-downtime updates preferred

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