https://www.cnblogs.com/mengzisama/p/13363541.html
https://www.runoob.com/postgresql/postgresql-data-type.html
导入命令 在161上执行
导入数据
/usr/local/postgresql/bin/psql -d eye -h localhost -p 5432 -U eye_admin -f  /root/draftdetail

http://www.macrozheng.com/#/reference/nginx
es
http://www.macrozheng.com/#/reference/elasticsearch_start
http://www.macrozheng.com/#/reference/filebeat_start

kubeadm
https://kubernetes.io/zh/docs/reference/setup-tools/kubeadm/kubeadm-join/

http://www.macrozheng.com/#/deploy/mall_swarm_deploy_k8s

-- SCHEMA: public
select current_timestamp,current_date from basic_id

select date '2001-09-28' + integer '7' from basic_id
select  date '2001-09-28' + interval '1 hour' from basic_id
select make_date(2013, 7, 15)  from basic_id

select age(timestamp '1957-06-13') from basic_id
select justify_days(interval '35 days') from basic_id
select make_time(8, 15, 23.5) from basic_id
select  date '2001-10-01' - date '2001-09-28'  from basic_id
