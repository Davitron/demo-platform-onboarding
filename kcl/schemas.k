schema Spec:
    _kclSteps: [Step]
    writeConnectionSecretsToNamespace: "crossplane-config"
    compositeTypeRef: CompositeTypeRef
    mode = "Pipeline"
    pipeline = pipeline_function(_kclSteps)


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

schema Step:
  name: str
  input_name?: str
  source: any
  dependencies?: str

schema Pipeline:
  step: str
  functionRef: FunctionRef
  input?: Input


schema FunctionRef:
  name: str

schema PipelineSpec:
  target: str
  source: any
  dependencies?: str
    

schema Input:
  apiVersion: str
  kind: str
  metadata: Metadata
  spec: PipelineSpec

pipeline_function = lambda pre_steps: [Step] -> any {
  # Define the environment config pipeline step
  environment_config: [any] = [
    {
      step = "environment-config"
      functionRef.name = "function-environment-config"
      input = {
        apiVersion: "environmentconfigs.fn.crossplane.io/v1beta1"
        kind: "Input"
        spec = {
          environmentConfigs = [
            {
              type = "Reference"
              ref = {
                name = "global-environment-variables"
              }
            }
          ]
        }
      }
    }
  ]

  # Generate pipelines from pre_steps
  pipelines: [Pipeline] = [
    {
      step = "kcl"
      functionRef.name = s.name
      input = {
        apiVersion = "krm.kcl.dev/v1alpha1"
        kind = "KCLRun"
        metadata.name = s.input_name
        spec = {
          target = "Default"
          dependencies = s.dependencies
          source = s.source
        }
      }
    }
    for s in pre_steps
  ]

  # Final pipeline step
  auto_ready: [any] = [
    {
      step = "automatically-detect-ready-composed-resources"
      functionRef.name = "function-auto-ready"
    }
  ]

  # Concatenate all pipeline steps
  environment_config + pipelines + auto_ready
}


schema CompositeTypeRef:
  apiVersion: str
  kind: str

