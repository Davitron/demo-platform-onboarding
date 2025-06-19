import schemas
import file

_steps: [schemas.Step] = [
    {
        name = "function-kcl"
        input_name = "provision argoproj resources"
        dependencies = 'argoproj = "0.2.1"'
        source: file.read("kcl/argoproj_resources.k")
    }
]

schemas.Composition {
    metadata = schemas.Metadata {
        name = "xonboardingclaims.platform.knab.dev"
    }
    spec = schemas.Spec {
        _kclSteps = _steps
        compositeTypeRef = {
            apiVersion = "platform.knab.dev/v1alpha1"
            kind = "XOnboardingClaim"
        }
    }
}
