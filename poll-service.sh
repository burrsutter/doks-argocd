MYIP=$(kubectl -n mystuff get service myapp -o jsonpath="{.status.loadBalancer.ingress[0].ip}"):8080

while true
do curl $MYIP
sleep .3
done
