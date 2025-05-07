oxr = option("params").oxr
dxr = option("params").dxr
_name = "-".join(oxr.metadata.name.split("-")[:-1])
_spec = oxr.spec

genericChartUrl = "https://github.com/Davitron/simple-generic-helm-chart.git"
_items = []

argoProject = {
    apiVersion = "argoproj.io/v1alpha1"
    kind = "AppProject"
    metadata = {
      name = _name
      namespace = "argocd"
      finalizers = ["resources-finalizer.argocd.argoproj.io"]
    }
    spec = {
      description = "Xonboarding claims"
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


applicationSet = {
  apiVersion = "argoproj.io/v1alpha1"
  kind = "ApplicationSet"
  metadata = {
    _name = _name
    namespace = "argocd"
  }
  spec = {
    goTemplate = True
    generators = [
      {
        clusters = {
          selector = {
            matchLabels = {
              "cluster_mode" = "workload"
            }
          }
        }
      }
    ]
    template = {
      metadata = {
        name = _name+"-{{ .name }}"
        annotations = {
          "argocd.argoproj.io/sync-options" = "SkipDryRunOnMissingResource=true"
        }
      }
      spec = {
        project = _name
        sources = [
          {
            repoURL = _spec.repoURL
            targetRevision = "refs/tags/{{ .name }}"
            ref = "values"
          },
          {
            repoURL = genericChartUrl
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
          namespace = _name
        }

        syncPolicy = {
          automated = {
            prune = True
            selfHeal = True
          }
          syncOptions = [
            "CreateNamespace=true",
            "PrunePropagationPolicy=foreground",
            "PruneLast=true",
            "RespectIgnoreDifferences=true",
            "ApplyOutOfSyncOnly=true",
            "ServerSideApply=true",
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

_items += [{
  apiVersion = "kubernetes.crossplane.io/v1alpha2"
  kind = "Object"
  metadata = {
    name = _name + "-project"
    annotations = {
      "crossplane.io/external-name" = _name
    }
  }
  spec = {
    managementPolicies = ["Observe", "Create", "Update", "Delete"]
    forProvider = {
      manifest = argoProject
    }
    providerConfigRef = {
      name = "provider-kubernetes"
    }
  }
}]

_items += [{
  apiVersion = "kubernetes.crossplane.io/v1alpha2"
  kind = "Object"
  metadata = {
    name = _name + "-application-set"
    annotations = {
      "crossplane.io/external-name" = _name
    }
  }
  spec = {
    managementPolicies = ["Observe", "Create", "Update", "Delete"]
    forProvider = {
      manifest = applicationSet
    }
    providerConfigRef = {
      name = "provider-kubernetes"
    }
  }
}]






items = _items