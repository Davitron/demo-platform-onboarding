import schemas
import file 

_steps: [schemas.Step] = [
    {
        name = "function-kcl",
        input_name = "provision argoproj resources", 
        dependencies = 'argoproj = "0.2.1"'
        source: file.read("kcl/argoproj_resources.k"),
    }
]


schemas.Composition {
    metadata = schemas.Metadata {
        name = "xonboardingclaims.demo.platform.bank.com"
    }
    spec = schemas.Spec {
        _kclSteps = _steps,
        compositeTypeRef = {
            apiVersion = "demo.platform.bank.com/v1alpha1",
            kind = "XOnboardingClaim",
        },
    }
}