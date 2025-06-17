.PHONY: package-generate
ITEMS = composition

GHCR_USER ?= davitron
GHCR_REPO ?= demo-platform-onboarding
GHCR_TAG  ?= v0.2.11

package-generate:
	@echo "Generating composition for package..."; \
	rm -f package/composition.yaml; \
	kcl kcl/main.k --output package/composition.yaml; \

.PHONY: ghcr-login
ghcr-login:
	@echo $$GH_PAT | docker login ghcr.io -u $(GHCR_USER) --password-stdin

.PHONY: package-publish
package-publish: ghcr-login
	@echo "Publishing package to GHCR..."; \
	crossplane xpkg build  -f ./package -o onboarding-claim.tar.gz; \
	crossplane xpkg push -f onboarding-claim.tar.gz ghcr.io/$(GHCR_USER)/$(GHCR_REPO):$(GHCR_TAG); \
