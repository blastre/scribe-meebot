# Scribe Client Python

[![PyPI version](https://badge.fury.io/py/scribe-client.svg)](https://badge.fury.io/py/scribe-client)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python 3.7+](https://img.shields.io/badge/python-3.7+-blue.svg)](https://www.python.org/downloads/)

🚀 **Build Meeting Assistants in Hours, Not Months**

A Python client library for Scribe - the privacy-first, open-source API for real-time meeting transcription. Build powerful meeting assistants with just a few lines of code. 


repo https://github.com/blastre/scribe-meetbot

## ✨ Features

- 🤖 **Meeting Bots**: Send bots to automatically join Google Meet, (Zoom, Teams coming soon)
- ⚡ **Real-time**: Get transcripts as meetings happen, not after
- 🌍 **109 Languages**: Real-time transcription and translation across all of them
- 🧠 **Auto Language Detection**: No language setup needed - Scribe automatically detects what's being spoken
- 🔄 **Real-time Translation**: Choose any target language for instant translation instead of transcription
- 🔔 **Webhook Automation**: Get notified instantly when meetings end for seamless post-meeting workflows
- 🔒 **Privacy-First**: Open-source alternative to recall.ai - your data stays under your control
- 🚀 **Rapid Development**: Build complex meeting apps in hours
- 🎯 **Simple API**: Clean abstractions that make building on top a joy

## 🛠️ What You Can Build

Transform your ideas into reality with Scribe's powerful API:

- **Meeting Assistant Apps**: Like Otter.ai, Fireflies.ai, Fathom
- **CRM Integrations**: Auto-populate meeting notes in Salesforce, HubSpot
- **Compliance Tools**: Automatically record and transcribe important business calls
- **Language Learning**: Real-time translation for international meetings
- **Accessibility Tools**: Live captions for hearing-impaired participants
- **Analytics Dashboards**: Extract insights from meeting conversations


## 📋 API Operations Overview

### 🎯 User Operations
These are the primary operations for API users who want to integrate Scribe's transcription capabilities into their applications. This includes bot management, accessing transcripts, and configuring webhooks.

### 🔧 Admin Operations (Self-hosting only)
These operations are exclusively for users who self-host Scribe and need to manage user accounts, create API tokens, and perform administrative tasks. Most API users will not need these operations.

## 🚀 Get Started in 5 Minutes

### 1. Get Your API Key
Get your API key in 3 clicks from your transcription provider - no waiting, no approval process!

### 2. Install the Client

```bash
pip install scribe-client
```



## 🎯 Quick Start Example

```python
from scribe_client import ScribeClient

# Initialize the client
client = ScribeClient(
    api_key="your-api-key-here",            # For user operations
)

meeting_id = "abc-def-ghi"

# Request a bot to join a meeting
meeting = client.request_bot(
    platform="google_meet",
    native_meeting_id=meeting_id,
    bot_name="Scribe Bot",
    language="en"  # Optional - auto-detected if not provided
)

# get meeting transcript during or after the meeting

# Option 1: Get latest meeting by platform + native_meeting_id (backward compatible)
transcript = client.get_transcript("google_meet", "abc-defg-hij")

# Option 2: Get specific meeting by database ID (new feature)
transcript = client.get_transcript("google_meet", "abc-defg-hij", meeting_id=123)


# switch to translation to a different language instead of transcription during meeting
client.update_bot_config(
    platform="google_meet",
    native_meeting_id=meeting_id,
    language='es'
)


#stop the bot
client.stop_bot(platform="google_meet",native_meeting_id=meeting_id)

# delete meeting transcription for scribe
client.delete_meeting(
    platform="google_meet",
    native_meeting_id=meeting_id,
)
```

## 🌍 Language Detection & Translation Workflows

### Auto Language Detection
```python
# No language specified - Scribe automatically detects what's being spoken
meeting = client.request_bot(
    platform="google_meet",
    native_meeting_id="abc-def-ghi",
    bot_name="Smart Bot"
    # language not specified - auto-detection enabled!
)
```

### 📝 Transcription in Specific Language
```python
# Transcribe in specific language (if you know what will be spoken)
meeting = client.request_bot(
    platform="google_meet",
    native_meeting_id="abc-def-ghi",
    language="es",  # Spanish transcription
    task="transcribe"
)
```

### 🔄 Real-time Translation
```python
# Translate everything to English in real-time
meeting = client.request_bot(
    platform="google_meet",
    native_meeting_id="abc-def-ghi",
    language="pt",  # Target language (Portuguese)
    task="translate"  # Translation mode
)
```

## 🔔 Webhook Automation for Post-Meeting Workflows

Set up webhooks to get notified instantly when meetings end - perfect for automated post-meeting processing:

```python
# Set up webhook to receive meeting completion notifications
client.set_webhook_url("https://your-server.com/webhook/scribe")
```


## 📚 Full API Reference https://github.com/blastre/scribe-meetbot/blob/main/docs/user_api_guide.md


### User Profile

#### `set_webhook_url(webhook_url)`
Set the webhook URL for the authenticated user.

### Admin Operations (Self-hosting Only)

⚠️ **Note**: Admin operations are only available for self-hosted Scribe deployments. Most API users will only need the User Operations above.

#### `create_user(email, name=None, image_url=None, max_concurrent_bots=None)`
Create a new user (Self-hosting admin only).

#### `list_users(skip=0, limit=100)`
List users in the system (Self-hosting admin only).

#### `update_user(user_id, name=None, image_url=None, max_concurrent_bots=None)`
Update user information (Self-hosting admin only).

#### `get_user_by_email(email)`
Retrieve a user by email address (Self-hosting admin only).

#### `create_token(user_id)`
Generate a new API token for a user (Self-hosting admin only).

## 📋 Requirements

- Python 3.7+
- requests >= 2.25.0



## Support

- **Issues** — [github.com/blastre/scribe-meetbot/issues](https://github.com/blastre/scribe-meetbot/issues)
- **Docs** — see [`docs/`](../../docs) in the main repository

## License

Apache License 2.0 — see [LICENSE](../../LICENSE) and [NOTICE](../../NOTICE).
