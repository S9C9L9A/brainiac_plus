#!/bin/bash

# Test Integrazione Instagram per BrainiacPlus
# Verifica connessione e recupera metriche

TOKEN="${1:-EAAd3zUKn7ToBQih7VAB8uK9QNegVHDis0yFPmJTvNH068GX2pxLnEumRhMsOWa44H2glo1LdE5WtrGBqGEwQZBLNHJqxMUKMP31KyTnxf32utRjMVQROoZAzh2lzLBItEfENahn9MBVGgjjv6vfsPJbZCLdYNUTTFpad7i1D84mqBhIWdhZBaWUk9UHaUpmD7ZBlUkchkioVdZBirfGvdEMrEv}"
PAGE_ID="113132123896705"

echo "=========================================="
echo "📸 Instagram Integration Test"
echo "=========================================="
echo ""

if [ "$1" = "" ]; then
    echo "ℹ️  Usando token di default. Puoi passare un altro token:"
    echo "   $0 'tuo_token_qui'"
    echo ""
fi

# Test 1: Verifica token valido
echo "1️⃣ Test Token Facebook"
echo "----------------------------------------"
FB_USER=$(curl -s "https://graph.facebook.com/v18.0/me?access_token=$TOKEN")
FB_ERROR=$(echo "$FB_USER" | jq -r '.error.message // "none"')

if [ "$FB_ERROR" != "none" ]; then
    echo "❌ Token non valido: $FB_ERROR"
    exit 1
else
    FB_NAME=$(echo "$FB_USER" | jq -r '.name')
    echo "✅ Token valido per: $FB_NAME"
fi
echo ""

# Test 2: Verifica pagina Facebook
echo "2️⃣ Test Pagina Facebook"
echo "----------------------------------------"
PAGE_INFO=$(curl -s "https://graph.facebook.com/v18.0/$PAGE_ID?fields=id,name,category&access_token=$TOKEN")
PAGE_NAME=$(echo "$PAGE_INFO" | jq -r '.name')
PAGE_ERROR=$(echo "$PAGE_INFO" | jq -r '.error.message // "none"')

if [ "$PAGE_ERROR" != "none" ]; then
    echo "❌ Errore recupero pagina: $PAGE_ERROR"
    exit 1
else
    echo "✅ Pagina trovata: $PAGE_NAME"
fi
echo ""

# Test 3: Cerca Instagram Business Account
echo "3️⃣ Test Instagram Business Account"
echo "----------------------------------------"
IG_DATA=$(curl -s "https://graph.facebook.com/v18.0/$PAGE_ID?fields=instagram_business_account&access_token=$TOKEN")
IG_ACCOUNT_ID=$(echo "$IG_DATA" | jq -r '.instagram_business_account.id // "null"')

if [ "$IG_ACCOUNT_ID" = "null" ]; then
    echo "⚠️  Nessun account Instagram Business collegato a questa pagina!"
    echo ""
    echo "📝 Per collegare Instagram:"
    echo "   1. Vai su Facebook → $PAGE_NAME (pagina)"
    echo "   2. Impostazioni → Instagram"
    echo "   3. Clicca 'Collega account Instagram'"
    echo "   4. Accedi con il tuo account Instagram Business"
    echo ""
    echo "ℹ️  Se non hai un account Instagram Business:"
    echo "   1. Apri Instagram app"
    echo "   2. Profilo → Menu → Impostazioni"
    echo "   3. Account → Passa a account professionale"
    echo "   4. Scegli 'Business'"
    echo ""
    exit 0
fi

echo "✅ Instagram Business Account trovato!"
echo "   ID: $IG_ACCOUNT_ID"
echo ""

# Test 4: Info account Instagram
echo "4️⃣ Info Account Instagram"
echo "----------------------------------------"
IG_INFO=$(curl -s "https://graph.facebook.com/v18.0/$IG_ACCOUNT_ID?fields=id,username,name,followers_count,follows_count,media_count,profile_picture_url,biography&access_token=$TOKEN")
IG_ERROR=$(echo "$IG_INFO" | jq -r '.error.message // "none"')

if [ "$IG_ERROR" != "none" ]; then
    echo "❌ Errore: $IG_ERROR"
    echo ""
    echo "Possibili cause:"
    echo "  • Token non ha permesso 'instagram_basic'"
    echo "  • Account Instagram non è Business/Creator"
    echo ""
    echo "Permessi necessari:"
    echo "  - instagram_basic"
    echo "  - instagram_manage_insights"
    echo ""
    echo "Genera nuovo token con questi permessi:"
    echo "  https://developers.facebook.com/tools/explorer/"
    exit 1
fi

IG_USERNAME=$(echo "$IG_INFO" | jq -r '.username')
IG_FOLLOWERS=$(echo "$IG_INFO" | jq -r '.followers_count')
IG_FOLLOWING=$(echo "$IG_INFO" | jq -r '.follows_count')
IG_POSTS=$(echo "$IG_INFO" | jq -r '.media_count')

echo "✅ Account Instagram:"
echo "   Username: @$IG_USERNAME"
echo "   Followers: $IG_FOLLOWERS"
echo "   Following: $IG_FOLLOWING"
echo "   Posts: $IG_POSTS"
echo ""

# Test 5: Post recenti
echo "5️⃣ Post Recenti"
echo "----------------------------------------"
IG_MEDIA=$(curl -s "https://graph.facebook.com/v18.0/$IG_ACCOUNT_ID/media?fields=id,caption,media_type,timestamp,like_count,comments_count&limit=5&access_token=$TOKEN")
MEDIA_COUNT=$(echo "$IG_MEDIA" | jq '.data | length')

