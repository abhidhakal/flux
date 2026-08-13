import {defineSecret} from "firebase-functions/params";
import {HttpsError, onCall} from "firebase-functions/v2/https";
import {initializeApp} from "firebase-admin/app";
import {getFirestore} from "firebase-admin/firestore";
import {google} from "googleapis";
import {
  AppStoreServerAPIClient,
  Environment as AppleEnvironment,
  SignedDataVerifier,
} from "@apple/app-store-server-library";

initializeApp();

const openAiApiKey = defineSecret("OPENAI_API_KEY");
const googlePlayServiceAccountJson = defineSecret("GOOGLE_PLAY_SERVICE_ACCOUNT_JSON");
const appleIssuerId = defineSecret("APPLE_ISSUER_ID");
const appleKeyId = defineSecret("APPLE_KEY_ID");
const applePrivateKey = defineSecret("APPLE_PRIVATE_KEY");
const appleRootCertificates = defineSecret("APPLE_ROOT_CERTIFICATES");
const appleAppAppleId = defineSecret("APPLE_APPLE_ID");
const appleEnvironment = defineSecret("APPLE_ENVIRONMENT");
const maxContextBytes = 12_000;
const dailyRequestLimit = 20;
const androidPackageName = "com.klivostudios.flux";
const subscriptionProductIds = new Set(["premium_monthly", "premium_yearly"]);

const insightSchema = {
  type: "object",
  additionalProperties: false,
  properties: {
    title: {type: "string"},
    summary: {type: "string"},
    actions: {
      type: "array",
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          label: {type: "string"},
          reason: {type: "string"},
        },
        required: ["label", "reason"],
      },
    },
    caution: {type: "string"},
  },
  required: ["title", "summary", "actions", "caution"],
} as const;

type FinancialContext = {
  currencyCode?: unknown;
  currencySymbol?: unknown;
  currencyDecimalPlaces?: unknown;
  income?: unknown;
  expenses?: unknown;
  net?: unknown;
  savingsRate?: unknown;
  categoryTotals?: unknown;
  activeBudgetCount?: unknown;
  atRiskBudgetCount?: unknown;
  activeGoalCount?: unknown;
  overdueGoalCount?: unknown;
};

function isObject(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function validateContext(value: unknown): FinancialContext {
  if (!isObject(value)) {
    throw new HttpsError("invalid-argument", "A financial context is required.");
  }

  const serialized = JSON.stringify(value);
  if (serialized.length > maxContextBytes) {
    throw new HttpsError("invalid-argument", "The financial context is too large.");
  }

  const allowedKeys = new Set([
    "version",
    "currencyCode",
    "currencySymbol",
    "currencyDecimalPlaces",
    "income",
    "expenses",
    "net",
    "savingsRate",
    "categoryTotals",
    "activeBudgetCount",
    "atRiskBudgetCount",
    "activeGoalCount",
    "overdueGoalCount",
  ]);
  if (Object.keys(value).some((key) => !allowedKeys.has(key))) {
    throw new HttpsError("invalid-argument", "Unsupported financial context fields.");
  }

  const currencyCode = value.currencyCode;
  const currencySymbol = value.currencySymbol;
  const currencyDecimalPlaces = value.currencyDecimalPlaces;
  if (typeof currencyCode !== "string" ||
      !/^[A-Z]{3}$/.test(currencyCode) ||
      typeof currencySymbol !== "string" ||
      currencySymbol.length > 8 ||
      typeof currencyDecimalPlaces !== "number" ||
      !Number.isInteger(currencyDecimalPlaces) ||
      currencyDecimalPlaces < 0 || currencyDecimalPlaces > 2) {
    throw new HttpsError("invalid-argument", "Currency context is invalid.");
  }

  const numericFields = [
    "income",
    "expenses",
    "net",
    "savingsRate",
    "activeBudgetCount",
    "atRiskBudgetCount",
    "activeGoalCount",
    "overdueGoalCount",
  ];
  for (const field of numericFields) {
    const fieldValue = value[field];
    if (fieldValue !== undefined &&
        fieldValue !== null &&
        (typeof fieldValue !== "number" || !Number.isFinite(fieldValue))) {
      throw new HttpsError("invalid-argument", "Financial context contains invalid numbers.");
    }
  }

  const categoryTotals = value.categoryTotals;
  if (!isObject(categoryTotals) || Object.keys(categoryTotals).length > 50 ||
      Object.entries(categoryTotals).some(([category, amount]) =>
          category.length > 80 ||
          typeof amount !== "number" ||
          !Number.isFinite(amount) ||
          amount < 0)) {
    throw new HttpsError("invalid-argument", "Financial categories are invalid.");
  }

  return value as FinancialContext;
}

async function consumeDailyRequest(userId: string): Promise<void> {
  const date = new Date().toISOString().slice(0, 10);
  const reference = getFirestore().collection("ai_usage").doc(`${userId}_${date}`);

  await getFirestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(reference);
    const count = snapshot.exists ? (snapshot.data()?.count ?? 0) : 0;
    if (typeof count !== "number" || count >= dailyRequestLimit) {
      throw new HttpsError(
          "resource-exhausted", "Daily AI insight limit reached. Try again tomorrow.");
    }
    transaction.set(reference, {
      userId,
      date,
      count: count + 1,
      updatedAt: new Date().toISOString(),
    }, {merge: true});
  });
}

