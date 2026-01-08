from django.test import TestCase
from django.contrib.auth import get_user_model
from core.models import Group, GroupMembership, Market, Bet, Transaction, InviteCode
from core.services import AMMCalculator, MarketService, PointsService


class AMMTestCase(TestCase):
    """Test AMM calculation"""

    def test_amm_initialization(self):
        """Test AMM initialization"""
        amm = AMMCalculator()
        self.assertEqual(amm.base_reserve, 1000)
        self.assertEqual(amm.share_reserve, 1000)

    def test_calculate_shares(self):
        """Test share calculation"""
        amm = AMMCalculator()
        shares = amm.calculate_shares(100)
        self.assertGreater(shares, 0)
        self.assertLess(shares, 100)  # Should get fewer shares than points

    def test_calculate_odds(self):
        """Test odds calculation"""
        amm = AMMCalculator()
        yes_odds = amm.calculate_odds('yes')
        no_odds = amm.calculate_odds('no')
        self.assertEqual(yes_odds, 1.0)  # Initial odds should be 1:1
        self.assertEqual(no_odds, 1.0)

    def test_constant_product(self):
        """Test that constant product is maintained"""
        amm = AMMCalculator()
        initial_k = amm.k
        amm.calculate_shares(100)
        self.assertEqual(amm.k, initial_k)  # k should remain constant


class ModelTestCase(TestCase):
    """Test database models"""

    def setUp(self):
        """Set up test data"""
        self.user = get_user_model().objects.create_user(
            username='testuser',
            email='test@example.com',
            preferred_language='en'
        )
        self.group = Group.objects.create(
            name='Test Group',
            default_language='en'
        )
        self.group.admins.add(self.user)

    def test_group_creation(self):
        """Test group creation"""
        self.assertEqual(self.group.name, 'Test Group')
        self.assertIn(self.user, self.group.admins.all())

    def test_group_membership(self):
        """Test group membership"""
        membership = GroupMembership.objects.create(
            user=self.user,
            group=self.group,
            points_balance=1000
        )
        self.assertEqual(membership.points_balance, 1000)

    def test_market_creation(self):
        """Test market creation"""
        market = Market.objects.create(
            group=self.group,
            creator=self.user,
            resolver=self.user,
            title='Test Market',
            description='A test market',
            resolution_criteria='Test criteria',
            deadline_dates=['2025-01-15', '2025-02-01'],
            content_language='en',
            status='draft'
        )
        self.assertEqual(market.status, 'draft')

    def test_invite_code(self):
        """Test invite code creation"""
        invite = InviteCode.objects.create(
            group=self.group,
            code='TEST123',
            created_by=self.user
        )
        self.assertFalse(invite.used)
        self.assertEqual(invite.code, 'TEST123')


class IntegrationTestCase(TestCase):
    """Integration tests"""

    def setUp(self):
        """Set up test data"""
        self.user = get_user_model().objects.create_user(
            username='testuser',
            email='test@example.com',
            preferred_language='en'
        )
        self.group = Group.objects.create(
            name='Test Group',
            default_language='en'
        )
        self.group.admins.add(self.user)
        self.membership = GroupMembership.objects.create(
            user=self.user,
            group=self.group,
            points_balance=1000
        )

    def test_points_distribution(self):
        """Test points distribution"""
        initial_balance = self.membership.points_balance
        PointsService.distribute_stipend(self.group, amount=100)
        self.membership.refresh_from_db()
        self.assertEqual(
            self.membership.points_balance,
            initial_balance + 100
        )

    def test_manual_points_adjustment(self):
        """Test manual points adjustment"""
        initial_balance = self.membership.points_balance
        PointsService.adjust_points(
            self.user,
            self.group,
            50,
            'Bonus points'
        )
        self.membership.refresh_from_db()
        self.assertEqual(
            self.membership.points_balance,
            initial_balance + 50
        )
