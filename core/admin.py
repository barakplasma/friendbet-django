from django.contrib import admin
from .models import User, Group, GroupMembership, InviteCode, Market, Bet, Transaction


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ['username', 'email', 'preferred_language', 'is_staff']
    list_filter = ['preferred_language', 'is_staff']
    search_fields = ['username', 'email']


@admin.register(Group)
class GroupAdmin(admin.ModelAdmin):
    list_display = ['name', 'default_language', 'created']
    list_filter = ['default_language', 'created']
    search_fields = ['name']
    filter_horizontal = ['admins']


@admin.register(GroupMembership)
class GroupMembershipAdmin(admin.ModelAdmin):
    list_display = ['user', 'group', 'points_balance', 'joined_at']
    list_filter = ['joined_at']
    search_fields = ['user__username', 'group__name']


@admin.register(InviteCode)
class InviteCodeAdmin(admin.ModelAdmin):
    list_display = ['code', 'group', 'email', 'used', 'created_by', 'created']
    list_filter = ['used', 'created']
    search_fields = ['code', 'email', 'group__name']


@admin.register(Market)
class MarketAdmin(admin.ModelAdmin):
    list_display = ['title', 'group', 'status', 'resolution', 'content_language', 'created']
    list_filter = ['status', 'resolution', 'content_language', 'created']
    search_fields = ['title', 'description', 'group__name']


@admin.register(Bet)
class BetAdmin(admin.ModelAdmin):
    list_display = ['market', 'user', 'deadline_date', 'outcome', 'amount', 'created']
    list_filter = ['outcome', 'deadline_date', 'created']
    search_fields = ['market__title', 'user__username']


@admin.register(Transaction)
class TransactionAdmin(admin.ModelAdmin):
    list_display = ['user', 'group', 'transaction_type', 'amount', 'created']
    list_filter = ['transaction_type', 'created']
    search_fields = ['user__username', 'group__name']