function extractOutputText(body: Record<string, unknown>): string | null {
  if (typeof body.output_text === "string") return body.output_text;
  const output = body.output;
  if (!Array.isArray(output)) return null;

  for (const item of output) {
    if (!isObject(item) || !Array.isArray(item.content)) continue;
    for (const content of item.content) {
      if (isObject(content) && typeof content.text === "string") {
        return content.text;
      }
    }
  }
  return null;
}

type VerifiedSubscription = {
  productId: string;
  expiresAt: Date;
  purchaseId: string;
  platform: "android" | "ios";
};

function requirePurchaseField(value: unknown, fieldName: string): string {
  if (typeof value !== "string" || value.length === 0 || value.length > 20_000) {
    throw new HttpsError("invalid-argument", `${fieldName} is invalid.`);
  }
  return value;
}

function getAppleEnvironment(): AppleEnvironment {
  return appleEnvironment.value().toLowerCase() === "production" ?
    AppleEnvironment.PRODUCTION : AppleEnvironment.SANDBOX;
}

async function verifyAndroidSubscription(
    purchaseToken: string, productId: string): Promise<VerifiedSubscription> {
  let serviceAccount: {client_email?: string; private_key?: string};
  try {
    serviceAccount = JSON.parse(googlePlayServiceAccountJson.value()) as {
      client_email?: string;
      private_key?: string;
    };
  } catch {
    throw new HttpsError("failed-precondition", "Google Play verification is not configured.");
  }

  if (!serviceAccount.client_email || !serviceAccount.private_key) {
    throw new HttpsError("failed-precondition", "Google Play verification is not configured.");
  }

  const auth = new google.auth.JWT({
    email: serviceAccount.client_email,
    key: serviceAccount.private_key,
    scopes: ["https://www.googleapis.com/auth/androidpublisher"],
  });
  const publisher = google.androidpublisher({version: "v3", auth});
  const response = await publisher.purchases.subscriptionsv2.get({
    packageName: androidPackageName,
    token: purchaseToken,
  });
  const subscription = response.data;
  const activeStates = new Set([
    "SUBSCRIPTION_STATE_ACTIVE",
    "SUBSCRIPTION_STATE_IN_GRACE_PERIOD",
  ]);
  if (!activeStates.has(subscription.subscriptionState ?? "")) {
    throw new HttpsError("permission-denied", "The Google Play subscription is not active.");
  }

  const lineItem = subscription.lineItems?.find((item) => item.productId === productId) ??
    subscription.lineItems?.[0];
  const expiryValue = lineItem?.expiryTime;
  if (!lineItem?.productId || !expiryValue) {
    throw new HttpsError("permission-denied", "The Google Play purchase is incomplete.");
  }
  const expiresAt = new Date(expiryValue);
  if (!Number.isFinite(expiresAt.getTime()) || expiresAt <= new Date()) {
    throw new HttpsError("permission-denied", "The Google Play subscription has expired.");
  }

  return {
    productId: lineItem.productId,
    expiresAt,
    purchaseId: purchaseToken,
    platform: "android",
  };
}

