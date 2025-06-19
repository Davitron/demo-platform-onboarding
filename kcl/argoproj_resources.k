import argoproj.v1alpha1 as argocdv1alpha1

oxr = option("params").oxr
dxr = option("params").dxr
_name = "-".join(oxr.metadata.name.split("-")[:-1:])
claim_name = oxr?.spec?.claimRef?.name
_spec = oxr.spec
# Might be used later for addons (Namespace level annotations)
_addonsMap = {}
generateAnnotations = lambda addons {
    addons_annotations = {_addonsMap[addon] = "true" for addon, enabled in addons if enabled and _addonsMap[addon]}
    dayzero = {
        **addons_annotations
        "platform.knab.dev/dayzero-config-enabled": "true"
    }
    dayzero
}

_git_url_map = {
    # might revert to ssh later depending on what BAWAG uses
    "github" = "https://github.com/bawaggroup"
    "azuredevops" = "git@ssh.dev.azure.com:v3/knab/KnabNL"
}

git_url = _git_url_map[oxr.spec.gitProvider]

generic_helm_chart = "${git_url}/avm-k8s-charts"
application_repo = "${git_url}/${claim_name}"

project = argocdv1alpha1.AppProject {
    metadata = {
        name = claim_name
        namespace = "argocd"
        finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
        description = oxr.spec.description
        sourceRepos = ["*"]
        destinations = [
            {
                name = "*"
                namespace = "*"
            }
        ]
        clusterResourceWhitelist = [
            {
                group = "*"
                kind = "*"
            }
        ]
        roles = []
    }
}

applicationset = argocdv1alpha1.ApplicationSet {
    apiVersion = "argoproj.io/v1alpha1"
    kind = "ApplicationSet"
    metadata = {
        name = claim_name
        namespace = "argocd"
        finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
        goTemplate = True
        generators = [
            {
                clusters = {}
            }
        ]
        template = {
            metadata = {
                name = claim_name + "-{{ .name }}"
                annotations = {
                    "argocd.argoproj.io/sync-options" = "SkipDryRunOnMissingResource=true"
                }
            }
            spec = {
                project = claim_name
                sources = [
                    {
                        repoURL = application_repo
                        targetRevision = "HEAD"
                        ref = "values"
                    }
                    {
                        repoURL = generic_helm_chart
                        targetRevision = "HEAD"
                        path = "./charts"
                        helm = {
                            valueFiles = [
                                "$values/{{ if eq .name \"in-cluster\" }}.platform/mgnt.yaml{{ else }}.platform/{{ .metadata.labels.env }}.yaml{{ end }}"
                            ]
                        }
                    }
                ]
                destination = {
                    server = "{{ .server }}"
                    namespace = claim_name
                }
                syncPolicy = {
                    managedNamespaceMetadata = {
                        labels = {
                            "argocd.argoproj.io/instance" = claim_name
                        }
                        annotations = {
                            "argocd.argoproj.io/tracking-id": "${claim_name}-{{ .name }}:/Namespace:${claim_name}/${claim_name}"
                            **generateAnnotations(_spec.addons)
                        }
                    }
                    automated = {
                        prune = True
                        selfHeal = True
                    }
                    syncOptions = [
                        "CreateNamespace=true"
                        "PrunePropagationPolicy=foreground"
                        "PruneLast=true"
                        "RespectIgnoreDifferences=true"
                        "ApplyOutOfSyncOnly=true"
                        "ServerSideApply=true"
                    ]
                    retry = {
                        limit = 5
                        backoff = {
                            duration = "5s"
                            maxDuration = "1m"
                            factor = 2
                        }
                    }
                }
            }
        }
    }
}

project_object = {
    apiVersion = "kubernetes.crossplane.io/v1alpha2"
    kind = "Object"
    metadata = {
        name = claim_name + "-project"
        annotations = {
            "crossplane.io/external-name" = claim_name
            "krm.kcl.dev/composition-resource-name" = "project"
        }
    }
    spec = {
        managementPolicies = ["Observe", "Create", "Update", "Delete"]
        forProvider = {
            manifest = project
        }
        providerConfigRef = {
            name = "provider-kubernetes"
        }
    }
}

applicationset_object = {
    apiVersion = "kubernetes.crossplane.io/v1alpha2"
    kind = "Object"
    metadata = {
        name = claim_name + "-applicationset"
        annotations = {
            "crossplane.io/external-name" = claim_name
            "krm.kcl.dev/composition-resource-name" = "applicationset"
        }
    }
    spec = {
        managementPolicies = ["Observe", "Create", "Update", "Delete"]
        forProvider = {
            manifest = applicationset
        }
        providerConfigRef = {
            name = "provider-kubernetes"
        }
    }
}

items = [
    project_object
    applicationset_object
]
