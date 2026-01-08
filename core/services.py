from decimal import Decimal
from django.db import transaction
from django.utils import timezone
from .models import Market, Bet, Transaction, GroupMembership


class AMMCalculator:
    """Automated Market Maker using constant product formula"""

    def __init__(self, base_reserve=1000, share_reserve=1000):
        """
        Initialize AMM with reserves
        k = base_reserve * share_reserve (constant product)
        """
        self.base_reserve = Decimal(str(base_reserve))
        self.share_reserve = Decimal(str(share_reserve))
        self.k = self.base_reserve * self.share_reserve

    def calculate_shares(self, amount):
        """Calculate shares received for a given bet amount"""
        amount = Decimal(str(amount))
        if amount <= 0:
            raise ValueError("Amount must be positive")

        # Constant product formula: (x + dx) * (y - dy) = k
        # dy = y - (k / (x + dx))
        new_base_reserve = self.base_reserve + amount
        new_share_reserve = self.k / new_base_reserve
        shares_received = self.share_reserve - new_share_reserve

        # Update reserves
        self.base_reserve = new_base_reserve
        self.share_reserve = new_share_reserve

        return int(shares_received)

    def calculate_odds(self, outcome='yes'):
        """Calculate current odds for an outcome"""
        if outcome == 'yes':
            # Price = base_reserve / share_reserve
            price = float(self.base_reserve / self.share_reserve)
        else:
            # Price = share_reserve / base_reserve
            price = float(self.share_reserve / self.base_reserve)

        return price

    def get_pool_state(self):
        """Return current pool state"""
        return {
            'base_reserve': float(self.base_reserve),
            'share_reserve': float(self.share_reserve),
            'k': float(self.k),
            'yes_odds': self.calculate_odds('yes'),
            'no_odds': self.calculate_odds('no'),
        }


class MarketService:
    """Service for market operations"""

    @staticmethod
    @transaction.atomic
    def place_bet(market, user, deadline_date, outcome, amount):
        """Place a bet on a market"""
        if market.status != 'active':
            raise ValueError("Market is not active")

        if deadline_date not in market.deadline_dates:
            raise ValueError("Invalid deadline date")

        if amount < 10:
            raise ValueError("Minimum bet amount is 10 points")

        # Get user's group membership and points
        try:
            membership = GroupMembership.objects.get(
                user=user,
                group=market.group
            )
        except GroupMembership.DoesNotExist:
            raise ValueError("User is not a member of this group")

        if membership.points_balance < amount:
            raise ValueError("Insufficient points")

        # Get or create AMM for this market and deadline
        amm_key = f"{market.id}_{deadline_date}_{outcome}"
        # In a real implementation, you'd store the AMM state in the database
        amm = AMMCalculator()

        # Calculate shares
        try:
            shares_received = amm.calculate_shares(amount)
        except ValueError as e:
            raise ValueError(f"Invalid bet amount: {e}")

        # Create bet
        bet = Bet.objects.create(
            market=market,
            user=user,
            deadline_date=deadline_date,
            outcome=outcome,
            amount=amount,
            shares_received=shares_received
        )

        # Deduct points
        membership.points_balance -= amount

        # Create transaction
        Transaction.objects.create(
            user=user,
            group=market.group,
            amount=-amount,
            transaction_type='bet',
            related_market=market,
            related_deadline_date=deadline_date
        )

        membership.save()
        return bet

    @staticmethod
    @transaction.atomic
    def resolve_market(market, resolution, resolution_date=None):
        """Resolve a market and calculate payouts"""
        if market.status != 'active':
            raise ValueError("Market is not active")

        if resolution not in ['yes', 'no', 'cancelled']:
            raise ValueError("Invalid resolution")

        market.resolution = resolution
        market.resolved_at = timezone.now()

        if resolution == 'cancelled':
            market.status = 'resolved'
            # Return all points to bettors
            for bet in market.bets.all():
                membership = GroupMembership.objects.get(
                    user=bet.user,
                    group=market.group
                )
                membership.points_balance += bet.amount

                Transaction.objects.create(
                    user=bet.user,
                    group=market.group,
                    amount=bet.amount,
                    transaction_type='adjustment',  # Return cancelled bet
                    related_market=market,
                    related_deadline_date=bet.deadline_date
                )
                membership.save()
        else:
            market.resolution_date = resolution_date
            market.status = 'resolved'

            # Calculate winnings for each deadline
            for deadline in market.deadline_dates:
                deadline_bets = market.bets.filter(deadline_date=deadline)

                for bet in deadline_bets:
                    membership = GroupMembership.objects.get(
                        user=bet.user,
                        group=market.group
                    )

                    if resolution == bet.outcome:
                        # Calculate winnings based on shares
                        # This is simplified - real implementation would use current pool state
                        winnings = bet.shares_received * 2  # Simplified payout

                        membership.points_balance += winnings

                        Transaction.objects.create(
                            user=bet.user,
                            group=market.group,
                            amount=winnings,
                            transaction_type='win',
                            related_market=market,
                            related_deadline_date=deadline
                        )
                    else:
                        Transaction.objects.create(
                            user=bet.user,
                            group=market.group,
                            amount=-bet.amount,
                            transaction_type='loss',
                            related_market=market,
                            related_deadline_date=deadline
                        )

                    membership.save()

        market.save()

    @staticmethod
    def get_market_odds(market):
        """Get current odds for all deadlines in a market"""
        odds = {}
        for deadline in market.deadline_dates:
            # In a real implementation, you'd fetch the actual pool state
            amm = AMMCalculator()
            odds[deadline] = {
                'yes': amm.calculate_odds('yes'),
                'no': amm.calculate_odds('no')
            }
        return odds


class PointsService:
    """Service for points management"""

    @staticmethod
    @transaction.atomic
    def distribute_stipend(group, amount=100):
        """Distribute weekly stipend to all group members"""
        memberships = group.memberships.all()
        for membership in memberships:
            membership.points_balance += amount
            membership.save()

            Transaction.objects.create(
                user=membership.user,
                group=group,
                amount=amount,
                transaction_type='stipend'
            )

    @staticmethod
    @transaction.atomic
    def adjust_points(user, group, amount, reason):
        """Manually adjust user points (admin only)"""
        membership, created = GroupMembership.objects.get_or_create(
            user=user,
            group=group,
            defaults={'points_balance': 1000}
        )

        membership.points_balance += amount
        membership.save()

        Transaction.objects.create(
            user=user,
            group=group,
            amount=amount,
            transaction_type='adjustment'
        )

        return membership