async function verifyAppleSubscription(
    transactionId: string, productId: string): Promise<VerifiedSubscription> {
  const environment = getAppleEnvironment();
  const issuerId = appleIssuerId.value();
  const keyId = appleKeyId.value();
  const privateKey = applePrivateKey.value();
  const bundleId = "com.klivostudios.flux";
  if (!issuerId || !keyId || !privateKey || !appleRootCertificates.value()) {
    throw new HttpsError("failed-precondition", "Apple verification is not configured.");
  }

  let rootCertificates: Buffer[];
  try {
    const encodedCertificates = JSON.parse(appleRootCertificates.value()) as unknown;
    if (!Array.isArray(encodedCertificates)) throw new Error("invalid certificates");
    rootCertificates = encodedCertificates.map((certificate) => {
      if (typeof certificate !== "string") throw new Error("invalid certificate");
      return Buffer.from(certificate, "base64");
    });
  } catch {
    throw new HttpsError("failed-precondition", "Apple root certificates are invalid.");
  }

  const client = new AppStoreServerAPIClient(
      privateKey,
      keyId,
      issuerId,
      bundleId,
      environment,
  );
  const response = await client.getTransactionInfo(transactionId);
  if (!response.signedTransactionInfo) {
    throw new HttpsError("permission-denied", "Apple returned no transaction details.");
  }

  const verifier = new SignedDataVerifier(
      rootCertificates,
      true,
      environment,
      bundleId,
      environment === AppleEnvironment.PRODUCTION ? Number(appleAppAppleId.value()) : undefined,
  );
  const transaction = await verifier.verifyAndDecodeTransaction(response.signedTransactionInfo);
  if (transaction.productId !== productId || transaction.bundleId !== bundleId) {
    throw new HttpsError("permission-denied", "The Apple purchase does not match Flux.");
  }
  if (!transaction.expiresDate || transaction.revocationDate) {
    throw new HttpsError("permission-denied", "The Apple subscription is not active.");
  }
  const expiresAt = new Date(transaction.expiresDate);
  if (!Number.isFinite(expiresAt.getTime()) || expiresAt <= new Date()) {
    throw new HttpsError("permission-denied", "The Apple subscription has expired.");
  }

  return {
    productId: transaction.productId,
    expiresAt,
    purchaseId: transaction.transactionId ?? transactionId,
    platform: "ios",
  };
}

export const verifySubscriptionPurchase = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 30,
    memory: "256MiB",
    maxInstances: 5,
    secrets: [
      googlePlayServiceAccountJson,
      appleIssuerId,
      appleKeyId,
      applePrivateKey,
      appleRootCertificates,
      appleAppAppleId,
      appleEnvironment,
    ],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in before verifying a subscription.");
    }

    const platform = request.data?.platform;
    if (platform !== "android" && platform !== "ios") {
      throw new HttpsError("invalid-argument", "A supported purchase platform is required.");
    }
    const productId = requirePurchaseField(request.data?.productId, "productId");
    if (!subscriptionProductIds.has(productId)) {
      throw new HttpsError("invalid-argument", "Unsupported subscription product.");
    }

    const verified = platform === "android" ?
      await verifyAndroidSubscription(
          requirePurchaseField(request.data?.purchaseToken, "purchaseToken"), productId) :
      await verifyAppleSubscription(
          requirePurchaseField(request.data?.transactionId, "transactionId"), productId);

    const entitlement = getFirestore().collection("entitlements").doc(request.auth.uid);
    await entitlement.set({
      userId: request.auth.uid,
      productId: verified.productId,
      platform: verified.platform,
      purchaseId: verified.purchaseId,
      status: "active",
      expiresAt: verified.expiresAt,
      updatedAt: new Date(),
    }, {merge: true});

    return {
      isPremium: true,
      productId: verified.productId,
      expiresAt: verified.expiresAt.toISOString(),
    };
  },
);

export const generateFinancialInsight = onCall(
  {
    region: "us-central1",
    timeoutSeconds: 30,
    memory: "256MiB",
    maxInstances: 3,
    secrets: [openAiApiKey],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in to use Flux intelligence.");
    }

    const context = validateContext(request.data?.context);
    const apiKey = openAiApiKey.value();
    if (!apiKey) {
      throw new HttpsError("failed-precondition", "AI service is not configured.");
    }
    await consumeDailyRequest(request.auth.uid);

    const response = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: "gpt-5.6-luna",
        store: false,
        input: [
          {
            role: "system",
            content:
              "You are Flux, a concise personal finance education assistant. Use only the supplied aggregate context. All monetary values must use the supplied currency code and symbol; never assume USD, dollars, or the $ symbol. Respect the supplied decimal precision. Never invent facts, give investment or tax advice, or recommend risky financial actions. Return practical, non-judgmental guidance.",
          },
          {
            role: "user",
            content: `Explain the user's current financial picture and give at most two practical next steps. Aggregate context: ${JSON.stringify(context)}`,
          },
        ],
        text: {
          format: {
            type: "json_schema",
            name: "financial_insight",
            strict: true,
            schema: insightSchema,
          },
        },
      }),
    });

    if (!response.ok) {
      throw new HttpsError("internal", "The AI service could not complete the request.");
    }

    const body = (await response.json()) as Record<string, unknown>;
    const outputText = extractOutputText(body);
    if (!outputText) {
      throw new HttpsError("internal", "The AI service returned an empty response.");
    }

    try {
      return JSON.parse(outputText);
    } catch {
      throw new HttpsError("internal", "The AI service returned an invalid response.");
    }
  },
);
