"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.submitVerification = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
const crypto_1 = require("crypto");
admin.initializeApp();
function normalizeNationalId(raw) {
    return raw.replace(/[^A-Za-z0-9]/g, "").toUpperCase();
}
function buildSignature(normalized) {
    return (0, crypto_1.createHash)("sha256").update(normalized).digest("hex");
}
exports.submitVerification = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "Login required.");
    }
    const uid = context.auth.uid;
    const rawId = String((data === null || data === void 0 ? void 0 : data.nationalIdNumber) || "");
    const idImageUrl = String((data === null || data === void 0 ? void 0 : data.idImageUrl) || "");
    const selfieImageUrl = String((data === null || data === void 0 ? void 0 : data.selfieImageUrl) || "");
    if (!rawId || rawId.length < 8 || rawId.length > 32) {
        throw new functions.https.HttpsError("invalid-argument", "Invalid national ID number.");
    }
    if (!idImageUrl || !selfieImageUrl) {
        throw new functions.https.HttpsError("invalid-argument", "Missing image URLs.");
    }
    const normalized = normalizeNationalId(rawId);
    const signature = buildSignature(normalized);
    const last4 = normalized.length >= 4
        ? normalized.substring(normalized.length - 4)
        : normalized;
    const firestore = admin.firestore();
    const signatureRef = firestore.collection("id_signatures").doc(signature);
    const userRef = firestore.collection("users").doc(uid);
    await firestore.runTransaction(async (tx) => {
        var _a;
        const sigSnap = await tx.get(signatureRef);
        if (sigSnap.exists) {
            const ownerUid = (_a = sigSnap.data()) === null || _a === void 0 ? void 0 : _a.ownerUid;
            if (ownerUid && ownerUid !== uid) {
                throw new functions.https.HttpsError("already-exists", "id_already_registered");
            }
        }
        tx.set(signatureRef, {
            ownerUid: uid,
            nationalIdLast4: last4,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        tx.set(userRef, {
            isVerified: true,
            verification: {
                status: "verified",
                provider: "fayda",
                idSignature: signature,
                nationalIdLast4: last4,
                idImageUrl,
                selfieImageUrl,
                verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
            },
            lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
    });
    return {
        signature,
        status: "verified",
    };
});
//# sourceMappingURL=index.js.map