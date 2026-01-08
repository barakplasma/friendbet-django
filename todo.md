# FriendBet Development Task List

## Phase 0: Foundation & Infrastructure Setup
*Complete these tasks first to establish the development environment.*

### Task 0.1: Initialize Project Structure
- **Description**: Set up basic project structure with separate frontend and backend directories
- **Acceptance Criteria**:
  - Root directory contains `frontend/` and `backend/` directories
  - Git repository initialized with appropriate .gitignore
  - README.md with basic project description and setup instructions
- **Complexity**: Simple
- **Dependencies**: None
- **Priority**: P0 (Must Have)

### Task 0.2: Set Up PocketBase Backend Development Environment
- **Description**: Download and configure PocketBase for local development
- **Acceptance Criteria**:
  - PocketBase binary downloaded and running locally on port 8090
  - Admin account created via web UI (http://localhost:8090/_/)
  - Basic project settings configured (app name, base URL)
  - Database directory structure created (pb_data/)
- **Complexity**: Simple
- **Dependencies**: Task 0.1
- **Priority**: P0 (Must Have)

### Task 0.3: Set Up Angular Frontend Project
- **Description**: Create Angular 17+ project with standalone components and Material UI
- **Acceptance Criteria**:
  - Angular 17+ project created in `frontend/` directory
  - Angular Material installed and configured
  - Standalone components enabled in project configuration
  - Basic routing module configured
  - Development server runs on port 4200
- **Complexity**: Simple
- **Dependencies**: Task 0.1
- **Priority**: P0 (Must Have)

### Task 0.4: Configure Angular Internationalization (i18n)
- **Description**: Set up bilingual support infrastructure for Hebrew and English
- **Acceptance Criteria**:
  - @angular/localize installed
  - Translation files created: `src/locale/messages.en.xlf` and `src/locale/messages.he.xlf`
  - Locale configuration added to angular.json
  - Language switching service created
  - RTL/LTR direction switching implemented
  - Basic test: UI text can switch between English and Hebrew
- **Complexity**: Medium
- **Dependencies**: Task 0.3
- **Priority**: P0 (Must Have)

## Phase 1: PocketBase Backend Foundation
*Core database schema and authentication setup.*

### Task 1.1: Define PocketBase Collections Schema
- **Description**: Create all required PocketBase collections with proper fields and relationships
- **Acceptance Criteria**:
  - Collections created: users (extended), groups, group_memberships, invite_codes, markets, bets, transactions
  - All fields defined with correct types (text, number, relation, date, select)
  - Relations established between collections
  - Indexes created on frequently queried fields
  - Collection rules configured for basic CRUD operations
- **Complexity**: Complex
- **Dependencies**: Task 0.2
- **Priority**: P0 (Must Have)

### Task 1.2: Configure OAuth Authentication Providers
- **Description**: Set up OAuth 2.0 authentication for Google, GitHub, and Microsoft
- **Acceptance Criteria**:
  - OAuth app credentials obtained for at least Google (GitHub, Microsoft optional for MVP)
  - OAuth providers configured in PocketBase admin UI
  - Redirect URLs properly set (localhost for dev, production domain for prod)
  - Test authentication flow works end-to-end
  - User profile data correctly mapped to users collection
  - preferred_language field defaults to 'en' for new users
- **Complexity**: Medium
- **Dependencies**: Task 1.1
- **Priority**: P0 (Must Have)

### Task 1.3: Implement PocketBase Collection Rules for Data Privacy
- **Description**: Configure access control rules to enforce bet privacy and admin-only operations
- **Acceptance Criteria**:
  - Non-admin users can only view their own bets
  - Non-admin users cannot see other users' bet amounts or positions
  - Only admins can view all betting data and create markets/groups
  - Collection rules prevent unauthorized updates/deletes
  - API rules tested via PocketBase API UI
- **Complexity**: Complex
- **Dependencies**: Task 1.1
- **Priority**: P0 (Must Have)

### Task 1.4: Create PocketBase Custom Hooks for AMM Logic
- **Description**: Implement Automated Market Maker logic in JavaScript/Go for calculating odds and shares
- **Acceptance Criteria**:
  - Hook fires on bet creation to calculate shares based on constant product formula
  - Odds calculation: `price = shares / (shares + pool_shares)` for each deadline pool
  - Separate pool tracking per market deadline date
  - Potential payout calculation exposed via API
  - Hook validates sufficient user balance before accepting bet
  - Unit tests for AMM calculations
- **Complexity**: Complex
- **Dependencies**: Task 1.1
- **Priority**: P0 (Must Have)

### Task 1.5: Create PocketBase Custom Hooks for Market Resolution
- **Description**: Implement automated payout calculation when markets are resolved
- **Acceptance Criteria**:
  - Hook fires on market resolution update
  - Calculates which deadline bets won/lost based on resolution date vs deadline dates
  - Automatically creates transaction records for all affected bets
  - Updates user point balances accordingly
  - Handles cancelled markets (returns all points)
  - Resolution audit trail created
- **Complexity**: Complex
- **Dependencies**: Task 1.4
- **Priority**: P0 (Must Have)

### Task 1.6: Create PocketBase Hook for Periodic Point Stipends
- **Description**: Implement cron job or scheduled hook for weekly point distribution
- **Acceptance Criteria**:
  - Hook runs weekly to distribute stipend (e.g., 100 points)
  - Only active group members receive stipend
  - Transaction records created for stipends
  - Configurable stipend amount and frequency
  - Admin can trigger manual stipend distribution
- **Complexity**: Medium
- **Dependencies**: Task 1.1
- **Priority**: P1 (Should Have)

## Phase 2: Angular Frontend Core Components
*Essential UI components for basic functionality.*

### Task 2.1: Create Authentication Service & Guards
- **Description**: Implement authentication service using PocketBase client SDK
- **Acceptance Criteria**:
  - AuthService handles OAuth login/logout flow
  - AuthGuard protects routes requiring authentication
  - User session persisted in PocketBase
  - User profile (including preferred_language) loaded on app init
  - Logout clears session and redirects to login
  - Unauthorized access redirects to OAuth login
- **Complexity**: Medium
- **Dependencies**: Task 1.2, Task 0.4
- **Priority**: P0 (Must Have)

### Task 2.2: Create Data Service Layer for PocketBase API
- **Description**: Implement services for all PocketBase collections (CRUD operations)
- **Acceptance Criteria**:
  - GroupService: list, get, create (admin only)
  - MarketService: list, get, create (admin only), update, resolve
  - BetService: place bet, get user bets, get market odds
  - UserService: get profile, update language preference
  - LeaderboardService: get group rankings
  - All services use PocketBase JS SDK
  - Error handling for API failures
  - Type definitions for all data models
- **Complexity**: Complex
- **Dependencies**: Task 1.1
- **Priority**: P0 (Must Have)

### Task 2.3: Implement Real-time Subscriptions Service
- **Description**: Create service for PocketBase real-time WebSocket subscriptions
- **Acceptance Criteria**:
  - Subscribe to market odds changes
  - Subscribe to leaderboard updates
  - Subscribe to user's own bet updates
  - Automatic reconnection on connection loss
  - Unsubscribe on component destroy
  - Integration with Angular Signals for reactive updates
- **Complexity**: Medium
- **Dependencies**: Task 2.2
- **Priority**: P0 (Must Have)

### Task 2.4: Create Main Navigation & Layout Component
- **Description**: Build app shell with navigation toolbar and routing
- **Acceptance Criteria**:
  - Material toolbar with app title
  - Navigation links: Dashboard, Markets, Leaderboard, Profile
  - Admin-only navigation: Admin Panel, Create Market, Invite Users
  - User menu with logout button
  - Language switcher (English/Hebrew) in toolbar
  - Responsive navigation (hamburger menu on mobile)
  - Proper RTL/LTR layout switching
- **Complexity**: Medium
- **Dependencies**: Task 0.4, Task 2.1
- **Priority**: P0 (Must Have)

### Task 2.5: Create Translation Keys for All UI Strings
- **Description**: Extract and translate all UI strings for Hebrew and English
- **Acceptance Criteria**:
  - All buttons, labels, error messages, tooltips translated
  - Navigation items translated
  - Form field labels and placeholders translated
  - Status and state text translated
  - Date/time formatting localized per locale
  - Number formatting for points (no separators, no currency symbols)
  - Translation files populated and validated
- **Complexity**: Medium
- **Dependencies**: Task 0.4
- **Priority**: P0 (Must Have)

## Phase 3: Group Management Features
*User group creation and invitation system.*

### Task 3.1: Build Group List/Selection Component
- **Description**: Create component for users to see and select their groups
- **Acceptance Criteria**:
  - Display list of user's groups
  - Show group name and member count
  - Click to navigate to group dashboard
  - Empty state if no groups
  - Loading state while fetching
  - Error handling for fetch failures
  - RTL/LTR layout support
- **Complexity**: Medium
- **Dependencies**: Task 2.2, Task 2.4
- **Priority**: P0 (Must Have)

### Task 3.2: Build Admin Create Group Component
- **Description**: Create admin-only form for creating new groups
- **Acceptance Criteria**:
  - Form with group name input
  - Default language selector (Hebrew/English)
  - Validation: name required, max length
  - Only accessible to admins (any user can create first group)
  - Success/error message handling
  - Redirect to group dashboard on creation
  - RTL/LTR form layout
- **Complexity**: Medium
- **Dependencies**: Task 2.2, Task 2.4
- **Priority**: P0 (Must Have)

### Task 3.3: Build Admin Invite Users Component
- **Description**: Create admin panel for inviting users via email or one-time codes
- **Acceptance Criteria**:
  - Email invitation form with validation
  - One-time code generator button
  - Generated code displayed with copy button
  - List of pending invitations with status
  - Ability to revoke pending invitations
  - Only visible to group admins
  - RTL/LTR support
- **Complexity**: Medium
- **Dependencies**: Task 2.2, Task 2.4
- **Priority**: P0 (Must Have)

### Task 3.4: Build User Join Flow Component
- **Description**: Create flow for users to accept invitations and join groups
- **Acceptance Criteria**:
  - Invite link validates and accepts email invitations
  - One-time code input form
  - Code validation and single-use enforcement
  - Automatic group membership creation
  - Initial point balance allocation (1000 points)
  - Success message and redirect to group
  - Error messages for invalid/expired codes
  - RTL/LTR support
- **Complexity**: Medium
- **Dependencies**: Task 2.2, Task 3.3
- **Priority**: P0 (Must Have)

### Task 3.5: Build Group Members Management Component
- **Description**: Create admin view for managing group members
- **Acceptance Criteria**:
  - List of all group members with:
    - Username
    - Join date
    - Current point balance
    - Admin badge
  - Remove member button (admin only)
  - Promote to admin button (admin only)
  - Confirmation dialogs for destructive actions
  - Only accessible to group admins
  - RTL/LTR table support
- **Complexity**: Medium
- **Dependencies**: Task 2.2, Task 3.1
- **Priority**: P1 (Should Have)

## Phase 4: Market Creation & Management
*Admin features for creating and managing prediction markets.*

### Task 4.1: Build Admin Create Market Form
- **Description**: Create comprehensive form for admins to create prediction markets
- **Acceptance Criteria**:
  - Form fields:
    - Title (required)
    - Description (required)
    - Resolution criteria (required)
    - Multiple deadline dates (dynamic add/remove, at least one required)
    - Resolver selector (self or other group members)
    - Content language selector (Hebrew/English badge)
  - Form validation for all fields
  - Draft save functionality
  - Publish button (transitions to active state)
  - Only accessible to group admins
  - RTL/LTR form layout with proper text direction for inputs
  - Language badge preview on form
- **Complexity**: Complex
- **Dependencies**: Task 2.2, Task 3.1
- **Priority**: P0 (Must Have)

### Task 4.2: Build Market List Component (Group Dashboard)
- **Description**: Create dashboard showing all markets in a group
- **Acceptance Criteria**:
  - Display markets as Material cards
  - Each card shows:
    - Title (in original language)
    - Description snippet
    - Language badge (He/En)
    - Status badge (Draft/Active/Resolved)
    - Current odds for each deadline (if active)
    - Time remaining to earliest deadline
  - Filter by status (All/Active/Resolved)
  - Click to view market details
  - Empty state with "Create Market" CTA for admins
  - Real-time odds updates via subscriptions
  - Loading and error states
  - RTL/LTR card layout
- **Complexity**: Complex
- **Dependencies**: Task 2.3, Task 4.1
- **Priority**: P0 (Must Have)

### Task 4.3: Build Market Detail Component
- **Description**: Create detailed view for a single market
- **Acceptance Criteria**:
  - Full market title and description (original language)
  - Language badge prominently displayed
  - Resolution criteria clearly shown
  - All deadline dates listed with:
    - Current odds (Yes/No)
    - Time remaining
    - "Bet on this deadline" button
  - Market status indicator
  - Resolver information
  - Betting history (admin only)
  - Back button to dashboard
  - Real-time odds updates
  - RTL/LTR content direction
  - BiDi handling for mixed language content
- **Complexity**: Complex
- **Dependencies**: Task 2.2, Task 4.2
- **Priority**: P0 (Must Have)

### Task 4.4: Build Admin Edit/Resolve Market Component
- **Description**: Create admin interface for editing and resolving markets
- **Acceptance Criteria**:
  - Edit form (pre-resolution only):
    - All fields from create form pre-populated
    - Save changes button
  - Resolve interface:
    - Resolution selector (Yes/No/Cancelled)
    - Resolution date picker (if Yes)
    - Resolution notes field (optional)
    - Confirm resolution button with confirmation dialog
  - Only accessible to designated resolver or group admins
  - Warning if resolving will affect multiple deadlines
  - Preview of which bets will win/lose
  - RTL/LTR support
- **Complexity**: Complex
- **Dependencies**: Task 4.3, Task 1.5
- **Priority**: P0 (Must Have)

## Phase 5: Betting System
*Core betting functionality with time-stacked private predictions.*

### Task 5.1: Build Place Bet Component
- **Description**: Create betting interface for placing time-stacked bets
- **Acceptance Criteria**:
  - Dialog or slide-in panel showing:
    - Market title and language badge
    - Selected deadline date
    - Current odds for that deadline
    - Bet outcome selector (Yes/No)
    - Bet amount input (number only, no currency symbol)
    - Minimum bet indicator (10 points)
    - Current balance display
    - Potential payout calculation (updates in real-time)
  - Validation:
    - Amount >= minimum bet
    - Amount <= current balance
    - Amount is valid number
  - "Place Bet" button with confirmation
  - "Cancel" button
  - Loading state during bet placement
  - Success/error messages
  - RTL/LTR layout
  - No currency symbols anywhere
- **Complexity**: Complex
- **Dependencies**: Task 2.2, Task 4.3, Task 1.4
- **Priority**: P0 (Must Have)

### Task 5.2: Build User Bet History Component
- **Description**: Create private view of user's own betting activity
- **Acceptance Criteria**:
  - Table showing user's bets:
    - Market title
    - Deadline date
    - Outcome (Yes/No)
    - Amount bet
    - Status (Pending/Won/Lost)
    - Payout (if won)
    - Transaction date
  - Filter by status (All/Pending/Won/Lost)
  - Sort by date or amount
  - Total points won/lost summary
  - Only shows current user's bets (privacy enforced)
  - Pagination for large histories
  - Empty state
  - RTL/LTR table support
- **Complexity**: Medium
- **Dependencies**: Task 2.2, Task 5.1
- **Priority**: P0 (Must Have)

### Task 5.3: Build Admin Bet Oversight Component
- **Description**: Create admin-only view of all betting activity
- **Acceptance Criteria**:
  - Table showing all bets in group:
    - Username
    - Market title
    - Deadline date
    - Outcome
    - Amount
    - Status
  - Filter by market, user, or status
  - Sort by any column
  - Total volume per market
  - Only accessible to group admins
  - Pagination
  - Export to CSV (optional)
  - RTL/LTR table support
- **Complexity**: Medium
- **Dependencies**: Task 2.2, Task 5.2
- **Priority**: P1 (Should Have)

### Task 5.4: Implement Real-time Odds Updates
- **Description**: Connect PocketBase subscriptions to update odds dynamically
- **Acceptance Criteria**:
  - Market detail page subscribes to odds changes
  - Odds update in real-time when bets are placed
  - Smooth animations for odds changes
  - Reconnection handling if connection drops
  - Unsubscribe when leaving market page
  - Visual indicator showing "Live" when updates active
  - Works across multiple deadline pools
- **Complexity**: Medium
- **Dependencies**: Task 2.3, Task 4.3, Task 5.1
- **Priority**: P0 (Must Have)

## Phase 6: Leaderboard & Profiles
*User profiles, rankings, and personal statistics.*

### Task 6.1: Build Group Leaderboard Component
- **Description**: Create rankings view for group members
- **Acceptance Criteria**:
  - Table showing:
    - Rank (1, 2, 3...)
    - Username
    - Total points (no currency symbol)
  - Sorted by points descending
  - Highlight top 3 users with medals/badges
  - Current user's row highlighted
  - Update in real-time via subscriptions
  - Pagination for large groups
  - Empty state
  - RTL/LTR table support
  - No betting history or positions visible (privacy)
- **Complexity**: Medium
- **Dependencies**: Task 2.2, Task 2.3
- **Priority**: P0 (Must Have)

### Task 6.2: Build User Profile Component
- **Description**: Create personal profile view with stats and settings
- **Acceptance Criteria**:
  - Display:
    - Username
    - Avatar (from OAuth)
    - Current point balance
    - Groups membership list
  - Personal stats (private):
    - Total markets bet on
    - Win rate (percentage)
    - Biggest win
    - Biggest loss
    - Total lifetime winnings/losses
  - UI language selector (Hebrew/English)
  - Save language preference
  - Only shows current user's profile (no public profiles)
  - RTL/LTR layout
- **Complexity**: Medium
- **Dependencies**: Task 2.2, Task 5.2
- **Priority**: P0 (Must Have)

### Task 6.3: Build Admin Points Management Component
- **Description**: Create admin interface for adjusting user point balances
- **Acceptance Criteria**:
  - List of group members with current balances
  - Adjust points button for each member
  - Dialog for adjustment:
    - Amount input (positive or negative)
    - Reason field (required, for audit trail)
    - Confirm button
  - Reset all points button (to starting balance)
  - Trigger stipend distribution button
  - Transaction log showing all manual adjustments
  - Only accessible to group admins
  - Confirmation dialogs for all actions
  - RTL/LTR support
- **Complexity**: Medium
- **Dependencies**: Task 2.2, Task 3.5
- **Priority**: P1 (Should Have)

## Phase 7: Admin Panel & Oversight
*Administrative features for managing the platform.*

### Task 7.1: Build Admin Dashboard Component
- **Description**: Create main admin panel with overview and quick actions
- **Acceptance Criteria**:
  - Overview stats:
    - Total group members
    - Active markets
    - Total betting volume
    - Pending resolutions
  - Quick action buttons:
    - Create Market
    - Invite Users
    - View All Bets
    - Manage Points
  - Recent activity log (admin-only view)
  - Only accessible to group admins
  - RTL/LTR layout
- **Complexity**: Medium
- **Dependencies**: Task 3.5, Task 4.1, Task 5.3, Task 6.3
- **Priority**: P1 (Should Have)

### Task 7.2: Build Market Resolution Dispute Interface
- **Description**: Create admin interface for reviewing and disputing resolutions
- **Acceptance Criteria**:
  - List of recently resolved markets with 24-hour dispute window
  - View resolution details:
    - Original market details
    - Resolution outcome and date
    - Affected bets and users
    - Resolver notes
  - "Dispute Resolution" button for admins
  - Override resolution dialog with:
    - New resolution selector
    - Reason for dispute (required)
    - Confirm button
  - Audit trail showing all resolution changes
  - Only accessible to group admins
  - RTL/LTR support
- **Complexity**: Complex
- **Dependencies**: Task 4.4, Task 7.1
- **Priority**: P1 (Should Have)

## Phase 8: Production Deployment
*Self-hosting setup and production configuration.*

### Task 8.1: Prepare Production Build Configuration
- **Description**: Configure Angular for production builds with i18n
- **Acceptance Criteria**:
  - Production build configuration in angular.json
  - Separate English and Hebrew build configurations
  - Environment-specific configuration files (dev, prod)
  - Production environment variables configured
  - Build optimization enabled
  - Source maps disabled for production
  - Assets optimization
- **Complexity**: Medium
- **Dependencies**: All Phase 0-7 tasks
- **Priority**: P0 (Must Have)

### Task 8.2: Create Deployment Scripts & Documentation
- **Description**: Write scripts and documentation for VPS deployment
- **Acceptance Criteria**:
  - Shell script for complete deployment:
    - PocketBase download and setup
    - Angular build and copy to pb_public/
    - Permissions setup
    - Systemd service creation
  - Step-by-step deployment guide:
    - VPS requirements
    - Initial server setup (SSH, firewall)
    - PocketBase installation
    - OAuth provider setup instructions
    - Nginx configuration (optional)
    - SSL certificate setup (Let's Encrypt)
    - Automated backup script
  - All scripts tested on clean VPS
- **Complexity**: Medium
- **Dependencies**: Task 8.1
- **Priority**: P0 (Must Have)

### Task 8.3: Configure Nginx Reverse Proxy (Optional)
- **Description**: Set up Nginx as reverse proxy for production
- **Acceptance Criteria**:
  - Nginx configuration file created
  - Reverse proxy to PocketBase on localhost
  - SSL/HTTPS configuration
  - Security headers configured
  - Static file caching rules
  - Gzip compression enabled
  - Configuration tested and validated
- **Complexity**: Medium
- **Dependencies**: Task 8.2
- **Priority**: P1 (Should Have)

### Task 8.4: Set Up Automated Backups
- **Description**: Configure automated database backups
- **Acceptance Criteria**:
  - Backup script that copies pb_data/data.db with timestamp
  - Cron job configured for daily backups
  - Backup retention policy (e.g., keep last 30 days)
  - Backup directory with proper permissions
  - Restore procedure documented
  - Backup script tested successfully
- **Complexity**: Simple
- **Dependencies**: Task 8.2
- **Priority**: P0 (Must Have)

### Task 8.5: Configure Production OAuth Providers
- **Description**: Set up OAuth apps for production domain
- **Acceptance Criteria**:
  - OAuth apps created in Google, GitHub, Microsoft consoles
  - Production domain redirect URLs configured
  - OAuth credentials added to PocketBase production instance
  - Test login flow works in production
  - HTTPS required for OAuth
- **Complexity**: Medium
- **Dependencies**: Task 8.2
- **Priority**: P0 (Must Have)

### Task 8.6: Production Testing & Validation
- **Description**: Comprehensive testing of production deployment
- **Acceptance Criteria**:
  - Full user journey tested in production:
    - OAuth login
    - Group creation
    - User invitations
    - Market creation
    - Bet placement
    - Market resolution
    - Leaderboard updates
    - Language switching
  - Real-time updates tested
  - RTL/LTR switching tested
  - Performance testing (page load times, API response times)
  - Security testing (unauthorized access prevention)
  - Cross-browser testing (Chrome, Firefox, Safari)
  - Mobile responsive testing
  - Bug fixes applied
- **Complexity**: Complex
- **Dependencies**: Task 8.5
- **Priority**: P0 (Must Have)

## Phase 9: Polish & Enhancements
*Nice-to-have features and improvements.*

### Task 9.1: Add Loading Skeletons & Optimistic UI
- **Description**: Improve perceived performance with loading states
- **Acceptance Criteria**:
  - Skeleton screens for all major views
  - Optimistic updates for bet placement
  - Smooth transitions between states
  - Loading spinners for async operations
  - Progressive image loading for avatars
  - Consistent loading patterns across app
- **Complexity**: Medium
- **Dependencies**: All Phase 1-6 tasks
- **Priority**: P2 (Could Have)

### Task 9.2: Implement Advanced Filtering & Search
- **Description**: Add search and advanced filter options
- **Acceptance Criteria**:
  - Search markets by title/description
  - Filter markets by status, language, date range
  - Filter bet history by outcome, date range
  - Save filter preferences
  - Keyboard shortcuts for search
  - RTL/LTR support for search UI
- **Complexity**: Medium
- **Dependencies**: Task 4.2, Task 5.2
- **Priority**: P2 (Could Have)

### Task 9.3: Add Data Export Features
- **Description**: Allow users to export their betting history
- **Acceptance Criteria**:
  - Export personal bet history to CSV
  - Export leaderboard to CSV (admin only)
  - Export market data to CSV (admin only)
  - Date range selection for exports
  - Proper CSV formatting for Hebrew characters
- **Complexity**: Simple
- **Dependencies**: Task 5.2, Task 6.1
- **Priority**: P2 (Could Have)

### Task 9.4: Create User Onboarding Flow
- **Description**: Add first-time user experience tutorial
- **Acceptance Criteria**:
  - Welcome modal for new users
  - Step-by-step tutorial highlighting key features
  - Optional tutorial (can be skipped)
  - Progress indicator
  - Tutorial completion tracking
  - Localized tutorial content in Hebrew and English
  - RTL/LTR support
- **Complexity**: Medium
- **Dependencies**: All core UI tasks
- **Priority**: P2 (Could Have)

### Task 9.5: Implement Notification System
- **Description**: Add in-app notifications for market resolutions
- **Acceptance Criteria**:
  - Notification bell icon in toolbar
  - Notifications for:
    - Market resolved (if you bet on it)
    - Invitation to new group
    - Point stipend received
  - Mark notifications as read
  - Clear all notifications button
  - Notification count badge
  - Real-time notification delivery via PocketBase
  - RTL/LTR support
- **Complexity**: Medium
- **Dependencies**: Task 2.3, Task 4.4
- **Priority**: P2 (Could Have)

### Task 9.6: Add Accessibility Improvements
- **Description**: Enhance accessibility for screen readers and keyboard navigation
- **Acceptance Criteria**:
  - ARIA labels on all interactive elements
  - Keyboard navigation for all features
  - Focus management in dialogs and forms
  - Screen reader announcements for dynamic updates
  - High contrast mode support
  - Accessibility audit completed with axe DevTools
  - WCAG 2.1 AA compliance tested
- **Complexity**: Medium
- **Dependencies**: All UI tasks
- **Priority**: P2 (Could Have)

## Phase 10: Testing & Documentation
*Quality assurance and developer documentation.*

### Task 10.1: Write Unit Tests for Core Logic
- **Description**: Create unit tests for business logic
- **Acceptance Criteria**:
  - Unit tests for AMM calculations
  - Unit tests for market resolution logic
  - Unit tests for point balance updates
  - Unit tests for invite code validation
  - Minimum 80% code coverage for business logic
  - Tests run in CI/CD pipeline
- **Complexity**: Complex
- **Dependencies**: Task 1.4, Task 1.5
- **Priority**: P1 (Should Have)

### Task 10.2: Write Integration Tests for User Flows
- **Description**: Create end-to-end tests for critical user journeys
- **Acceptance Criteria**:
  - E2E test for complete betting flow
  - E2E test for market creation and resolution
  - E2E test for group invitation flow
  - E2E test for language switching
  - Tests run on each deployment
  - Tests compatible with CI/CD
- **Complexity**: Complex
- **Dependencies**: All Phase 1-7 tasks
- **Priority**: P1 (Should Have)

### Task 10.3: Create Administrator Guide
- **Description**: Write documentation for group administrators
- **Acceptance Criteria**:
  - How to create and manage groups
  - How to invite users
  - How to create markets
  - How to resolve markets
  - How to manage user points
  - How to handle disputes
  - How to interpret betting data (admin view)
  - Best practices for market criteria
  - Available in both Hebrew and English
  - Screenshots and diagrams included
- **Complexity**: Medium
- **Dependencies**: Task 7.1
- **Priority**: P1 (Should Have)

### Task 10.4: Create User Guide
- **Description**: Write end-user documentation
- **Acceptance Criteria**:
  - How to join a group
  - How to place bets (time-stacked betting explained)
  - How to read odds
  - How to view your betting history
  - How to understand the leaderboard
  - Privacy explanation (what others can/cannot see)
  - Points system explanation
  - FAQ section
  - Available in both Hebrew and English
  - Screenshots included
- **Complexity**: Medium
- **Dependencies**: Task 6.2
- **Priority**: P1 (Should Have)

### Task 10.5: Create Developer Documentation
- **Description**: Write technical documentation for future developers
- **Acceptance Criteria**:
  - Architecture overview
  - Database schema documentation
  - API endpoint documentation
  - PocketBase hooks documentation
  - Frontend component architecture
  - Environment setup guide
  - Deployment process
  - Troubleshooting guide
  - Code contribution guidelines
- **Complexity**: Medium
- **Dependencies**: All implementation tasks
- **Priority**: P2 (Could Have)

---

## Implementation Priority Summary

### MVP (Must Have - P0)
*Minimum Viable Product for friend group testing*
- Phase 0: Foundation (Tasks 0.1-0.4)
- Phase 1: PocketBase Foundation (Tasks 1.1-1.5)
- Phase 2: Angular Core (Tasks 2.1-2.5)
- Phase 3: Group Management (Tasks 3.1-3.4)
- Phase 4: Market Creation (Tasks 4.1-4.4)
- Phase 5: Betting System (Tasks 5.1-5.2, 5.4)
- Phase 6: Leaderboard (Tasks 6.1-6.2)
- Phase 8: Deployment (Tasks 8.1-8.2, 8.4-8.6)

**MVP Target**: Deployable, testable prediction market platform with core features working end-to-end.

### High Priority (Should Have - P1)
*Important features for production readiness*
- Task 1.6: Periodic stipends
- Task 3.5: Member management
- Task 5.3: Admin bet oversight
- Task 6.3: Points management
- Task 7.1: Admin dashboard
- Task 7.2: Dispute interface
- Task 8.3: Nginx configuration
- Task 10.1-10.4: Testing and documentation

### Nice to Have (P2)
*Enhancements and polish*
- Task 9.1-9.6: All polish and enhancement features
- Task 10.5: Developer documentation

---

## Estimated Timeline

- **MVP (P0)**: 4-6 weeks for one developer
- **P1 Features**: +2-3 weeks
- **P2 Polish**: +1-2 weeks

**Total**: 7-11 weeks for complete feature set

---

## Development Notes

### Key Technical Decisions
1. **PocketBase over Directus/Supabase**: Single binary deployment is critical for simple VPS self-hosting
2. **Angular over React/Vue**: Built-in i18n and Material UI with excellent RTL support
3. **SQLite over PostgreSQL**: Single file backup is essential for easy maintenance
4. **OAuth-only auth**: Email/password adds complexity; OAuth is simpler and more secure

### Risk Mitigation
- Start with AMM implementation early (Task 1.4) - it's the most complex logic
- Test bilingual support continuously, not as an afterthought
- Implement privacy rules at the collection level (Task 1.3) to prevent data leaks
- Production deployment should be practiced early to identify VPS issues

### Testing Strategy
- Test Hebrew RTL layout alongside English LTR from Task 0.4 onwards
- Test time-stacked betting logic thoroughly (multiple deadline scenarios)
- Test privacy enforcement - verify non-admins cannot see other bets
- Test real-time updates under poor network conditions
- Test market resolution edge cases (resolution before/after various deadlines)

### Deployment Checklist
Before going live:
- [ ] OAuth providers configured for production domain
- [ ] SSL certificate installed and HTTPS working
- [ ] Automated backups configured and tested
- [ ] Systemd service configured for auto-restart
- [ ] Firewall rules configured (only ports 80, 443 exposed)
- [ ] Initial admin account created
- [ ] Database backup performed
- [ ] Full user journey tested in production
- [ ] Performance tested (page load < 3 seconds)
- [ ] Mobile responsive tested
- [ ] Both languages tested in production

---

## Next Steps for Development Team

1. **Start with Phase 0**: Set up development environment (1 day)
2. **Proceed to Phase 1**: PocketBase foundation (3-5 days)
3. **Build Phase 2 & 3 in parallel**: Angular core and group management (5-7 days)
4. **Implement Phases 4-6**: Core features (10-14 days)
5. **Deploy MVP**: Phase 8 (2-3 days)
6. **Test with real users**: Get feedback on MVP
7. **Add P1 features**: Based on user feedback (7-10 days)
8. **Polish with P2**: If time permits (optional)

**Remember**: The goal is to get to a testable MVP as quickly as possible, then iterate based on real user feedback.