from django.contrib.auth.models import AbstractUser
from django.db import models
from django.utils.translation import gettext_lazy as _


class User(AbstractUser):
    LANGUAGE_CHOICES = [
        ('en', 'English'),
        ('he', 'Hebrew'),
    ]

    preferred_language = models.CharField(
        max_length=2,
        choices=LANGUAGE_CHOICES,
        default='en',
        verbose_name=_("Preferred Language")
    )
    avatar = models.ImageField(
        upload_to='avatars/',
        blank=True,
        null=True,
        verbose_name=_("Avatar")
    )

    class Meta:
        verbose_name = _("User")
        verbose_name_plural = _("Users")

    def __str__(self):
        return self.username


class Group(models.Model):
    name = models.CharField(
        max_length=255,
        verbose_name=_("Group Name")
    )
    admins = models.ManyToManyField(
        User,
        related_name='admin_groups',
        verbose_name=_("Administrators")
    )
    default_language = models.CharField(
        max_length=2,
        choices=User.LANGUAGE_CHOICES,
        default='en',
        verbose_name=_("Default Language")
    )
    created = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Created")
    )

    class Meta:
        verbose_name = _("Group")
        verbose_name_plural = _("Groups")
        ordering = ['-created']

    def __str__(self):
        return self.name


class GroupMembership(models.Model):
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='group_memberships',
        verbose_name=_("User")
    )
    group = models.ForeignKey(
        Group,
        on_delete=models.CASCADE,
        related_name='memberships',
        verbose_name=_("Group")
    )
    points_balance = models.IntegerField(
        default=1000,
        verbose_name=_("Points Balance")
    )
    joined_at = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Joined At")
    )

    class Meta:
        verbose_name = _("Group Membership")
        verbose_name_plural = _("Group Memberships")
        unique_together = ['user', 'group']
        ordering = ['-joined_at']

    def __str__(self):
        return f"{self.user.username} - {self.group.name}"


class InviteCode(models.Model):
    group = models.ForeignKey(
        Group,
        on_delete=models.CASCADE,
        related_name='invite_codes',
        verbose_name=_("Group")
    )
    code = models.CharField(
        max_length=32,
        unique=True,
        verbose_name=_("Invite Code")
    )
    email = models.EmailField(
        blank=True,
        null=True,
        verbose_name=_("Email")
    )
    used = models.BooleanField(
        default=False,
        verbose_name=_("Used")
    )
    created_by = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='created_invites',
        verbose_name=_("Created By")
    )
    created = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Created")
    )
    used_at = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name=_("Used At")
    )
    used_by = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        related_name='redeemed_invites',
        verbose_name=_("Used By")
    )

    class Meta:
        verbose_name = _("Invite Code")
        verbose_name_plural = _("Invite Codes")
        ordering = ['-created']

    def __str__(self):
        return f"{self.code} - {self.group.name}"


class Market(models.Model):
    STATUS_CHOICES = [
        ('draft', _('Draft')),
        ('active', _('Active')),
        ('closed', _('Closed')),
        ('resolved', _('Resolved')),
    ]

    RESOLUTION_CHOICES = [
        ('yes', _('Yes')),
        ('no', _('No')),
        ('cancelled', _('Cancelled')),
    ]

    CONTENT_LANGUAGE_CHOICES = User.LANGUAGE_CHOICES

    group = models.ForeignKey(
        Group,
        on_delete=models.CASCADE,
        related_name='markets',
        verbose_name=_("Group")
    )
    creator = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='created_markets',
        verbose_name=_("Creator")
    )
    resolver = models.ForeignKey(
        User,
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        related_name='resolvable_markets',
        verbose_name=_("Resolver")
    )
    title = models.CharField(
        max_length=500,
        verbose_name=_("Title")
    )
    description = models.TextField(
        verbose_name=_("Description")
    )
    resolution_criteria = models.TextField(
        verbose_name=_("Resolution Criteria")
    )
    deadline_dates = models.JSONField(
        verbose_name=_("Deadline Dates")
    )
    close_date = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name=_("Close Date")
    )
    status = models.CharField(
        max_length=20,
        choices=STATUS_CHOICES,
        default='draft',
        verbose_name=_("Status")
    )
    resolution = models.CharField(
        max_length=20,
        choices=RESOLUTION_CHOICES,
        blank=True,
        null=True,
        verbose_name=_("Resolution")
    )
    resolution_date = models.DateField(
        blank=True,
        null=True,
        verbose_name=_("Resolution Date")
    )
    resolved_at = models.DateTimeField(
        blank=True,
        null=True,
        verbose_name=_("Resolved At")
    )
    content_language = models.CharField(
        max_length=2,
        choices=CONTENT_LANGUAGE_CHOICES,
        default='en',
        verbose_name=_("Content Language")
    )
    created = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Created")
    )

    class Meta:
        verbose_name = _("Market")
        verbose_name_plural = _("Markets")
        ordering = ['-created']

    def __str__(self):
        return self.title


class Bet(models.Model):
    OUTCOME_CHOICES = [
        ('yes', _('Yes')),
        ('no', _('No')),
    ]

    market = models.ForeignKey(
        Market,
        on_delete=models.CASCADE,
        related_name='bets',
        verbose_name=_("Market")
    )
    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='bets',
        verbose_name=_("User")
    )
    deadline_date = models.DateField(
        verbose_name=_("Deadline Date")
    )
    outcome = models.CharField(
        max_length=3,
        choices=OUTCOME_CHOICES,
        verbose_name=_("Outcome")
    )
    amount = models.IntegerField(
        verbose_name=_("Amount")
    )
    shares_received = models.IntegerField(
        default=0,
        verbose_name=_("Shares Received")
    )
    created = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Created")
    )

    class Meta:
        verbose_name = _("Bet")
        verbose_name_plural = _("Bets")
        ordering = ['-created']
        unique_together = ['market', 'user', 'deadline_date', 'outcome']

    def __str__(self):
        return f"{self.user.username} - {self.market.title} - {self.amount}"


class Transaction(models.Model):
    TRANSACTION_TYPES = [
        ('bet', _('Bet')),
        ('win', _('Win')),
        ('loss', _('Loss')),
        ('stipend', _('Stipend')),
        ('adjustment', _('Adjustment')),
    ]

    user = models.ForeignKey(
        User,
        on_delete=models.CASCADE,
        related_name='transactions',
        verbose_name=_("User")
    )
    group = models.ForeignKey(
        Group,
        on_delete=models.CASCADE,
        related_name='transactions',
        verbose_name=_("Group")
    )
    amount = models.IntegerField(
        verbose_name=_("Amount")
    )
    transaction_type = models.CharField(
        max_length=20,
        choices=TRANSACTION_TYPES,
        verbose_name=_("Transaction Type")
    )
    related_market = models.ForeignKey(
        Market,
        on_delete=models.SET_NULL,
        blank=True,
        null=True,
        related_name='transactions',
        verbose_name=_("Related Market")
    )
    related_deadline_date = models.DateField(
        blank=True,
        null=True,
        verbose_name=_("Related Deadline Date")
    )
    created = models.DateTimeField(
        auto_now_add=True,
        verbose_name=_("Created")
    )

    class Meta:
        verbose_name = _("Transaction")
        verbose_name_plural = _("Transactions")
        ordering = ['-created']

    def __str__(self):
        return f"{self.user.username} - {self.transaction_type} - {self.amount}"