# demo-platform-onboarding


```
# _items += [{
#     apiVersion = "argoproj.io/v1alpha1"
#     kind = "ApplicationSet"
#     metadata = {
#       name = _name
#       namespace = "argocd"
#     }
#     spec = {
#       generators = [
#         {
#           clusters = {
#             selector = {
#               matchLabels = {
#                 "cluster_mode" = "workload"
#               }
#             }
#           }
#         }
#       ]
#       template = {
#         metadata = {
#           name = "{}-{{ .name }}".format(_name)
#           annotations = {
#             "argocd.argoproj.io/sync-options" = "SkipDryRunOnMissingResource=true"
#           }
#         }
#         spec = {
#           project = _name
#           sources = [
#             {
#               repoURL = _spec.repoURL
#               targetRevision = "{prefix}/{{ .name }}".format(prefix = "refs/tags")
#               ref = "values"
#             },
#             {
#               repoURL = genericChartUrl
#               targetRevision = "HEAD"
#               path = "./charts"
#               helm = {
#                 valueFiles = [
#                   "$values/{{ if eq .name \"in-cluster\" }}.platform/mgnt.yaml{{ else }}.platform/{{ .metadata.labels.env }}.yaml{{ end }}"
#                 ]
#               }
#             }
#           ]
#           destination = {
#             server = "{{ .server }}"
#             namespace = _name
#           }

#           syncPolicy = {
#             automated = {
#               prune = "true"
#               selfHeal = "true"
#             }
#             syncOptions = [
#               "CreateNamespace=true",
#               "PrunePropagationPolicy=foreground",
#               "PruneLast=true",
#               "RespectIgnoreDifferences=true",
#               "ApplyOutOfSyncOnly=true",
#               "ServerSideApply=true",
#             ]
#             retry = {
#               limit = 5
#               backoff = {
#                 duration = "5s"
#                 maxDuration = "1m"
#                 factor = 2
#               }
#             }
#           }
#         }
#       }
#     }
#   }
# ]
```