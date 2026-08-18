# API Gateway Passthrough — Verify & Test

This stack routes public HTTPS traffic through **API Gateway → Lambda authorizer → VPC link → private ALB → app**.

```
Client
  │
  ▼
API Gateway (HTTP API, stage: prod)
  │
  ├─► Lambda authorizer (approves/denies request)
  │
  ▼
VPC link (private ENIs in your subnets)
  │
  ▼
Internal ALB (listener on port 80)
  │
  ▼
Target app (any path the ALB serves)
```

All paths are forwarded unchanged. A request to `/api/foo` on API Gateway is sent to the ALB as `/api/foo`.

---

## 1. Get endpoint values from Terraform

From the `latest-cdn-apigw` directory:

```bash
terraform output apigw_passthrough_api_url
terraform output apigw_passthrough_alb_dns_name
terraform output apigw_passthrough_authorizer_lambda
```

| Output | Purpose |
|---|---|
| `apigw_passthrough_api_url` | Public API Gateway base URL (includes `/prod`) |
| `apigw_passthrough_alb_dns_name` | Internal ALB DNS (not reachable from the internet) |
| `apigw_passthrough_authorizer_lambda` | Lambda authorizer function name |

Example API Gateway URL:

```text
https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod
```

Append any app path after `/prod`:

```text
https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod/health
https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod/api/v1/users
```

---

## 2. Test via API Gateway (full path)

Replace `{api-url}` and `{app-path}` with your values.

### Basic GET

```bash
curl -sS -D - \
  "https://{api-id}.execute-api.us-east-1.amazonaws.com/prod/{app-path}"
```

Example:

```bash
curl -sS -D - \
  "https://abc123xyz.execute-api.us-east-1.amazonaws.com/prod/health"
```

**Expected:** HTTP `200` (or whatever your ALB app returns) with the app response body.

### POST with JSON body

```bash
curl -sS -D - -X POST \
  -H "Content-Type: application/json" \
  -d '{"test": true}' \
  "https://{api-id}.execute-api.us-east-1.amazonaws.com/prod/{app-path}"
```

### Verbose (shows TLS + headers)

```bash
curl -v \
  "https://{api-id}.execute-api.us-east-1.amazonaws.com/prod/{app-path}"
```

---

## 3. Confirm the Lambda authorizer ran

Every API Gateway request hits the authorizer before the VPC link / ALB integration.

### Check authorizer logs

```bash
LAMBDA_NAME=$(terraform output -raw apigw_passthrough_authorizer_lambda)

aws logs tail "/aws/lambda/${LAMBDA_NAME}" \
  --follow \
  --region us-east-1
```

In another terminal, run a curl request. You should see a new log entry for each request.

The authorizer currently allows all traffic (`isAuthorized: true`). A `403` from API Gateway usually means the authorizer denied the request or failed.

### Check API Gateway access logs (optional)

If access logging is enabled on the stage, confirm requests appear there in CloudWatch.

---

## 4. Confirm traffic reached the ALB

The ALB is internal, so you cannot curl it directly from your laptop. Verify indirectly:

| Check | How |
|---|---|
| API Gateway returns app response | curl returns your app's JSON/HTML, not `503`/`504` |
| ALB target health | AWS Console → EC2 → Target Groups → check targets are **healthy** |
| ALB access logs | If enabled on the ALB, confirm requests with matching paths |
| App logs | Check EC2/container logs on targets behind the ALB |

### Common failure responses

| Status | Likely cause |
|---|---|
| `403` | Lambda authorizer denied or errored |
| `500` | Authorizer Lambda crash or misconfigured invoke permission |
| `503` / `504` | VPC link cannot reach ALB (security groups, subnets, or unhealthy targets) |
| `404` from API Gateway | Wrong URL or missing `/prod` stage prefix |

---

## 5. Security group checklist

If you get `503`/`504`, verify networking:

1. **VPC link SG** — egress allowed to ALB listener port (default `80`).
2. **ALB SG** — ingress allowed **from** the VPC link security group on port `80`.
3. **Target SG** — ingress allowed from the ALB security group on the app port.
4. **Subnets** — VPC link ENIs are in subnets that can reach the ALB.

Your `dev.tfvars` reuses an existing VPC link security group. If Terraform did not manage ALB ingress rules, add them manually in the console.

---

## 6. Test from inside the VPC (optional)

To compare API Gateway vs direct ALB behaviour, run curl from an EC2 instance or SSM session in the same VPC:

```bash
ALB_DNS=$(terraform output -raw apigw_passthrough_alb_dns_name)

curl -sS "http://${ALB_DNS}/{app-path}"
```

The response body should match what you get through API Gateway (same path, minus the `/prod` stage prefix on the public URL).

---

## 7. Test via CloudFront (when CDN is enabled)

When `create_cdn = true`, use:

```bash
terraform output apigw_passthrough_cdn_url
```

Or, if CDN was wired manually:

```bash
terraform output apigw_passthrough_cloudfront_origin_config
```

Example CloudFront test:

```bash
curl -sS "https://{cloudfront-domain}/{app-path}"
```

CloudFront forwards matching paths to the same API Gateway origin (`origin_path = /prod`).

---

## 8. Quick smoke-test script

```bash
#!/usr/bin/env bash
set -euo pipefail

API_URL=$(terraform output -raw apigw_passthrough_api_url)
APP_PATH="${1:-health}"

echo "API Gateway base : ${API_URL}"
echo "Testing path       : /${APP_PATH}"
echo

HTTP_CODE=$(curl -sS -o /tmp/passthrough-response.txt -w "%{http_code}" \
  "${API_URL}/${APP_PATH}")

echo "HTTP status: ${HTTP_CODE}"
echo "Response:"
cat /tmp/passthrough-response.txt
echo
```

Usage:

```bash
chmod +x smoke-test.sh
./smoke-test.sh health
./smoke-test.sh api/v1/status
```

---

## 9. Request flow summary

| Step | Component | What to verify |
|---|---|---|
| 1 | Client → API Gateway | curl reaches `execute-api` URL |
| 2 | Lambda authorizer | CloudWatch logs show invocation |
| 3 | API Gateway → VPC link | No `503`/`504` at this step |
| 4 | VPC link → ALB | ALB access logs / target metrics increment |
| 5 | ALB → app | Response body matches direct ALB test from inside VPC |

A successful end-to-end test means: **curl via API Gateway returns the same app payload you would get hitting the ALB path from inside the VPC**, and **authorizer logs show the request was approved**.
