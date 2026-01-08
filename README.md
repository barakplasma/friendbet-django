# FriendBet - Private Prediction Market Platform

A boring Django implementation of a private prediction market platform for friend groups.

## Features

- **Admin-controlled groups** - Only admins can create groups and invite members
- **Time-stacked betting** - Place bets on multiple deadline dates for nuanced predictions
- **Private betting** - Individual bets remain confidential to ensure unbiased predictions
- **Points-based system** - No real money, just friendly competition
- **Bilingual support** - Hebrew and English with proper RTL/LTR handling
- **OAuth authentication** - Login with Google or GitHub

## Tech Stack

- **Backend**: Django 4.2 with PostgreSQL
- **Frontend**: Server-side rendered templates (no SPA)
- **Authentication**: python-social-auth (OAuth)
- **Deployment**: Kubernetes on friendbet.526462738.xyz
- **Package Management**: uv (fast Python package installer)

## Quick Start

### Local Development

1. **Install dependencies:**
   ```bash
   uv sync
   ```

2. **Set up environment variables:**
   ```bash
   export DJANGO_SECRET_KEY='your-secret-key'
   export DJANGO_DEBUG='True'
   export DJANGO_ALLOWED_HOSTS='localhost,127.0.0.1'
   export POSTGRES_DB='friendbet'
   export POSTGRES_USER='friendbet'
   export POSTGRES_PASSWORD='friendbet'
   export POSTGRES_HOST='localhost'
   export POSTGRES_PORT='5432'
   ```

3. **Run migrations:**
   ```bash
   uv run python manage.py migrate
   ```

4. **Create superuser:**
   ```bash
   uv run python manage.py createsuperuser
   ```

5. **Run development server:**
   ```bash
   uv run python manage.py runserver
   ```

### Kubernetes Deployment

1. **Build Docker image:**
   ```bash
   docker build -t friendbet:latest .
   ```

2. **Deploy to Kubernetes:**
   ```bash
   ./deploy.sh
   ```

The application will be available at: https://friendbet.526462738.xyz

## Project Structure

```
friendbet/
├── config/              # Django project settings
├── core/               # Main application
│   ├── models.py       # Database models
│   ├── views.py        # Views
│   ├── services.py     # Business logic (AMM, betting, etc.)
│   ├── admin.py        # Admin interface
│   └── urls.py         # URL routing
├── templates/          # HTML templates
├── static/            # CSS, JavaScript
├── k8s/               # Kubernetes manifests
├── locale/            # Translation files
├── pyproject.toml     # Dependencies (uv)
└── Dockerfile         # Container image
```

## Core Models

- **User** - Extended Django user with language preferences
- **Group** - Private friend groups with admin controls
- **GroupMembership** - User membership in groups with point balances
- **Market** - Yes/no prediction markets with time-stacked deadlines
- **Bet** - Individual bets on specific deadline dates
- **Transaction** - Transaction history (bets, wins, losses, stipends)

## Business Logic

### AMM (Automated Market Maker)
- Constant product formula: x * y = k
- Separate pools for each deadline date and outcome
- Real-time odds calculation

### Time-Stacked Betting
- Users can bet on multiple deadlines for the same market
- If event resolves before earliest deadline, win all stacked bets
- If event resolves after a deadline passes, lose that specific bet

### Privacy
- Individual bet amounts hidden from non-admins
- Only aggregate odds visible to regular users
- Admins have full oversight

## Admin Features

- Create and manage groups
- Generate invite codes
- Create markets with multiple deadlines
- Resolve markets and trigger automatic payouts
- Adjust user points
- Distribute stipends
- Full betting visibility

## Internationalization

- Full Hebrew and English UI support
- Proper RTL/LTR text direction
- Language switching at runtime
- Market content stored in original language

## Database Schema

See `CLAUDE.md` for complete specification and requirements.

## Development

```bash
# Run development server
uv run python manage.py runserver

# Create migrations
uv run python manage.py makemigrations

# Apply migrations
uv run python manage.py migrate

# Create superuser
uv run python manage.py createsuperuser

# Collect static files
uv run python manage.py collectstatic

# Run tests (when implemented)
uv run python manage.py test
```

## Deployment

The application is configured to run in Kubernetes at `friendbet.526462738.xyz`.

### Kubernetes Resources

- PostgreSQL database (persistent storage)
- Django application (gunicorn)
- Ingress with TLS (Let's Encrypt)
- ConfigMaps and Secrets for configuration

### Monitoring

```bash
# Check pod status
kubectl get pods -n friendbet

# View logs
kubectl logs -f deployment/django -n friendbet

# Check services
kubectl get svc -n friendbet
```

## License

Private prediction market platform for friend groups.

## Contributing

This is a private project for friend groups.