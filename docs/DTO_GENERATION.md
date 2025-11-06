# Dart DTO Generation Guide

## Status

The OpenAPI specification (`docs/openapi.yaml`) has been updated with all new endpoints and schemas. However, generating Dart DTOs requires Java to be installed on your system.

## Prerequisites

To generate Dart DTOs from the OpenAPI spec, you need:

1. **Java Runtime Environment (JRE)** or **Java Development Kit (JDK)**
   - Download from: https://www.java.com/download/ or https://adoptium.net/
   - Verify installation: `java -version`
   - Set JAVA_HOME if needed: `export JAVA_HOME=$(/usr/libexec/java_home)`

## Generation Options

### Option 1: Using OpenAPI Generator CLI (Recommended)

```bash
# Install globally via npm
npm install -g @openapitools/openapi-generator-cli

# Generate Dart DTOs
openapi-generator-cli generate \
  -i docs/openapi.yaml \
  -g dart \
  -o lib/shared/data/api/dtos \
  --additional-properties=pubName=api_dtos,pubVersion=1.0.0
```

### Option 2: Using npx (No Installation)

```bash
npx --yes @openapitools/openapi-generator-cli generate \
  -i docs/openapi.yaml \
  -g dart \
  -o lib/shared/data/api/dtos \
  --additional-properties=pubName=api_dtos,pubVersion=1.0.0
```

### Option 3: Using Docker (If Java Installation Fails)

```bash
docker run --rm \
  -v ${PWD}:/local \
  openapitools/openapi-generator-cli generate \
  -i /local/docs/openapi.yaml \
  -g dart \
  -o /local/lib/shared/data/api/dtos \
  --additional-properties=pubName=api_dtos,pubVersion=1.0.0
```

## Generated Files

After generation, you should have:

- `lib/shared/data/api/dtos/lib/` - Generated Dart models and API clients
- The generated code will include all DTOs for:
  - Jobs (JobCreateRequest, JobResponse, JobStatusUpdateRequest, etc.)
  - Ratings (RatingCreateRequest, RatingResponse)
  - Matching (MatchResponse)
  - All existing endpoints (User, Documents, Stripe, etc.)

## Manual Alternative (If Generator Fails)

If you cannot generate the DTOs automatically, you can manually create them based on the OpenAPI schemas. The schemas are well-defined in `docs/openapi.yaml` under:

- `components.schemas.JobCreateRequest`
- `components.schemas.JobResponse`
- `components.schemas.JobStatusUpdateRequest`
- `components.schemas.JobStatusResponse`
- `components.schemas.MatchResponse`
- `components.schemas.RatingCreateRequest`
- `components.schemas.RatingResponse`

## Next Steps

1. Install Java if not already installed
2. Run one of the generation commands above
3. Review and adjust generated DTOs if needed
4. Import and use in your Flutter app

## Current Status

✅ OpenAPI spec updated with all new endpoints
✅ All schemas defined
⏳ DTO generation pending (requires Java installation)

