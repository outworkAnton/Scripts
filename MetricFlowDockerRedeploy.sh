docker rm $(docker ps -a -f status=exited -q)
docker rmi outwork/metric-flow
