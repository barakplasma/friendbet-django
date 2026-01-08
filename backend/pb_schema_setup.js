// PocketBase Collection Setup for FriendBet
// This file defines the database schema as per PRD requirements
// Load this in PocketBase Admin UI > Settings > Import Collections

const collections = [
  {
    "name": "groups",
    "type": "base",
    "schema": [
      {
        "name": "name",
        "type": "text",
        "required": true,
        "options": {
          "min": 3,
          "max": 100
        }
      },
      {
        "name": "admin_ids",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "users",
          "maxSelect": 5,
          "displayFields": ["username", "email"]
        }
      },
      {
        "name": "default_language",
        "type": "select",
        "required": true,
        "options": {
          "values": ["he", "en"],
          "default": "en"
        }
      }
    ]
  },
  {
    "name": "group_memberships",
    "type": "base",
    "schema": [
      {
        "name": "user_id",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "users",
          "maxSelect": 1,
          "displayFields": ["username", "email"]
        }
      },
      {
        "name": "group_id",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "groups",
          "maxSelect": 1,
          "displayFields": ["name"]
        }
      },
      {
        "name": "points_balance",
        "type": "number",
        "required": true,
        "options": {
          "min": -999999,
          "default": 1000
        }
      },
      {
        "name": "joined_at",
        "type": "date",
        "required": true,
        "options": {
          "default": "now"
        }
      }
    ]
  },
  {
    "name": "invite_codes",
    "type": "base",
    "schema": [
      {
        "name": "group_id",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "groups",
          "maxSelect": 1,
          "displayFields": ["name"]
        }
      },
      {
        "name": "code",
        "type": "text",
        "required": true,
        "options": {
          "min": 8,
          "max": 50,
          "pattern": "^[a-zA-Z0-9_-]+$"
        }
      },
      {
        "name": "email",
        "type": "email",
        "required": false,
        "options": {}
      },
      {
        "name": "used",
        "type": "bool",
        "required": true,
        "options": {
          "default": false
        }
      },
      {
        "name": "created_by",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "users",
          "maxSelect": 1,
          "displayFields": ["username"]
        }
      },
      {
        "name": "used_at",
        "type": "date",
        "required": false,
        "options": {}
      },
      {
        "name": "used_by",
        "type": "relation",
        "required": false,
        "options": {
          "collectionId": "users",
          "maxSelect": 1,
          "displayFields": ["username"]
        }
      }
    ]
  },
  {
    "name": "markets",
    "type": "base",
    "schema": [
      {
        "name": "group_id",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "groups",
          "maxSelect": 1,
          "displayFields": ["name"]
        }
      },
      {
        "name": "creator_id",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "users",
          "maxSelect": 1,
          "displayFields": ["username"]
        }
      },
      {
        "name": "resolver_id",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "users",
          "maxSelect": 1,
          "displayFields": ["username"]
        }
      },
      {
        "name": "title",
        "type": "text",
        "required": true,
        "options": {
          "min": 5,
          "max": 200
        }
      },
      {
        "name": "description",
        "type": "editor",
        "required": true,
        "options": {}
      },
      {
        "name": "resolution_criteria",
        "type": "text",
        "required": true,
        "options": {
          "min": 10,
          "max": 1000
        }
      },
      {
        "name": "deadline_dates",
        "type": "json",
        "required": true,
        "options": {}
      },
      {
        "name": "close_date",
        "type": "date",
        "required": true,
        "options": {}
      },
      {
        "name": "status",
        "type": "select",
        "required": true,
        "options": {
          "values": ["draft", "active", "closed", "resolved"],
          "default": "draft"
        }
      },
      {
        "name": "resolution",
        "type": "select",
        "required": false,
        "options": {
          "values": ["yes", "no", "cancelled"]
        }
      },
      {
        "name": "resolution_date",
        "type": "date",
        "required": false,
        "options": {}
      },
      {
        "name": "resolved_at",
        "type": "date",
        "required": false,
        "options": {}
      },
      {
        "name": "content_language",
        "type": "select",
        "required": true,
        "options": {
          "values": ["he", "en"],
          "default": "en"
        }
      }
    ]
  },
  {
    "name": "bets",
    "type": "base",
    "schema": [
      {
        "name": "market_id",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "markets",
          "maxSelect": 1,
          "displayFields": ["title"]
        }
      },
      {
        "name": "user_id",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "users",
          "maxSelect": 1,
          "displayFields": ["username"]
        }
      },
      {
        "name": "deadline_date",
        "type": "date",
        "required": true,
        "options": {}
      },
      {
        "name": "outcome",
        "type": "select",
        "required": true,
        "options": {
          "values": ["yes", "no"]
        }
      },
      {
        "name": "amount",
        "type": "number",
        "required": true,
        "options": {
          "min": 10
        }
      },
      {
        "name": "shares_received",
        "type": "number",
        "required": true,
        "options": {
          "min": 0
        }
      }
    ]
  },
  {
    "name": "transactions",
    "type": "base",
    "schema": [
      {
        "name": "user_id",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "users",
          "maxSelect": 1,
          "displayFields": ["username"]
        }
      },
      {
        "name": "group_id",
        "type": "relation",
        "required": true,
        "options": {
          "collectionId": "groups",
          "maxSelect": 1,
          "displayFields": ["name"]
        }
      },
      {
        "name": "amount",
        "type": "number",
        "required": true,
        "options": {}
      },
      {
        "name": "type",
        "type": "select",
        "required": true,
        "options": {
          "values": ["bet", "win", "loss", "stipend", "adjustment"]
        }
      },
      {
        "name": "related_market_id",
        "type": "relation",
        "required": false,
        "options": {
          "collectionId": "markets",
          "maxSelect": 1,
          "displayFields": ["title"]
        }
      },
      {
        "name": "related_deadline_date",
        "type": "date",
        "required": false,
        "options": {}
      }
    ]
  }
];

// Instructions for setting up collections in PocketBase Admin UI:
console.log("To set up these collections:");
console.log("1. Access PocketBase Admin UI at http://localhost:8090/_/");
console.log("2. Go to Settings > Import Collections");
console.log("3. Copy the collections array and paste it into the import field");
console.log("4. Or manually create each collection using the schema definitions above");