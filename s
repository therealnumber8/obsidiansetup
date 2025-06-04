Below is a minimal, copy-paste-ready trio of manifests that covers
• trusting Harbor’s custom CA,
• registering its OCI Helm repo with Argo CD, and
• deploying the HedgeDoc chart that lives at `pamepkshbr02.harel-office.com/dockerhub/hedgedoc`.

All three objects go in the `argocd` namespace. Replace placeholders (`<…>`) with your real values.

## 1 – Trust the Harbor certificate

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-tls-certs-cm
  namespace: argocd
  labels:
    app.kubernetes.io/name: argocd-cm
    app.kubernetes.io/part-of: argocd
data:
  pamepkshbr02.harel-office.com: |
    -----BEGIN CERTIFICATE-----
    <root-or-intermediate-PEM-blob>
    -----END CERTIFICATE-----
```

Argo CD looks in this dedicated ConfigMap for extra CAs; the key **must** be only the host part of the repo URL.([argo-cd.readthedocs.io][1], [argo-cd.readthedocs.io][2])

## 2 – Register the OCI Helm repository

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: harbor-oci-helm
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  # Human-readable name that will show up in the UI
  name: harbor-hedgedoc
  # NOTE: no oci:// prefix here
  url: pamepkshbr02.harel-office.com/dockerhub
  type: helm
  enableOCI: "true"

  #––– optional auth –––
  #username: <robot-or-ci-user>
  #password: <token-or-password>
```

`enableOCI: "true"` tells Argo CD this is an OCI registry, not a classic Helm v3 chart index.([argo-cd.readthedocs.io][1], [medium.com][3])
If the registry is public you can omit the credentials block; otherwise supply a Harbor robot-account token.([goharbor.io][4])

## 3 – Application that pulls the chart

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hedgedoc
  namespace: argocd
spec:
  project: default
  source:
    # Matches the `url` field in the Secret
    repoURL: pamepkshbr02.harel-office.com/dockerhub
    # OCI layout ⇒ give the repository path then the chart name
    path: hedgedoc
    chart: hedgedoc
    targetRevision: "1.0.0"        # helm inspect oci://… to pick the exact tag
    helm:
      releaseName: hedgedoc
  destination:
    server: https://kubernetes.default.svc
    namespace: hedgedoc
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

### Why it works

* Argo CD pins CA certificates per-host via `argocd-tls-certs-cm`, allowing TLS validation of self-signed or private CAs instead of the risky `--insecure-skip-server-verification` flag.([argo-cd.readthedocs.io][5], [stackoverflow.com][6])
* The repository Secret follows the standard Helm-repo schema (`type: helm`) and simply flips `enableOCI` to activate OCI transport.([argo-cd.readthedocs.io][7], [github.com][8])
* OCI charts need `repoURL` (registry / project) and `path` (chart repo) + `chart` fields, mirroring Bitnami’s documented pattern.([medium.com][3], [iits-consulting.de][9])

### After applying

1. `kubectl apply -f <file>.yaml` for each section (or commit into your GitOps repo).
2. Restart `argocd-repo-server` once so it reloads the new CA bundle.([argo-cd.readthedocs.io][10])
3. Watch the app sync: `argocd app get hedgedoc`.

That’s it—Harbor’s chart should deploy cleanly with full TLS validation and without any manual `helm repo add` steps.

[1]: https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/?utm_source=chatgpt.com "Declarative Setup - Argo CD - Read the Docs"
[2]: https://argo-cd.readthedocs.io/en/release-2.2/user-guide/private-repositories/?utm_source=chatgpt.com "Private Repositories - Argo CD - Declarative GitOps CD for Kubernetes"
[3]: https://medium.com/%40qdrddr/argocd-app-with-helm-from-oci-repo-e52066647d99?utm_source=chatgpt.com "How-to build ArgoCD App with Helm from OCI Repo - Medium"
[4]: https://goharbor.io/docs/main/working-with-projects/working-with-oci/working-with-helm-oci-charts/?utm_source=chatgpt.com "Working with OCI Helm Charts - Harbor docs"
[5]: https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/?utm_source=chatgpt.com "Private Repositories - Argo CD - Declarative GitOps CD for Kubernetes"
[6]: https://stackoverflow.com/questions/75905987/argocd-using-self-signed-certificate?utm_source=chatgpt.com "ArgoCD using Self signed certificate - Stack Overflow"
[7]: https://argo-cd.readthedocs.io/en/release-2.9/operator-manual/declarative-setup/?utm_source=chatgpt.com "Declarative Setup - Argo CD - Read the Docs"
[8]: https://github.com/argoproj/argo-cd/issues/12371?utm_source=chatgpt.com "Helm in Argo CD does not use added self-signed CA for pulling ..."
[9]: https://iits-consulting.de/blog/argocd-how-to-use-a-private-oci-helm-chart-repository?utm_source=chatgpt.com "Argo CD: How to Use a private OCI Helm Chart Repository"
[10]: https://argo-cd.readthedocs.io/en/stable/operator-manual/tls/?utm_source=chatgpt.com "TLS configuration - Argo CD - Declarative GitOps CD for Kubernetes"

