---
name: security-audit
description: >
  Audit codebase security using OWASP Top 10 methodology.
  Use when "security audit", "check vulnerabilities", "OWASP", or "pentest prep".
---

# Security Audit

Comprehensive codebase security audit producing a severity-grouped report with OWASP Top 10 mapping.

## Syntax

```
/security-audit              # Full audit across all categories
/security-audit <scope>      # Focused audit (e.g., "auth", "api", "rls")
```

## Critical Rules

1. **Read before judging** - Explore actual code patterns before reporting findings
2. **No false positives** - Only report issues you can trace to specific code
3. **Severity must be justified** - Explain the attack vector and impact for each finding
4. **Acknowledge good patterns** - Report correctly implemented security measures

## Workflow

### Step 1: Discover Project Context

Before launching audits, gather context about the project's tech stack and architecture:

1. Read `CLAUDE.md` and project rules for architecture overview
2. Identify key technologies (framework, database, auth provider, payment provider)
3. Note security-relevant files mentioned in docs (auth, middleware, webhooks, RLS)

This context shapes which audit categories are relevant and where to look.

### Step 2: Launch Parallel Audits

Launch **Explore agents** in parallel (single message, multiple Task tools) across applicable categories. Each agent searches for specific vulnerability patterns.

Use `subagent_type: Explore` with thoroughness "very thorough" for each.

| Category | Agent Prompt Summary | When Applicable |
|----------|---------------------|-----------------|
| Auth & Access Control | Check auth functions, role verification, session management, IDOR patterns | Always |
| Injection & Input Validation | Check for raw SQL, unsanitized HTML, missing input validation (Zod/schema) | Always |
| Data Exposure | Check error messages for info leaks, verbose logging, PII in logs, API responses | Always |
| Security Headers & Config | Check response headers (CSP, HSTS, X-Frame-Options), env var handling, CORS | Web apps |
| Database Security | Check RLS policies, SECURITY DEFINER functions, GRANTs, soft-delete filters | Supabase/PostgreSQL |
| Webhook & API Security | Check signature verification, idempotency, error handling, auth on endpoints | Apps with webhooks |
| Cryptographic Practices | Check password hashing, token storage, timing-safe comparisons, key management | Apps with auth |
| Dependencies | Run `npm audit` or equivalent, check for known vulnerabilities | Always |

**Prompt template for each agent:**

```
Audit this codebase for [CATEGORY] vulnerabilities.

Tech stack context: [from Step 1]

Search for these specific patterns:
[List patterns from CHECKLIST.md for this category]

For each finding, report:
- File path and line number
- What the vulnerability is
- How it could be exploited (attack vector)
- Suggested fix

Also report correctly implemented security patterns you find (positive findings).
```

### Step 3: Compile Report

After all agents return, compile findings into a single report.

**Severity classification:**

| Severity | Criteria |
|----------|----------|
| HIGH | Exploitable without special conditions; data breach, privilege escalation, or RCE |
| MEDIUM | Exploitable with some conditions; defense-in-depth gap, partial access control bypass |
| LOW | Minor risk; information disclosure, missing hardening, best-practice gap |
| INFO | Positive finding or observation worth noting |

**Map each finding to OWASP Top 10 (2021):**

| Code | Category |
|------|----------|
| A01 | Broken Access Control |
| A02 | Cryptographic Failures |
| A03 | Injection |
| A04 | Insecure Design |
| A05 | Security Misconfiguration |
| A06 | Vulnerable Components |
| A07 | Authentication Failures |
| A08 | Software/Data Integrity Failures |
| A09 | Security Logging/Monitoring Failures |
| A10 | Server-Side Request Forgery |

### Step 4: Present Report

Use this output format:

```markdown
# Security Audit Report

## Executive Summary

[2-3 sentences: overall posture, count of findings by severity, key areas of concern]

## Findings by Severity

### HIGH (N)

| # | Finding | OWASP | File | Line |
|---|---------|-------|------|------|
| H1 | [Description] | A0X | `path/file.ts` | NNN |

[For each HIGH finding, add a details section with attack vector and suggested fix]

### MEDIUM (N)
[Same table format]

### LOW (N)
[Same table format]

### INFO (N)
[Same table format]

## Positive Security Findings

[Numbered list of correctly implemented security measures]

## OWASP Top 10 Compliance Matrix

| Category | Status | Key Issues |
|----------|--------|------------|
| A01: Broken Access Control | Good / Needs work | [refs] |
| A02: Cryptographic Failures | Good / Needs work | [refs] |
[... all 10 categories]

## Remediation Plan

### Phase 1: Critical (HIGH findings)
[Specific file:line fixes]

### Phase 2: Important (MEDIUM findings)
[Specific file:line fixes]

### Phase 3: Hardening (LOW findings)
[Specific file:line fixes]
```

### Step 5: Prompt for Action

After presenting the report, use `AskUserQuestion`:

```
Question: "What would you like to do next?"
Header: "Next step"
Options:
  - "Create issues" / "Create beads/issues for each remediation phase"
  - "Fix critical" / "Implement HIGH severity fixes now"
  - "Full remediation" / "Plan and implement all phases"
  - "Export report" / "Save report to docs/security-audit.md"
```

## Scoped Audits

When a scope argument is provided, run only the relevant category agents:

| Scope | Categories |
|-------|-----------|
| `auth` | Auth & Access Control, Cryptographic Practices |
| `api` | Webhook & API Security, Input Validation |
| `rls` or `database` | Database Security |
| `headers` or `config` | Security Headers & Config |
| `deps` | Dependencies only |

## Reference

See `CHECKLIST.md` for detailed search patterns per category.
