import .common
import file 


common.Composition {
    metadata = common.Metadata {
        name = "xonboardingclaims.demo.platform.bank.com"
    }
    spec = common.Spec {
        _kclResources = file.read("kcl/argoproj_resources.k")
    }
}