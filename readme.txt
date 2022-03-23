https://docs.digitalocean.com/reference/doctl/how-to/install/

https://docs.digitalocean.com/products/kubernetes/how-to/connect-to-cluster/

https://www.digitalocean.com/community/tutorials/how-to-deploy-to-kubernetes-using-argo-cd-and-gitops

brew install doctl

cd ~/devnation/doks

doctl auth init

https://cloud.digitalocean.com/account/api/tokens

doctl kubernetes cluster list

Download argocd binary
https://github.com/argoproj/argo-cd/releases

mkdir .kube

export KUBECONFIG=~/devnation/doks/.kube/config-ams3
export KUBECONFIG=~/devnation/doks/.kube/config-blr1
export KUBECONFIG=~/devnation/doks/.kube/config-tor1

export KUBE_EDITOR="code -w"
export PATH=~/devnation/bin:$PATH

doctl kubernetes cluster create ams3-kubernetes --region ams3 --node-pool="name=worker-pool;count=3"
doctl kubernetes cluster create blr1-kubernetes --region blr1 --node-pool="name=worker-pool;count=3"
doctl kubernetes cluster create tor1-kubernetes --region tor1 --node-pool="name=worker-pool;count=3"

doctl kubernetes cluster list

doctl k8s cluster kubeconfig show ams3-kubernetes >> $KUBECONFIG
# doctl kubernetes cluster kubeconfig save ams3-kubernetes
doctl k8s cluster kubeconfig show blr1-kubernetes >> $KUBECONFIG
# doctl kubernetes cluster kubeconfig save blr1-kubernetes
doctl k8s cluster kubeconfig show tor1-kubernetes >> $KUBECONFIG
# doctl kubernetes cluster kubeconfig save tor1-kubernetes

kubectl cluster-info

kubectl get nodes

# Test App

kubectl apply -f mystuff/namespace.yaml

kubectl config set-context --current --namespace=mystuff

kubectl apply -f mystuff/deployment.yaml

kubectl apply -f mystuff/service.yaml

kubectl get service quarkus-demo -o json

IP=$(kubectl get service quarkus-demo -o jsonpath="{.status.loadBalancer.ingress[0].ip}"):8080

echo $IP

curl $IP

while true
do curl $IP
sleep .3
done

kubectl delete namespace mystuff


# ArgoCD Hub

kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'

ARGOCD_PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
# really should change the default password

ARGOCD_IP=$(kubectl get service argocd-server -o jsonpath="{.status.loadBalancer.ingress[0].ip}"):80

echo $ARGOCD_IP

open http://$ARGOCD_IP

# Login with "admin" and $ARGOCD_PASS

argocd login --insecure --grpc-web $ARGOCD_IP  --username admin --password $ARGOCD_PASS

# you can change the password via "argocd account update-password"
# but it does not update the secret and can not be recovered

# Spoke 1
kubectl config get-contexts -o name
argocd cluster add --kubeconfig $KUBECONFIG do-blr1-blr1-kubernetes

# Spoke 2
kubectl config get-contexts -o name
argocd cluster add --kubeconfig $KUBECONFIG do-tor1-tor1-kubernetes

argocd cluster list

https://www.screencast.com/t/UXPfHbnOKHG

# each imported cluster has a secret
kubectl get secrets -n argocd -l argocd.argoproj.io/secret-type=cluster


# Deploy an app to the hub cluster
argocd app create quarkus-demo --repo https://github.com/burrsutter/doks-argocd.git --path mystuff --dest-server https://kubernetes.default.svc --dest-namespace mystuff
argocd app sync quarkus-demo

MYIP=$(kubectl -n mystuff get service myapp -o jsonpath="{.status.loadBalancer.ingress[0].ip}"):8080

while true
do curl $MYIP
sleep .3
done

# Make a change and make it sync
# git commit 
# git push

argocd app sync quarkus-demo --prune

# Clean up App
argocd app delete quarkus-demo

# Create an ApplicationSet for N clusters
----
argocd app list
----

there should be no Apps 

----
NAME  CLUSTER  NAMESPACE  PROJECT  STATUS  HEALTH  SYNCPOLICY  CONDITIONS  REPO  PATH  TARGET
----


kubectl apply -f myapplicationset.yaml

argocd app list

Still there should be no Apps, Apps are "generated" later

----
NAME  CLUSTER  NAMESPACE  PROJECT  STATUS  HEALTH  SYNCPOLICY  CONDITIONS  REPO  PATH  TARGET
----

https://www.screencast.com/t/D0sy7fZ1nx2G


Remember
----
kubectl get secrets -n argocd -l argocd.argoproj.io/secret-type=cluster
----

kubectl label secret env=myapptarget -n argocd -l argocd.argoproj.io/secret-type=cluster

kubectl get secrets  -l env=myapptarget -n argocd

and magic?

debugging

kubectl describe applicationset myapp

argocd app list

----
NAME                           CLUSTER                                                              NAMESPACE  PROJECT  STATUS  HEALTH   SYNCPOLICY  CONDITIONS  REPO                                           PATH      TARGET
do-blr1-blr1-kubernetes-myapp  https://a5eab264-8c96-40f0-85a9-3a3ff0a1bd2c.k8s.ondigitalocean.com  mystuff    default  Synced  Healthy  Auto-Prune  <none>      https://github.com/burrsutter/doks-argocd.git  mystuff/  main
do-tor1-tor1-kubernetes-myapp  https://7acb3943-e28b-421c-ae93-ba7bad6c043b.k8s.ondigitalocean.com  mystuff    default  Synced  Healthy  Auto-Prune  <none>      https://github.com/burrsutter/doks-argocd.git  mystuff/  main
----

https://www.screencast.com/t/azp4YoUIm9


# On each spokem wait for the external IP address

MYIP=$(kubectl -n mystuff get service myapp -o jsonpath="{.status.loadBalancer.ingress[0].ip}"):8080

while true
do curl $MYIP
sleep .3
done

https://www.screencast.com/t/Lpri31eqto0


Edit deployment.yaml and change replicas 
git commit -am "changed replicas"
git push

Refresh Hard

https://www.screencast.com/t/SafMsOr6POiS



# Remove all clusters, save some money
doctl k8s cluster delete ams3-kubernetes
doctl k8s cluster delete blr1-kubernetes
doctl k8s cluster delete tor1-kubernetes



https://stackoverflow.com/questions/66114851/kubectl-wait-for-service-to-get-external-ip

