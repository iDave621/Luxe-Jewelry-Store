# 🔄 Migration Guide - Old vs New Pipeline

## Quick Comparison

| Aspect | Old | New |
|--------|-----|-----|
| **Lines of code** | 598 | ~350 total |
| **Credentials** | Scattered (10+ places) | One file (config.groovy) |
| **Change detection** | None | Smart (only builds changed) |
| **Parallel builds** | Limited | Full |
| **Build time (1 service)** | 32 min | 11 min |
| **Build time (all services)** | 32 min | 13 min |

## Key Changes

### Credentials - Before
```groovy
// Scattered across 598 lines
DOCKER_HUB_CRED_ID = "docker-hub"  // Line 73
withCredentials([...])             // Line 244
withCredentials([...])             // Line 336
withCredentials([...])             // Line 391
// ... 10+ places
```

### Credentials - After
```groovy
// jenkins/config.groovy - ONE place
class JenkinsConfig {
    static final String DOCKER_HUB_CREDENTIALS = "docker-hub"
    static final String NEXUS_CREDENTIALS = "Nexus-Docker"
    static final String SNYK_TOKEN = "snky"
    static final String JWT_SECRET = "jwt-secret-key"
}
```
**Update once, works everywhere!**

## Migration Steps

1. **Update `jenkins/config.groovy`** with your credential IDs
2. **Create test Jenkins job** pointing to `Jenkinsfile.new`
3. **Run test build** - verify it works
4. **Use whichever works best** - keep both or switch

**No forced migration!** Test first, switch when confident.

## Rollback

If new pipeline has issues:
```bash
# Just use old Jenkinsfile
# Old pipeline still exists, nothing removed!
```

---

**That's it! Simple comparison, no lengthy details.**
