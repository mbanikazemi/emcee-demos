echo "Cleanup"
kubectl config use-context $CTX_CLUSTER1
kubectl delete deploy,svc --all -n foo
kubectl delete deploy,svc --all -n bar
kubectl delete ns foo bar
kubectl config use-context $CTX_CLUSTER2
kubectl delete deploy,svc --all -n foo
kubectl delete deploy,svc --all -n bar
kubectl delete ns foo bar