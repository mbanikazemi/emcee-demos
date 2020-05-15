#!/bin/bash
source init.sh

## ---

echo "DEMO: Homogeneous #3: Locality load balance: sleep.foo (cluster1) -> httpbin.foo (cluster2)"

echo "---"

echo "## Deploy sleep.foo on CTX_CLUSTER1"
kubectl config use-context $CTX_CLUSTER1
kubectl create namespace foo
kubectl label namespace foo istio-injection=enabled
kubectl apply -n foo -f https://raw.githubusercontent.com/istio/istio/release-1.5/samples/sleep/sleep.yaml

echo "## Deploy helloworld.foo v2 on CTX_CLUSTER2"
kubectl config use-context $CTX_CLUSTER2
kubectl apply -n foo -f https://raw.githubusercontent.com/istio/istio/release-1.5/samples/helloworld/helloworld.yaml -l 'app=helloworld'
kubectl apply -n foo -f https://raw.githubusercontent.com/istio/istio/release-1.5/samples/helloworld/helloworld.yaml  -l 'version=v2'

sleep 20s

echo "## Expose tcp-echo.foo on $CTX_CLUSTER2 by modifying the Service with an annotation"
kubectl annotate service helloworld -n foo emcee.io/expose='true'

echo "## Test sleep.foo (cluster1) -> tcp-echo.foo (cluster2) "
kubectl config use-context $CTX_CLUSTER1
echo "## curl helloworld:5000"
kubectl exec -n foo $(kubectl get pod -n foo -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep  -- curl -s http://helloworld:5000/hello

echo "## Deploy helloworld.foo v2 on CTX_CLUSTER2"
kubectl config use-context $CTX_CLUSTER2
kubectl apply -n foo -f https://raw.githubusercontent.com/istio/istio/release-1.5/samples/helloworld/helloworld.yaml -l 'app=helloworld'
kubectl apply -n foo -f https://raw.githubusercontent.com/istio/istio/release-1.5/samples/helloworld/helloworld.yaml  -l 'version=v1'

sleep 20s

echo "## Test sleep.foo (cluster1) -> helloworld.foo (cluster2) should see v2 in output"
kubectl config use-context $CTX_CLUSTER1
echo "## curl helloworld:5000"
kubectl exec -n foo $(kubectl get pod -n foo -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep  -- curl -s http://helloworld:5000/hello

echo "## Test sleep.foo (cluster1) -> helloworld.foo (cluster1 and cluster2) - Should only see v1 in output "
kubectl config use-context $CTX_CLUSTER1
echo "## curl helloworld:5000"
kubectl exec -n foo $(kubectl get pod -n foo -l app=sleep -o jsonpath={.items..metadata.name}) -c sleep  -- curl -s http://helloworld:5000/hello


source cleanup.sh