# 📱 Instagram Content Automation - Complete Guide

## 🎯 Overview

**Automated Instagram Content Generation & Publishing System**

This automation generates AI-powered photos/videos using **Higgsfield** and publishes them to **Instagram** on a schedule.

---

## ✅ Features Created

### 1. **Services** (`lib/core/services/`)

#### Higgsfield Service
**File**: `higgsfield_service.dart`

**Capabilities**:
- ✅ Generate images from text prompts
- ✅ Generate videos/Reels from text prompts
- ✅ AI-powered caption generation
- ✅ Multiple styles: realistic, artistic, cinematic, cartoon, anime, vintage
- ✅ Custom aspect ratios (1:1 for posts, 9:16 for Reels)
- ✅ Async job tracking
- ✅ Content download

**Example Usage**:
```dart
final service = HiggsfieldService(apiKey: 'YOUR_API_KEY');

// Generate image
final image = await service.generateImage(
  prompt: 'A stunning sunset over mountains',
  style: 'realistic',
  aspectRatio: '1:1',
);

// Generate video
final video = await service.generateVideo(
  prompt: 'Time-lapse of city lights at night',
  duration: 15,
  style: 'cinematic',
  aspectRatio: '9:16',
);

// Generate caption
final caption = await service.generateCaption(
  contentDescription: 'Sunset mountains',
  tone: 'engaging',
  hashtags: ['nature', 'sunset', 'mountains'],
);
```

#### Instagram Service
**File**: `instagram_service.dart`

**Capabilities**:
- ✅ Upload photos
- ✅ Upload videos/Reels
- ✅ Upload carousels (multiple photos)
- ✅ Auto-caption
- ✅ Hashtags support
- ✅ Location tagging
- ✅ Media insights/analytics
- ✅ Profile information

**Example Usage**:
```dart
final service = InstagramService(
  accessToken: 'YOUR_ACCESS_TOKEN',
  userId: 'YOUR_USER_ID',
);

// Upload photo
final mediaId = await service.uploadPhoto(
  imageFile: File('/path/to/image.jpg'),
  caption: 'Check out this amazing view! #nature',
);

// Upload Reel
final reelId = await service.uploadVideo(
  videoFile: File('/path/to/video.mp4'),
  caption: 'Day in my life ✨',
  isReel: true,
);

// Get insights
final insights = await service.getMediaInsights(mediaId);
print('Engagement: ${insights.engagement}');
```

---

### 2. **Models** (`lib/features/automation/models/`)

#### SocialMediaTask
**File**: `social_media_task.dart`

**Fields**:
- `name`: Task name
- `contentType`: Photo, Video, or Carousel
- `contentPrompt`: AI generation prompt
- `contentStyle`: Visual style (realistic, artistic, etc.)
- `videoDuration`: For videos (5-90 seconds)
- `caption`: Custom caption (optional)
- `hashtags`: List of hashtags
- `autoGenerateCaption`: Let AI write caption
- `platform`: Instagram, Facebook, TikTok, YouTube
- `schedule`: Cron expression
- `status`: Pending, Generating, Uploading, Completed, Failed

**Enums**:
```dart
enum ContentType { photo, video, carousel }
enum PublishPlatform { instagram, facebook, tiktok, youtube }
enum TaskStatus { pending, generating, uploading, completed, failed }
```

---

### 3. **Controllers** (`lib/features/automation/controllers/`)

#### SocialMediaController
**File**: `social_media_controller.dart`

**Functions**:
- `executeTask()`: Run automation workflow
- `addTask()`: Create new task
- `updateTask()`: Modify existing task
- `deleteTask()`: Remove task
- `toggleTask()`: Enable/disable task

**Workflow**:
```
1. Generate Content (Higgsfield) ⏳
2. Generate Caption (AI) ✍️
3. Download Content 📥
4. Upload to Instagram 📲
5. Complete ✅
```

---

### 4. **UI** (`lib/features/automation/screens/`)

#### CreateSocialMediaTaskScreen
**File**: `create_social_media_task_screen.dart`

**Sections**:
1. **Basic Info**
   - Task name
   - Schedule (cron syntax)

2. **Content Generation**
   - Content type selector (Photo/Video/Carousel)
   - AI prompt input
   - Style selector (6 styles)
   - Video duration slider (5-90s)

3. **Caption & Hashtags**
   - Auto-generate caption toggle
   - Custom caption input
   - Hashtags input

4. **Publishing**
   - Platform selector (Instagram focus)

---

## 🚀 Setup Guide

### Step 1: Get Higgsfield API Key

1. Go to https://higgsfield.ai
2. Create account
3. Generate API key
4. Add to app settings

### Step 2: Connect Instagram

1. Create Facebook Developer App
2. Add Instagram Basic Display or Instagram Graph API
3. Get Access Token & User ID
4. Authenticate in BrainiacPlus

