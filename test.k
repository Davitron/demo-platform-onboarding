applicationSet = {
    apiVersion = "argoproj.io/v1alpha1"
    kind = "ApplicationSet"
    metadata = {
      name = "testy"
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
          name = "test"
          annotations = {
            "argocd.argoproj.io/sync-options" = "SkipDryRunOnMissingResource=true"
          }
        }
        spec = {
          project = "xonboardingclaims.demo.platform.bank.com"
          sources = [
            {
              repoURL = "{{ .repoURL }}"
              targetRevision = "refs/tags/{{ .name }}"
              ref = "values"
            },
            {
              repoURL = "{{ .genericChartUrl }}"
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
            namespace = "xonboardingclaims.demo.platform.bank.com"
          }

          syncPolicy = {
            automated = {
              prune = "true"
              selfHeal = "true"
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