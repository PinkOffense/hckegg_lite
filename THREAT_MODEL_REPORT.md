# Threat Model Report
## HCKEgg Aviculture 360 Lite

**Document Version:** 1.0
**Assessment Date:** February 2, 2026
**Classification:** Confidential
**Prepared By:** Security Assessment Team

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Scope and Methodology](#2-scope-and-methodology)
3. [System Overview](#3-system-overview)
4. [Asset Inventory](#4-asset-inventory)
5. [Trust Boundaries](#5-trust-boundaries)
6. [Threat Analysis (STRIDE)](#6-threat-analysis-stride)
7. [Attack Surface Analysis](#7-attack-surface-analysis)
8. [Vulnerability Assessment](#8-vulnerability-assessment)
9. [Risk Matrix](#9-risk-matrix)
10. [Security Controls Assessment](#10-security-controls-assessment)
11. [Recommendations](#11-recommendations)
12. [Conclusion](#12-conclusion)
13. [Appendix](#13-appendix)

---

## 1. Executive Summary

### 1.1 Overview

This threat model report presents a comprehensive security analysis of **HCKEgg Aviculture 360 Lite**, a Flutter-based mobile application designed for small and medium-sized poultry producers. The application manages egg production, sales, expenses, veterinary records, and feed stock inventory with offline-first capabilities.

### 1.2 Key Findings Summary

| Risk Level | Count | Description |
|------------|-------|-------------|
| **Critical** | 0 | No critical vulnerabilities identified |
| **High** | 2 | CORS misconfiguration, Missing certificate pinning |
| **Medium** | 4 | In-memory rate limiting, Network security config, Security headers, Image data handling |
| **Low** | 3 | Local storage encryption, Request size limits, Documentation gaps |

### 1.3 Overall Security Posture

**Rating: GOOD (7.5/10)**

The application demonstrates mature security practices including:
- Proper authentication and authorization via Supabase
- Row-Level Security (RLS) at database level
- Input validation and error sanitization
- Multi-layer middleware protection

Primary concerns are configuration-dependent rather than fundamental implementation flaws.

### 1.4 Critical Recommendations

1. **Immediate**: Configure CORS to allow only specific production domains
2. **High Priority**: Implement certificate pinning for API and Supabase connections
3. **Before Production**: Add Android Network Security Configuration

---

## 2. Scope and Methodology

### 2.1 Scope

| Component | Included | Notes |
|-----------|----------|-------|
| Flutter Mobile Application | Yes | Android, iOS, Web builds |
| Dart Frog Backend API | Yes | REST API server |
| Supabase Integration | Yes | Auth, Database, Storage |
| Third-party Dependencies | Partial | Security-relevant packages |
| Infrastructure (Render.com) | No | Out of scope |

### 2.2 Methodology

This assessment follows industry-standard threat modeling frameworks:

- **STRIDE**: Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege
- **OWASP Mobile Top 10 2024**: Mobile-specific security risks
- **OWASP API Security Top 10**: API-specific vulnerabilities
- **NIST Cybersecurity Framework**: Risk assessment guidance

### 2.3 Assessment Techniques

1. **Static Code Analysis**: Manual review of ~19,000 lines of Dart code
2. **Architecture Review**: Analysis of Clean Architecture implementation
3. **Configuration Analysis**: Review of security configurations
4. **Data Flow Analysis**: Mapping of sensitive data movement
5. **Dependency Analysis**: Review of third-party package security

### 2.4 Limitations

- No dynamic penetration testing performed
- Infrastructure security (Render.com, Supabase hosting) not assessed
- Third-party service security relies on vendor attestations

---

## 3. System Overview

### 3.1 Technology Stack

| Layer | Technology | Version |
|-------|------------|---------|
| Frontend | Flutter/Dart | 3.x / SDK >=3.10.0 |
| State Management | Provider | ^6.1.2 |
| Backend API | Dart Frog | Custom REST |
| Database | PostgreSQL | Via Supabase |
| Authentication | Supabase Auth | ^2.8.0 |
| OCR | Google ML Kit | ^0.13.0 |
| Offline Storage | Drift (SQLite) | ^2.20.3 |

### 3.2 Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              EXTERNAL ZONE                                   │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────┐                      │
│  │   Mobile    │    │   Web       │    │  Desktop    │                      │
│  │   Device    │    │  Browser    │    │   Client    │                      │
│  └──────┬──────┘    └──────┬──────┘    └──────┬──────┘                      │
└─────────┼──────────────────┼──────────────────┼─────────────────────────────┘
          │                  │                  │
          │ HTTPS            │ HTTPS            │ HTTPS
          │                  │                  │
┌─────────┼──────────────────┼──────────────────┼─────────────────────────────┐
│         │         TRUST BOUNDARY 1            │                              │
│         ▼                  ▼                  ▼                              │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                    FLUTTER APPLICATION                               │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │    │
│  │  │ Presentation│  │   Domain    │  │    Data     │                  │    │
│  │  │   Layer     │◄─┤   Layer     │◄─┤   Layer     │                  │    │
│  │  │  (Provider) │  │ (Use Cases) │  │(Repository) │                  │    │
│  │  └─────────────┘  └─────────────┘  └──────┬──────┘                  │    │
│  │                                           │                          │    │
│  │  ┌─────────────┐  ┌─────────────┐         │                          │    │
│  │  │   Drift     │  │  ML Kit     │         │                          │    │
│  │  │  (SQLite)   │  │   (OCR)     │         │                          │    │
│  │  │ Local Store │  │   Local     │         │                          │    │
│  │  └─────────────┘  └─────────────┘         │                          │    │
│  └───────────────────────────────────────────┼──────────────────────────┘    │
│                                              │                               │
│                                              │ HTTPS + JWT                   │
│                                              │                               │
└──────────────────────────────────────────────┼───────────────────────────────┘
                                               │
┌──────────────────────────────────────────────┼───────────────────────────────┐
│                         TRUST BOUNDARY 2     │                               │
│                                              ▼                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                      DART FROG API SERVER                            │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │    │
│  │  │  Logging    │─►│Rate Limiter │─►│    CORS     │                  │    │
│  │  │ Middleware  │  │ Middleware  │  │ Middleware  │                  │    │
│  │  └─────────────┘  └─────────────┘  └──────┬──────┘                  │    │
│  │                                           │                          │    │
│  │  ┌─────────────┐  ┌─────────────┐         ▼                          │    │
│  │  │   Auth      │─►│  Business   │◄────────┘                          │    │
│  │  │ Middleware  │  │   Logic     │                                    │    │
│  │  └─────────────┘  └──────┬──────┘                                    │    │
│  └───────────────────────────┼──────────────────────────────────────────┘    │
│                              │                                               │
│                              │ Service Role Key                              │
│                              │                                               │
└──────────────────────────────┼───────────────────────────────────────────────┘
                               │
┌──────────────────────────────┼───────────────────────────────────────────────┐
│                  TRUST BOUNDARY 3 (SUPABASE)                                 │
│                              ▼                                               │
│  ┌─────────────────────────────────────────────────────────────────────┐    │
│  │                         SUPABASE PLATFORM                            │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                  │    │
│  │  │    Auth     │  │  PostgreSQL │  │   Storage   │                  │    │
│  │  │   (JWT)     │  │    (RLS)    │  │  (Buckets)  │                  │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘                  │    │
│  └─────────────────────────────────────────────────────────────────────┘    │
│                                                                              │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 3.3 Data Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          DATA FLOW OVERVIEW                                  │
└─────────────────────────────────────────────────────────────────────────────┘

                    ┌─────────────────┐
                    │      User       │
                    └────────┬────────┘
                             │
                    ┌────────▼────────┐
          ┌─────────┤   Credentials   ├─────────┐
          │         │ Email/Password  │         │
          │         │  Google OAuth   │         │
          │         └─────────────────┘         │
          │                                     │
          ▼                                     ▼
┌─────────────────┐                   ┌─────────────────┐
│   Supabase      │                   │   Google        │
│     Auth        │◄──────────────────│   OAuth 2.0    │
└────────┬────────┘                   └─────────────────┘
         │
         │ JWT Token
         ▼
┌─────────────────┐
│  Flutter App    │
│  (Token Store)  │
└────────┬────────┘
         │
         │ Bearer Token
         ▼
┌─────────────────┐         ┌─────────────────┐
│  Dart Frog API  │────────►│    Supabase     │
│  (Validation)   │ RLS     │   PostgreSQL    │
└────────┬────────┘         └─────────────────┘
         │
         │ Filtered Data
         ▼
┌─────────────────┐
│  User Response  │
│ (Own Data Only) │
└─────────────────┘


                    ┌─────────────────┐
                    │  SENSITIVE DATA │
                    │      FLOWS      │
                    └─────────────────┘

┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Camera    │────►│  ML Kit     │────►│  Feed Stock │
│   Image     │     │  OCR Local  │     │   Dialog    │
└─────────────┘     └─────────────┘     └──────┬──────┘
                                               │
                    ┌─────────────┐            │
                    │  Customer   │            │
                    │    PII      │            │
                    │ Name/Phone  │            │
                    └──────┬──────┘            │
                           │                   │
                           ▼                   ▼
                    ┌─────────────────────────────┐
                    │      API Request            │
                    │   (HTTPS Encrypted)         │
                    └─────────────┬───────────────┘
                                  │
                                  ▼
                    ┌─────────────────────────────┐
                    │     Supabase Database       │
                    │   (RLS + User Isolation)    │
                    └─────────────────────────────┘
```

---

## 4. Asset Inventory

### 4.1 Data Assets

| Asset | Classification | Storage Location | Encryption |
|-------|---------------|------------------|------------|
| User Credentials | **Critical** | Supabase Auth | Yes (bcrypt) |
| JWT Tokens | **Critical** | Memory / Supabase | Yes (signed) |
| Customer PII (name, email, phone) | **High** | PostgreSQL | At rest (Supabase) |
| Financial Data (sales, expenses) | **High** | PostgreSQL | At rest |
| Production Data (egg records) | **Medium** | PostgreSQL | At rest |
| Health Records (vet data) | **Medium** | PostgreSQL | At rest |
| Feed Stock Data | **Medium** | PostgreSQL | At rest |
| User Preferences | **Low** | Local + Cloud | No |

### 4.2 System Assets

| Asset | Description | Criticality |
|-------|-------------|-------------|
| Dart Frog API Server | Backend REST API | **Critical** |
| Supabase Instance | Database + Auth | **Critical** |
| Flutter Application | Client application | **High** |
| Google OAuth Integration | Authentication provider | **High** |
| ML Kit (OCR) | Local image processing | **Low** |

### 4.3 Code Assets

| Asset | Location | Description |
|-------|----------|-------------|
| API Keys | Environment Variables | Supabase URL, Service Key |
| Google Client IDs | Environment Variables | OAuth configuration |
| Source Code | Git Repository | ~19,000 LOC |

---

## 5. Trust Boundaries

### 5.1 Identified Trust Boundaries

| ID | Boundary | Description | Controls |
|----|----------|-------------|----------|
| TB-1 | Client ↔ Network | Data leaving device | HTTPS, Input validation |
| TB-2 | Network ↔ API | API ingress point | Auth middleware, Rate limiting, CORS |
| TB-3 | API ↔ Database | Data persistence | Service role key, RLS policies |
| TB-4 | User ↔ Application | User input | Input validation, Sanitization |
| TB-5 | App ↔ External Services | Third-party integrations | OAuth, Secure tokens |

### 5.2 Trust Boundary Analysis

```
┌────────────────────────────────────────────────────────────────────────────┐
│                        TRUST BOUNDARY DETAILS                               │
└────────────────────────────────────────────────────────────────────────────┘

TB-1: CLIENT ↔ NETWORK
├── Risk: Data interception, MITM attacks
├── Current Controls:
│   ├── [✓] HTTPS enforcement (all URLs hardcoded)
│   ├── [✓] JWT token authentication
│   └── [✗] Certificate pinning (NOT IMPLEMENTED)
└── Recommendation: Implement certificate pinning

TB-2: NETWORK ↔ API
├── Risk: Unauthorized access, DDoS, Injection
├── Current Controls:
│   ├── [✓] Bearer token validation
│   ├── [✓] Rate limiting (tiered)
│   ├── [⚠] CORS (permissive default)
│   ├── [✓] Input validation
│   └── [✓] Error sanitization
└── Recommendation: Configure strict CORS for production

TB-3: API ↔ DATABASE
├── Risk: Data breach, SQL injection, Privilege escalation
├── Current Controls:
│   ├── [✓] Parameterized queries (Supabase ORM)
│   ├── [✓] Row-Level Security policies
│   ├── [✓] User-scoped data access
│   └── [✓] Service role key isolation
└── Recommendation: None (well protected)

TB-4: USER ↔ APPLICATION
├── Risk: XSS, Input injection, Data manipulation
├── Current Controls:
│   ├── [✓] Input validators (email, URL, dates, etc.)
│   ├── [✓] Display name sanitization
│   └── [✓] Image size constraints
└── Recommendation: None (adequate controls)

TB-5: APP ↔ EXTERNAL SERVICES
├── Risk: Token theft, OAuth abuse, API key exposure
├── Current Controls:
│   ├── [✓] Native Google Sign-In
│   ├── [✓] Environment variables for keys
│   └── [✓] Platform-specific OAuth handling
└── Recommendation: None (well handled)
```

---

## 6. Threat Analysis (STRIDE)

### 6.1 STRIDE Matrix

| Threat Type | Applicable | Risk Level | Mitigated |
|-------------|------------|------------|-----------|
| **S**poofing | Yes | Medium | Partial |
| **T**ampering | Yes | Low | Yes |
| **R**epudiation | Yes | Low | Partial |
| **I**nformation Disclosure | Yes | Medium | Partial |
| **D**enial of Service | Yes | Medium | Partial |
| **E**levation of Privilege | Yes | Low | Yes |

### 6.2 Detailed STRIDE Analysis

#### 6.2.1 Spoofing Identity

| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| S-01 | Attacker impersonates legitimate user via stolen JWT | Medium | High | **Medium** |
| S-02 | MITM attack intercepts credentials | Low | Critical | **Medium** |
| S-03 | OAuth token hijacking | Low | High | **Low** |

**Current Mitigations:**
- JWT tokens validated on every request (`backend/routes/api/_middleware.dart:33-35`)
- Tokens have expiration (Supabase default: 1 hour)
- Automatic token refresh logic (`lib/app/auth_gate.dart:60-92`)
- Google OAuth uses native SDKs with secure token handling

**Gaps:**
- No certificate pinning to prevent MITM
- No device binding for tokens

**Recommendations:**
1. Implement certificate pinning
2. Consider token binding to device fingerprint
3. Add session invalidation on suspicious activity

---

#### 6.2.2 Tampering with Data

| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| T-01 | API request tampering in transit | Very Low | High | **Low** |
| T-02 | Local database manipulation | Low | Medium | **Low** |
| T-03 | Response tampering | Very Low | Medium | **Low** |

**Current Mitigations:**
- All traffic over HTTPS (TLS 1.2+)
- Server-side validation on all inputs (`backend/lib/core/utils/validators.dart`)
- RLS prevents unauthorized data modification
- Supabase ORM prevents SQL injection

**Gaps:**
- No response signing/integrity verification
- Local SQLite (Drift) not encrypted

**Recommendations:**
1. Consider encrypting local Drift database for sensitive offline data
2. Implement response integrity checks for critical operations

---

#### 6.2.3 Repudiation

| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| R-01 | User denies performing action | Medium | Low | **Low** |
| R-02 | Insufficient audit trail | Medium | Medium | **Medium** |

**Current Mitigations:**
- Request logging middleware (`backend/routes/_middleware.dart:8-17`)
- Auth event logging with masked user IDs (`backend/lib/core/utils/logger.dart:88-93`)
- Timestamps on all database records

**Gaps:**
- No comprehensive audit log table
- No immutable action history

**Recommendations:**
1. Implement audit_log table for critical actions (sales, deletions)
2. Consider event sourcing for financial transactions

---

#### 6.2.4 Information Disclosure

| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| I-01 | Error messages leak sensitive info | Low | Medium | **Low** |
| I-02 | Logs expose PII | Low | Medium | **Low** |
| I-03 | API exposes other users' data | Very Low | Critical | **Low** |
| I-04 | Customer PII exposure | Low | High | **Medium** |

**Current Mitigations:**
- Error sanitization on frontend (`lib/core/api/api_client.dart:300-335`)
- Error sanitization on backend (`backend/lib/core/utils/error_sanitizer.dart`)
- PII masking in logs (`lib/services/auth_service.dart:73-92`)
- RLS enforces user data isolation (`supabase/schema.sql:299-388`)
- Generic error messages prevent user enumeration

**Gaps:**
- Customer PII (name, email, phone) stored in plaintext
- No field-level encryption for sensitive data

**Recommendations:**
1. Consider encrypting customer contact information at application level
2. Implement data masking in API responses where full PII isn't needed

---

#### 6.2.5 Denial of Service

| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| D-01 | API rate limit bypass (distributed) | Medium | High | **Medium** |
| D-02 | Large payload attacks | Medium | Medium | **Medium** |
| D-03 | Auth endpoint brute force | Low | Medium | **Low** |

**Current Mitigations:**
- Rate limiting with tiered limits (`backend/lib/core/middleware/rate_limiter.dart:33-52`)
  - Auth endpoints: 3-5 req/min (strict)
  - General: 100 req/min
  - Authenticated: 200 req/min
- Retry-After headers on rate limit
- 45-second timeouts prevent hanging connections

**Gaps:**
- In-memory rate limiter (per-instance only)
- No request body size limits
- No slowloris protection

**Recommendations:**
1. Implement Redis-backed rate limiting for multi-instance deployments
2. Add request body size limits (e.g., 10MB max)
3. Consider CDN/WAF for production (Cloudflare, AWS WAF)

---

#### 6.2.6 Elevation of Privilege

| Threat ID | Description | Likelihood | Impact | Risk |
|-----------|-------------|------------|--------|------|
| E-01 | Horizontal privilege escalation (access other users' data) | Very Low | Critical | **Low** |
| E-02 | Vertical privilege escalation (admin access) | Very Low | Critical | **Low** |
| E-03 | JWT manipulation | Very Low | Critical | **Low** |

**Current Mitigations:**
- RLS policies on all tables (`supabase/schema.sql:299-388`)
- All queries scoped by `auth.uid()`
- No admin roles defined in application (single-user per account model)
- JWT signature verification via Supabase

**Gaps:**
- No explicit role-based access control (though current model doesn't require it)

**Recommendations:**
1. If admin features added, implement proper RBAC
2. Add anomaly detection for unusual data access patterns

---

## 7. Attack Surface Analysis

### 7.1 Entry Points

| Entry Point | Protocol | Authentication | Authorization |
|-------------|----------|----------------|---------------|
| `/api/v1/auth/signin` | HTTPS POST | None (public) | Rate limited |
| `/api/v1/auth/signup` | HTTPS POST | None (public) | Rate limited |
| `/api/v1/auth/refresh` | HTTPS POST | Refresh token | Rate limited |
| `/api/v1/eggs/*` | HTTPS | JWT Bearer | RLS (user_id) |
| `/api/v1/sales/*` | HTTPS | JWT Bearer | RLS (user_id) |
| `/api/v1/expenses/*` | HTTPS | JWT Bearer | RLS (user_id) |
| `/api/v1/health/*` | HTTPS | JWT Bearer | RLS (user_id) |
| `/api/v1/feed/*` | HTTPS | JWT Bearer | RLS (user_id) |
| `/api/v1/reservations/*` | HTTPS | JWT Bearer | RLS (user_id) |
| Google OAuth Callback | HTTPS | OAuth 2.0 | Google verified |
| Camera/Image Picker | Device API | None | User permission |

### 7.2 Attack Surface Reduction

**Current Measures:**
- Minimal public endpoints (only auth)
- All data endpoints require authentication
- No admin endpoints exposed
- OCR processing is entirely local (no external API)

**Recommendations:**
- Consider IP allowlisting for API if used in controlled environments
- Implement API versioning deprecation policy

---

## 8. Vulnerability Assessment

### 8.1 Identified Vulnerabilities

#### VULN-001: Permissive CORS Configuration

| Attribute | Value |
|-----------|-------|
| **Severity** | High |
| **CVSS 3.1** | 6.5 (Medium) |
| **CWE** | CWE-942: Overly Permissive Cross-domain Whitelist |
| **Location** | `backend/lib/core/middleware/cors.dart:25` |

**Description:**
Default CORS configuration allows all origins (`['*']`), enabling any website to make cross-origin requests to the API.

**Code Reference:**
```dart
const CorsConfig({
  this.allowedOrigins = const ['*'],  // Vulnerable
  this.allowedMethods = const ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  ...
});
```

**Attack Scenario:**
1. Attacker creates malicious website
2. Victim visits attacker's site while authenticated to HCKEgg
3. Attacker's JavaScript makes API requests using victim's credentials
4. Attacker exfiltrates victim's data

**Remediation:**
```dart
// Production configuration (already exists at lines 156-162)
static CorsConfig production() {
  final origins = Platform.environment['CORS_ALLOWED_ORIGINS']
      ?.split(',')
      .map((e) => e.trim())
      .toList() ?? ['https://hckegg.app', 'https://app.hckegg.app'];
  return CorsConfig(allowedOrigins: origins);
}
```
Set environment variable: `CORS_ALLOWED_ORIGINS=https://hckegg.app,https://app.hckegg.app`

---

#### VULN-002: Missing Certificate Pinning

| Attribute | Value |
|-----------|-------|
| **Severity** | High |
| **CVSS 3.1** | 5.9 (Medium) |
| **CWE** | CWE-295: Improper Certificate Validation |
| **Location** | Network layer (entire application) |

**Description:**
No certificate pinning implemented for HTTPS connections to API or Supabase, making the application vulnerable to MITM attacks via compromised Certificate Authorities.

**Attack Scenario:**
1. Attacker obtains fraudulent certificate from compromised CA
2. Attacker performs MITM attack on network
3. Application accepts fraudulent certificate
4. Attacker intercepts credentials and data

**Remediation:**
```dart
// Add to pubspec.yaml
dependencies:
  http_certificate_pinning: ^2.0.0

// Implementation example
final client = HttpClient()
  ..badCertificateCallback = (cert, host, port) {
    final validFingerprints = [
      'SHA256:xxxx...', // API certificate
      'SHA256:yyyy...', // Supabase certificate
    ];
    return validFingerprints.contains(sha256(cert.der));
  };
```

---

#### VULN-003: In-Memory Rate Limiter

| Attribute | Value |
|-----------|-------|
| **Severity** | Medium |
| **CVSS 3.1** | 5.3 (Medium) |
| **CWE** | CWE-770: Allocation of Resources Without Limits |
| **Location** | `backend/lib/core/middleware/rate_limiter.dart:86-157` |

**Description:**
Rate limiting uses in-memory storage, which doesn't persist across server restarts and doesn't scale across multiple instances.

**Code Reference:**
```dart
final Map<String, _RateLimitEntry> _entries = {};  // In-memory only
```

**Attack Scenario:**
1. For single instance: Restart server to reset rate limits
2. For multiple instances: Distribute requests across instances to bypass limits

**Remediation:**
```dart
// Implement Redis-backed store
class RedisRateLimitStore implements RateLimitStore {
  final RedisConnection _redis;

  Future<int> incrementAndGet(String key, Duration window) async {
    final count = await _redis.incr(key);
    if (count == 1) {
      await _redis.expire(key, window.inSeconds);
    }
    return count;
  }
}
```

---

#### VULN-004: Missing Android Network Security Configuration

| Attribute | Value |
|-----------|-------|
| **Severity** | Medium |
| **CVSS 3.1** | 4.8 (Medium) |
| **CWE** | CWE-319: Cleartext Transmission of Sensitive Information |
| **Location** | `android/app/src/main/AndroidManifest.xml` |

**Description:**
No explicit network security configuration to enforce HTTPS-only traffic on Android.

**Remediation:**
Create `android/app/src/main/res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    <domain-config cleartextTrafficPermitted="false">
        <domain includeSubdomains="true">hckegg-api.onrender.com</domain>
        <domain includeSubdomains="true">supabase.co</domain>
    </domain-config>
</network-security-config>
```

Add to AndroidManifest.xml:
```xml
<application
    android:networkSecurityConfig="@xml/network_security_config"
    ...>
```

---

#### VULN-005: Missing Security Headers

| Attribute | Value |
|-----------|-------|
| **Severity** | Medium |
| **CVSS 3.1** | 4.3 (Medium) |
| **CWE** | CWE-693: Protection Mechanism Failure |
| **Location** | `backend/routes/_middleware.dart` |

**Description:**
API responses lack security headers (CSP, X-Frame-Options, X-Content-Type-Options, etc.).

**Remediation:**
```dart
Handler securityHeadersMiddleware(Handler handler) {
  return (context) async {
    final response = await handler(context);
    return response.copyWith(
      headers: {
        ...response.headers,
        'X-Content-Type-Options': 'nosniff',
        'X-Frame-Options': 'DENY',
        'X-XSS-Protection': '1; mode=block',
        'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
        'Content-Security-Policy': "default-src 'self'",
        'Referrer-Policy': 'strict-origin-when-cross-origin',
      },
    );
  };
}
```

---

#### VULN-006: Image Data Retained in Memory

| Attribute | Value |
|-----------|-------|
| **Severity** | Low |
| **CVSS 3.1** | 3.3 (Low) |
| **CWE** | CWE-226: Sensitive Information in Resource Not Removed |
| **Location** | `lib/dialogs/feed_stock_dialog.dart:35` |

**Description:**
Captured image bytes for OCR are stored in widget state but not explicitly cleared after processing.

**Code Reference:**
```dart
Uint8List? _capturedImageBytes;  // Not cleared after use
```

**Remediation:**
```dart
void _clearImageData() {
  _capturedImageBytes = null;
}

@override
void dispose() {
  _clearImageData();
  super.dispose();
}

// After OCR processing
void _processOcrResult(String text) {
  // ... process text ...
  _clearImageData();  // Clear sensitive image data
}
```

---

### 8.2 Vulnerability Summary Table

| ID | Vulnerability | Severity | Status | Priority |
|----|--------------|----------|--------|----------|
| VULN-001 | Permissive CORS | High | Open | P1 |
| VULN-002 | No Certificate Pinning | High | Open | P1 |
| VULN-003 | In-Memory Rate Limiter | Medium | Open | P2 |
| VULN-004 | No Android Network Config | Medium | Open | P2 |
| VULN-005 | Missing Security Headers | Medium | Open | P2 |
| VULN-006 | Image Data Retention | Low | Open | P3 |

---

## 9. Risk Matrix

### 9.1 Risk Assessment Matrix

```
                    IMPACT
                    ┌─────────────────────────────────────────────────┐
                    │  Negligible │   Minor   │  Moderate │  Major   │  Critical │
    ┌───────────────┼─────────────┼───────────┼───────────┼──────────┼───────────┤
    │   Almost      │             │           │           │          │           │
    │   Certain     │    LOW      │  MEDIUM   │   HIGH    │ CRITICAL │ CRITICAL  │
L   ├───────────────┼─────────────┼───────────┼───────────┼──────────┼───────────┤
I   │   Likely      │    LOW      │  MEDIUM   │  MEDIUM   │   HIGH   │ CRITICAL  │
K   ├───────────────┼─────────────┼───────────┼───────────┼──────────┼───────────┤
E   │   Possible    │    LOW      │   LOW     │  MEDIUM   │   HIGH   │   HIGH    │
L   ├───────────────┼─────────────┼───────────┼───────────┼──────────┼───────────┤
I   │   Unlikely    │    LOW      │   LOW     │   LOW     │  MEDIUM  │  MEDIUM   │
H   ├───────────────┼─────────────┼───────────┼───────────┼──────────┼───────────┤
O   │   Rare        │    LOW      │   LOW     │   LOW     │   LOW    │  MEDIUM   │
O   └───────────────┴─────────────┴───────────┴───────────┴──────────┴───────────┘
D
```

### 9.2 Threat Risk Ratings

| Threat | Likelihood | Impact | Risk Rating |
|--------|------------|--------|-------------|
| CORS Abuse (VULN-001) | Possible | Moderate | **MEDIUM** |
| MITM via no pinning (VULN-002) | Unlikely | Major | **MEDIUM** |
| Rate Limit Bypass (VULN-003) | Possible | Minor | **LOW** |
| Cleartext Traffic (VULN-004) | Rare | Moderate | **LOW** |
| Missing Headers (VULN-005) | Possible | Minor | **LOW** |
| Data Leak via Memory (VULN-006) | Rare | Minor | **LOW** |
| SQL Injection | Rare | Critical | **MEDIUM** (Mitigated) |
| XSS | Rare | Moderate | **LOW** (Mitigated) |
| Credential Theft | Unlikely | Critical | **MEDIUM** |
| Data Breach | Rare | Critical | **MEDIUM** |

### 9.3 Overall Risk Profile

```
┌────────────────────────────────────────────────────────────────────────────┐
│                          RISK DISTRIBUTION                                  │
└────────────────────────────────────────────────────────────────────────────┘

  CRITICAL │
           │
      HIGH │ ██ (2)
           │ VULN-001, VULN-002
    MEDIUM │ ████ (4)
           │ VULN-003, VULN-004, VULN-005, Credential Theft
       LOW │ ██████ (6)
           │ VULN-006, SQL Injection, XSS, etc.
           │
           └─────────────────────────────────────────────────────
```

---

## 10. Security Controls Assessment

### 10.1 Authentication Controls

| Control | Status | Effectiveness | Notes |
|---------|--------|---------------|-------|
| JWT Token Authentication | ✅ Implemented | High | Supabase-managed |
| Token Expiration | ✅ Implemented | High | 1-hour default |
| Token Refresh | ✅ Implemented | High | Automatic refresh |
| Password Policy | ⚠️ Partial | Medium | 8-char minimum only |
| OAuth Integration | ✅ Implemented | High | Google OAuth |
| Session Management | ✅ Implemented | High | Proper state handling |
| Multi-Factor Auth | ❌ Not Implemented | N/A | Could be added via Supabase |

### 10.2 Authorization Controls

| Control | Status | Effectiveness | Notes |
|---------|--------|---------------|-------|
| Row-Level Security | ✅ Implemented | High | All tables protected |
| User Data Isolation | ✅ Implemented | High | auth.uid() scoping |
| API Auth Middleware | ✅ Implemented | High | All /api routes |
| Role-Based Access | ⚠️ N/A | N/A | Single-user model |

### 10.3 Input Validation Controls

| Control | Status | Effectiveness | Notes |
|---------|--------|---------------|-------|
| Email Validation | ✅ Implemented | High | RFC 5322 pattern |
| URL Validation | ✅ Implemented | High | HTTPS only |
| Date Validation | ✅ Implemented | High | Format + range |
| Numeric Validation | ✅ Implemented | High | Range checks |
| UUID Validation | ✅ Implemented | High | Format validation |
| SQL Injection Prevention | ✅ Implemented | High | Parameterized queries |

### 10.4 Error Handling Controls

| Control | Status | Effectiveness | Notes |
|---------|--------|---------------|-------|
| Error Sanitization (Backend) | ✅ Implemented | High | Sensitive patterns filtered |
| Error Sanitization (Frontend) | ✅ Implemented | High | Safe fallback messages |
| PII Masking in Logs | ✅ Implemented | High | Email/ID masking |
| Generic Auth Errors | ✅ Implemented | High | Prevents enumeration |

### 10.5 Network Security Controls

| Control | Status | Effectiveness | Notes |
|---------|--------|---------------|-------|
| HTTPS Enforcement | ✅ Implemented | High | All URLs HTTPS |
| Rate Limiting | ⚠️ Partial | Medium | In-memory only |
| CORS | ⚠️ Misconfigured | Low | Allows all origins |
| Certificate Pinning | ❌ Not Implemented | N/A | Recommended |
| Security Headers | ❌ Not Implemented | N/A | Recommended |

### 10.6 Data Protection Controls

| Control | Status | Effectiveness | Notes |
|---------|--------|---------------|-------|
| Encryption in Transit | ✅ Implemented | High | TLS 1.2+ |
| Encryption at Rest | ✅ Implemented | High | Supabase managed |
| Local DB Encryption | ❌ Not Implemented | N/A | Drift unencrypted |
| Account Deletion | ✅ Implemented | High | Full cascade |
| Data Backup | ⚠️ Vendor-managed | Medium | Supabase handles |

---

## 11. Recommendations

### 11.1 Immediate Actions (P1 - Before Production)

#### REC-001: Configure CORS for Production
**Priority:** P1 - Critical
**Effort:** Low (1-2 hours)
**Risk Reduced:** VULN-001

**Action Items:**
1. Set environment variable `CORS_ALLOWED_ORIGINS` with production domains
2. Verify CORS middleware uses production configuration
3. Test cross-origin requests from unauthorized domains are blocked

```bash
# Production deployment
export CORS_ALLOWED_ORIGINS="https://hckegg.app,https://app.hckegg.app"
```

---

#### REC-002: Implement Certificate Pinning
**Priority:** P1 - High
**Effort:** Medium (4-8 hours)
**Risk Reduced:** VULN-002

**Action Items:**
1. Add `http_certificate_pinning` package to dependencies
2. Implement pinning for API and Supabase endpoints
3. Set up certificate rotation process
4. Add backup pins for certificate renewal

---

### 11.2 High Priority Actions (P2 - Within 30 Days)

#### REC-003: Add Android Network Security Configuration
**Priority:** P2 - Medium
**Effort:** Low (1-2 hours)
**Risk Reduced:** VULN-004

**Action Items:**
1. Create `network_security_config.xml`
2. Add reference to AndroidManifest.xml
3. Test cleartext traffic is blocked

---

#### REC-004: Implement Security Headers
**Priority:** P2 - Medium
**Effort:** Low (2-4 hours)
**Risk Reduced:** VULN-005

**Action Items:**
1. Create security headers middleware
2. Add to middleware chain
3. Verify headers in API responses

---

#### REC-005: Implement Distributed Rate Limiting
**Priority:** P2 - Medium (if scaling beyond single instance)
**Effort:** Medium (8-16 hours)
**Risk Reduced:** VULN-003

**Action Items:**
1. Set up Redis instance
2. Implement Redis-backed rate limit store
3. Update rate limiter middleware
4. Test rate limits persist across restarts

---

### 11.3 Recommended Enhancements (P3 - Roadmap)

#### REC-006: Add Request Body Size Limits
**Priority:** P3 - Low
**Effort:** Low (1-2 hours)

```dart
Handler bodySizeLimitMiddleware(Handler handler, {int maxBytes = 10 * 1024 * 1024}) {
  return (context) async {
    final contentLength = context.request.headers['content-length'];
    if (contentLength != null && int.parse(contentLength) > maxBytes) {
      return Response(statusCode: 413, body: 'Request too large');
    }
    return handler(context);
  };
}
```

---

#### REC-007: Implement Audit Logging
**Priority:** P3 - Low
**Effort:** Medium (8-16 hours)

**Action Items:**
1. Create audit_log table in Supabase
2. Log critical actions (sales, deletions, auth events)
3. Implement retention policy

---

#### REC-008: Clear Sensitive Data from Memory
**Priority:** P3 - Low
**Effort:** Low (1-2 hours)
**Risk Reduced:** VULN-006

**Action Items:**
1. Clear image bytes after OCR processing
2. Implement dispose() cleanup in relevant widgets

---

#### REC-009: Consider Local Database Encryption
**Priority:** P3 - Low
**Effort:** Medium (8-16 hours)

**Action Items:**
1. Evaluate flutter_secure_storage for sensitive data
2. Consider sqlcipher for Drift encryption
3. Implement if handling highly sensitive offline data

---

### 11.4 Production Deployment Checklist

```markdown
## Pre-Production Security Checklist

### Environment Configuration
- [ ] Set ENV=production
- [ ] Configure CORS_ALLOWED_ORIGINS with specific domains
- [ ] Set LOG_LEVEL=info (not debug)
- [ ] Configure Supabase production project

### Build Configuration
- [ ] Build with --dart-define for all secrets
- [ ] Enable code obfuscation for release builds
- [ ] Remove debug logging from production

### Platform Security
- [ ] Add Android network security config
- [ ] Enable iOS App Transport Security
- [ ] Configure certificate pinning

### Monitoring
- [ ] Enable Supabase audit logging
- [ ] Set up error alerting
- [ ] Configure rate limit alerts

### Testing
- [ ] Penetration test critical endpoints
- [ ] Verify RLS policies with unauthorized access attempts
- [ ] Test error message sanitization
```

---

## 12. Conclusion

### 12.1 Summary

The HCKEgg Aviculture 360 Lite application demonstrates a **solid security foundation** with proper implementation of:

- **Authentication & Authorization**: JWT-based auth with Row-Level Security
- **Input Validation**: Comprehensive validators on all endpoints
- **Error Handling**: Sanitized error messages preventing information leakage
- **Data Isolation**: User-scoped data access enforced at database level

### 12.2 Key Risks

The primary security concerns are **configuration-dependent** rather than fundamental implementation flaws:

1. **CORS Misconfiguration** - Easily remediated with environment configuration
2. **Missing Certificate Pinning** - Common gap, important for production
3. **In-Memory Rate Limiting** - Acceptable for single-instance, needs Redis for scale

### 12.3 Security Posture Rating

| Category | Rating | Notes |
|----------|--------|-------|
| Authentication | A | Well-implemented with Supabase |
| Authorization | A | RLS provides strong isolation |
| Input Validation | A | Comprehensive coverage |
| Error Handling | A | Good sanitization |
| Network Security | B- | HTTPS good, missing pinning & headers |
| Data Protection | B+ | Good transit/rest encryption |
| **Overall** | **B+** | Good with targeted improvements needed |

### 12.4 Next Steps

1. **Immediate**: Address P1 recommendations (CORS, Certificate Pinning)
2. **Before Production**: Complete deployment checklist
3. **Ongoing**: Schedule periodic security assessments

---

## 13. Appendix

### 13.1 OWASP Mobile Top 10 (2024) Mapping

| Risk | Applicability | Status |
|------|--------------|--------|
| M1: Improper Credential Usage | Applicable | ✅ Mitigated |
| M2: Inadequate Supply Chain Security | Applicable | ⚠️ Review deps |
| M3: Insecure Authentication/Authorization | Applicable | ✅ Mitigated |
| M4: Insufficient Input/Output Validation | Applicable | ✅ Mitigated |
| M5: Insecure Communication | Applicable | ⚠️ No pinning |
| M6: Inadequate Privacy Controls | Applicable | ✅ Mitigated |
| M7: Insufficient Binary Protections | Applicable | ⚠️ No obfuscation |
| M8: Security Misconfiguration | Applicable | ⚠️ CORS issue |
| M9: Insecure Data Storage | Applicable | ⚠️ Local DB unencrypted |
| M10: Insufficient Cryptography | Low Risk | ✅ Mitigated |

### 13.2 OWASP API Security Top 10 Mapping

| Risk | Applicability | Status |
|------|--------------|--------|
| API1: Broken Object Level Authorization | Applicable | ✅ RLS protects |
| API2: Broken Authentication | Applicable | ✅ Mitigated |
| API3: Broken Object Property Level Authorization | Applicable | ✅ Mitigated |
| API4: Unrestricted Resource Consumption | Applicable | ⚠️ Rate limiting partial |
| API5: Broken Function Level Authorization | Low Risk | ✅ N/A (no admin) |
| API6: Unrestricted Access to Sensitive Business Flows | Applicable | ✅ Mitigated |
| API7: Server Side Request Forgery | Low Risk | ✅ N/A |
| API8: Security Misconfiguration | Applicable | ⚠️ CORS issue |
| API9: Improper Inventory Management | Low Risk | ✅ N/A |
| API10: Unsafe Consumption of APIs | Applicable | ✅ Mitigated |

### 13.3 File References

| File | Security Relevance |
|------|-------------------|
| `lib/services/auth_service.dart` | Authentication implementation |
| `lib/core/api/api_client.dart` | API client with error handling |
| `backend/routes/api/_middleware.dart` | Auth middleware |
| `backend/lib/core/middleware/cors.dart` | CORS configuration |
| `backend/lib/core/middleware/rate_limiter.dart` | Rate limiting |
| `backend/lib/core/utils/validators.dart` | Input validation |
| `backend/lib/core/utils/error_sanitizer.dart` | Error sanitization |
| `supabase/schema.sql` | RLS policies |

### 13.4 Glossary

| Term | Definition |
|------|------------|
| **CORS** | Cross-Origin Resource Sharing |
| **CSRF** | Cross-Site Request Forgery |
| **JWT** | JSON Web Token |
| **MITM** | Man-in-the-Middle Attack |
| **PII** | Personally Identifiable Information |
| **RLS** | Row-Level Security |
| **STRIDE** | Spoofing, Tampering, Repudiation, Information Disclosure, DoS, Elevation of Privilege |
| **XSS** | Cross-Site Scripting |

---

**Document Control**

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-02-02 | Security Assessment Team | Initial release |

---

*This document is confidential and intended for internal use only. Distribution outside the organization requires explicit authorization.*
