#!/bin/bash -e
cd kubernetes
ansible-playbook -i ansible/inventory/inventory ansible/playbooks/create_cluster.yml
kubectl apply -f tiller.yml
helm init --service-account tiller --wait
kubectl get pods -n kube-system --selector app=helm
cd charts/gitlab-omnibus
helm install --name gitlab . -f values.yaml
#kubectl get pod --all-namespaces=true
#kubectl get service -n nginx-ingress nginx
cd ../prometheus
helm install --name  prom . -f custom_values.yml
helm upgrade --install grafana stable/grafana --set "adminPassword=admin" \
--set "service.type=NodePort" \
--set "ingress.enabled=true" \
--set "ingress.hosts={search-engine-grafana}"
helm upgrade --install kibana stable/kibana \
--set "ingress.enabled=true" \
--set "ingress.hosts={search-engine-kibana}" \
--set "env.ELASTICSEARCH_URL=http://elasticsearch-logging:9200" \
--version 0.1.1
cd ../efk
helm install --name  efk .
helm repo add incubator http://storage.googleapis.com/kubernetes-charts-incubator
helm upgrade --install elasticsearch-curator incubator/elasticsearch-curator --set "config.elasticsearch.hosts={elasticsearch-logging}" -f charts/es-curator/values.yaml