if [ "$MEDIA_COUNT" -gt 0 ]; then
    echo "✅ Trovati $MEDIA_COUNT post recenti:"
    echo ""
    echo "$IG_MEDIA" | jq -r '.data[] | "   📸 \(.media_type) - ❤️  \(.like_count) 💬 \(.comments_count)\n      \(.caption[0:50])...\n      \(.timestamp)\n"'
else
    echo "ℹ️  Nessun post trovato"
fi
echo ""

# Test 6: Calcola metriche
echo "6️⃣ Metriche Engagement"
echo "----------------------------------------"

TOTAL_LIKES=$(echo "$IG_MEDIA" | jq '[.data[].like_count] | add // 0')
TOTAL_COMMENTS=$(echo "$IG_MEDIA" | jq '[.data[].comments_count] | add // 0')
TOTAL_ENGAGEMENT=$((TOTAL_LIKES + TOTAL_COMMENTS))
ENGAGEMENT_RATE=$(echo "scale=2; $TOTAL_ENGAGEMENT / $IG_FOLLOWERS * 100" | bc 2>/dev/null || echo "0")

echo "   Total Likes: $TOTAL_LIKES"
echo "   Total Comments: $TOTAL_COMMENTS"
echo "   Total Engagement: $TOTAL_ENGAGEMENT"
echo "   Engagement Rate: ${ENGAGEMENT_RATE}%"
echo ""

# Test 7: Verifica permessi
echo "7️⃣ Verifica Permessi Token"
echo "----------------------------------------"
PERMS=$(curl -s "https://graph.facebook.com/v18.0/me/permissions?access_token=$TOKEN")
HAS_IG_BASIC=$(echo "$PERMS" | jq -r '.data[] | select(.permission == "instagram_basic") | .status' 2>/dev/null)
HAS_IG_INSIGHTS=$(echo "$PERMS" | jq -r '.data[] | select(.permission == "instagram_manage_insights") | .status' 2>/dev/null)
HAS_IG_PUBLISH=$(echo "$PERMS" | jq -r '.data[] | select(.permission == "instagram_content_publish") | .status' 2>/dev/null)

if [ "$HAS_IG_BASIC" = "granted" ]; then
    echo "   ✅ instagram_basic"
else
    echo "   ❌ instagram_basic (mancante)"
fi

if [ "$HAS_IG_INSIGHTS" = "granted" ]; then
    echo "   ✅ instagram_manage_insights"
else
    echo "   ⚠️  instagram_manage_insights (opzionale per analytics)"
fi

if [ "$HAS_IG_PUBLISH" = "granted" ]; then
    echo "   ✅ instagram_content_publish"
else
    echo "   ⚠️  instagram_content_publish (opzionale per pubblicazione)"
fi
echo ""

# Riepilogo e configurazione
echo "=========================================="
echo "✅ Test Completato!"
echo "=========================================="
echo ""

if [ "$IG_ACCOUNT_ID" != "null" ] && [ "$IG_ERROR" = "none" ]; then
    echo "🎉 Instagram è configurato e funzionante!"
    echo ""
    echo "📊 Dati da usare in BrainiacPlus:"
    echo ""
    echo "SocialMediaService("
    echo "  id: 'ig_1',"
    echo "  platform: SocialPlatform.instagram,"
    echo "  name: '$IG_USERNAME',"
    echo "  pageId: '$IG_ACCOUNT_ID',"
    echo "  accessToken: 'tuo_token',"
    echo "  isConfigured: true,"
    echo "  isActive: true,"
    echo "  metrics: SocialMediaMetrics("
    echo "    followers: $IG_FOLLOWERS,"
    echo "    posts: $IG_POSTS,"
    echo "    engagement: $TOTAL_ENGAGEMENT,"
    echo "    likes: $TOTAL_LIKES,"
    echo "    comments: $TOTAL_COMMENTS,"
    echo "    engagementRate: $ENGAGEMENT_RATE,"
    echo "  ),"
    echo ")"
    echo ""
    
    # Salva config
    cat > /tmp/instagram_config.json << EOF
{
  "instagram_account_id": "$IG_ACCOUNT_ID",
  "username": "$IG_USERNAME",
  "followers": $IG_FOLLOWERS,
  "following": $IG_FOLLOWING,
  "posts": $IG_POSTS,
  "total_likes": $TOTAL_LIKES,
  "total_comments": $TOTAL_COMMENTS,
  "engagement_rate": $ENGAGEMENT_RATE,
  "facebook_page_id": "$PAGE_ID",
  "token": "$TOKEN"
}
EOF
    
    echo "💾 Configurazione salvata in: /tmp/instagram_config.json"
    echo ""
    echo "🚀 Prossimi passi:"
    echo "   1. Apri: lib/features/dashboard/controllers/social_media_controller.dart"
    echo "   2. Aggiungi il servizio Instagram (copia il codice sopra)"
    echo "   3. Riavvia l'app Flutter"
    echo "   4. Vedrai la card Instagram nella dashboard!"
    echo ""
else
    echo "⚠️  Configurazione Instagram incompleta"
    echo ""
    echo "Leggi la guida completa:"
    echo "   cat INSTAGRAM_SETUP_GUIDE.md"
    echo ""
fi

echo "=========================================="
