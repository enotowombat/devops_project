#!/bin/bash
echo -n "Ener Docker Hub Username: "
read dockerhubuser
echo -n "Ener Docker Hub Password: "
read dockerhubpassword
echo -n "Ener Gitlab CI Username: "
read user
echo -n "Ener Gitlab CI Password: "
read password
echo "Set Docker Hub repository name to configs"
sed -i 's/dockerhubuser/'$dockerhubuser'/' $(find gitlab_ci/search-engine -name values.yaml)
echo "Git init and push applicaions to Gilab reposiory"
cd gitlab_ci/ui
git init
git remote add se_ui http://${user}:${password}@gitlab-gitlab/${dockerhubuser}/se_ui.git
git add .
git commit -m "init"
git push se_ui master
cd ../crawler
git init
git remote add se_crawler http://${user}:${password}@gitlab-gitlab/${dockerhubuser}/se_crawler.git
git add .
git commit -m "init"
git push se_crawler master
cd ../search-engine
git init
git remote add search-engine http://${user}:${password}@gitlab-gitlab/${dockerhubuser}/search-engine.git
git add .
git commit -m "init"
git push search-engine master
cd ../../
cd gitlab_ci/mongodb_exporter
echo "Build mongodb-exporter Docker image"
docker build -t ${dockerhubuser}/mongodb_exporter .
echo "Login to Docker Hub"
docker login -u $dockerhubuser -p $dockerhubpassword
echo "Push mongodb-exporter to Docker Hub"
docker push ${dockerhubuser}/mongodb_exporter
