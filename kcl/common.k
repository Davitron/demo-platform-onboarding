schema Composition:
  apiVersion = "apiextensions.crossplane.io/v1"
  kind = "Composition"    
  metadata: Metadata
  spec: Spec


schema Metadata:
    name: str
    labels?: Labels


schema Labels:
    type: str
    location: str

schema Spec:
    _kclResources: str
    writeConnectionSecretsToNamespace: "crossplane-config"
    compositeTypeRef = {
      apiVersion: "demo.platform.bank.com/v1alpha1", 
      kind: "XOnboardingClaim",
    }
    mode = "Pipeline"
    pipeline = [
        {
            step = "kcl"
            functionRef.name = "function-kcl"
            input = {
                apiVersion = "krm.kcl.dev/v1alpha1"
                kind = "KCLRun"
                metadata.name = "kubernetes"
                spec = {
                    target = "Default"
                    source = _kclResources
                }
            }
        }, 
        {
            step = "automatically-detect-ready-composed-resources"
            functionRef.name = "function-auto-ready"
        }
    ]


schema KubernetesObject:
    name: str
    base = {
        apiVersion = "kubernetes.crossplane.io/v1alpha1"
        kind = "Object"
        spec: KubernetesObjectSpec
    }
    patches: []

schema KubernetesObjectBase:
    apiVersion = "kubernetes.crossplane.io/v1alpha1"
    kind = "Object"
    spec: KubernetesObjectSpec

schema KubernetesObjectSpec:
    forProvider: KubernetesObjectForProvider

schema KubernetesObjectForProvider:
    manifest: any

ManifestSpec = "spec.forProvider.manifest.spec"