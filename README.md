# KEDA demo

Testing KEDA by using Kind

## Caveats

Per https://github.com/kedacore/http-add-on/issues/882

Keda works by polling to see if requests are in a queue.  If by chance, when KEDA polls and the request isn't in the queue KEDA won't reset any counters and therefore will scale down the deployment.

The better method would be to change it like so, this will allow in-flight slow clients to reset the KEDA

"store and propagate last request timestamp and return if the scaler is active"

## Getting Started

Installing Kind

```
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
# For ARM64
[ $(uname -m) = aarch64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-arm64
chmod +x ./kind

# For Intel Macs
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-amd64
# For M1 / ARM Macs
[ $(uname -m) = arm64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-darwin-arm64
chmod +x ./kind
```

Setting up the cluster

```
./build-cluster.sh
```

Installing Ingress

```
./setup-ingress.sh
```

Install keda-core

```
./keda-core.sh
```

Install keda-addon

```
keda-addon.sh
```

Install an example

```
git clone https://github.com/kedacore/http-add-on.git
helm install xkcd http-add-on/examples/xkcd -n keda
```

Fix the svc redirect:
```
k -n keda patch svc xkcd-proxy -p $(jq -r -c -n '{spec: { externalName: "keda-add-ons-http-interceptor-proxy.keda.svc.cluster.local" }}')
```

In a terminal watch the events:
```
k -n keda get events -w
```

Now test: this will hang for a second while the deployment spins up
```
curl -H 'Host: myhost.com' localhost/path2
```

You'll see the events terminal light up with events that look like this:
```
0s          Normal   KEDAScaleTargetActivated     scaledobject/xkcd            Scaled apps/v1.Deployment keda/xkcd from 0 to 1
0s          Normal   ScalingReplicaSet            deployment/xkcd              Scaled up replica set xkcd-795f74df74 to 1 from 0
0s          Normal   SuccessfulCreate             replicaset/xkcd-795f74df74   Created pod: xkcd-795f74df74-f7ptz
0s          Normal   Scheduled                    pod/xkcd-795f74df74-f7ptz    Successfully assigned keda/xkcd-795f74df74-f7ptz to kind-control-plane
0s          Normal   Pulling                      pod/xkcd-795f74df74-f7ptz    Pulling image "registry.k8s.io/e2e-test-images/agnhost:2.45"
0s          Normal   Pulled                       pod/xkcd-795f74df74-f7ptz    Successfully pulled image "registry.k8s.io/e2e-test-images/agnhost:2.45" in 316.722494ms (316.745232ms including waiting)
0s          Normal   Created                      pod/xkcd-795f74df74-f7ptz    Created container xkcd
0s          Normal   Started                      pod/xkcd-795f74df74-f7ptz    Started container xkcd
```

After about 5 minutes, the deployment will scale back down and you'll see events like so:
```
0s          Normal   KEDAScaleTargetDeactivated   scaledobject/xkcd            Deactivated apps/v1.Deployment keda/xkcd from 1 to 0
0s          Normal   ScalingReplicaSet            deployment/xkcd              Scaled down replica set xkcd-795f74df74 to 0 from 1
0s          Normal   Killing                      pod/xkcd-795f74df74-f7ptz    Stopping container xkcd
0s          Normal   SuccessfulDelete             replicaset/xkcd-795f74df74   Deleted pod: xkcd-795f74df74-f7ptz
```