### Step 3: Create Your First Automation

1. Open BrainiacPlus → **Automation**
2. Click **"New Social Media Task"**
3. Fill in:
   - **Name**: "Daily Motivation Post"
   - **Schedule**: `0 9 * * *` (Daily at 9 AM)
   - **Content Type**: Photo
   - **Prompt**: "Inspirational quote on a gradient background"
   - **Style**: artistic
   - **Hashtags**: motivation,inspiration,mindset
   - **Platform**: Instagram
4. Click **Create Task**

### Step 4: Test Manually

Before scheduling, test the task:
```dart
final controller = ref.read(socialMediaControllerProvider.notifier);
await controller.executeTask(task);
```

---

## 📊 Cron Schedule Examples

```
0 9 * * *     # Daily at 9:00 AM
0 */6 * * *   # Every 6 hours
0 12 * * 1    # Every Monday at noon
0 18 * * 1-5  # Weekdays at 6 PM
*/30 * * * *  # Every 30 minutes
```

---

## 🎨 Content Prompt Examples

### Photos
```
"Minimalist workspace with laptop and coffee"
"Vibrant sunset over ocean with palm trees"
"Fitness motivation: person running at sunrise"
"Healthy breakfast bowl with fruits and granola"
"Modern architecture with geometric patterns"
```

### Videos/Reels
```
"Time-lapse of clouds moving over cityscape"
"Close-up of latte art being poured"
"Smooth camera pan across mountain landscape"
"Product showcase with 360-degree rotation"
"Day-to-night transition of urban skyline"
```

### Carousels
```
"3-slide transformation before/after/tips"
"Step-by-step recipe with ingredients"
"Travel photo series from beach vacation"
"Product lineup with different color variants"
```

---

## 🎯 Best Practices

### Content Strategy
- ✅ Post consistently (1-3 times/day)
- ✅ Mix content types (60% photos, 30% Reels, 10% carousels)
- ✅ Use trending hashtags (research monthly)
- ✅ Engage within first hour of posting
- ✅ Analyze insights weekly

### AI Prompts
- ✅ Be specific about style and mood
- ✅ Include key elements (colors, objects, setting)
- ✅ Mention desired lighting and composition
- ✅ Specify aspect ratio requirements
- ✅ Test variations to find what works

### Hashtags
- ✅ Use 15-30 hashtags
- ✅ Mix sizes: 5 large (1M+), 10 medium (100K-1M), 10 small (<100K)
- ✅ Include branded hashtags
- ✅ Avoid banned hashtags
- ✅ Rotate hashtag sets

---

## 🔐 Security

### API Keys
Store securely in environment variables or encrypted storage:
```dart
// DO NOT hardcode in source!
final higgsfieldKey = dotenv.env['HIGGSFIELD_API_KEY'];
final instaToken = await SecureStorage.read('instagram_token');
```

### Instagram Access Tokens
- Short-lived: 1 hour (requires refresh)
- Long-lived: 60 days (auto-refresh recommended)
- User token vs Page token (different permissions)

---

## 📈 Future Enhancements

### Phase 2
- [ ] Multi-platform publishing (TikTok, YouTube, Facebook)
- [ ] Content calendar visualization
- [ ] A/B testing for captions
- [ ] Auto-reply to comments
- [ ] Story automation

### Phase 3
- [ ] Analytics dashboard
- [ ] Competitor analysis
- [ ] Hashtag performance tracking
- [ ] Optimal posting time prediction
- [ ] User-generated content sourcing

### Phase 4
- [ ] Influencer collaboration tools
- [ ] Ad campaign automation
- [ ] E-commerce integration
- [ ] Live video scheduling
- [ ] Advanced filters and effects

---

## 🐛 Troubleshooting

### "Higgsfield API not configured"
**Solution**: Add API key in settings or initialize service with key

### "Instagram not connected"
**Solution**: Complete OAuth flow and store access token

### "Video processing timeout"
**Solution**: Check video format (MP4), size (<100MB), duration (<90s)

### "Caption too long"
**Solution**: Instagram limit is 2,200 characters

### "Invalid hashtags"
**Solution**: Remove spaces, special characters, banned tags

---

## 📚 API Documentation

- **Higgsfield**: https://docs.higgsfield.ai
- **Instagram Graph API**: https://developers.facebook.com/docs/instagram-api
- **Cron Syntax**: https://crontab.guru

---

## ✅ Checklist Before Going Live

- [ ] Higgsfield API key configured
- [ ] Instagram authenticated
- [ ] Test task created and executed successfully
- [ ] Captions and hashtags reviewed
- [ ] Schedule verified (correct timezone)
- [ ] Backup content prepared (in case AI fails)
- [ ] Error notifications enabled
- [ ] Content moderation enabled (optional)

---

**Created by**: Automation Agent
**Date**: 2026-02-13
**Status**: ✅ Ready for Testing
