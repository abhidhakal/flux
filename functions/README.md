# Flux AI Functions

This is the server-only boundary for Flux AI features. It uses
`gpt-5.6-luna` through the OpenAI Responses API for cost-sensitive,
high-volume insight generation.

The callable endpoint requires Firebase Authentication and accepts only a
small aggregate financial context. Do not send raw transactions, titles,
descriptions, document IDs, or user IDs to the provider.

Each authenticated user is limited to 20 requests per UTC day. Usage counts
are stored in the server-only `ai_usage` collection and are not accessible to
the Flutter client.

Before deployment, configure the secret:

```bash
firebase functions:secrets:set OPENAI_API_KEY --project flux-budget-tracking
```

The key belongs in Firebase Secret Manager—not `lib/`, Flutter assets,
`google-services.json`, `.env` files shipped with the app, or the Functions
source. The command above prompts for the value and stores it server-side.

Then install dependencies, build, and deploy from this directory:

```bash
npm install
npm run build
firebase deploy --only functions:generateFinancialInsight --project flux-budget-tracking
```

The Flutter client calls this endpoint only after the user confirms that
aggregate totals and category summaries may be sent. Raw transactions,
titles, descriptions, document IDs, and user IDs remain on the device.

## Subscription verification

`verifySubscriptionPurchase` verifies the purchase with Google Play or Apple
before writing `entitlements/{firebaseUid}`. The client cannot write that
collection. Configure these Firebase Secret Manager values before deploying
the verifier:

```bash
firebase functions:secrets:set GOOGLE_PLAY_SERVICE_ACCOUNT_JSON --project flux-budget-tracking
firebase functions:secrets:set APPLE_ISSUER_ID --project flux-budget-tracking
firebase functions:secrets:set APPLE_KEY_ID --project flux-budget-tracking
firebase functions:secrets:set APPLE_PRIVATE_KEY --project flux-budget-tracking
firebase functions:secrets:set APPLE_ROOT_CERTIFICATES --project flux-budget-tracking
firebase functions:secrets:set APPLE_APPLE_ID --project flux-budget-tracking
firebase functions:secrets:set APPLE_ENVIRONMENT --project flux-budget-tracking
```

`GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` is the complete JSON key for a Google
service account granted access to the Google Play Developer API. The Apple
private key is the `.p8` contents. `APPLE_ROOT_CERTIFICATES` is a JSON array
of base64-encoded Apple root certificate files. Set `APPLE_ENVIRONMENT` to
`sandbox` while testing and `production` for the live App Store; production
also requires the numeric App Store Connect app ID in `APPLE_APPLE_ID`.

Deploy the verifier and rules together after the store products are configured:

```bash
npm run build
firebase deploy --only functions:verifySubscriptionPurchase,firestore:rules --project flux-budget-tracking
```

Do not grant Pro from the Flutter purchase callback or from local preferences.
The callback only becomes an entitlement after the server verification
function succeeds.
